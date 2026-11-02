-- Candidate: close legacy standalone Math result/hint/state bypasses too.
-- Mixed essay_exam_history is a separate rollout blocker: do not enable globally until audited.
begin;
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public,math_private to math_executor;
set role math_executor;
alter function public.math_evaluation_detail(uuid) rename to math_evaluation_detail_task16f_legacy;
revoke all on function public.math_evaluation_detail_task16f_legacy(uuid) from public,anon,authenticated,service_role;
create function public.math_evaluation_detail(p_id uuid) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare u uuid; answer jsonb;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 answer=public.math_evaluation_detail_task16f_legacy(p_id);
 if not exists(select 1 from math_private.coaching_disclosures where evaluation_id=p_id and student_id=u) then
  answer=jsonb_build_object('evaluation_id',p_id,'disclosed',false,'coaching_required',true);
 end if;return answer;
end$$;
revoke all on function public.math_evaluation_detail(uuid) from public,anon,authenticated,service_role;
grant execute on function public.math_evaluation_detail(uuid) to authenticated,postgres;
alter function public.math_reveal_hint(uuid,uuid) rename to math_reveal_hint_task16f_legacy;
revoke all on function public.math_reveal_hint_task16f_legacy(uuid,uuid) from public,anon,authenticated,service_role;
create function public.math_reveal_hint(p_hint uuid,p_key uuid) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare answer jsonb;
begin
 answer=public.math_reveal_hint_task16f_legacy(p_hint,p_key);
 return (answer-'body')||jsonb_build_object('body',case when answer->>'level'='0' then '문제의 조건과 학생 풀이의 해당 단계를 대조하세요.' when answer->>'level'='1' then '사용한 정의와 정리의 적용 조건을 확인하세요.' else '각 계산을 검산하고 수정한 풀이를 원래 풀이와 비교하세요.' end);
end$$;
revoke all on function public.math_reveal_hint(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.math_reveal_hint(uuid,uuid) to authenticated,postgres;
reset role;
-- Existing math_learning is owned by postgres, unlike the two Math-owned helpers.
alter function public.math_learning(jsonb) rename to math_learning_task16f_legacy;
revoke all on function public.math_learning_task16f_legacy(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_learning_task16f_legacy(jsonb) to math_executor;
create function public.math_learning(p_request jsonb) returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare answer jsonb; data jsonb; rows jsonb; item jsonb;
begin
 answer=public.math_learning_task16f_legacy(p_request);data=answer->'result';
 if p_request->>'action'='read_learning_state' then
  rows='[]';for item in select value from jsonb_array_elements(data->'core') loop
   rows=rows||jsonb_build_array(jsonb_build_object('core_id',item->'core_id','position',item->'position','error_id',item->'error_id','step_id',item->'step_id','title','풀이 단계 확인','diagnosis','조건과 계산을 대조하세요.','why','사용한 개념의 조건을 확인하세요.','next_action','직접 풀이를 수정하세요.'));
  end loop;data=(data-'reevaluation_delta')||jsonb_build_object('core',rows,'reevaluation_delta',null);
 elsif p_request->>'action'='read_learning_history' then
  rows='[]';for item in select value from jsonb_array_elements(data->'attempts') loop rows=rows||jsonb_build_array(item-'reevaluation_delta');end loop;
  data=jsonb_set(data,'{attempts}',rows);
 end if;
 return jsonb_set(answer,'{result}',data);
end$$;
revoke all on function public.math_learning(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_learning(jsonb) to authenticated,math_executor;
revoke create on schema public,math_private from math_executor;
revoke math_executor from postgres granted by postgres;
commit;
