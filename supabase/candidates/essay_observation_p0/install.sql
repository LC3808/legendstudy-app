-- CANDIDATE ONLY. Owner approval required. Additive owner-scoped SELECT projections.
-- No dispatch, claim, retry, Credit, History, RLS or package mutation.
begin;
create function public.essay_exam_request_status(p_key uuid,p_exam uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare u uuid=auth.uid(); r essay_exam_private.runs;
begin
 perform math_private.require_active(array[u]);
 select x.* into r from essay_exam_private.runs x join public.credit_accounts a on a.id=x.account_id
 where a.user_id=u and x.request_key=p_key and x.exam_id=p_exam;
 return jsonb_build_object('version','exam-request-status-v1','found',r.id is not null,
 'run_id',r.id,'exam_id',r.exam_id,'parent_id',r.parent_id,
 'previous_paid_run_id',to_jsonb(r)->'previous_paid_run_id','state',r.state);
end $fn$;

create function public.essay_exam_observation(p_run uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare u uuid=auth.uid(); result jsonb; expected integer;
begin
 perform math_private.require_active(array[u]);
 -- One SELECT snapshot binds retry generation, checkpoint state and official
 -- labels. Never combine status from one generation with a later generation.
 with owned as (
   select r.* from essay_exam_private.runs r join public.credit_accounts a on a.id=r.account_id
   where r.id=p_run and a.user_id=u
 ), context as (
   select r.*,coalesce(t.attempts,'{}'::jsonb) attempts,coalesce(t.generation,0) generation
   from owned r left join lateral (select * from essay_exam_private.retry_requests
     where run_id=r.id order by generation desc limit 1) t on true
 ), states as (
   select r.id,a.ordinality,q.display_order,jsonb_build_object('question_id',a.value->>'questionId','label',q.label,'state',
     case when r.state='completed' then 'completed'
     when c.state='checkpoint' and c.payload->>'state' in ('completed','failed','reconciling') then c.payload->>'state'
     when c.state='pending' then 'processing' else 'waiting' end) value
   from context r cross join lateral jsonb_array_elements(r.snapshot->'answers') with ordinality a(value,ordinality)
   join public.essay_questions q on q.id=(a.value->>'questionId')::uuid and q.essay_exam_id=r.exam_id
   left join essay_exam_private.checkpoints c on c.run_id=r.id and c.key='q'||(a.ordinality-1)||
     case when coalesce((r.attempts->>(a.ordinality-1)::text)::integer,0)=0 then '' else '-retry-'||(r.attempts->>(a.ordinality-1)::text) end
 )
 select jsonb_build_object('version','exam-session-v1','run_id',r.id,'exam_id',r.exam_id,'state',r.state,'generation',r.generation,
   'questions',(select jsonb_agg(s.value order by s.display_order,s.ordinality) from states s),
   'retry_allowed',r.state='reserved' and not exists(select 1 from essay_exam_private.checkpoints where run_id=r.id and key='final')
     and exists(select 1 from states s where s.value->>'state'='failed')
     and not exists(select 1 from states s where s.value->>'state' not in ('completed','failed')))
 ,jsonb_array_length(r.snapshot->'answers')
 into result,expected from context r;
 if result is null then raise sqlstate 'PT404';end if;
 if jsonb_array_length(result->'questions') is distinct from expected then raise exception 'QUESTION_METADATA_UNAVAILABLE';end if;
 return result;
end $fn$;

create function public.essay_exam_question_result(p_run uuid,p_question uuid) returns jsonb
language plpgsql security definer set search_path='' as $fn$
declare u uuid=auth.uid(); r essay_exam_private.runs; a jsonb; idx bigint; n integer;
 cp essay_exam_private.checkpoints; checked essay_exam_private.checkpoints;
 k text; pkg jsonb; entry jsonb; ver text; criteria jsonb; h jsonb; q jsonb;
begin
 perform math_private.require_active(array[u]);
 select x.* into r from essay_exam_private.runs x join public.credit_accounts c on c.id=x.account_id where x.id=p_run and c.user_id=u;
 if r.id is null then raise sqlstate 'PT404';end if;
 select x.value,x.ordinality-1 into a,idx from jsonb_array_elements(r.snapshot->'answers') with ordinality x(value,ordinality) where x.value->>'questionId'=p_question::text;
 if a is null then raise sqlstate 'PT404';end if;
 h=public.essay_exam_history(p_run)->'runs'->0;
 if r.state='completed' then return h;end if;
 if r.state<>'reserved' then raise sqlstate 'PT409' using message='QUESTION_RESULT_UNAVAILABLE';end if;
 select coalesce((t.attempts->>idx::text)::integer,0) into n from essay_exam_private.retry_requests t where t.run_id=p_run order by t.generation desc limit 1;
 k='q'||idx||case when coalesce(n,0)=0 then '' else '-retry-'||n end;
 select * into cp from essay_exam_private.checkpoints where run_id=p_run and key=k;
 select * into checked from essay_exam_private.checkpoints where run_id=p_run and key=k||'-reviewed';
 if cp.state is distinct from 'checkpoint' or cp.payload->>'state' is distinct from 'completed'
 or checked.state is distinct from 'checkpoint' or cp.payload->'output' is distinct from checked.payload->'p_output'
 or cp.payload->>'evaluation_id' is distinct from checked.payload->>'p_evaluation'
 or cp.payload->'output'->>'contract_version' is distinct from '1.3'
 or cp.payload->'output'->>'answer_hash' is distinct from encode(sha256(convert_to(a->>'body','UTF8')),'hex')
 or not exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and key=k||'-usage' and state='checkpoint')
 then raise sqlstate 'PT409' using message='QUESTION_RESULT_UNAVAILABLE';end if;
 -- Resolve only the frozen, still-authorized package through the existing contract.
 pkg=public.essay_material_runtime_package(r.exam_id,r.snapshot->'runtime'->>'package_digest');
 ver='material-'||(pkg->>'package_version')||'-'||(pkg->>'package_digest');
 if a->>'rubricVersion' is distinct from ver or a->>'evidenceVersion' is distinct from ver then raise exception 'FROZEN_QUESTION_SET';end if;
 select x into entry from jsonb_array_elements(pkg->'questions') x where x->>'question_id'=p_question::text;
 select jsonb_agg(jsonb_build_object('binding',jsonb_build_object('id',extensions.uuid_generate_v5('bfbc9384-f407-440d-aa9e-45e2f485a849',ver||'/'||p_question||'/criterion/'||(m.ordinality-1)),'version',ver),'label',m.value->>'evidenceText') order by m.ordinality)
 into criteria from jsonb_array_elements(entry->'source_page_references') with ordinality m(value,ordinality) where m.value->>'role'='criteria';
 if criteria is null or exists(select 1 from jsonb_array_elements(cp.payload->'output'->'dimensions') d where not exists(select 1 from jsonb_array_elements(criteria) c where c->'binding'->>'id'=d->>'criterion_id')) then raise exception 'CRITERION_VERSION';end if;
 q=jsonb_build_object('questionId',p_question,'rubricVersion',ver,'evidenceVersion',ver,'criteria',criteria,'evaluation',(cp.payload->'output')-'local_reviews');
 return h||jsonb_build_object('result_scope','completed_question','question_state','completed','answers',jsonb_build_array(a),'result',jsonb_build_object('questions',jsonb_build_array(q)));
end $fn$;
revoke all on function public.essay_exam_request_status(uuid,uuid),public.essay_exam_observation(uuid),public.essay_exam_question_result(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.essay_exam_request_status(uuid,uuid),public.essay_exam_observation(uuid),public.essay_exam_question_result(uuid,uuid) to authenticated;
commit;
