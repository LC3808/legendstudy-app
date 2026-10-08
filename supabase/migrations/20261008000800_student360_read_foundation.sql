-- Additive, operator-gated supplement to the existing member detail/credit RPCs.
-- Same Essay source can serve the student/report contract. No new fact store.
begin;
create function student_private.essay_summary(p_user uuid) returns jsonb language sql stable set search_path='' as $$
 with sessions as materialized (
  select s.id,s.question_id,s.created_at,q.label question_label,x.admission_year,u.id university_id,u.name university_name
  from public.essay_practice_sessions s join public.essay_questions q on q.id=s.question_id
  join public.essay_exams x on x.id=q.essay_exam_id join public.universities u on u.id=x.university_id
  where s.user_id=p_user order by s.created_at desc,s.id desc limit 50
 ), evaluations as materialized (
  select e.id,e.attempt_id,e.question_id,e.session_id,e.status,e.request_kind,e.invalidated_at,e.completed_at,e.supersedes_evaluation_id,
   e.regime_key,e.evaluation_version,e.contract_version,e.evidence_manifest_sha256,e.requested_at,a.submitted_at,a.question_metadata_version,
   e.strengths[1:10] strengths,e.rewrite_checklist[1:10] rewrite_checklist
  from public.essay_evaluations e join sessions s on s.id=e.session_id join public.essay_attempts a on a.id=e.attempt_id
  order by e.requested_at desc,e.id desc limit 50
 ) select jsonb_build_object('version','essay-summary-v1','session_limit',50,'evaluation_limit',50,
 'has_more_sessions',exists(select 1 from public.essay_practice_sessions where user_id=p_user order by created_at desc,id desc offset 50 limit 1),
 'has_more_evaluations',exists(select 1 from public.essay_evaluations e join sessions s on s.id=e.session_id order by e.requested_at desc,e.id desc offset 50 limit 1),
 'sessions',coalesce((select jsonb_agg(to_jsonb(s)||jsonb_build_object(
 'attempt_count',(select count(*) from public.essay_attempts a where a.session_id=s.id),
 'latest_activity',(select max(a.submitted_at) from public.essay_attempts a where a.session_id=s.id)) order by s.created_at desc,s.id desc) from sessions s),'[]'::jsonb),
 'evaluations',coalesce((select jsonb_agg(to_jsonb(e)||jsonb_build_object('dimensions',
  coalesce((select jsonb_agg(jsonb_build_object('criterion_id',d.criterion_id,'definition_version',c.definition_version,'level_1_to_5',d.level_1_to_5,'display_order',d.display_order) order by d.display_order)
   from public.essay_evaluation_dimensions d join public.essay_evaluation_criteria c on c.id=d.criterion_id where d.evaluation_id=e.id),'[]'::jsonb)) order by e.requested_at desc,e.id desc) from evaluations e),'[]'::jsonb))
$$;
create function public.my_essay_summary() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 return student_private.essay_summary(auth.uid());
end$$;
create function public.admin_student360(p_account_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare identity jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 if p_account_id is null or not exists(select 1 from auth.users where id=p_account_id) then raise sqlstate 'PT404' using message='MEMBER_NOT_FOUND';end if;
 if not account_private.allowed(p_account_id) then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 select jsonb_build_object('display_name',p.display_name,'academic_status',p.academic_status,'school_office_code',p.neis_office_code,'school_code',p.neis_school_code,'grade_level',p.grade_level,'intended_major',p.intended_major) into identity from public.profiles p where p.id=p_account_id;
 return jsonb_build_object('version','student360-v1','as_of',statement_timestamp(),
 'identity',identity,'study',student_private.study_summary(p_account_id,statement_timestamp()),
 'applications',student_private.applications(p_account_id,0),'essay',student_private.essay_summary(p_account_id),
 'academic_performance',null,'period_entitlement',null);
end$$;
revoke all on function student_private.essay_summary(uuid),public.my_essay_summary(),public.admin_student360(uuid) from public,anon,authenticated;
grant execute on function public.my_essay_summary(),public.admin_student360(uuid) to authenticated;
commit;
-- Disable only the new RPC grants to roll back exposure. Existing Admin/QL remains unchanged.
