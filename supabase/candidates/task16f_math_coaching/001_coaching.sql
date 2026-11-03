-- TASK16-F candidate only. NOT APPLIED to Production. Existing evaluator/billing unchanged.
begin;
grant math_executor to postgres with admin false, inherit false, set true granted by postgres;
grant create on schema math_private,public to math_executor;
grant usage on schema auth to math_executor;
grant references on public.math_evaluations,auth.users to math_executor;
set role math_executor;
create table math_private.coaching_disclosures(
 evaluation_id uuid primary key references public.math_evaluations(id) on delete cascade,
 student_id uuid not null references auth.users(id) on delete cascade,
 client_key uuid not null unique, delivered_at timestamptz not null default clock_timestamp()
);
alter table math_private.coaching_disclosures enable row level security;
revoke all on math_private.coaching_disclosures from public,anon,authenticated,service_role;

-- Only deterministic, reviewed labels are public before disclosure. Student work is not an answer secret.
create function math_private.coaching_projection(p_id uuid,p_result jsonb,p_student text,p_policy jsonb,p_disclosed boolean)
returns jsonb language plpgsql immutable set search_path='' as $$
declare tasks jsonb='[]'; strengths jsonb='[]'; concepts jsonb='[]'; item jsonb; step jsonb; title text; direction text; total integer=0;
begin
 for item in select value from jsonb_array_elements(coalesce(p_result->'errors','[]'))
  where value->>'classification'='ROOT' and coalesce(value->>'materiality','MATERIAL_ERROR') not in ('NON_ERROR_VARIATION','PRESENTATION_ISSUE')
  order by case value->>'materiality' when 'MATERIAL_ERROR' then 0 else 1 end,value->>'id' loop
  total=total+1;if total>5 then continue;end if;
  select value into step from jsonb_array_elements(coalesce(p_result->'steps','[]')) where value->>'id'=item->>'step_id';
  title=case item->>'category' when 'CALCULATION' then '계산 과정과 검산' when 'SIGN' then '부호와 식의 변형' when 'THEOREM_MISUSE' then '공식의 적용 조건' when 'CONCLUSION' then '결론과 경계 조건' else '풀이의 조건과 논리 연결' end;
  direction=case item->>'category' when 'CALCULATION' then '한 번에 계산한 부분을 나누어 다시 검산해 보세요.' when 'SIGN' then '식을 옮기거나 나누는 과정의 부호를 확인해 보세요.' when 'CONCLUSION' then '경계값이 원래 조건을 만족하는지 대입해 보세요.' else '사용한 정의와 정리의 조건이 모두 성립하는지 확인해 보세요.' end;
  tasks=tasks||jsonb_build_array(jsonb_build_object('id',item->>'id','step_id',item->>'step_id','position',step->'position','title',title,'importance',case item->>'materiality' when 'MATERIAL_ERROR' then '중요도 높음' else '중요도 보통' end,'student_formula',p_student,'description','원본에서 확인한 학생 풀이와 문제의 조건을 대조하세요.','direction',direction,'source_note','학생 확인 전사본 · AI가 다시 작성한 수식이 아닙니다.'));
 end loop;
 if exists(select 1 from jsonb_array_elements(coalesce(p_result->'steps','[]')) where value->>'status'='VALID') then
 strengths=jsonb_build_array(jsonb_build_object('title','타당한 풀이 단계의 유지','description','저장된 평가에서 타당하다고 인정된 단계가 있습니다. 학생 답안과 공식 평가 근거를 함께 확인하세요.','student_formula',p_student));end if;
 if total>0 then concepts=jsonb_build_array(jsonb_build_object('id','equivalence','name','동치 변형과 적용 조건','formula','a=b \Rightarrow a+c=b+c','description','식을 변형할 때 앞뒤 조건이 같은 해를 표현하는지 확인합니다.','condition','양변에 같은 연산을 적용하고 정의역을 유지합니다.','caution','나누는 식이 영인지, 부등식에서 부호가 바뀌는지 확인합니다.','relation','오류로 연결된 식의 변형과 조건 누락을 점검합니다.'));end if;
 return jsonb_build_object('version','math-coaching-v1','evaluation_id',p_id,'disclosed',p_disclosed,'diagnosis',case when p_result->'overall'->>'status'='NOT_DETERMINABLE' or p_result->'overall'->>'review_status'='HUMAN_REVIEW_REQUIRED' then '현재 답안은 확정 판정할 수 없습니다. 인식 결과와 평가 근거를 다시 확인해야 합니다.' when total=0 then '저장된 평가에서 우선 수정할 오류가 확인되지 않았습니다.' else '풀이에서 우선 점검할 부분이 있습니다. 조건과 계산을 확인한 뒤 직접 수정해 보세요.' end,'tasks',tasks,'remaining_task_count',greatest(0,total-5),'strengths',strengths,'concepts',concepts,'rewrite_policy',p_policy);
end$$;
revoke all on function math_private.coaching_projection(uuid,jsonb,text,jsonb,boolean) from public,anon,authenticated,service_role;

create function public.math_coaching(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare u uuid; e public.math_evaluations; a public.math_attempts; v jsonb=p_request->'payload'; action text=p_request->>'action'; answer jsonb; policy jsonb; disclosed boolean; student text; item jsonb; refs jsonb; h public.math_hints; key uuid; old math_private.coaching_disclosures; history jsonb; task jsonb; projected_tasks jsonb; source_regions jsonb; matched_text text; step_regions jsonb;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 if p_request->>'dto_version' is distinct from 'math-coaching-v1' or p_request-array['dto_version','action','payload']<>'{}' or jsonb_typeof(v) is distinct from 'object' or action not in ('read','reveal','hint','history') or action is null then raise invalid_parameter_value;end if;
 if v-(case when action='hint' then array['evaluation_id','client_submission_id','task_id','level'] when action='reveal' then array['evaluation_id','client_submission_id'] else array['evaluation_id'] end)<>'{}' then raise invalid_parameter_value;end if;
 select er.* into e from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=(v->>'evaluation_id')::uuid and ar.student_id=u;
 if not found then raise no_data_found;end if;
 if e.state<>'COMPLETED' then raise invalid_parameter_value using message='EVALUATION_NOT_COMPLETE';end if;
 select * into a from public.math_attempts where id=e.attempt_id;
 if action='reveal' then
  key=(v->>'client_submission_id')::uuid;if key is null then raise invalid_parameter_value;end if;
  perform pg_advisory_xact_lock(hashtextextended(e.id::text,716));
  select * into old from math_private.coaching_disclosures where client_key=key;
  if found and old.evaluation_id<>e.id then raise unique_violation using message='DISCLOSURE_RETRY_CONFLICT';end if;
  insert into math_private.coaching_disclosures(evaluation_id,student_id,client_key) values(e.id,u,key) on conflict(evaluation_id) do nothing;
 end if;
 disclosed=exists(select 1 from math_private.coaching_disclosures where evaluation_id=e.id and student_id=u);
 if action='history' then
  history=public.math_learning(jsonb_build_object('dto_version','math-learning-v1','action','read_learning_history','payload',jsonb_build_object('evaluation_id',e.id)))->'result';
  answer=jsonb_build_object('lineage_id',history->'lineage_id','attempts','[]'::jsonb);
  for item in select value from jsonb_array_elements(history->'attempts') loop
   answer=jsonb_set(answer,'{attempts}',answer->'attempts'||jsonb_build_array((item-'reevaluation_delta')||jsonb_build_object('solution_revealed',coalesce((item->>'solution_revealed')::boolean,false) or exists(select 1 from math_private.coaching_disclosures where evaluation_id=(item->>'evaluation_id')::uuid))));
  end loop;
 elsif action='hint' then
  if v->>'level' is null or (v->>'level')::integer not in (1,2) or v->>'client_submission_id' is null then raise invalid_parameter_value;end if;
  select hints.* into h from public.math_hints hints join public.math_core core on core.id=hints.core_id where core.evaluation_id=e.id and core.error_id=(v->>'task_id')::uuid and hints.level=(v->>'level')::integer and hints.validated;
  if not found then raise invalid_parameter_value using message='HINT_UNAVAILABLE';end if;
  perform public.math_reveal_hint(h.id,(v->>'client_submission_id')::uuid);
  answer=jsonb_build_object('level',h.level,'body',case when h.level=1 then '사용한 정의·정리의 적용 조건을 확인하고 원래 문제의 조건과 대조하세요.' else '조건을 적용한 각 계산을 검산하고 수정한 풀이를 원래 풀이와 비교하세요.' end);
 else
  policy=(public.math_learning(jsonb_build_object('dto_version','math-learning-v1','action','read_learning_state','payload',jsonb_build_object('evaluation_id',e.id)))->'result'->'included_reevaluation')||jsonb_build_object('paid_available',false);
  select string_agg(coalesce(nullif(normalized_math,''),raw_text),E'\n' order by reading_order) into student from public.math_extraction_regions where run_id=e.selected_extraction_id;
  student=coalesce(student,a.typed_answer,'');
  answer=math_private.coaching_projection(e.id,e.result,student,policy,disclosed)||jsonb_build_object('attempt_id',a.id,'lineage_id',a.lineage_id,'completed_at',e.completed_at);
  -- Original confirmed region text is authoritative; never copy AI step.representation.
  projected_tasks='[]';
  for task in select value from jsonb_array_elements(answer->'tasks') loop
   select value->'regions' into step_regions from jsonb_array_elements(e.result->'steps') where value->>'id'=task->>'step_id';
   select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'artifact_id',r.artifact_id,'page',r.page,'reading_order',r.reading_order,'x',r.x,'y',r.y,'width',r.width,'height',r.height) order by r.reading_order),'[]'),
    string_agg(coalesce(nullif(r.normalized_math,''),r.raw_text),E'\n' order by r.reading_order)
    into source_regions,matched_text from public.math_extraction_regions r
    where r.run_id=e.selected_extraction_id and exists(select 1 from jsonb_array_elements(coalesce(step_regions,'[]')) z where z#>>'{}'=r.id::text or z->>'region_id'=r.id::text);
   projected_tasks=projected_tasks||jsonb_build_array(task||jsonb_build_object('source_regions',source_regions,'student_formula',coalesce(matched_text,student),'source_note',case when matched_text is null then '단계별 원본 영역 연결 미확정 · 전체 학생 확인 전사본' else '해당 단계에 연결된 학생 확인 전사본' end));
  end loop;
  answer=jsonb_set(answer,'{tasks}',projected_tasks);
  answer=answer||(select jsonb_build_object('exam_label',ps.label||' · '||s.leaf_key) from public.math_subproblems s join public.math_problems p on p.id=s.problem_id join public.math_problem_sets ps on ps.id=p.problem_set_id where s.id=e.leaf_id);
  if disclosed then
   select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'origin',s.origin,'body',s.body)),'[]') into refs from public.math_considered_references cr join public.math_canonical_solutions s on s.id=cr.solution_id where cr.evaluation_id=e.id;
   answer=answer||jsonb_build_object('full_solution',jsonb_build_object('steps',e.result->'steps','paths',e.result->'paths','references',refs,'generated_solution',e.result->'generated_solution'));
  end if;
 end if;
 return jsonb_build_object('dto_version','math-coaching-v1','action',action,'result',answer);
end$$;
revoke all on function public.math_coaching(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_coaching(jsonb) to authenticated;
reset role;
revoke usage on schema auth from math_executor;
revoke references on public.math_evaluations,auth.users from math_executor;
revoke create on schema public,math_private from math_executor;
revoke math_executor from postgres granted by postgres;
commit;
