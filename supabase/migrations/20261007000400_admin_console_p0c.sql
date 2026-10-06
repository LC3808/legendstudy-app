-- ============================================================================
-- ADMIN-P0-C — Essay / Math operations read model
--
-- This migration is READ ONLY. It creates no table, writes no row, and changes
-- no policy, price, Credit rule or evaluation state. It exists so an operator
-- can see how the evaluation pipeline is actually behaving without opening the
-- answer text of a student's essay.
--
-- Design notes
--
-- 1. Answer text is never read. essay_attempts.body and essay_drafts are not
--    touched. These functions answer "did this evaluation work, what did it
--    cost, how long did it take, on which model"; reading the essay is a
--    different, separately authorized act.
--
-- 2. Essay and Math are one surface, not two. They share the operator
--    vocabulary (type, status, outcome, Credits, re-evaluation, processing time,
--    provider/model, human review) so the console reads the same way for both,
--    and Math carries its own availability because it is a separate runtime.
--
-- 3. Authorization is public.admin_operator() from the P0-A migration. It is NOT
--    merged with public.is_quality_operator(). The two answer different
--    questions — "may this person use the operations console" and "may this
--    person judge evaluation quality" — and a shared gate would silently grant
--    one with the other. Because of that the human review STATE below is read
--    straight from the projection table rather than through the quality
--    console's ql_review_state(), whose contract requires the quality role.
--
-- 4. Optional subsystems degrade instead of failing. Math, payment and deletion
--    migrations are not applied in every environment, so absent Math is reported
--    as absent, never as zero activity.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Shape probe
--
-- Presence of a table is not enough. The Math runtime ships as several
-- migrations, so an environment can hold a partial table that exists but does
-- not yet carry the columns this read needs. Reporting that as "installed"
-- would produce a runtime error in the console; reporting it as "no activity"
-- would be a lie. It is reported as its own state.
-- ---------------------------------------------------------------------------
create function essay_private.admin_relation_ready(p_relation text, p_columns text[])
returns boolean
language sql stable security definer set search_path='' as $$
    select to_regclass(p_relation) is not null
       and not exists (
           select 1 from unnest(p_columns) c
            where not exists (select 1 from pg_attribute a
                               where a.attrelid = to_regclass(p_relation)
                                 and a.attname = c
                                 and a.attnum > 0
                                 and not a.attisdropped));
$$;
revoke all on function essay_private.admin_relation_ready(text,text[]) from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 1. Essay (인문논술) operations
--
-- One row per evaluation request, newest first. A student who rewrites an essay
-- produces a second evaluation with supersedes_evaluation_id set; the pair shows
-- as two rows flagged as re-evaluation rather than being collapsed, because "how
-- often is re-evaluation used and does it succeed" is the question.
-- ---------------------------------------------------------------------------
create function public.admin_essay_operations(
    p_limit integer default 25,
    p_status text default null,
    p_before timestamptz default null
) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
    bounded integer := least(greatest(coalesce(p_limit, 25), 1), 100);
    hq_available boolean := to_regclass('public.human_quality_judgments') is not null;
    hq_map jsonb := '{}'::jsonb;
    items jsonb := '[]'::jsonb;
    summary jsonb;
begin
    if not public.admin_operator() then
        raise sqlstate 'PT403' using message='FORBIDDEN';
    end if;
    if p_status is not null
       and p_status not in ('requested', 'processing', 'completed', 'failed', 'cancelled') then
        raise sqlstate 'PT422' using message='INVALID_STATUS';
    end if;

    -- Human review state, keyed by evaluation. The latest judgment that nothing
    -- supersedes is the current one; earlier judgments remain in the history.
    if hq_available then
        execute $q$
            select coalesce(jsonb_object_agg(x.evaluation_id::text, jsonb_build_object(
                       'disposition', x.latest_disposition,
                       'reviewed_at', x.latest_reviewed_at)), '{}'::jsonb)
              from (select j.evaluation_id,
                           (array_agg(j.overall_disposition order by j.created_at desc, j.id desc))[1]
                               as latest_disposition,
                           max(j.created_at) as latest_reviewed_at
                      from public.human_quality_judgments j
                     where not exists (select 1 from public.human_quality_judgments s
                                        where s.supersedes_judgment_id = j.id)
                     group by j.evaluation_id) x
        $q$ into hq_map;
    end if;

    select coalesce(jsonb_agg(q.row order by q.requested_at desc, q.evaluation_id desc), '[]'::jsonb)
      into items
      from (
        select jsonb_build_object(
                   'evaluation_id', e.id,
                   'attempt_id', e.attempt_id,
                   'member_id', s.user_id,
                   'status', e.status,
                   'outcome', case e.status
                                  when 'completed' then 'success'
                                  when 'failed' then 'failure'
                                  when 'cancelled' then 'failure'
                                  else 'pending' end,
                   'requested_at', e.requested_at,
                   'terminated_at', e.terminated_at,
                   'completed_at', e.completed_at,
                   'processing_ms', case
                       when e.completed_at is not null
                       then (extract(epoch from (e.completed_at - e.requested_at)) * 1000)::bigint
                       when e.terminated_at is not null
                       then (extract(epoch from (e.terminated_at - e.requested_at)) * 1000)::bigint
                       else null end,
                   'is_reevaluation', e.supersedes_evaluation_id is not null,
                   'invalidated', e.invalidated_at is not null,
                   'invalidation_reason', e.invalidation_reason,
                   'error_code', e.error_code,
                   'model_provider', e.model_provider,
                   'model_name', e.model_name,
                   'model_version', e.model_version,
                   'prompt_version', e.prompt_version,
                   'evaluation_version', e.evaluation_version,
                   'credits_charged', b.credits_required,
                   'billing_status', b.status,
                   'billing_reason', b.reason,
                   'human_review_state', case
                       when not hq_available then 'NOT_TRACKED'
                       when hq_map ? e.id::text then 'REVIEWED'
                       else 'NOT_REVIEWED' end,
                   'human_review_disposition', hq_map -> e.id::text ->> 'disposition',
                   'human_reviewed_at', hq_map -> e.id::text ->> 'reviewed_at'
               ) as row,
               e.requested_at, e.id as evaluation_id
          from public.essay_evaluations e
          join public.essay_practice_sessions s on s.id = e.session_id
          left join public.essay_billing_decisions b on b.evaluation_id = e.id
         where (p_status is null or e.status = p_status)
           and (p_before is null or e.requested_at < p_before)
         order by e.requested_at desc, e.id desc
         limit bounded
      ) q;

    select jsonb_build_object(
               'total', count(*),
               'requested', count(*) filter (where status = 'requested'),
               'processing', count(*) filter (where status = 'processing'),
               'completed', count(*) filter (where status = 'completed'),
               'failed', count(*) filter (where status = 'failed'),
               'cancelled', count(*) filter (where status = 'cancelled'),
               'reevaluations', count(*) filter (where supersedes_evaluation_id is not null)
           )
      into summary
      from public.essay_evaluations;

    return jsonb_build_object(
        'dto_version', 'admin-ops-v1',
        'type', 'humanities',
        'available', true,
        'human_review_tracked', hq_available,
        'items', items,
        'summary', summary
    );
end$$;
revoke all on function public.admin_essay_operations(integer,text,timestamptz)
    from public, anon, authenticated, service_role;
grant execute on function public.admin_essay_operations(integer,text,timestamptz) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Math (수리논술) operations
--
-- Math is a separate runtime with its own state machine (REQUESTED / PROCESSING
-- / COMPLETED / FAILED / INVALIDATED) and its own re-evaluation kind, so it is a
-- separate entry point rather than a branch of the one above.
--
-- When the Math tables are not installed the function reports that plainly. It
-- does not return an empty list, because an operator must not read "no Math
-- activity" out of "Math is not deployed".
-- ---------------------------------------------------------------------------
create function public.admin_math_operations(
    p_limit integer default 25,
    p_before timestamptz default null
) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
    bounded integer := least(greatest(coalesce(p_limit, 25), 1), 100);
    present boolean := to_regclass('public.math_attempts') is not null
                    and to_regclass('public.math_evaluations') is not null;
    installed boolean := essay_private.admin_relation_ready('public.math_evaluations',
                             array['id','attempt_id','request_kind','state','requested_at',
                                   'completed_at','contract_version','error_code'])
                     and essay_private.admin_relation_ready('public.math_attempts',
                             array['id','student_id','kind']);
    items jsonb := '[]'::jsonb;
    summary jsonb;
begin
    if not public.admin_operator() then
        raise sqlstate 'PT403' using message='FORBIDDEN';
    end if;

    if not installed then
        return jsonb_build_object(
            'dto_version', 'admin-ops-v1',
            'type', 'math',
            'available', false,
            'reason', case when present then 'SCHEMA_INCOMPLETE' else 'NOT_INSTALLED' end,
            'items', '[]'::jsonb,
            'summary', null
        );
    end if;

    execute $q$
        select coalesce(jsonb_agg(r.row order by r.requested_at desc, r.evaluation_id desc), '[]'::jsonb)
          from (
            select jsonb_build_object(
                       'evaluation_id', me.id,
                       'attempt_id', me.attempt_id,
                       'member_id', ma.student_id,
                       'attempt_kind', ma.kind,
                       'request_kind', me.request_kind,
                       'status', lower(me.state),
                       'outcome', case me.state
                                      when 'COMPLETED' then 'success'
                                      when 'FAILED' then 'failure'
                                      when 'INVALIDATED' then 'invalidated'
                                      else 'pending' end,
                       'requested_at', me.requested_at,
                       'completed_at', me.completed_at,
                       'processing_ms', case
                           when me.completed_at is not null
                           then (extract(epoch from (me.completed_at - me.requested_at)) * 1000)::bigint
                           else null end,
                       'is_reevaluation', me.request_kind = 'MATH_REEVALUATION',
                       'invalidated', me.state = 'INVALIDATED',
                       'error_code', me.error_code,
                       'model_provider', null,
                       'model_name', null,
                       'model_version', me.contract_version,
                       'prompt_version', null,
                       'credits_charged', null,
                       'billing_status', null,
                       'billing_reason', null,
                       'human_review_state', 'NOT_TRACKED',
                       'human_review_disposition', null,
                       'human_reviewed_at', null
                   ) as row,
                   me.requested_at, me.id as evaluation_id
              from public.math_evaluations me
              join public.math_attempts ma on ma.id = me.attempt_id
             where $1 is null or me.requested_at < $1
             order by me.requested_at desc, me.id desc
             limit $2
          ) r
    $q$ into items using p_before, bounded;

    execute $q$
        select jsonb_build_object(
                   'total', count(*),
                   'requested', count(*) filter (where state = 'REQUESTED'),
                   'processing', count(*) filter (where state = 'PROCESSING'),
                   'completed', count(*) filter (where state = 'COMPLETED'),
                   'failed', count(*) filter (where state = 'FAILED'),
                   'invalidated', count(*) filter (where state = 'INVALIDATED'),
                   'reevaluations', count(*) filter (where request_kind = 'MATH_REEVALUATION')
               )
          from public.math_evaluations
    $q$ into summary;

    return jsonb_build_object(
        'dto_version', 'admin-ops-v1',
        'type', 'math',
        'available', true,
        'reason', null,
        'items', items,
        'summary', summary
    );
end$$;
revoke all on function public.admin_math_operations(integer,timestamptz)
    from public, anon, authenticated, service_role;
grant execute on function public.admin_math_operations(integer,timestamptz) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Operations summary — the console's headline
--
-- Reports availability per type first and activity second, so a zero is never
-- ambiguous.
-- ---------------------------------------------------------------------------
create function public.admin_operations_summary() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
    math_present boolean := to_regclass('public.math_attempts') is not null
                        and to_regclass('public.math_evaluations') is not null;
    math_installed boolean := math_present
                          and essay_private.admin_relation_ready('public.math_evaluations',
                                  array['id','attempt_id','request_kind','state','requested_at',
                                        'completed_at','contract_version','error_code'])
                          and essay_private.admin_relation_ready('public.math_attempts',
                                  array['id','student_id','kind']);
    hq_available boolean := to_regclass('public.human_quality_judgments') is not null;
    essay jsonb;
    math jsonb;
begin
    if not public.admin_operator() then
        raise sqlstate 'PT403' using message='FORBIDDEN';
    end if;

    -- One pass, one FROM: a scalar subquery over the same table would resolve
    -- the bare column names against the outer row, which is a silent way to
    -- produce a wrong number rather than an error.
    select jsonb_build_object(
               'total', count(*),
               'pending', count(*) filter (where e.status in ('requested', 'processing')),
               'succeeded', count(*) filter (where e.status = 'completed'),
               'failed', count(*) filter (where e.status in ('failed', 'cancelled')),
               'last_24h', count(*) filter (where e.requested_at > essay_private.clock() - interval '24 hours'),
               'median_processing_ms', percentile_cont(0.5) within group (
                   order by case when e.completed_at is not null and e.completed_at >= e.requested_at
                                 then extract(epoch from (e.completed_at - e.requested_at)) * 1000 end)
           )
      into essay
      from public.essay_evaluations e;

    if math_installed then
        execute $q$
            select jsonb_build_object(
                       'total', count(*),
                       'pending', count(*) filter (where m.state in ('REQUESTED', 'PROCESSING')),
                       'succeeded', count(*) filter (where m.state = 'COMPLETED'),
                       'failed', count(*) filter (where m.state in ('FAILED', 'INVALIDATED')),
                       'last_24h', count(*) filter (where m.requested_at > essay_private.clock() - interval '24 hours'),
                       'median_processing_ms', percentile_cont(0.5) within group (
                           order by case when m.completed_at is not null and m.completed_at >= m.requested_at
                                         then extract(epoch from (m.completed_at - m.requested_at)) * 1000 end)
                   )
              from public.math_evaluations m
        $q$ into math;
    end if;

    return jsonb_build_object(
        'dto_version', 'admin-ops-v1',
        'essay', jsonb_build_object('available', true, 'summary', essay),
        'math', jsonb_build_object(
            'available', math_installed,
            'reason', case when math_installed then null
                           when math_present then 'SCHEMA_INCOMPLETE'
                           else 'NOT_INSTALLED' end,
            'summary', math),
        'human_review_tracked', hq_available,
        'human_reviewed_cases', case
            when hq_available
            then (select count(distinct j.evaluation_id) from public.human_quality_judgments j)
            else null end,
        'as_of', essay_private.clock()
    );
end$$;
revoke all on function public.admin_operations_summary()
    from public, anon, authenticated, service_role;
grant execute on function public.admin_operations_summary() to authenticated;

comment on function public.admin_essay_operations(integer,text,timestamptz) is
    'Operator read of the 인문논술 evaluation pipeline. Never reads answer text. Gated by admin_operator(); the quality role is deliberately not required and not granted.';
comment on function public.admin_math_operations(integer,timestamptz) is
    'Operator read of the 수리논술 evaluation pipeline. Reports NOT_INSTALLED rather than zero activity when the Math runtime is absent.';
comment on function public.admin_operations_summary() is
    'Operator headline for the operations console. Availability is reported before activity so a zero is never ambiguous.';