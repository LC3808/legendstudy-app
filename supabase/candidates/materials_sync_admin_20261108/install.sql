-- Additional production approval required. Existing data and original ops logs retained.
begin;
alter table ingestion_ops.config
 add column next_due_at timestamptz not null default ((date_trunc('day',now() at time zone 'Asia/Seoul')+interval '1 day 4 hours') at time zone 'Asia/Seoul'),
 add column last_success_at timestamptz,
 add column last_completed_at timestamptz,
 add column next_retry_at timestamptz,
 add column last_poll_at timestamptz;
-- First 04:00 after installation, then successful automatic completion +72h.
update ingestion_ops.config set next_due_at = case
 when (now() at time zone 'Asia/Seoul')::time < time '04:00'
 then (date_trunc('day',now() at time zone 'Asia/Seoul')+interval '4 hours') at time zone 'Asia/Seoul'
 else next_due_at end;
update ingestion_ops.config set last_completed_at=(select max(finished_at) from ingestion_ops.runs),
 last_success_at=(select max(finished_at) from ingestion_ops.runs where status in ('success','partial') and coalesce((summary->'counts'->>'failed')::int,0)=0);
alter table ingestion_ops.runs add column requested_at timestamptz not null default now(),
 add column requested_by uuid;
alter table ingestion_ops.runs alter column started_at drop not null;
alter table ingestion_ops.runs drop constraint runs_status_check;
alter table ingestion_ops.runs add constraint runs_status_check check(status in ('queued','running','success','partial','failed','interrupted','rolled_back'));
-- Installation must follow completion of the first run; never rewrite active history.
create unique index material_sync_single_active on ingestion_ops.runs ((true)) where status in ('queued','running');
alter table ingestion_ops.observations add column content_hash text;
grant update(next_due_at,last_success_at,last_completed_at,next_retry_at,last_poll_at) on ingestion_ops.config to legendstudy_material_sync;
create policy sync_schedule_update on ingestion_ops.config for update to legendstudy_material_sync using(true) with check(true);

create index material_sync_changes_run on ingestion_ops.changes(run_id,post_id);

create function ingestion_ops.admin_status() returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise insufficient_privilege; end if;
 select jsonb_build_object('version','material-sync-v1','enabled',c.enabled,'interval_hours',72,
 'next_due_at',c.next_due_at,'next_retry_at',c.next_retry_at,'last_poll_at',c.last_poll_at,
 'last_success_at',c.last_success_at,'last_completed_at',c.last_completed_at,
 'runs',coalesce((select jsonb_agg(to_jsonb(r) order by r.requested_at desc) from
  (select id,trigger_name,status,requested_at,started_at,finished_at,
    (coalesce(summary,'{}'::jsonb) - 'posts') || jsonb_build_object('metrics',coalesce(summary->'metrics',
      (select jsonb_build_object(
       'new_posts',count(*) filter(where ch.table_name='source_posts' and ch.before_row='null'::jsonb),
       'modified_posts',count(distinct ch.post_id) filter(where
         (ch.table_name<>'source_posts' or ch.after_row-array['last_crawled_at','content_hash','parser_version']<>'{}'::jsonb)
         and not exists(select 1 from ingestion_ops.changes n where n.run_id=x.id and n.post_id=ch.post_id and n.table_name='source_posts' and n.before_row='null'::jsonb)),
       'added_attachments',count(*) filter(where ch.table_name='resources' and ch.before_row='null'::jsonb),
       'replaced_attachments',count(*) filter(where ch.table_name='resources' and ch.before_row<>'null'::jsonb and ch.after_row?'source_url'),
       'removed_attachments',count(*) filter(where ch.table_name='resources' and ch.after_row->>'is_active'='false')
      ) from ingestion_ops.changes ch where ch.run_id=x.id))) as summary
    from ingestion_ops.runs x order by requested_at desc limit 15) r),'[]'::jsonb),
 'issues',coalesce((select jsonb_agg(to_jsonb(o)) from (select post_id,status,error_code,observed_at,last_success_at
   from ingestion_ops.observations where status in ('failed','review') order by observed_at desc limit 30) o),'[]'::jsonb))
 into result from ingestion_ops.config c where singleton;
 return result;
end $$;
create function ingestion_ops.admin_request() returns jsonb language plpgsql security definer set search_path='' as $$
declare active_run uuid; active_status text;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise insufficient_privilege; end if;
 if not (select enabled from ingestion_ops.config where singleton) then raise exception 'SYNC_DISABLED' using errcode='55000'; end if;
 if not pg_try_advisory_xact_lock(178431,18) then
  return jsonb_build_object('accepted',false,'status','running');
 end if;
 select id,status into active_run,active_status from ingestion_ops.runs where status in ('queued','running') limit 1;
 if active_run is not null then return jsonb_build_object('accepted',false,'id',active_run,'status',active_status); end if;
 active_run:=gen_random_uuid();
 insert into ingestion_ops.runs(id,trigger_name,status,requested_by,started_at) values(active_run,'admin','queued',auth.uid(),null);
 return jsonb_build_object('accepted',true,'id',active_run,'status','queued');
end $$;
revoke all on function ingestion_ops.admin_status(),ingestion_ops.admin_request() from public,anon;
grant usage on schema ingestion_ops to authenticated;
grant execute on function ingestion_ops.admin_status(),ingestion_ops.admin_request() to authenticated;
-- Thin public invoker endpoints. Private tables stay inaccessible to authenticated.
create function public.admin_material_sync_status() returns jsonb language sql security invoker set search_path='' as $$select ingestion_ops.admin_status()$$;
create function public.admin_material_sync_request() returns jsonb language sql security invoker set search_path='' as $$select ingestion_ops.admin_request()$$;
revoke all on function public.admin_material_sync_status(),public.admin_material_sync_request() from public,anon;
grant execute on function public.admin_material_sync_status(),public.admin_material_sync_request() to authenticated;
commit;
