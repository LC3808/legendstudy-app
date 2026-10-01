-- LSA-2C: canonical shared-backend Quality READ authorization. NOT APPLIED.
-- Owner review/application only. No provider005/day_targets ledger repair.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
create table public.quality_operators (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
alter table public.quality_operators owner to postgres;
alter table public.quality_operators enable row level security;
-- Clear inherited/default grants, including service_role excess privileges.
revoke all on table public.quality_operators from public,anon,authenticated,service_role;
grant select,insert,delete on table public.quality_operators to service_role;
create function public.is_quality_operator() returns boolean
language plpgsql stable security definer set search_path='' as $$
declare claims jsonb; expiry numeric;
begin
 -- Identity is always auth.uid(); API JWT signature validation remains at the gateway.
 -- Require an unexpired verified request context, also denying missing/malformed context.
 claims := nullif(current_setting('request.jwt.claims',true),'')::jsonb;
 if auth.uid() is null or claims->>'sub' is distinct from auth.uid()::text or claims->>'role' is distinct from 'authenticated' or jsonb_typeof(claims->'exp') is distinct from 'number' then return false; end if;
 expiry := (claims->>'exp')::numeric;
 if expiry <= extract(epoch from statement_timestamp()) then return false; end if;
 return exists(select 1 from public.quality_operators q where q.user_id=auth.uid());
exception when invalid_text_representation or numeric_value_out_of_range then return false;
end$$;

-- Composite cursor fixes timestamp ties. Signature intentionally differs from LAB draft.
create function public.ql_list_cases(p_limit integer default 50,p_before timestamptz default null,p_before_id uuid default null)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare n integer := least(100,greatest(1,coalesce(p_limit,50))); result jsonb;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501'; end if;
 if (p_before is null) <> (p_before_id is null) then raise exception 'paired cursor required' using errcode='22023'; end if;
 with page as materialized (
  select e.* from public.essay_evaluations e
  where p_before is null or (e.requested_at,e.id)<(p_before,p_before_id)
  order by e.requested_at desc,e.id desc limit n+1
 ), shown as materialized (select * from page order by requested_at desc,id desc limit n),
 summaries as (
 select e.requested_at,e.id,pg_catalog.jsonb_build_object(
  'evaluation_id',e.id,'attempt_id',e.attempt_id,'question_id',e.question_id,
  'university_name',u.name,'exam_name',ex.exam_name,'admission_year',ex.admission_year,'question_label',q.label,
  'requested_at',e.requested_at,'completed_at',e.completed_at,'submitted_at',a.submitted_at,
  'status',e.status,'request_kind',e.request_kind,'invalidated_at',e.invalidated_at,
  'model_provider',e.model_provider,'model_name',e.model_name,'prompt_version',e.prompt_version,
  'contract_version',e.contract_version,'evaluation_version',e.evaluation_version,
  'regime_key',e.regime_key,'evidence_manifest_sha256',e.evidence_manifest_sha256,
  'core_count',case when e.contract_version='1.3' and e.status='completed' and not exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=e.id and p.scaffolding_observation is null) then
    (select count(*) from public.essay_improvement_progress p where p.evaluation_id=e.id
       and p.status<>'resolved' and p.scaffolding_observation->'core_focus'='true'::jsonb) else null end,
  'has_generated_rewrite',exists(select 1 from public.essay_generated_rewrites rw where rw.evaluation_id=e.id),
  'has_subsequent_student_attempt',exists(select 1 from public.essay_attempts sa where sa.session_id=e.session_id and sa.attempt_no>a.attempt_no),
  'processing_outcome',(select pr.status from public.essay_ai_processing_runs pr where pr.evaluation_id=e.id and pr.rewrite_id is null order by pr.run_no desc limit 1),
  'student_pseudonym',left(pg_catalog.md5(ps.user_id::text),12)
 ) as item
 from shown e join public.essay_attempts a on a.id=e.attempt_id
 join public.essay_practice_sessions ps on ps.id=e.session_id
 join public.essay_questions q on q.id=e.question_id join public.essay_exams ex on ex.id=q.essay_exam_id
 join public.universities u on u.id=ex.university_id
 )
 select pg_catalog.jsonb_build_object('dto_version','ql-read-v1','cases',
   coalesce((select jsonb_agg(item order by requested_at desc,id desc) from summaries),'[]'::jsonb),
   'next_cursor',case when (select count(*) from page)>n then
     (select jsonb_build_object('requested_at',requested_at,'evaluation_id',id) from shown order by requested_at,id limit 1) else null end)
 into result;
 return result;
end$$;
create function public.ql_case_detail(p_evaluation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
stable
as $$
declare
    v jsonb;
begin
    if not public.is_quality_operator() then
        raise exception 'not authorized' using errcode = '42501';
    end if;
    if p_evaluation_id is null then
        raise exception 'evaluation id required' using errcode = '22004';
    end if;

    select pg_catalog.jsonb_build_object(
        'dto_version', 'ql-read-v1',
        'evaluation_id', e.id,
        'question_context', pg_catalog.jsonb_build_object(
            'question_id', q.id,
            'question_label', q.label,
            'university', u.name,
            'exam_name', ex.exam_name,
            'admission_year', ex.admission_year,
            'campus', ex.campus,
            'admission_track', ex.admission_track,
            'verification_status', ex.verification_status,
            'official_source_url', ex.official_source_url,
            'question_metadata_version', a.question_metadata_version,
            'submitted_conditions', a.conditions_snapshot
        ),
        'student_submission', pg_catalog.jsonb_build_object(
            'attempt_id', a.id,
            'attempt_no', a.attempt_no,
            'submitted_at', a.submitted_at,
            'character_count', a.character_count,
            'input_method', a.input_method,
            'body_sha256', a.body_sha256,
            'count_rule_version', a.count_rule_version,
            'answer_full_text', a.body            -- full student answer: quality verification source
        ),
        'student_pseudonym', left(pg_catalog.md5(ps.user_id::text), 12),
        'evaluation', pg_catalog.jsonb_build_object(
            'status', e.status,
            'request_kind', e.request_kind,
            'supersedes_evaluation_id', e.supersedes_evaluation_id,
            'correction_reason', e.correction_reason,
            'invalidated_at', e.invalidated_at,
            'invalidation_reason', e.invalidation_reason,
            'overall_summary', e.overall_summary,
            'strengths', pg_catalog.to_jsonb(e.strengths),
            'rewrite_checklist', pg_catalog.to_jsonb(e.rewrite_checklist),
            'uncertainty_note', e.uncertainty_note,
            'error_code', e.error_code,
            'requested_at', e.requested_at,
            'completed_at', e.completed_at
        ),
        'dimensions', coalesce((
            select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                       'dimension_id', d.id,
                       'criterion_id', c.id,
                       'criterion_definition_version', c.definition_version,
                       'criterion_description', c.description,
                       'source_evidence_id', c.source_evidence_id,
                       'criterion_key', c.criterion_key,
                       'criterion_label', c.label,
                       'origin', c.origin,
                       'official_weight_percent', c.official_weight_percent,
                       'level_1_to_5', d.level_1_to_5,
                       'explanation', d.explanation,
                       'uncertainty_note', d.uncertainty_note
                   ) order by d.display_order)
            from public.essay_evaluation_dimensions d
                join public.essay_evaluation_criteria c on c.id = d.criterion_id
            where d.evaluation_id = e.id
        ), '[]'::jsonb),
        'improvements', coalesce((
            select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                       'progress_id', ip.id,
                       'previous_progress_id', ip.previous_progress_id,
                       'previous_progress', (select pg_catalog.jsonb_build_object(
                         'progress_id', pp.id,'evaluation_id',pp.evaluation_id,'status',pp.status,
                         'previous_progress_id',pp.previous_progress_id,'explanation',pp.explanation,
                         'next_action',pp.next_action,'scaffolding_observation',pp.scaffolding_observation)
                         from public.essay_improvement_progress pp where pp.id=ip.previous_progress_id),
                       'is_core', case when ip.scaffolding_observation is null then null
                         else ip.status<>'resolved' and (ip.scaffolding_observation->>'core_focus')::boolean end,
                       'scaffolding_observation', ip.scaffolding_observation,
                       'issue_key', ii.issue_key,
                       'category', ii.category,
                       'status', ip.status,
                       'title', ip.title,
                       'explanation', ip.explanation,
                       'next_action', ip.next_action,
                       'priority', ip.priority
                   ) order by ip.priority, ii.issue_key, ip.id)
            from public.essay_improvement_progress ip
                join public.essay_improvement_items ii on ii.id = ip.issue_id
            where ip.evaluation_id = e.id
        ), '[]'::jsonb),
        'scaffolding_availability', case when e.status<>'completed' then 'not_completed'
            when e.contract_version<>'1.3' then 'legacy_not_available'
            when exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=e.id and p.scaffolding_observation is null)
              then 'incomplete' else 'available' end,
        'core_improvement_keys', case when e.contract_version<>'1.3' or e.status<>'completed' or exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=e.id and p.scaffolding_observation is null) then null else coalesce((
            select pg_catalog.jsonb_agg(i.issue_key order by p.priority,i.issue_key,p.id)
            from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id
            where p.evaluation_id=e.id and p.status<>'resolved' and p.scaffolding_observation->'core_focus'='true'::jsonb
        ),'[]'::jsonb) end,
        'sentence_feedback', case when e.contract_version<>'1.3' or e.status<>'completed' or exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=e.id and p.scaffolding_observation is null) then null else coalesce((
            select pg_catalog.jsonb_agg(s.value || pg_catalog.jsonb_build_object('linked_issue_key',i.issue_key,'progress_id',p.id)
                order by p.priority,i.issue_key,p.id,s.ordinality)
            from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id
            cross join lateral pg_catalog.jsonb_array_elements(p.scaffolding_observation->'sentences') with ordinality s(value,ordinality)
            where p.evaluation_id=e.id
        ),'[]'::jsonb) end,
        'history_context', e.input_snapshot->'scaffolding_context',
        'previous_review_representation', 'progress_links_and_uncertainty; original review array not stored',
        'reference_metadata_scope', 'current_catalog; frozen bindings identify evaluated versions',
        'official_evidence', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
            'evidence_id',qe.id,'resource_id',qe.resource_id,'role',qe.role,'source_locator',qe.source_locator,
            'mapping_version',qe.mapping_version,'source_sha256',qe.source_sha256,
            'source_url',r.source_url) order by qe.id)
            from public.essay_question_evidence qe join public.resources r on r.id=qe.resource_id
            where qe.question_id=e.question_id),'[]'::jsonb),
        'evaluation_evidence_links', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
            'evidence_id',ee.evidence_id,'dimension_id',ee.dimension_id,'progress_id',ee.improvement_progress_id) order by ee.id)
            from public.essay_evaluation_evidence ee where ee.evaluation_id=e.id),'[]'::jsonb),
        'frozen_evidence_bindings', e.input_snapshot->'evidence',
        'frozen_criterion_bindings', e.input_snapshot->'criteria',
        'student_attempts', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
            'attempt_id',sa.id,'attempt_no',sa.attempt_no,'submitted_at',sa.submitted_at,
            'answer_full_text',sa.body,'body_sha256',sa.body_sha256) order by sa.attempt_no)
            from (select * from public.essay_attempts sa where sa.session_id=e.session_id
                  and sa.attempt_no between a.attempt_no-10 and a.attempt_no+10 order by sa.attempt_no limit 21) sa),'[]'::jsonb),
        'attempt_window',pg_catalog.jsonb_build_object('from',greatest(1,a.attempt_no-10),'to',a.attempt_no+10,
            'truncated',exists(select 1 from public.essay_attempts sa where sa.session_id=e.session_id
                              and (sa.attempt_no<a.attempt_no-10 or sa.attempt_no>a.attempt_no+10))),
        'generated_rewrite', (
            select pg_catalog.jsonb_build_object(
                       'status', r.status,
                       'origin', r.origin,          -- always 'ai_generated'; distinct from student rewrite attempt
                       'body', r.body,
                       'completed_at', r.completed_at
                   )
            from public.essay_generated_rewrites r
            where r.evaluation_id = e.id
            order by r.created_at desc
            limit 1
        ),
        'provenance', pg_catalog.jsonb_build_object(
            'model_provider', e.model_provider,
            'model_name', e.model_name,
            'model_version', e.model_version,
            'prompt_version', e.prompt_version,
            'contract_version', e.contract_version,
            'evaluation_version', e.evaluation_version,
            'regime_key', e.regime_key,
            'evidence_completeness', e.evidence_completeness,
            'evidence_manifest_sha256', e.evidence_manifest_sha256,
            'input_sha256', e.input_sha256,
            'output_sha256', e.output_sha256
        ),
        'processing', (
            select pg_catalog.jsonb_build_object(
                       'run_id', pr.id,
                       'run_no', pr.run_no,
                       'started_at', pr.started_at,
                       'completed_at', pr.completed_at,
                       'provider', pr.provider,
                       'model_name', pr.model_name,
                       'status', pr.status,
                       'latency_ms', pr.latency_ms,
                       'input_tokens', pr.input_tokens,
                       'output_tokens', pr.output_tokens,
                       'cost_amount', pr.cost_amount,
                       'cost_basis', pr.cost_basis,
                       'currency', pr.currency,
                       'error_code', pr.error_code,
                       'timed_out_at', pr.timed_out_at
                   )
            from public.essay_ai_processing_runs pr
            where pr.evaluation_id = e.id and pr.rewrite_id is null and pr.selected_result
            order by pr.run_no desc
            limit 1
        ),
        'latest_processing', (select pg_catalog.jsonb_build_object('run_id',pr.id,'run_no',pr.run_no,'status',pr.status,
            'provider',pr.provider,'model_name',pr.model_name,'started_at',pr.started_at,'completed_at',pr.completed_at,
            'selected_result',pr.selected_result,'error_code',pr.error_code,'timed_out_at',pr.timed_out_at,
            'latency_ms',pr.latency_ms,'input_tokens',pr.input_tokens,'output_tokens',pr.output_tokens,
            'cost_amount',pr.cost_amount,'cost_basis',pr.cost_basis,'currency',pr.currency)
            from public.essay_ai_processing_runs pr where pr.evaluation_id=e.id and pr.rewrite_id is null
            order by pr.run_no desc limit 1),
        'session_evaluations_truncated',(select pg_catalog.count(*)>100 from
            (select 1 from public.essay_evaluations se where se.session_id=e.session_id limit 101) bounded),
        -- Session-level navigation for longitudinal review (bounded, ids/status only).
        'session_evaluations', coalesce((
            select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                       'evaluation_id', se.id,
                       'attempt_id', se.attempt_id,
                       'supersedes_evaluation_id',se.supersedes_evaluation_id,
                       'invalidated_at',se.invalidated_at,
                       'status', se.status,
                       'requested_at', se.requested_at
                   ) order by se.requested_at desc,se.id desc)
            from (select se.* from public.essay_evaluations se where se.session_id=e.session_id
                  order by se.requested_at desc,se.id desc limit 100) se
        ), '[]'::jsonb)

    )
    into v
    from public.essay_evaluations e
        join public.essay_attempts          a  on a.id  = e.attempt_id
        join public.essay_practice_sessions ps on ps.id = e.session_id
        join public.essay_questions         q  on q.id  = e.question_id
        join public.essay_exams             ex on ex.id = q.essay_exam_id
        join public.universities            u  on u.id  = ex.university_id
    where e.id = p_evaluation_id;

    if v is null then
        raise exception 'case not found' using errcode = 'P0002';
    end if;

    return v;
end;
$$;


alter function public.is_quality_operator() owner to postgres;
alter function public.ql_list_cases(integer,timestamptz,uuid) owner to postgres;
alter function public.ql_case_detail(uuid) owner to postgres;
revoke all on function public.is_quality_operator(),public.ql_list_cases(integer,timestamptz,uuid),public.ql_case_detail(uuid) from public,anon,authenticated,service_role;
grant execute on function public.is_quality_operator(),public.ql_list_cases(integer,timestamptz,uuid),public.ql_case_detail(uuid) to authenticated;
commit;
