-- LegendStudy feedback notification worker support.
-- Candidate only: do not apply to Production without independent review.

begin;

alter table public.feedback_notifications
    add column next_attempt_at timestamptz default pg_catalog.now(),
    add column claimed_at timestamptz,
    add column claim_token uuid;

update public.feedback_notifications
set next_attempt_at = pg_catalog.now()
where next_attempt_at is null;

alter table public.feedback_notifications
    drop constraint if exists feedback_notifications_status_check;

alter table public.feedback_notifications
    add constraint feedback_notifications_status_check
    check (status in ('pending', 'processing', 'sent', 'failed'));

alter table public.feedback_notifications
    add constraint feedback_notifications_processing_claim_check
    check (
        (status = 'processing') =
        (claimed_at is not null and claim_token is not null)
    );

alter table public.feedback_notifications
    add constraint feedback_notifications_non_processing_claim_clear
    check (
        status = 'processing' or (claimed_at is null and claim_token is null)
    );

create index feedback_notifications_claimable
    on public.feedback_notifications (next_attempt_at, created_at, id)
    where status in ('pending', 'failed') and attempt_count < 8;

create function public.claim_feedback_notifications(p_batch_size integer default 10)
returns table (
    notification_id uuid,
    feedback_id uuid,
    claim_token uuid,
    attempt_count integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
    bounded_batch integer := least(greatest(coalesce(p_batch_size, 1), 1), 10);
begin
    return query
    with candidates as (
        select n.id
        from public.feedback_notifications as n
        where n.attempt_count < 8
          and (
              (n.status = 'pending' and
               coalesce(n.next_attempt_at, pg_catalog.now()) <= pg_catalog.now())
              or
              (n.status = 'failed' and n.next_attempt_at is not null and
               n.next_attempt_at <= pg_catalog.now())
          )
        order by coalesce(n.next_attempt_at, n.created_at), n.created_at, n.id
        for update skip locked
        limit bounded_batch
    ), claimed as (
        update public.feedback_notifications as n
        set status = 'processing',
            attempt_count = n.attempt_count + 1,
            claimed_at = pg_catalog.now(),
            claim_token = pg_catalog.gen_random_uuid()
        from candidates as c
        where n.id = c.id
        returning n.id, n.feedback_id, n.claim_token, n.attempt_count
    )
    select c.id, c.feedback_id, c.claim_token, c.attempt_count
    from claimed as c;
end;
$$;

create function public.complete_feedback_notification(
    p_notification_id uuid,
    p_claim_token uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.feedback_notifications
    set status = 'sent',
        sent_at = pg_catalog.now(),
        last_error_code = null,
        next_attempt_at = null,
        claimed_at = null,
        claim_token = null
    where id = p_notification_id
      and status = 'processing'
      and claim_token = p_claim_token;
    return found;
end;
$$;

create function public.fail_feedback_notification(
    p_notification_id uuid,
    p_claim_token uuid,
    p_error_code text,
    p_retryable boolean
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    current_attempt integer;
    retry_at timestamptz;
begin
    if p_error_code is null or
       p_error_code not in (
           'network', 'timeout', 'rate_limited', 'provider_5xx',
           'provider_rejected', 'invalid_config', 'invalid_recipient', 'unknown'
       ) then
        return false;
    end if;

    select attempt_count into current_attempt
    from public.feedback_notifications
    where id = p_notification_id
      and status = 'processing'
      and claim_token = p_claim_token
    for update;

    if not found then return false; end if;

    retry_at := case
        when p_retryable and current_attempt < 3 and current_attempt = 1
            then pg_catalog.now() + pg_catalog.make_interval(mins => 1)
        when p_retryable and current_attempt < 3 and current_attempt = 2
            then pg_catalog.now() + pg_catalog.make_interval(mins => 5)
        else null
    end;

    update public.feedback_notifications
    set status = 'failed',
        sent_at = null,
        last_error_code = p_error_code,
        next_attempt_at = retry_at,
        claimed_at = null,
        claim_token = null
    where id = p_notification_id;
    return true;
end;
$$;

create function public.reclaim_feedback_notification_leases(
    p_lease_seconds integer default 900
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    reclaimed integer;
    lease_seconds integer := least(greatest(coalesce(p_lease_seconds, 900), 60), 3600);
begin
    update public.feedback_notifications
    set status = 'failed',
        next_attempt_at = pg_catalog.now(),
        claimed_at = null,
        claim_token = null,
        last_error_code = 'timeout'
    where status = 'processing'
      and claimed_at < pg_catalog.now() -
          pg_catalog.make_interval(secs => lease_seconds);
    get diagnostics reclaimed = row_count;
    return reclaimed;
end;
$$;

revoke all on function public.claim_feedback_notifications(integer)
    from public, anon, authenticated;
revoke all on function public.complete_feedback_notification(uuid, uuid)
    from public, anon, authenticated;
revoke all on function public.fail_feedback_notification(uuid, uuid, text, boolean)
    from public, anon, authenticated;
revoke all on function public.reclaim_feedback_notification_leases(integer)
    from public, anon, authenticated;

grant execute on function public.claim_feedback_notifications(integer) to service_role;
grant execute on function public.complete_feedback_notification(uuid, uuid) to service_role;
grant execute on function public.fail_feedback_notification(uuid, uuid, text, boolean) to service_role;
grant execute on function public.reclaim_feedback_notification_leases(integer) to service_role;

commit;
