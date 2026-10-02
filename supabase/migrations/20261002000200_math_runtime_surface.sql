-- MATH-2D bounded runtime consumer surface. No Production activation.
begin;
do $$begin
 if current_user<>'postgres' or (select rolsuper from pg_roles where rolname=current_user) then raise exception 'NON_SUPERUSER_POSTGRES_REQUIRED';end if;
 if to_regclass('public.math_attempts') is null then raise exception 'MATH_2C_REQUIRED';end if;
 if has_schema_privilege('math_executor','public','CREATE') or exists(select 1 from pg_auth_members where roleid='math_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'UNEXPECTED_TOPOLOGY';end if;
end$$;
create unique index math_confirmed_candidate_once on public.math_extraction_runs(predecessor_id) where kind='CONFIRMED';
-- Exact existing six-function allowlist in runtime/ownership.json; no new owner category.
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to math_executor;
set role math_executor;
create or replace function public.math_register_artifact(uuid,jsonb) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts; v jsonb=$2; new_id uuid=gen_random_uuid(); path text; old public.math_attempt_artifacts;
begin
 select * into a from public.math_attempts where id=$1;
 if a.student_id is distinct from math_private.current_subject() then raise insufficient_privilege;end if;
 perform math_private.require_active(array[a.student_id]);perform 1 from public.math_attempts where id=a.id for update;
 if v is null or jsonb_typeof(v)<>'object' or v-array['position','media_type','byte_size','content_sha256','width','height','orientation']<>'{}' or octet_length(v::text)>2048 or a.input_kind='TYPED' or exists(select 1 from public.math_evaluations where attempt_id=a.id) then raise invalid_parameter_value;end if;
 select * into old from public.math_attempt_artifacts where attempt_id=a.id and position=(v->>'position')::integer;
 if found then
  if row(old.media_type,old.byte_size,old.content_sha256,old.width,old.height,old.orientation) is distinct from row(v->>'media_type',(v->>'byte_size')::bigint,v->>'content_sha256',(v->>'width')::integer,(v->>'height')::integer,(v->>'orientation')::integer) then raise unique_violation using message='ARTIFACT_RETRY_CONFLICT';end if;
  return jsonb_build_object('artifact_id',old.id,'storage_state',old.storage_state,'upload_available',false);
 end if;
 if (select count(*) from public.math_attempt_artifacts where attempt_id=a.id)>=20 or exists(select 1 from public.math_extraction_runs where attempt_id=a.id) then raise invalid_parameter_value using message='EVIDENCE_FROZEN';end if;
 path=a.student_id::text||'/'||a.id::text||'/raw/'||new_id::text;
 insert into public.math_attempt_artifacts(id,attempt_id,position,namespace,bucket,object_key,media_type,byte_size,content_sha256,width,height,orientation,storage_state)
 values(new_id,a.id,(v->>'position')::integer,'raw','math-private',path,v->>'media_type',(v->>'byte_size')::bigint,v->>'content_sha256',(v->>'width')::integer,(v->>'height')::integer,(v->>'orientation')::integer,'REGISTERED');
 return jsonb_build_object('artifact_id',new_id,'storage_state','REGISTERED','upload_available',false);
end$math_fn$;
create or replace function public.math_confirm_extraction(uuid,uuid,jsonb) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts;r public.math_extraction_runs;new_id uuid;v jsonb=$3;item jsonb;region public.math_extraction_regions; old public.math_extraction_runs; h text; latest uuid;
begin
 select * into a from public.math_attempts where id=$1;
 if a.student_id is distinct from math_private.current_subject() then raise insufficient_privilege;end if;
 perform math_private.require_active(array[a.student_id]);perform 1 from public.math_attempts where id=a.id for update;
 select * into r from public.math_extraction_runs where id=$2 and attempt_id=a.id and kind='CANDIDATE' and state='COMPLETED';
 if r.id is null or jsonb_typeof(v) is distinct from 'array' or jsonb_array_length(v)>100 or octet_length(v::text)>262144 then raise invalid_parameter_value;end if;
 if (select count(distinct z->>'region_id') from jsonb_array_elements(v) z)<>jsonb_array_length(v) then raise invalid_parameter_value;end if;
 for item in select value from jsonb_array_elements(v) loop
  if jsonb_typeof(item->'raw_text') is distinct from 'string' or jsonb_typeof(item->'normalized_math') is distinct from 'string' or item-array['region_id','raw_text','normalized_math']<>'{}' or not(item ?& array['region_id','raw_text','normalized_math']) or not exists(select 1 from public.math_extraction_regions where id=(item->>'region_id')::uuid and run_id=r.id) then raise invalid_parameter_value;end if;
 end loop;
 if exists(select 1 from public.math_extraction_regions z where run_id=r.id and uncertain and not exists(select 1 from jsonb_array_elements(v) q where (q->>'region_id')::uuid=z.id)) then raise invalid_parameter_value using message='UNCERTAINTY_NOT_CONFIRMED';end if;
 select id into latest from public.math_extraction_runs where attempt_id=a.id and kind='CANDIDATE' order by created_at desc,id desc limit 1;
 if latest is distinct from r.id then raise invalid_parameter_value using message='STALE_CONFIRMATION';end if;
 h=encode(sha256(convert_to(jsonb_build_array(r.output_sha256,v)::text,'UTF8')),'hex');
 select * into old from public.math_extraction_runs where predecessor_id=r.id and kind='CONFIRMED';
 if found then
  if old.output_sha256 is distinct from h then raise unique_violation using message='CONFIRMATION_RETRY_CONFLICT';end if;
  return old.id;
 end if;
 if exists(select 1 from public.math_evaluations where attempt_id=a.id) then raise invalid_parameter_value using message='INPUT_FROZEN';end if;
 insert into public.math_extraction_runs(attempt_id,predecessor_id,kind,state,confirmed_at,output_sha256) values(a.id,r.id,'CONFIRMED','COMPLETED',clock_timestamp(),encode(sha256(convert_to(jsonb_build_array(r.output_sha256,v)::text,'UTF8')),'hex')) returning math_extraction_runs.id into new_id;
 for region in select * from public.math_extraction_regions where run_id=r.id order by reading_order loop
  select value into item from jsonb_array_elements(v) where (value->>'region_id')::uuid=region.id;
  insert into public.math_extraction_regions(run_id,attempt_id,artifact_id,page,reading_order,raw_text,normalized_math,confidence,uncertain,x,y,width,height)
  values(new_id,a.id,region.artifact_id,region.page,region.reading_order,coalesce(item->>'raw_text',region.raw_text),coalesce(item->>'normalized_math',region.normalized_math),region.confidence,false,region.x,region.y,region.width,region.height);
 end loop;
 return new_id;
end$math_fn$;
create or replace function public.math_request_evaluation(uuid,uuid) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts;e public.math_evaluations;p uuid;run uuid;h text;solution_pins jsonb;
begin
 select * into a from public.math_attempts where id=$1;
 if a.student_id is distinct from math_private.current_subject() then raise insufficient_privilege;end if;
 perform math_private.require_active(array[a.student_id]);perform math_private.lock_account_attempt(a.id);
 if $2 is null then raise invalid_parameter_value;end if;
 h=encode(sha256(convert_to(a.id::text,'UTF8')),'hex');
 select * into e from public.math_evaluations where idempotency_key=$2;
 if found then if e.attempt_id<>a.id or e.request_sha256<>h then raise unique_violation;end if;return e.id;end if;
 if exists(select 1 from public.math_evaluations where attempt_id=a.id and state in ('REQUESTED','PROCESSING','COMPLETED')) then raise unique_violation using message='ATTEMPT_ALREADY_EVALUATED';end if;
 if a.input_kind<>'TYPED' then
  select x.id into run from public.math_extraction_runs x where x.attempt_id=a.id and x.kind='CONFIRMED' and x.state='COMPLETED' and x.predecessor_id=(select id from public.math_extraction_runs where attempt_id=a.id and kind='CANDIDATE' order by created_at desc,id desc limit 1);
  if run is null or exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id and storage_state<>'PRESENT') then raise invalid_parameter_value using message='INPUT_NOT_READY';end if;
 end if;
 p=math_private.resolve_profile(a.leaf_id);
 select coalesce(jsonb_agg(id order by id),'[]') into solution_pins from public.math_canonical_solutions where leaf_id=a.leaf_id and state='ACTIVE';
 insert into public.math_evaluations(attempt_id,leaf_id,profile_id,selected_extraction_id,request_kind,idempotency_key,request_sha256,state,authority_solutions)
 values(a.id,a.leaf_id,p,run,case when a.kind='INITIAL' then 'MATH_INITIAL_EVALUATION' else 'MATH_REEVALUATION' end,$2,h,'REQUESTED',solution_pins) returning * into e;
 insert into public.math_evaluation_sources(evaluation_id,source_id) select e.id,s.id from public.math_source_artifacts s join public.math_subproblems l on l.problem_id=s.problem_id where l.id=a.leaf_id;
 insert into public.math_evaluation_criteria(evaluation_id,leaf_id,criterion_id) select e.id,a.leaf_id,id from public.math_scoring_criteria where leaf_id=a.leaf_id;
 perform math_private.authorize_billing(e.id);return e.id;
end$math_fn$;
create or replace function public.math_claim_extraction(uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts;r public.math_extraction_runs;
begin
 select * into a from public.math_attempts where id=$1;
 perform math_private.require_active(array[a.student_id]);perform 1 from public.math_attempts where id=a.id for update;
 if exists(select 1 from public.math_evaluations where attempt_id=a.id) then raise invalid_parameter_value using message='INPUT_FROZEN';end if;
 if a.input_kind='TYPED' or not exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id) or exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id and storage_state<>'PRESENT') then raise invalid_parameter_value using message='INPUT_NOT_READY';end if;
 update public.math_extraction_runs set state='FAILED',error_code='TIMEOUT' where attempt_id=a.id and state='PROCESSING' and lease_until<=clock_timestamp();
 if exists(select 1 from public.math_extraction_runs where attempt_id=a.id and state='PROCESSING') then raise unique_violation using message='EXTRACTION_IN_PROGRESS';end if;
 insert into public.math_extraction_runs(attempt_id,kind,state,lease_token,lease_until) values(a.id,'CANDIDATE','PROCESSING',gen_random_uuid(),clock_timestamp()+interval '5 minutes') returning * into r;
 return jsonb_build_object('run_id',r.id,'lease_token',r.lease_token,'lease_until',r.lease_until,'artifacts',(select jsonb_agg(jsonb_build_object('artifact_id',id,'position',position,'media_type',media_type) order by position) from public.math_attempt_artifacts where attempt_id=a.id));
end$math_fn$;
create or replace function public.math_finalize_extraction(uuid,uuid,jsonb) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare r public.math_extraction_runs;a public.math_attempts;v jsonb=$3;item jsonb;h text;
begin
 select * into r from public.math_extraction_runs where id=$1;select * into a from public.math_attempts where id=r.attempt_id;perform math_private.require_active(array[a.student_id]);
 perform 1 from public.math_attempts where id=r.attempt_id for update;
 select * into r from public.math_extraction_runs where id=$1 for update;
 h=encode(sha256(convert_to(v::text,'UTF8')),'hex');
 if r.state='COMPLETED' and r.lease_token=$2 and r.output_sha256=h then return r.id;end if;
 if r.kind<>'CANDIDATE' or r.state<>'PROCESSING' or r.lease_token is distinct from $2 or $2 is null or r.lease_until<=clock_timestamp() then raise invalid_parameter_value using message='STALE_EXTRACTION_FENCE';end if;
 if v is null or jsonb_typeof(v)<>'object' or v-array['regions','provider','model','model_version']<>'{}' or octet_length(v::text)>262144 or jsonb_typeof(v->'regions') is distinct from 'array' or jsonb_array_length(v->'regions') not between 1 and 100 then raise invalid_parameter_value;end if;
 for item in select value from jsonb_array_elements(v->'regions') loop
  if item-array['artifact_id','page','reading_order','raw_text','normalized_math','confidence','uncertain','x','y','width','height']<>'{}' or not(item ?& array['artifact_id','page','reading_order','raw_text','normalized_math','uncertain','x','y','width','height']) then raise invalid_parameter_value;end if;
  insert into public.math_extraction_regions(run_id,attempt_id,artifact_id,page,reading_order,raw_text,normalized_math,confidence,uncertain,x,y,width,height)
  values(r.id,a.id,(item->>'artifact_id')::uuid,(item->>'page')::integer,(item->>'reading_order')::integer,item->>'raw_text',item->>'normalized_math',(item->>'confidence')::numeric,(item->>'uncertain')::boolean,(item->>'x')::numeric,(item->>'y')::numeric,(item->>'width')::numeric,(item->>'height')::numeric);
 end loop;
 if nullif(v->>'provider','') is null or nullif(v->>'model','') is null then raise invalid_parameter_value;end if;
 update public.math_extraction_runs set state='COMPLETED',output_sha256=h,provider=v->>'provider',model=v->>'model',model_version=v->>'model_version' where id=r.id;
 return r.id;
end$math_fn$;
create or replace function public.math_fail_extraction(uuid,uuid,text) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare r public.math_extraction_runs;u uuid;
begin
 select * into r from public.math_extraction_runs where id=$1;select student_id into u from public.math_attempts where id=r.attempt_id;perform math_private.require_active(array[u]);
 perform 1 from public.math_attempts where id=r.attempt_id for update;
 select * into r from public.math_extraction_runs where id=$1 for update;
 if r.lease_token is distinct from $2 or $2 is null or r.state not in ('PROCESSING','FAILED') then raise invalid_parameter_value;end if;
 update public.math_extraction_runs set state='FAILED',error_code=$3 where id=r.id;
end$math_fn$;
grant execute on function public.math_submit_attempt(jsonb) to postgres;
grant execute on function public.math_register_artifact(uuid,jsonb) to postgres;
grant execute on function public.math_confirm_extraction(uuid,uuid,jsonb) to postgres;
grant execute on function public.math_request_evaluation(uuid,uuid) to postgres;
grant execute on function public.math_evaluation_detail(uuid) to postgres;
grant execute on function public.math_reveal_hint(uuid,uuid) to postgres;
grant execute on function public.math_claim_extraction(uuid) to postgres;
grant execute on function public.math_finalize_extraction(uuid,uuid,jsonb) to postgres;
grant execute on function public.math_fail_extraction(uuid,uuid,text) to postgres;
grant execute on function public.math_claim_evaluation(uuid) to postgres;
grant execute on function public.math_finalize_evaluation(uuid,uuid,jsonb) to postgres;
grant execute on function public.math_fail_evaluation(uuid,uuid,text) to postgres;
reset role;
revoke create on schema public from math_executor;
revoke math_executor from postgres granted by postgres;
-- Named PostgREST argument: {"p_request":{...}}. No arbitrary caller identity.
create function public.math_input(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload'; action text=p_request->>'action'; u uuid;
 a public.math_attempts; candidate public.math_extraction_runs; confirmed public.math_extraction_runs;
 result jsonb; allowed text[]; ready boolean=false; lim integer; before_at timestamptz; before_id uuid;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 if p_request is null or jsonb_typeof(p_request)<>'object' or octet_length(p_request::text)>300000 or p_request-array['dto_version','action','payload']<>'{}' or p_request->>'dto_version' is distinct from 'math-input-v1' or jsonb_typeof(v) is distinct from 'object' then raise invalid_parameter_value using message='INVALID_MATH_INPUT_CONTRACT';end if;
 allowed=case action
 when 'create_attempt' then array['client_submission_id','leaf_id','kind','predecessor_id','prior_evaluation_id','target_step_id','typed_answer','input_kind']
 when 'register_evidence' then array['attempt_id','metadata']
 when 'confirm_extraction' then array['attempt_id','run_id','regions']
 when 'read_input' then array['attempt_id']
 when 'request_evaluation' then array['attempt_id','client_submission_id']
 when 'read_result' then array['evaluation_id']
 when 'reveal_hint' then array['hint_id','client_submission_id']
 when 'history' then array['limit','before_at','before_id'] else null end;
 if allowed is null or v-allowed<>'{}' then raise invalid_parameter_value;end if;
 case action
 when 'create_attempt' then result=jsonb_build_object('attempt_id',public.math_submit_attempt(v));
 when 'register_evidence' then result=public.math_register_artifact((v->>'attempt_id')::uuid,v->'metadata');
 when 'confirm_extraction' then result=jsonb_build_object('confirmed_run_id',public.math_confirm_extraction((v->>'attempt_id')::uuid,(v->>'run_id')::uuid,v->'regions'));
 when 'request_evaluation' then result=jsonb_build_object('evaluation_id',public.math_request_evaluation((v->>'attempt_id')::uuid,(v->>'client_submission_id')::uuid));
 when 'read_result' then result=public.math_evaluation_detail((v->>'evaluation_id')::uuid);
 when 'reveal_hint' then result=public.math_reveal_hint((v->>'hint_id')::uuid,(v->>'client_submission_id')::uuid);
 when 'history' then
  lim=coalesce((v->>'limit')::integer,20);before_at=(v->>'before_at')::timestamptz;before_id=(v->>'before_id')::uuid;
  if lim not between 1 and 50 or (before_at is null)<>(before_id is null) then raise invalid_parameter_value;end if;
  select jsonb_build_object('attempts',coalesce(jsonb_agg(row_value order by created_at desc,id desc),'[]'),'limit',lim,'evaluation_history_limit',20) into result from (
   select x.id,x.created_at,jsonb_build_object('attempt_id',x.id,'leaf_id',x.leaf_id,'kind',x.kind,'predecessor_id',x.predecessor_id,'prior_evaluation_id',x.prior_evaluation_id,'target_step_id',x.target_step_id,'created_at',x.created_at,'evaluations',(select coalesce(jsonb_agg(jsonb_build_object('evaluation_id',e.id,'state',e.state,'requested_at',e.requested_at) order by e.requested_at,e.id),'[]') from (select id,state,requested_at from public.math_evaluations where attempt_id=x.id order by requested_at desc,id desc limit 20) e)) row_value
   from public.math_attempts x where x.student_id=u and (before_at is null or (x.created_at,x.id)<(before_at,before_id)) order by x.created_at desc,x.id desc limit lim
  ) rows;
 when 'read_input' then
  select * into a from public.math_attempts where id=(v->>'attempt_id')::uuid and student_id=u;
  if not found then raise no_data_found;end if;
  perform 1 from public.math_attempts where id=a.id for update;
  select * into candidate from public.math_extraction_runs where attempt_id=a.id and kind='CANDIDATE' order by created_at desc,id desc limit 1;
  select * into confirmed from public.math_extraction_runs where predecessor_id=candidate.id and kind='CONFIRMED';
  ready=a.input_kind='TYPED' or (candidate.state='COMPLETED' and confirmed.id is not null and exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id) and not exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id and storage_state<>'PRESENT'));
  result=jsonb_build_object('attempt',jsonb_build_object('attempt_id',a.id,'leaf_id',a.leaf_id,'kind',a.kind,'input_kind',a.input_kind,'typed_answer',a.typed_answer,'predecessor_id',a.predecessor_id,'prior_evaluation_id',a.prior_evaluation_id,'target_step_id',a.target_step_id),
   'input_state',case when exists(select 1 from public.math_evaluations where attempt_id=a.id) then 'INPUT_FROZEN' when coalesce(ready,false) then 'READY_FOR_EVALUATION' when candidate.state='PROCESSING' then 'EXTRACTION_PROCESSING' when candidate.state='COMPLETED' then 'CONFIRMATION_REQUIRED' else 'INPUT_REQUIRED' end,
   'can_request_evaluation',coalesce(ready,false) and not exists(select 1 from public.math_evaluations where attempt_id=a.id and state in ('REQUESTED','PROCESSING','COMPLETED')),'selected_extraction_id',confirmed.id,'candidate',case when candidate.id is null then null else jsonb_build_object('run_id',candidate.id,'state',candidate.state,'provider',candidate.provider,'model',candidate.model,'model_version',candidate.model_version,'error_code',candidate.error_code) end,
   'artifacts',(select coalesce(jsonb_agg(jsonb_build_object('artifact_id',id,'position',position,'media_type',media_type,'byte_size',byte_size,'width',width,'height',height,'orientation',orientation,'storage_state',storage_state,'upload_available',false) order by position),'[]') from public.math_attempt_artifacts where attempt_id=a.id),
   'candidate_regions',(select coalesce(jsonb_agg(to_jsonb(z)-array['attempt_id','run_id'] order by reading_order),'[]') from public.math_extraction_regions z where run_id=candidate.id),
   'confirmed_regions',(select coalesce(jsonb_agg(to_jsonb(z)-array['attempt_id','run_id'] order by reading_order),'[]') from public.math_extraction_regions z where run_id=confirmed.id));
 end case;
 if octet_length(result::text)>2097152 then raise program_limit_exceeded using message='MATH_RESPONSE_BOUND';end if;
 return jsonb_build_object('dto_version','math-input-v1','action',action,'result',result);
end$$;
revoke all on function public.math_input(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_input(jsonb) to authenticated;

create function public.math_extraction(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload'; action text=p_request->>'action';result jsonb;allowed text[];
begin
 if p_request is null or jsonb_typeof(p_request)<>'object' or octet_length(p_request::text)>300000 or p_request-array['dto_version','action','payload']<>'{}' or p_request->>'dto_version' is distinct from 'math-extraction-v1' or jsonb_typeof(v) is distinct from 'object' then raise invalid_parameter_value;end if;
 allowed=case action when 'claim' then array['attempt_id'] when 'finalize' then array['run_id','lease_token','output'] when 'fail' then array['run_id','lease_token','error_code'] else null end;
 if allowed is null or v-allowed<>'{}' then raise invalid_parameter_value;end if;
 case action
 when 'claim' then
  result=public.math_claim_extraction((v->>'attempt_id')::uuid);
  result=result||jsonb_build_object('evidence',(select jsonb_agg(jsonb_build_object('artifact_id',id,'bucket',bucket,'object_key',object_key,'media_type',media_type,'content_sha256',content_sha256,'byte_size',byte_size,'position',position) order by position) from public.math_attempt_artifacts where attempt_id=(v->>'attempt_id')::uuid));
 when 'finalize' then result=jsonb_build_object('run_id',public.math_finalize_extraction((v->>'run_id')::uuid,(v->>'lease_token')::uuid,v->'output'));
 when 'fail' then perform public.math_fail_extraction((v->>'run_id')::uuid,(v->>'lease_token')::uuid,v->>'error_code');result=jsonb_build_object('failed',true);
 end case;
 if octet_length(result::text)>2097152 then raise program_limit_exceeded using message='MATH_RESPONSE_BOUND';end if;
 return jsonb_build_object('dto_version','math-extraction-v1','action',action,'result',result);
end$$;
revoke all on function public.math_extraction(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_extraction(jsonb) to math_extraction_worker;

create function public.math_evaluation(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload';action text=p_request->>'action';reply jsonb;allowed text[];
begin
 if p_request is null or jsonb_typeof(p_request)<>'object' or octet_length(p_request::text)>600000 or p_request-array['dto_version','action','payload']<>'{}' or p_request->>'dto_version' is distinct from 'math-worker-v1' or jsonb_typeof(v) is distinct from 'object' then raise invalid_parameter_value;end if;
 allowed=case action when 'claim' then array['evaluation_id'] when 'finalize' then array['evaluation_id','lease_token','output'] when 'fail' then array['evaluation_id','lease_token','error_code'] else null end;
 if allowed is null or v-allowed<>'{}' then raise invalid_parameter_value;end if;
 case action
 when 'claim' then
  reply=public.math_claim_evaluation((v->>'evaluation_id')::uuid);
  select reply||jsonb_build_object('context',jsonb_build_object(
   'attempt',jsonb_build_object('attempt_id',a.id,'kind',a.kind,'typed_answer',a.typed_answer,'input_kind',a.input_kind,'prior_evaluation_id',a.prior_evaluation_id,'target_step_id',a.target_step_id),
   'leaf',(select to_jsonb(l) from public.math_subproblems l where id=e.leaf_id),
   'problem',(select to_jsonb(p) from public.math_problems p join public.math_subproblems l on l.problem_id=p.id where l.id=e.leaf_id),
   'profile',(select to_jsonb(p) from public.math_evaluation_profiles p where id=e.profile_id),
   'extraction',(select coalesce(jsonb_agg(to_jsonb(z)-array['attempt_id','run_id'] order by reading_order),'[]') from public.math_extraction_regions z where run_id=e.selected_extraction_id),
   'criteria',(select coalesce(jsonb_agg(to_jsonb(c) order by c.id),'[]') from public.math_evaluation_criteria x join public.math_scoring_criteria c on c.id=x.criterion_id where x.evaluation_id=e.id),
   'sources',(select coalesce(jsonb_agg(to_jsonb(s) order by s.id),'[]') from public.math_evaluation_sources x join public.math_source_artifacts s on s.id=x.source_id where x.evaluation_id=e.id),
   'solutions',(select coalesce(jsonb_agg(to_jsonb(s) order by s.id),'[]') from public.math_canonical_solutions s where e.authority_solutions ? s.id::text)
  )) into reply from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where e.id=(v->>'evaluation_id')::uuid;
 when 'finalize' then reply=to_jsonb(public.math_finalize_evaluation((v->>'evaluation_id')::uuid,(v->>'lease_token')::uuid,v->'output'));
 when 'fail' then perform public.math_fail_evaluation((v->>'evaluation_id')::uuid,(v->>'lease_token')::uuid,v->>'error_code');reply=jsonb_build_object('failed',true);
 end case;
 if octet_length(reply::text)>2097152 then raise program_limit_exceeded using message='MATH_RESPONSE_BOUND';end if;
 return jsonb_build_object('dto_version','math-worker-v1','action',action,'result',reply);
end$$;
revoke all on function public.math_evaluation(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_evaluation(jsonb) to math_evaluation_worker;
create function public.qlm_quality(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload';action text=p_request->>'action';answer jsonb;allowed text[]; ids uuid[];
begin
 -- Nonlocking coarse gate; existing domain RPCs recheck authority under ordered lifecycle locks.
 if auth.uid() is null or not exists(select 1 from public.quality_operators where user_id=auth.uid()) then raise insufficient_privilege;end if;
 if p_request is null or jsonb_typeof(p_request)<>'object' or octet_length(p_request::text)>65536 or p_request-array['dto_version','action','payload']<>'{}' or p_request->>'dto_version' is distinct from 'qlm-runtime-v1' or jsonb_typeof(v) is distinct from 'object' then raise invalid_parameter_value;end if;
 allowed=case action when 'list' then array['limit','before_at','before_id'] when 'detail' then array['evaluation_id'] when 'submit_judgment' then array['judgment'] when 'review_state' then array['evaluation_ids'] when 'history' then array['evaluation_id','limit','before_at','before_id'] else null end;
 if allowed is null or v-allowed<>'{}' then raise invalid_parameter_value;end if;
 case action
 when 'list' then answer=public.qlm_list_cases((v->>'limit')::integer,(v->>'before_at')::timestamptz,(v->>'before_id')::uuid);
 when 'detail' then answer=public.qlm_case_detail((v->>'evaluation_id')::uuid);
 when 'submit_judgment' then answer=public.qlm_submit_human_judgment(v->'judgment');
 when 'review_state' then
  if jsonb_typeof(v->'evaluation_ids') is distinct from 'array' or jsonb_array_length(v->'evaluation_ids')>100 then raise invalid_parameter_value;end if;
  select coalesce(array_agg(x::uuid),'{}'::uuid[]) into ids from jsonb_array_elements_text(v->'evaluation_ids') x;answer=public.qlm_review_state(ids);
 when 'history' then answer=public.qlm_list_human_judgments((v->>'evaluation_id')::uuid,(v->>'limit')::integer,(v->>'before_at')::timestamptz,(v->>'before_id')::uuid);
 end case;
 if octet_length(answer::text)>2097152 then raise program_limit_exceeded using message='MATH_RESPONSE_BOUND';end if;
 return jsonb_build_object('dto_version','qlm-runtime-v1','action',action,'result',answer);
end$$;
revoke all on function public.qlm_quality(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.qlm_quality(jsonb) to authenticated;

-- All four wrappers are postgres-owned. Internal EXECUTE below is not client authority.
do $$begin
 if has_schema_privilege('math_executor','public','CREATE') or exists(select 1 from pg_auth_members where roleid='math_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'BOOTSTRAP_NOT_RESTORED';end if;
end$$;
commit;
