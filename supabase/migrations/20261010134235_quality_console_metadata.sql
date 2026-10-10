-- CANDIDATE ONLY: Owner final apply approval required. No data/ACL changes.
-- Domain-separated SHA-256 of high-entropy Auth UUID is a stable pseudonym,
-- NOT anonymization or a secret. Only operator-gated RPCs may return it.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
do $preflight$
begin
 if md5(pg_get_functiondef('public.qlm_list_cases(integer,timestamp with time zone,uuid)'::regprocedure)) <> '09e99c01c3b50850e4cf6e3778d847d8'
 or md5(pg_get_functiondef('public.qlm_case_detail(uuid)'::regprocedure)) <> '06a6eec442d7ff3f3869b4b74cde82ba'
 then raise exception 'QUALITY_METADATA_BASELINE_DRIFT'; end if;
 if exists(select 1 from pg_proc where oid in ('public.qlm_list_cases(integer,timestamp with time zone,uuid)'::regprocedure,'public.qlm_case_detail(uuid)'::regprocedure)
 and (proowner <> 'postgres'::regrole or proacl::text is distinct from '{postgres=X/postgres,authenticated=X/postgres}'))
 then raise exception 'QUALITY_METADATA_ACL_DRIFT'; end if;
end $preflight$;
create or replace function public.qlm_list_cases(integer,timestamp with time zone,uuid)
returns jsonb language plpgsql volatile security definer set search_path='' as $function$
declare n integer:=least(100,greatest(1,coalesce($1,20)));v jsonb;
begin
 perform math_private.hq_require_operator(null);
 if ($2 is null)<>($3 is null) then raise invalid_parameter_value;end if;
 with page as materialized (
  select e.* from public.math_evaluations e
  where e.state='COMPLETED' and exists(select 1 from public.math_attempts a
   where a.id=e.attempt_id and account_private.allowed(a.student_id))
  and ($2 is null or (e.completed_at,e.id)<($2,$3))
  order by e.completed_at desc,e.id desc limit n
 )
 select coalesce(jsonb_agg(jsonb_build_object('evaluation_id',e.id,'completed_at',e.completed_at,
 'leaf_id',e.leaf_id,'quality_metadata',
jsonb_build_object(
 'version','quality-metadata-v1',
 'student_reference','qs1_'||pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
   'legendstudy:quality:subject:v1:'||a.student_id::text,'UTF8')),'hex'),
 'attempt_id',a.id,'lineage_id',case when root.id is not null then a.lineage_id end,
 'root_attempt_id',root.id,'predecessor_attempt_id',case when pa.id is not null then a.predecessor_id end,
 'prior_evaluation_id',case when pa.id is not null and prior.leaf_id=e.leaf_id then a.prior_evaluation_id end,
 'relationship_state',case when root.id is null then 'UNLINKED'
   when a.kind='INITIAL' and a.id=root.id then 'ROOT'
   when pa.id is not null and prior.leaf_id=e.leaf_id then 'LINKED' else 'UNLINKED' end,
 'problem_set_id',ps.id,'problem_id',p.id,'leaf_id',e.leaf_id,
 'problem_label',case when ps.label is not null and p.display_order is not null
   then ps.label||' · 문항 '||p.display_order::text end,
 'essay_type','math','exam_id',ex.id,'university_id',ex.university_id,
 'university_name',case when ex.verification_status='verified' and ex.verified_at is not null then u.name end,
 'academic_year',case when ex.verification_status='verified' and ex.verified_at is not null then ex.admission_year end,
 'exam_metadata_verified',coalesce(ex.verification_status='verified' and ex.verified_at is not null,false),
 'evaluation_profile_id',e.profile_id,'rubric_version',ep.rubric_version)) order by e.completed_at desc,e.id desc),'[]'::jsonb)
 into v from page e
join public.math_attempts a on a.id=e.attempt_id
 left join public.math_attempts root on root.id=a.lineage_id and root.student_id=a.student_id
   and root.leaf_id=a.leaf_id and root.kind='INITIAL' and root.lineage_id=root.id
 left join public.math_evaluations prior on prior.id=a.prior_evaluation_id
 left join public.math_attempts pa on pa.id=prior.attempt_id and pa.id=a.predecessor_id
   and pa.student_id=a.student_id and pa.leaf_id=a.leaf_id and pa.lineage_id=a.lineage_id
 left join public.math_subproblems l on l.id=e.leaf_id
 left join public.math_problems p on p.id=l.problem_id
 left join public.math_problem_sets ps on ps.id=p.problem_set_id
 left join public.essay_exams ex on ex.id=ps.essay_exam_id
 left join public.universities u on u.id=ex.university_id
 left join public.math_evaluation_profiles ep on ep.id=e.profile_id;
 return jsonb_build_object('dto_version','qlm-read-v1','cases',v);
end $function$;

create or replace function public.qlm_case_detail(uuid)
returns jsonb language plpgsql volatile security definer set search_path='' as $function$
declare metadata jsonb; existing jsonb;
begin
 perform math_private.hq_require_operator($1);
 existing:=math_private.evaluation_projection($1,true);
 select jsonb_build_object(
 'version','quality-metadata-v1',
 'student_reference','qs1_'||pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
   'legendstudy:quality:subject:v1:'||a.student_id::text,'UTF8')),'hex'),
 'attempt_id',a.id,'lineage_id',case when root.id is not null then a.lineage_id end,
 'root_attempt_id',root.id,'predecessor_attempt_id',case when pa.id is not null then a.predecessor_id end,
 'prior_evaluation_id',case when pa.id is not null and prior.leaf_id=e.leaf_id then a.prior_evaluation_id end,
 'relationship_state',case when root.id is null then 'UNLINKED'
   when a.kind='INITIAL' and a.id=root.id then 'ROOT'
   when pa.id is not null and prior.leaf_id=e.leaf_id then 'LINKED' else 'UNLINKED' end,
 'problem_set_id',ps.id,'problem_id',p.id,'leaf_id',e.leaf_id,
 'problem_label',case when ps.label is not null and p.display_order is not null
   then ps.label||' · 문항 '||p.display_order::text end,
 'essay_type','math','exam_id',ex.id,'university_id',ex.university_id,
 'university_name',case when ex.verification_status='verified' and ex.verified_at is not null then u.name end,
 'academic_year',case when ex.verification_status='verified' and ex.verified_at is not null then ex.admission_year end,
 'exam_metadata_verified',coalesce(ex.verification_status='verified' and ex.verified_at is not null,false),
 'evaluation_profile_id',e.profile_id,'rubric_version',ep.rubric_version) into metadata from public.math_evaluations e
 join public.math_attempts a on a.id=e.attempt_id
 left join public.math_attempts root on root.id=a.lineage_id and root.student_id=a.student_id
   and root.leaf_id=a.leaf_id and root.kind='INITIAL' and root.lineage_id=root.id
 left join public.math_evaluations prior on prior.id=a.prior_evaluation_id
 left join public.math_attempts pa on pa.id=prior.attempt_id and pa.id=a.predecessor_id
   and pa.student_id=a.student_id and pa.leaf_id=a.leaf_id and pa.lineage_id=a.lineage_id
 left join public.math_subproblems l on l.id=e.leaf_id
 left join public.math_problems p on p.id=l.problem_id
 left join public.math_problem_sets ps on ps.id=p.problem_set_id
 left join public.essay_exams ex on ex.id=ps.essay_exam_id
 left join public.universities u on u.id=ex.university_id
 left join public.math_evaluation_profiles ep on ep.id=e.profile_id where e.id=$1;
 return existing||jsonb_build_object('quality_metadata',metadata);
end $function$;
-- CREATE OR REPLACE retains OIDs, owner and ACL. No GRANT, REVOKE or table write.
commit;
