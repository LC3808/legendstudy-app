begin;
do $$begin if exists(select 1 from public.math_attempts) then raise exception 'EMPTY_MATH_INSTALL_ONLY';end if;end$$;
drop function public.qlm_quality(jsonb);
drop function public.math_input(jsonb);
drop function public.math_extraction(jsonb);
drop function public.math_evaluation(jsonb);
drop index public.math_confirmed_candidate_once;
grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to math_executor;
set role math_executor;
create or replace function public.math_register_artifact(uuid,jsonb) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts; v jsonb=$2; new_id uuid=gen_random_uuid(); path text;
begin
 select * into a from public.math_attempts where id=$1;
 if a.student_id is distinct from math_private.current_subject() then raise insufficient_privilege;end if;
 perform math_private.require_active(array[a.student_id]);
 if v is null or jsonb_typeof(v)<>'object' or v-array['position','media_type','byte_size','content_sha256','width','height','orientation']<>'{}' or octet_length(v::text)>2048 or a.input_kind='TYPED' or exists(select 1 from public.math_evaluations where attempt_id=a.id) then raise invalid_parameter_value;end if;
 path=a.student_id::text||'/'||a.id::text||'/raw/'||new_id::text;
 insert into public.math_attempt_artifacts(id,attempt_id,position,namespace,bucket,object_key,media_type,byte_size,content_sha256,width,height,orientation,storage_state)
 values(new_id,a.id,(v->>'position')::integer,'raw','math-private',path,v->>'media_type',(v->>'byte_size')::bigint,v->>'content_sha256',(v->>'width')::integer,(v->>'height')::integer,(v->>'orientation')::integer,'REGISTERED');
 return jsonb_build_object('artifact_id',new_id,'storage_state','REGISTERED','upload_available',false);
end$math_fn$;
create or replace function public.math_confirm_extraction(uuid,uuid,jsonb) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts;r public.math_extraction_runs;new_id uuid;v jsonb=$3;item jsonb;region public.math_extraction_regions;
begin
 select * into a from public.math_attempts where id=$1;
 if a.student_id is distinct from math_private.current_subject() then raise insufficient_privilege;end if;
 perform math_private.require_active(array[a.student_id]);perform 1 from public.math_attempts where id=a.id for update;
 select * into r from public.math_extraction_runs where id=$2 and attempt_id=a.id and kind='CANDIDATE' and state='COMPLETED';
 if r.id is null or exists(select 1 from public.math_evaluations where attempt_id=a.id) or jsonb_typeof(v) is distinct from 'array' or jsonb_array_length(v)>100 or octet_length(v::text)>262144 then raise invalid_parameter_value;end if;
 if (select count(distinct z->>'region_id') from jsonb_array_elements(v) z)<>jsonb_array_length(v) then raise invalid_parameter_value;end if;
 for item in select value from jsonb_array_elements(v) loop
  if item-array['region_id','raw_text','normalized_math']<>'{}' or not(item ?& array['region_id','raw_text','normalized_math']) or not exists(select 1 from public.math_extraction_regions where id=(item->>'region_id')::uuid and run_id=r.id) then raise invalid_parameter_value;end if;
 end loop;
 if exists(select 1 from public.math_extraction_regions z where run_id=r.id and uncertain and not exists(select 1 from jsonb_array_elements(v) q where (q->>'region_id')::uuid=z.id)) then raise invalid_parameter_value using message='UNCERTAINTY_NOT_CONFIRMED';end if;
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
  select id into run from public.math_extraction_runs where attempt_id=a.id and kind='CONFIRMED' and state='COMPLETED' order by confirmed_at desc,id desc limit 1;
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
 if a.input_kind='TYPED' or not exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id) or exists(select 1 from public.math_attempt_artifacts where attempt_id=a.id and storage_state<>'PRESENT') then raise invalid_parameter_value using message='INPUT_NOT_READY';end if;
 if exists(select 1 from public.math_extraction_runs where attempt_id=a.id and state='PROCESSING') then raise unique_violation using message='EXTRACTION_IN_PROGRESS';end if;
 insert into public.math_extraction_runs(attempt_id,kind,state,lease_token,lease_until) values(a.id,'CANDIDATE','PROCESSING',gen_random_uuid(),clock_timestamp()+interval '5 minutes') returning * into r;
 return jsonb_build_object('run_id',r.id,'lease_token',r.lease_token,'lease_until',r.lease_until,'artifacts',(select jsonb_agg(jsonb_build_object('artifact_id',id,'position',position,'media_type',media_type) order by position) from public.math_attempt_artifacts where attempt_id=a.id));
end$math_fn$;
create or replace function public.math_finalize_extraction(uuid,uuid,jsonb) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare r public.math_extraction_runs;a public.math_attempts;v jsonb=$3;item jsonb;h text;
begin
 select * into r from public.math_extraction_runs where id=$1;select * into a from public.math_attempts where id=r.attempt_id;perform math_private.require_active(array[a.student_id]);
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
 select * into r from public.math_extraction_runs where id=$1 for update;
 if r.lease_token is distinct from $2 or $2 is null or r.state not in ('PROCESSING','FAILED') then raise invalid_parameter_value;end if;
 update public.math_extraction_runs set state='FAILED',error_code=$3 where id=r.id;
end$math_fn$;
revoke execute on function public.math_submit_attempt(jsonb) from postgres;
revoke execute on function public.math_register_artifact(uuid,jsonb) from postgres;
revoke execute on function public.math_confirm_extraction(uuid,uuid,jsonb) from postgres;
revoke execute on function public.math_request_evaluation(uuid,uuid) from postgres;
revoke execute on function public.math_evaluation_detail(uuid) from postgres;
revoke execute on function public.math_reveal_hint(uuid,uuid) from postgres;
revoke execute on function public.math_claim_extraction(uuid) from postgres;
revoke execute on function public.math_finalize_extraction(uuid,uuid,jsonb) from postgres;
revoke execute on function public.math_fail_extraction(uuid,uuid,text) from postgres;
revoke execute on function public.math_claim_evaluation(uuid) from postgres;
revoke execute on function public.math_finalize_evaluation(uuid,uuid,jsonb) from postgres;
revoke execute on function public.math_fail_evaluation(uuid,uuid,text) from postgres;
reset role;
revoke create on schema public from math_executor;
revoke math_executor from postgres granted by postgres;
commit;
