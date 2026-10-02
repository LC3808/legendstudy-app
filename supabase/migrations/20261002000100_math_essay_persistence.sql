-- MATH-2C. Isolated implementation; separate Owner Production apply required.
-- No provider calls, price policy, wallet duplication or unrelated migration replay.
-- Runtime fails closed without ADR-2; Math erasure/Storage deployment are activation gates.
begin;
set local lock_timeout='5s';
set local statement_timeout='60s';
do $preflight$begin
 if current_user<>'postgres' or (select rolsuper from pg_roles where rolname=current_user) then raise exception 'MATH_REQUIRES_REVIEWED_NON_SUPERUSER_POSTGRES';end if;
 if (select count(*) from pg_auth_members where roleid='essay_executor'::regrole)<>1 or not exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and member='postgres'::regrole and grantor='supabase_admin'::regrole and admin_option and not inherit_option and not set_option) then raise exception 'MATH_EXISTING_ROLE_TOPOLOGY_DRIFT';end if;
 if to_regnamespace('math_private') is not null then raise exception 'MATH_NAMESPACE_COLLISION';end if;
end $preflight$;
create role math_executor nologin nobypassrls nosuperuser nocreatedb nocreaterole noreplication noinherit;
create role math_extraction_worker nologin nobypassrls nosuperuser nocreatedb nocreaterole noreplication noinherit;
create role math_evaluation_worker nologin nobypassrls nosuperuser nocreatedb nocreaterole noreplication noinherit;
-- Immutable content versions and typed personal Math graph.
create schema math_private;
revoke all on schema math_private from public,anon,authenticated,service_role;
create table public.math_problem_sets(
 id uuid primary key default gen_random_uuid(),essay_exam_id uuid not null references public.essay_exams(id),
 logical_id uuid not null,version integer not null check(version>0),label text not null check(length(label) between 1 and 300),
 state text not null check(state in ('DRAFT','ACTIVE','SUPERSEDED','RETIRED')),created_at timestamptz not null default clock_timestamp(),unique(logical_id,version));
create table public.math_problems(
 id uuid primary key default gen_random_uuid(),problem_set_id uuid not null references public.math_problem_sets(id),
 logical_id uuid not null,version integer not null check(version>0),display_order integer not null check(display_order>=0),
 statement text not null check(length(statement) between 1 and 30000),state text not null check(state in ('DRAFT','ACTIVE','SUPERSEDED','RETIRED')),
 created_at timestamptz not null default clock_timestamp(),unique(logical_id,version),unique(problem_set_id,display_order));
create table public.math_subproblems(
 id uuid primary key default gen_random_uuid(),problem_id uuid not null references public.math_problems(id),
 leaf_key text not null check(length(leaf_key) between 1 and 100),display_order integer not null check(display_order>=0),
 statement text not null check(length(statement)<=20000),response_format text not null check(response_format in ('SHORT_ANSWER','SHORT_REASONING','FULL_SOLUTION','PROOF')),
 allow_common_rubric boolean not null default false,unique(problem_id,leaf_key),unique(problem_id,display_order),unique(id,problem_id));
create table public.math_source_artifacts(
 id uuid primary key default gen_random_uuid(),problem_id uuid not null references public.math_problems(id),
 resource_id uuid references public.resources(id),source_role text not null check(source_role in ('QUESTION','SCORING','INTENT','SOLUTION')),
 source_url text not null check(length(source_url) between 1 and 2000),locator text not null check(length(locator) between 1 and 500),
 provenance text not null check(provenance in ('OFFICIAL','VERIFIED_INTERNAL','AI_PROPOSED')),
 verification text not null check(verification in ('REFERENCE_ONLY','HASH_VERIFIED')),content_sha256 text check(content_sha256 ~ '^[0-9a-f]{64}$'),
 check((verification='HASH_VERIFIED')=(content_sha256 is not null)),created_at timestamptz not null default clock_timestamp(),unique(id,problem_id));
create table public.math_evaluation_profiles(
 id uuid primary key default gen_random_uuid(),logical_id uuid not null,version integer not null check(version>0),
 scope text not null check(scope in ('LEAF','PROBLEM','EXAM','COMMON_MATH_RUBRIC')),
 leaf_id uuid references public.math_subproblems(id),problem_id uuid references public.math_problems(id),essay_exam_id uuid references public.essay_exams(id),
 response_format text not null check(response_format in ('SHORT_ANSWER','SHORT_REASONING','FULL_SOLUTION','PROOF')),
 rubric_version text not null check(rubric_version='math-rubric-v1'),required_dimensions text[] not null,optional_dimensions text[] not null default '{}',
 reasoning_required boolean not null,state text not null check(state in ('DRAFT','ACTIVE','SUPERSEDED','RETIRED')),
 check(case scope when 'LEAF' then leaf_id is not null and problem_id is null and essay_exam_id is null when 'PROBLEM' then leaf_id is null and problem_id is not null and essay_exam_id is null when 'EXAM' then leaf_id is null and problem_id is null and essay_exam_id is not null else num_nonnulls(leaf_id,problem_id,essay_exam_id)=0 end),
 check(required_dimensions <@ array['problem_understanding','concept_selection','solution_strategy','logical_development','computation_accuracy','justification_completeness','final_conclusion','mathematical_writing','case_analysis','graph_interpretation']),
 check(optional_dimensions <@ array['problem_understanding','concept_selection','solution_strategy','logical_development','computation_accuracy','justification_completeness','final_conclusion','mathematical_writing','case_analysis','graph_interpretation']),
 check(not required_dimensions && optional_dimensions),unique(logical_id,version));
create unique index math_profile_active_scope on public.math_evaluation_profiles(scope,leaf_id,problem_id,essay_exam_id,response_format) nulls not distinct where state='ACTIVE';
create table public.math_scoring_criteria(
 id uuid primary key default gen_random_uuid(),leaf_id uuid not null references public.math_subproblems(id),source_id uuid not null references public.math_source_artifacts(id),
 criterion_key text not null check(length(criterion_key) between 1 and 100),description text not null check(length(description) between 1 and 5000),
 official_points numeric check(official_points>=0),rubric_dimensions text[] not null,unique(leaf_id,criterion_key),unique(id,leaf_id));
create table public.math_canonical_solutions(
 id uuid primary key default gen_random_uuid(),leaf_id uuid not null references public.math_subproblems(id),source_id uuid references public.math_source_artifacts(id),
 logical_id uuid not null,version integer not null check(version>0),origin text not null check(origin in ('OFFICIAL','VERIFIED_INTERNAL','AI_PROPOSED')),
 state text not null check(state in ('DRAFT','ACTIVE','SUPERSEDED','RETIRED')),body text not null check(length(body) between 1 and 30000),
 check(origin<>'OFFICIAL' or source_id is not null),unique(logical_id,version),unique(id,leaf_id));
create table public.math_canonical_solution_steps(
 id uuid primary key default gen_random_uuid(),solution_id uuid not null references public.math_canonical_solutions(id),position integer not null check(position>0),
 body text not null check(length(body) between 1 and 5000),criterion_id uuid references public.math_scoring_criteria(id),unique(solution_id,position));
create table public.math_attempts(
 id uuid primary key default gen_random_uuid(),student_id uuid not null references public.profiles(id) on delete restrict,
 leaf_id uuid not null references public.math_subproblems(id),kind text not null check(kind in ('INITIAL','FULL_RESOLVE','STEP_RETRY','SHORT_ANSWER_RESOLVE')),
 predecessor_id uuid references public.math_attempts(id) on delete cascade,lineage_id uuid not null references public.math_attempts(id) on delete cascade deferrable initially deferred,
 prior_evaluation_id uuid,target_step_id uuid,typed_answer text check(length(typed_answer)<=30000),input_kind text not null check(input_kind in ('TYPED','EVIDENCE','MIXED')),
 client_submission_id uuid not null unique,submission_sha256 text not null check(submission_sha256 ~ '^[0-9a-f]{64}$'),
 created_at timestamptz not null default clock_timestamp(),
 check((kind='INITIAL')=(predecessor_id is null and prior_evaluation_id is null)),check((kind='STEP_RETRY')=(target_step_id is not null)),
 check(input_kind<>'TYPED' or nullif(btrim(typed_answer),'') is not null),unique(id,student_id),unique(id,leaf_id));
create index math_attempt_student on public.math_attempts(student_id,created_at,id);
create index math_attempt_lineage on public.math_attempts(lineage_id,created_at,id);
create table public.math_attempt_artifacts(
 id uuid primary key default gen_random_uuid(),attempt_id uuid not null references public.math_attempts(id) on delete cascade,
 position integer not null check(position>0),namespace text not null check(namespace in ('raw','render','crop','derived','generated')),
 bucket text not null check(bucket='math-private'),object_key text not null unique,
 media_type text not null check(media_type in ('image/png','image/jpeg','image/webp','application/pdf')),
 content_sha256 text check(content_sha256 ~ '^[0-9a-f]{64}$'),byte_size bigint not null check(byte_size between 1 and 20971520),
 width integer check(width between 1 and 50000),height integer check(height between 1 and 50000),orientation integer check(orientation in (0,90,180,270)),
 storage_state text not null check(storage_state in ('REGISTERED','PRESENT','ERASURE_PENDING','ABSENT_VERIFIED')),
 erase_due_at timestamptz,absence_verified_at timestamptz,created_at timestamptz not null default clock_timestamp(),
 check((storage_state='ABSENT_VERIFIED')=(absence_verified_at is not null)),unique(attempt_id,position),unique(id,attempt_id));
create table public.math_extraction_runs(
 id uuid primary key default gen_random_uuid(),attempt_id uuid not null references public.math_attempts(id) on delete cascade,
 predecessor_id uuid,kind text not null check(kind in ('CANDIDATE','CONFIRMED')),state text not null check(state in ('PROCESSING','COMPLETED','FAILED')),
 lease_token uuid,lease_until timestamptz,output_sha256 text check(output_sha256 ~ '^[0-9a-f]{64}$'),
 confirmed_at timestamptz,provider text,model text,model_version text,error_code text check(error_code in ('INPUT_FAILED','TIMEOUT','INVALID_OUTPUT')),
 created_at timestamptz not null default clock_timestamp(),unique(id,attempt_id),
 foreign key(predecessor_id,attempt_id) references public.math_extraction_runs(id,attempt_id) deferrable initially deferred,
 check(kind<>'CONFIRMED' or (predecessor_id is not null and confirmed_at is not null and state='COMPLETED')));
create table public.math_extraction_regions(
 id uuid primary key default gen_random_uuid(),run_id uuid not null,attempt_id uuid not null,artifact_id uuid not null,
 page integer not null check(page>0),reading_order integer not null check(reading_order>0),
 raw_text text not null check(length(raw_text)<=10000),normalized_math text not null check(length(normalized_math)<=10000),
 confidence numeric check(confidence between 0 and 1),uncertain boolean not null,
 x numeric not null check(x between 0 and 1),y numeric not null check(y between 0 and 1),width numeric not null,height numeric not null,
 check(width>0 and height>0 and x+width<=1 and y+height<=1),
 foreign key(run_id,attempt_id) references public.math_extraction_runs(id,attempt_id) on delete cascade,
 foreign key(artifact_id,attempt_id) references public.math_attempt_artifacts(id,attempt_id) deferrable initially deferred,unique(run_id,reading_order),unique(id,run_id));
create table public.math_evaluations(
 id uuid primary key default gen_random_uuid(),attempt_id uuid not null,leaf_id uuid not null,profile_id uuid not null references public.math_evaluation_profiles(id),
 selected_extraction_id uuid,request_kind text not null check(request_kind in ('MATH_INITIAL_EVALUATION','MATH_REEVALUATION')),
 idempotency_key uuid not null unique,request_sha256 text not null check(request_sha256 ~ '^[0-9a-f]{64}$'),
 state text not null check(state in ('REQUESTED','PROCESSING','COMPLETED','FAILED','INVALIDATED')),
 authority_solutions jsonb not null,lease_token uuid,lease_until timestamptz,contract_version text not null default 'math-eval-v1' check(contract_version='math-eval-v1'),
 output_hash_version text check(output_hash_version='math-output-v1'),output_sha256 text check(output_sha256 ~ '^[0-9a-f]{64}$'),result jsonb,
 requested_at timestamptz not null default clock_timestamp(),completed_at timestamptz,error_code text check(error_code in ('TIMEOUT','INVALID_OUTPUT','PROCESSING_FAILED','ACCOUNT_ERASURE')),
 foreign key(attempt_id,leaf_id) references public.math_attempts(id,leaf_id) on delete cascade,
 foreign key(selected_extraction_id,attempt_id) references public.math_extraction_runs(id,attempt_id) deferrable initially deferred,
 check((state in ('COMPLETED','INVALIDATED'))=(completed_at is not null and output_sha256 is not null and result is not null)),unique(id,leaf_id),unique(id,attempt_id));
create index math_evaluation_attempt on public.math_evaluations(attempt_id,requested_at,id);
create index math_evaluation_cases on public.math_evaluations(completed_at desc,id desc) where completed_at is not null;
create table public.math_solution_steps(
 id uuid primary key,evaluation_id uuid not null,leaf_id uuid not null,position integer not null check(position>0),
 step_kind text not null check(step_kind in ('INTERPRETATION','CONCEPT','TRANSFORMATION','COMPUTATION','JUSTIFICATION','CASE','CONCLUSION')),
 representation text not null check(length(representation) between 1 and 5000),status text not null check(status in ('VALID','INVALID','INSUFFICIENT_JUSTIFICATION','CALCULATION_ERROR','LOGICAL_GAP','PROPAGATED_ERROR','NOT_ASSESSABLE')),
 explanation text not null check(length(explanation)<=5000),
 foreign key(evaluation_id,leaf_id) references public.math_evaluations(id,leaf_id) on delete cascade,unique(evaluation_id,position),unique(id,evaluation_id));
alter table public.math_attempts add foreign key(prior_evaluation_id,predecessor_id) references public.math_evaluations(id,attempt_id) deferrable initially deferred;
alter table public.math_attempts add foreign key(target_step_id,prior_evaluation_id) references public.math_solution_steps(id,evaluation_id) deferrable initially deferred;
create table public.math_step_regions(
 evaluation_id uuid not null,step_id uuid not null,run_id uuid not null,region_id uuid not null,
 primary key(step_id,region_id),foreign key(step_id,evaluation_id) references public.math_solution_steps(id,evaluation_id) on delete cascade,
 foreign key(region_id,run_id) references public.math_extraction_regions(id,run_id) deferrable initially deferred);
create table public.math_step_dependencies(
 evaluation_id uuid not null,from_step_id uuid not null,to_step_id uuid not null,primary key(evaluation_id,from_step_id,to_step_id),check(from_step_id<>to_step_id),
 foreign key(from_step_id,evaluation_id) references public.math_solution_steps(id,evaluation_id) on delete cascade,
 foreign key(to_step_id,evaluation_id) references public.math_solution_steps(id,evaluation_id) on delete cascade);
create table public.math_errors(
 id uuid primary key,evaluation_id uuid not null references public.math_evaluations(id) on delete cascade,step_id uuid,
 classification text not null check(classification in ('ROOT','PROPAGATED')),category text not null,
 check(classification<>'ROOT' or materiality='MATERIAL_ERROR'),
 materiality text not null check(materiality in ('MATERIAL_ERROR','MINOR_ERROR','PRESENTATION_ISSUE','NON_ERROR_VARIATION')),explanation text not null check(length(explanation) between 1 and 5000),
 foreign key(step_id,evaluation_id) references public.math_solution_steps(id,evaluation_id) deferrable initially deferred,unique(id,evaluation_id));
create table public.math_error_propagations(
 evaluation_id uuid not null,root_error_id uuid not null,consequence_error_id uuid not null,primary key(evaluation_id,root_error_id,consequence_error_id),check(root_error_id<>consequence_error_id),
 foreign key(root_error_id,evaluation_id) references public.math_errors(id,evaluation_id) on delete cascade,
 foreign key(consequence_error_id,evaluation_id) references public.math_errors(id,evaluation_id) on delete cascade);
create table public.math_core(
 id uuid primary key,evaluation_id uuid not null references public.math_evaluations(id) on delete cascade,position integer not null check(position between 1 and 100),error_id uuid,step_id uuid,
 title text not null check(length(title) between 1 and 300),diagnosis text not null check(length(diagnosis) between 1 and 1000),why text not null check(length(why) between 1 and 2000),next_action text not null check(length(next_action) between 1 and 2000),
 check(num_nonnulls(error_id,step_id)>0),foreign key(error_id,evaluation_id) references public.math_errors(id,evaluation_id) deferrable initially deferred,foreign key(step_id,evaluation_id) references public.math_solution_steps(id,evaluation_id) deferrable initially deferred,unique(evaluation_id,position),unique(id,evaluation_id));
create table public.math_hints(
 id uuid primary key,evaluation_id uuid not null,core_id uuid not null,level integer not null check(level between 0 and 2),body text not null check(length(body) between 1 and 3000),
 leakage_class text not null check(leakage_class in ('CORE_ONLY','SAFE_DIRECTION','CONCEPT_REVEAL')),validated boolean not null,
 foreign key(core_id,evaluation_id) references public.math_core(id,evaluation_id) on delete cascade,unique(core_id,level),unique(id,evaluation_id));
create table public.math_hint_exposures(
 id uuid primary key default gen_random_uuid(),hint_id uuid not null references public.math_hints(id) on delete cascade,client_key uuid not null unique,delivered_at timestamptz not null default clock_timestamp());
create table public.math_considered_references(
 evaluation_id uuid not null,leaf_id uuid not null,solution_id uuid not null,primary key(evaluation_id,solution_id),
 foreign key(evaluation_id,leaf_id) references public.math_evaluations(id,leaf_id) on delete cascade,foreign key(solution_id,leaf_id) references public.math_canonical_solutions(id,leaf_id));
create table public.math_evaluated_paths(
 evaluation_id uuid not null references public.math_evaluations(id) on delete cascade,path_key text not null check(length(path_key) between 1 and 200),
 verdict text not null check(verdict in ('OFFICIAL_PATH_MATCH','ALTERNATIVE_VALID_PATH','INVALID_PATH','INSUFFICIENT_JUSTIFICATION')),
 explanation text not null check(length(explanation) between 1 and 5000),primary key(evaluation_id,path_key));
create table public.math_evaluation_sources(
 evaluation_id uuid not null references public.math_evaluations(id) on delete cascade,source_id uuid not null references public.math_source_artifacts(id),primary key(evaluation_id,source_id));
create table public.math_evaluation_criteria(
 evaluation_id uuid not null,leaf_id uuid not null,criterion_id uuid not null,result jsonb,
 primary key(evaluation_id,criterion_id),foreign key(evaluation_id,leaf_id) references public.math_evaluations(id,leaf_id) on delete cascade,
 foreign key(criterion_id,leaf_id) references public.math_scoring_criteria(id,leaf_id));
create table public.math_solution_exposures(
 id uuid primary key default gen_random_uuid(),evaluation_id uuid not null,solution_id uuid not null,client_key uuid not null unique,
 delivered_at timestamptz not null default clock_timestamp(),foreign key(evaluation_id,solution_id) references public.math_considered_references(evaluation_id,solution_id) on delete cascade);
create table public.math_billing_bindings(
 math_evaluation_id uuid primary key references public.math_evaluations(id) on delete cascade,billing_decision_id uuid not null unique,account_id uuid not null,
 foreign key(billing_decision_id,account_id) references public.essay_billing_decisions(id,account_id) on delete restrict);

grant usage on schema math_private to math_executor,essay_executor;grant usage on schema public to math_executor,math_extraction_worker,math_evaluation_worker;
alter table public.human_quality_judgments add column math_evaluation_id uuid references public.math_evaluations(id) on delete cascade;
alter table public.human_quality_judgments alter column evaluation_id drop not null;
alter table public.human_quality_judgments add constraint hq_exact_domain check(num_nonnulls(evaluation_id,math_evaluation_id)=1);
alter table public.human_quality_judgments add unique(id,math_evaluation_id);
alter table public.human_quality_judgments add foreign key(supersedes_judgment_id,math_evaluation_id) references public.human_quality_judgments(id,math_evaluation_id);
create index human_quality_math_history on public.human_quality_judgments(math_evaluation_id,created_at desc,id desc) where math_evaluation_id is not null;

grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to math_executor;
grant create on schema math_private to math_executor;
set role math_executor;
create or replace function public.math_submit_attempt(jsonb) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid=math_private.current_subject(); v jsonb=$1; key uuid; h text; old public.math_attempts; parent public.math_attempts; l public.math_subproblems; new_id uuid=gen_random_uuid(); attempt_kind text; prior uuid; step uuid;
begin
 perform math_private.require_active(array[u]);
 if v is null or jsonb_typeof(v)<>'object' or octet_length(v::text)>65536 or v-array['client_submission_id','leaf_id','kind','predecessor_id','prior_evaluation_id','target_step_id','typed_answer','input_kind']<>'{}' then raise invalid_parameter_value;end if;
 key=(v->>'client_submission_id')::uuid;attempt_kind=v->>'kind';prior=(v->>'prior_evaluation_id')::uuid;step=(v->>'target_step_id')::uuid;
 if key is null then raise invalid_parameter_value;end if;
 h=encode(sha256(convert_to(v::text,'UTF8')),'hex');perform pg_advisory_xact_lock(hashtextextended(key::text,18293));
 select * into old from public.math_attempts where client_submission_id=key;
 if found then if old.student_id<>u or old.submission_sha256<>h then raise unique_violation;end if;return old.id;end if;
 select * into l from public.math_subproblems where id=(v->>'leaf_id')::uuid;
 perform math_private.resolve_profile(l.id);
 if attempt_kind<>'INITIAL' then
  select * into parent from public.math_attempts where id=(v->>'predecessor_id')::uuid;
  if parent.id is null or parent.student_id<>u or not exists(select 1 from public.math_subproblems a join public.math_problems ap on ap.id=a.problem_id join public.math_problems bp on bp.id=l.problem_id where a.id=parent.leaf_id and a.leaf_key=l.leaf_key and ap.logical_id=bp.logical_id)
   or not exists(select 1 from public.math_evaluations where id=prior and attempt_id=parent.id and state='COMPLETED') then raise invalid_parameter_value using message='INVALID_LINEAGE';end if;
  if attempt_kind='STEP_RETRY' and not exists(select 1 from public.math_solution_steps where id=step and evaluation_id=prior) then raise invalid_parameter_value;end if;
  if attempt_kind='SHORT_ANSWER_RESOLVE' and l.response_format<>'SHORT_ANSWER' then raise invalid_parameter_value;end if;
 end if;
 insert into public.math_attempts(id,student_id,leaf_id,kind,predecessor_id,lineage_id,prior_evaluation_id,target_step_id,typed_answer,input_kind,client_submission_id,submission_sha256)
 values(new_id,u,l.id,attempt_kind,parent.id,coalesce(parent.lineage_id,new_id),prior,step,v->>'typed_answer',v->>'input_kind',key,h);
 return new_id;
end$math_fn$;
revoke all on function public.math_submit_attempt(jsonb) from public,anon,authenticated,service_role;grant execute on function public.math_submit_attempt(jsonb) to math_executor,authenticated;
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
revoke all on function public.math_register_artifact(uuid,jsonb) from public,anon,authenticated,service_role;grant execute on function public.math_register_artifact(uuid,jsonb) to math_executor,authenticated;
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
revoke all on function public.math_confirm_extraction(uuid,uuid,jsonb) from public,anon,authenticated,service_role;grant execute on function public.math_confirm_extraction(uuid,uuid,jsonb) to math_executor,authenticated;
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
revoke all on function public.math_request_evaluation(uuid,uuid) from public,anon,authenticated,service_role;grant execute on function public.math_request_evaluation(uuid,uuid) to math_executor,authenticated;
create or replace function public.math_attempt_detail(uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid; a public.math_attempts;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);select * into a from public.math_attempts where id=$1 and student_id=u;if not found then raise no_data_found;end if;
 return to_jsonb(a)-array['student_id','submission_sha256','client_submission_id'];
end$math_fn$;
revoke all on function public.math_attempt_detail(uuid) from public,anon,authenticated,service_role;grant execute on function public.math_attempt_detail(uuid) to math_executor,authenticated;
create or replace function public.math_evaluation_detail(uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 if not exists(select 1 from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where e.id=$1 and a.student_id=u) then raise no_data_found;end if;
 return math_private.evaluation_projection($1,false);
end$math_fn$;
revoke all on function public.math_evaluation_detail(uuid) from public,anon,authenticated,service_role;grant execute on function public.math_evaluation_detail(uuid) to math_executor,authenticated;
create or replace function public.math_reveal_hint(uuid,uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid; h public.math_hints; old public.math_hint_exposures;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 select hr.* into h from public.math_hints hr join public.math_evaluations e on e.id=hr.evaluation_id join public.math_attempts a on a.id=e.attempt_id where hr.id=$1 and a.student_id=u and e.state='COMPLETED' and hr.validated;
 if not found or $2 is null then raise no_data_found;end if;
 if h.level=2 and not exists(select 1 from public.math_hints prior join public.math_hint_exposures x on x.hint_id=prior.id where prior.core_id=h.core_id and prior.level=1) then raise invalid_parameter_value using message='REVEAL_L1_FIRST';end if;
 perform pg_advisory_xact_lock(hashtextextended($2::text,735));select * into old from public.math_hint_exposures where client_key=$2;
 if old.id is not null and old.hint_id<>h.id then raise unique_violation;end if;
 if old.id is null then insert into public.math_hint_exposures(hint_id,client_key) values(h.id,$2);end if;
 return jsonb_build_object('hint_id',h.id,'level',h.level,'body',h.body);
end$math_fn$;
revoke all on function public.math_reveal_hint(uuid,uuid) from public,anon,authenticated,service_role;grant execute on function public.math_reveal_hint(uuid,uuid) to math_executor,authenticated;
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
revoke all on function public.math_claim_extraction(uuid) from public,anon,authenticated,service_role;grant execute on function public.math_claim_extraction(uuid) to math_executor,math_extraction_worker;
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
revoke all on function public.math_finalize_extraction(uuid,uuid,jsonb) from public,anon,authenticated,service_role;grant execute on function public.math_finalize_extraction(uuid,uuid,jsonb) to math_executor,math_extraction_worker;
create or replace function public.math_fail_extraction(uuid,uuid,text) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare r public.math_extraction_runs;u uuid;
begin
 select * into r from public.math_extraction_runs where id=$1;select student_id into u from public.math_attempts where id=r.attempt_id;perform math_private.require_active(array[u]);
 select * into r from public.math_extraction_runs where id=$1 for update;
 if r.lease_token is distinct from $2 or $2 is null or r.state not in ('PROCESSING','FAILED') then raise invalid_parameter_value;end if;
 update public.math_extraction_runs set state='FAILED',error_code=$3 where id=r.id;
end$math_fn$;
revoke all on function public.math_fail_extraction(uuid,uuid,text) from public,anon,authenticated,service_role;grant execute on function public.math_fail_extraction(uuid,uuid,text) to math_executor,math_extraction_worker;
create or replace function public.math_claim_evaluation(uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations;u uuid;
begin
 select ar.student_id into u from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=$1;
 perform math_private.require_active(array[u]);perform math_private.lock_evaluation($1);
 select * into e from public.math_evaluations where id=$1;
 if e.state<>'REQUESTED' then raise invalid_parameter_value using message='EVALUATION_NOT_CLAIMABLE';end if;
 update public.math_evaluations set state='PROCESSING',lease_token=gen_random_uuid(),lease_until=clock_timestamp()+interval '5 minutes' where id=e.id returning * into e;
 return jsonb_build_object('evaluation_id',e.id,'lease_token',e.lease_token,'lease_until',e.lease_until,'attempt_id',e.attempt_id,'profile_id',e.profile_id,'selected_extraction_id',e.selected_extraction_id,'authority_solutions',e.authority_solutions);
end$math_fn$;
revoke all on function public.math_claim_evaluation(uuid) from public,anon,authenticated,service_role;grant execute on function public.math_claim_evaluation(uuid) to math_executor,math_evaluation_worker;
create or replace function public.math_finalize_evaluation(uuid,uuid,jsonb) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; u uuid; v jsonb; w jsonb; h text;
begin
 select ar.student_id into u from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=$1;
 perform math_private.require_active(array[u]);perform math_private.lock_evaluation($1);
 select * into e from public.math_evaluations where id=$1;
 h=encode(sha256(convert_to(jsonb_build_object('hash_version','math-output-v1','evaluation_id',e.id,'attempt_id',e.attempt_id,'leaf_id',e.leaf_id,'profile_id',e.profile_id,'authority_solutions',e.authority_solutions,'source_pins',(select jsonb_agg(source_id order by source_id) from public.math_evaluation_sources where evaluation_id=e.id),'criterion_pins',(select jsonb_agg(criterion_id order by criterion_id) from public.math_evaluation_criteria where evaluation_id=e.id),'output',$3)::text,'UTF8')),'hex');
 if e.state='COMPLETED' and e.lease_token=$2 and e.output_sha256=h then return e.id;end if;
 if e.state<>'PROCESSING' or e.lease_token is distinct from $2 or e.lease_until<=clock_timestamp() then raise invalid_parameter_value using message='STALE_FINALIZE';end if;
 perform math_private.validate_output(e.id,$3);
 for v in select value from jsonb_array_elements($3->'steps') loop
  insert into public.math_solution_steps values((v->>'id')::uuid,e.id,e.leaf_id,(v->>'position')::integer,v->>'kind',v->>'representation',v->>'status',v->>'explanation');
  for w in select value from jsonb_array_elements(v->'regions') loop
   if jsonb_typeof(w)<>'string' or not exists(select 1 from public.math_extraction_regions where id=(w#>>'{}')::uuid and run_id=e.selected_extraction_id) then raise check_violation;end if;
   insert into public.math_step_regions values(e.id,(v->>'id')::uuid,e.selected_extraction_id,(w#>>'{}')::uuid);
  end loop;
 end loop;
 for v in select value from jsonb_array_elements($3->'edges') loop insert into public.math_step_dependencies values(e.id,(v->>'from')::uuid,(v->>'to')::uuid);end loop;
 if exists(with recursive walk(start,finish,path,cycle) as(
  select from_step_id,to_step_id,array[from_step_id,to_step_id],false from public.math_step_dependencies where evaluation_id=e.id
  union all select w.start,d.to_step_id,w.path||d.to_step_id,d.to_step_id=any(w.path) from walk w join public.math_step_dependencies d on d.from_step_id=w.finish and d.evaluation_id=e.id where not w.cycle)
  select 1 from walk where cycle) then raise check_violation using message='DAG_CYCLE';end if;
 for v in select value from jsonb_array_elements($3->'errors') loop insert into public.math_errors values((v->>'id')::uuid,e.id,(v->>'step_id')::uuid,v->>'classification',v->>'category',v->>'materiality',v->>'explanation');end loop;
 for v in select value from jsonb_array_elements($3->'causes') loop
  if not exists(select 1 from public.math_errors where id=(v->>'root')::uuid and evaluation_id=e.id and classification='ROOT') or not exists(select 1 from public.math_errors where id=(v->>'consequence')::uuid and evaluation_id=e.id and classification='PROPAGATED') then raise check_violation;end if;
  insert into public.math_error_propagations values(e.id,(v->>'root')::uuid,(v->>'consequence')::uuid);
 end loop;
 if exists(select 1 from public.math_errors x where x.evaluation_id=e.id and x.classification='PROPAGATED' and not exists(select 1 from public.math_error_propagations p where p.consequence_error_id=x.id and p.evaluation_id=e.id)) then raise check_violation;end if;
 for v in select value from jsonb_array_elements($3->'core') loop insert into public.math_core values((v->>'id')::uuid,e.id,(v->>'position')::integer,(v->>'error_id')::uuid,(v->>'step_id')::uuid,v->>'title',v->>'diagnosis',v->>'why',v->>'next_action');end loop;
 for v in select value from jsonb_array_elements($3->'hints') loop insert into public.math_hints values((v->>'id')::uuid,e.id,(v->>'core_id')::uuid,(v->>'level')::integer,v->>'body',v->>'leakage_class',(v->>'validated')::boolean);end loop;
 for v in select value from jsonb_array_elements($3->'references') loop
  if jsonb_typeof(v)<>'string' or not e.authority_solutions @> jsonb_build_array(v) then raise check_violation using message='UNPINNED_REFERENCE';end if;
  insert into public.math_considered_references values(e.id,e.leaf_id,(v#>>'{}')::uuid);
 end loop;
 for v in select value from jsonb_array_elements($3->'paths') loop insert into public.math_evaluated_paths values(e.id,v->>'key',v->>'verdict',v->>'explanation');end loop;
 for v in select value from jsonb_array_elements($3->'criteria') loop
  update public.math_evaluation_criteria set result=v where evaluation_id=e.id and criterion_id=(v->>'criterion_id')::uuid;
  if not found then raise check_violation using message='UNPINNED_CRITERION';end if;
 end loop;
 if exists(select 1 from public.math_evaluation_criteria where evaluation_id=e.id and result is null) then raise check_violation using message='MISSING_CRITERION';end if;
 perform math_private.settle_billing(e.id);
 update public.math_evaluations set state='COMPLETED',result=$3,output_hash_version='math-output-v1',output_sha256=h,completed_at=clock_timestamp() where id=e.id;
 return e.id;
end$math_fn$;
revoke all on function public.math_finalize_evaluation(uuid,uuid,jsonb) from public,anon,authenticated,service_role;grant execute on function public.math_finalize_evaluation(uuid,uuid,jsonb) to math_executor,math_evaluation_worker;
create or replace function public.math_fail_evaluation(uuid,uuid,text) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations;u uuid;
begin
 select ar.student_id into u from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=$1;
 perform math_private.require_active(array[u]);perform math_private.lock_evaluation($1);
 select * into e from public.math_evaluations where id=$1;
 if e.lease_token is distinct from $2 or $2 is null or e.state not in ('PROCESSING','FAILED') then raise invalid_parameter_value;end if;
 if $3 not in ('TIMEOUT','INVALID_OUTPUT','PROCESSING_FAILED') or $3 is null then raise invalid_parameter_value;end if;
 perform math_private.release_billing(e.id);update public.math_evaluations set state='FAILED',error_code=$3 where id=e.id;
end$math_fn$;
revoke all on function public.math_fail_evaluation(uuid,uuid,text) from public,anon,authenticated,service_role;grant execute on function public.math_fail_evaluation(uuid,uuid,text) to math_executor,math_evaluation_worker;
create or replace function math_private.resolve_profile(uuid) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare l public.math_subproblems; exam uuid; ids uuid[];
begin
 perform pg_advisory_xact_lock(7864321);
 select * into l from public.math_subproblems where id=$1;
 select s.essay_exam_id into exam from public.math_problems p join public.math_problem_sets s on s.id=p.problem_set_id where p.id=l.problem_id and p.state='ACTIVE' and s.state='ACTIVE';
 if exam is null then raise invalid_parameter_value using message='CONTENT_UNAVAILABLE';end if;
 with candidates as(select p.id,case p.scope when 'LEAF' then 4 when 'PROBLEM' then 3 when 'EXAM' then 2 else 1 end rank from public.math_evaluation_profiles p
 where p.state='ACTIVE' and p.response_format=l.response_format and (p.leaf_id=l.id or p.problem_id=l.problem_id or p.essay_exam_id=exam or (p.scope='COMMON_MATH_RUBRIC' and l.allow_common_rubric)))
 select array_agg(id) into ids from candidates where rank=(select max(rank) from candidates);
 if coalesce(cardinality(ids),0)<>1 then raise invalid_parameter_value using message='PROFILE_MISSING_OR_AMBIGUOUS';end if;
 return ids[1];
end$math_fn$;
revoke all on function math_private.resolve_profile(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.resolve_profile(uuid) to math_executor;
create or replace function math_private.lock_evaluation(uuid) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare attempt uuid;
begin
 select attempt_id into attempt from public.math_evaluations where id=$1;
 if attempt is null then raise no_data_found;end if;
 perform math_private.lock_account_attempt(attempt);
 perform 1 from public.math_evaluations where id=$1 for update;
end$math_fn$;
revoke all on function math_private.lock_evaluation(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.lock_evaluation(uuid) to math_executor;
create or replace function math_private.evaluation_projection(uuid,boolean) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; a public.math_attempts; result jsonb;
begin
 select * into e from public.math_evaluations where id=$1 and state in ('COMPLETED','INVALIDATED');if not found then raise no_data_found;end if;
 select * into a from public.math_attempts where id=e.attempt_id;
 result=e.result;
 if not $2 then
  result=result||jsonb_build_object('hints',coalesce((select jsonb_agg(v) from jsonb_array_elements(result->'hints') v where (v->>'level')::integer=0 or exists(select 1 from public.math_hint_exposures where hint_id=(v->>'id')::uuid)),'[]'::jsonb),'generated_solution',null,'references','[]'::jsonb);
 end if;
 return jsonb_build_object('dto_version','qlm-read-v1','evaluation_id',e.id,'attempt_id',a.id,'leaf_id',e.leaf_id,'profile_id',e.profile_id,'kind',a.kind,'prior_evaluation_id',a.prior_evaluation_id,'target_step_id',a.target_step_id,'typed_answer',a.typed_answer,'input_kind',a.input_kind,'selected_extraction_id',e.selected_extraction_id,'output_sha256',e.output_sha256,'state',e.state,'output',result,
 'leaf',(select to_jsonb(l) from public.math_subproblems l where id=e.leaf_id),
 'problem',(select to_jsonb(p) from public.math_problems p join public.math_subproblems l on l.problem_id=p.id where l.id=e.leaf_id),
 'profile',(select to_jsonb(p) from public.math_evaluation_profiles p where id=e.profile_id),
 'sources',coalesce((select jsonb_agg(to_jsonb(s) order by s.id) from public.math_evaluation_sources x join public.math_source_artifacts s on s.id=x.source_id where x.evaluation_id=e.id),'[]'::jsonb),
 'criteria',coalesce((select jsonb_agg(jsonb_build_object('criterion',to_jsonb(c),'result',x.result) order by c.id) from public.math_evaluation_criteria x join public.math_scoring_criteria c on c.id=x.criterion_id where x.evaluation_id=e.id),'[]'::jsonb),
 'considered_references',case when $2 then coalesce((select jsonb_agg(to_jsonb(s) order by s.id) from public.math_considered_references x join public.math_canonical_solutions s on s.id=x.solution_id where x.evaluation_id=e.id),'[]'::jsonb) else '[]'::jsonb end,
 'extraction',coalesce((select jsonb_agg(to_jsonb(r)-'attempt_id' order by reading_order) from public.math_extraction_regions r where run_id=e.selected_extraction_id),'[]'::jsonb),
 'evidence',coalesce((select jsonb_agg(jsonb_build_object('artifact_id',id,'position',position,'media_type',media_type,'storage_state',storage_state,'access','UNAVAILABLE_PENDING_STORAGE_GATE') order by position) from public.math_attempt_artifacts where attempt_id=a.id),'[]'::jsonb));
end$math_fn$;
revoke all on function math_private.evaluation_projection(uuid,boolean) from public,anon,authenticated,service_role;grant execute on function math_private.evaluation_projection(uuid,boolean) to math_executor,postgres;
create or replace function math_private.validate_output(uuid,jsonb) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; p public.math_evaluation_profiles; a public.math_attempts; v jsonb; k text; ids uuid[]; required text[]:=array['contract_version','extraction_id','steps','edges','errors','causes','core','hints','references','paths','criteria','rubric','overall','provenance','progression','generated_solution'];
begin
 select * into e from public.math_evaluations where id=$1; select * into p from public.math_evaluation_profiles where id=e.profile_id;select * into a from public.math_attempts where id=e.attempt_id;
 if $2 is null or jsonb_typeof($2)<>'object' or octet_length($2::text)>524288 or $2-required<>'{}' or not $2 ?& required or $2->>'contract_version' is distinct from 'math-eval-v1' or ($2->>'extraction_id')::uuid is distinct from e.selected_extraction_id then raise invalid_parameter_value using message='INVALID_OUTPUT_ENVELOPE';end if;
 foreach k in array array['steps','edges','errors','causes','core','hints','references','paths','criteria'] loop
  if jsonb_typeof($2->k)<>'array' or jsonb_array_length($2->k)>100 then raise invalid_parameter_value;end if;
 end loop;
 if jsonb_typeof($2->'rubric')<>'object' or ($2->'rubric')-(p.required_dimensions||p.optional_dimensions)<>'{}' or not ($2->'rubric' ?& p.required_dimensions) then raise invalid_parameter_value using message='RUBRIC_SHAPE';end if;
 for k,v in select * from jsonb_each($2->'rubric') loop
  if jsonb_typeof(v)<>'string' or v#>>'{}' not in ('STRONG','ADEQUATE','NEEDS_IMPROVEMENT','INSUFFICIENT','NOT_APPLICABLE','NOT_ASSESSABLE') or (k=any(p.required_dimensions) and v#>>'{}'='NOT_APPLICABLE') then raise invalid_parameter_value;end if;
 end loop;
 if p.reasoning_required and $2->'overall'->>'coverage'='ATTEMPTED' and jsonb_array_length($2->'steps')=0 then raise invalid_parameter_value using message='REASONING_REQUIRED';end if;
 if jsonb_typeof($2->'overall')<>'object' or ($2->'overall')-array['status','explanation','answer_status','coverage']<>'{}' or ($2->'overall')->>'status' not in ('ANSWER_CORRECT_AND_REASONING_SUFFICIENT','ANSWER_CORRECT_REASONING_INCOMPLETE','ANSWER_INCORRECT_APPROACH_MOSTLY_VALID','FUNDAMENTAL_APPROACH_ERROR','NOT_DETERMINABLE') or length(($2->'overall')->>'explanation') not between 1 and 10000 then raise invalid_parameter_value;end if;
 foreach k in array array['status','explanation','answer_status','coverage'] loop if jsonb_typeof($2->'overall'->k) is distinct from 'string' then raise invalid_parameter_value;end if;end loop;
 if jsonb_typeof($2->'provenance')<>'object' or ($2->'provenance')-array['provider','model','model_version','prompt_version']<>'{}' then raise invalid_parameter_value;end if;
 foreach k in array array['provider','model','model_version','prompt_version'] loop if jsonb_typeof(($2->'provenance')->k) is distinct from 'string' or length(($2->'provenance')->>k) not between 1 and 200 then raise invalid_parameter_value;end if;end loop;
 if a.kind='INITIAL' and $2->'progression'<>'null' then raise invalid_parameter_value;end if;
 if a.kind<>'INITIAL' and (jsonb_typeof($2->'progression')<>'object' or ($2->'progression')-array['prior_evaluation_id','target_step_id','downstream','summary']<>'{}' or (($2->'progression')->>'prior_evaluation_id')::uuid is distinct from a.prior_evaluation_id or (($2->'progression')->>'target_step_id')::uuid is distinct from a.target_step_id or (a.kind='STEP_RETRY' and ($2->'progression')->>'downstream' is distinct from 'NOT_REASSESSED')) then raise invalid_parameter_value using message='INVALID_PROGRESSION';end if;
 if $2->'generated_solution'<>'null' and (jsonb_typeof($2->'generated_solution')<>'object' or ($2->'generated_solution')-array['body','origin']<>'{}' or ($2->'generated_solution')->>'origin' is distinct from 'AI_GENERATED' or length(($2->'generated_solution')->>'body') not between 1 and 20000) then raise invalid_parameter_value;end if;
 for v in select value from jsonb_array_elements($2->'steps') loop
  if v-array['id','position','kind','representation','status','explanation','regions']<>'{}' or not v ?& array['id','position','kind','representation','status','explanation','regions'] or jsonb_typeof(v->'regions')<>'array' or jsonb_array_length(v->'regions')>100 then raise invalid_parameter_value;end if;
 end loop;
 for v in select value from jsonb_array_elements($2->'edges') loop if v-array['from','to']<>'{}' or not v ?& array['from','to'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'errors') loop
  if v-array['id','step_id','classification','category','materiality','explanation']<>'{}' or not v ?& array['id','step_id','classification','category','materiality','explanation'] or v->>'category' not in ('CONDITION_MISREAD','CONCEPT_SELECTION','STRATEGY','LOGICAL_GAP','CALCULATION','SIGN','ALGEBRAIC_TRANSFORMATION','CASE_OMISSION','DOMAIN_RANGE','THEOREM_MISUSE','GRAPH_INTERPRETATION','JUSTIFICATION','CONCLUSION','OTHER') then raise invalid_parameter_value;end if;
 end loop;
 for v in select value from jsonb_array_elements($2->'causes') loop if v-array['root','consequence']<>'{}' or not v ?& array['root','consequence'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'core') loop if v-array['id','position','error_id','step_id','title','diagnosis','why','next_action']<>'{}' or not v ?& array['id','position','error_id','step_id','title','diagnosis','why','next_action'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'hints') loop if v-array['id','core_id','level','body','leakage_class','validated']<>'{}' or not v ?& array['id','core_id','level','body','leakage_class','validated'] or v->'validated' is distinct from 'true'::jsonb or ((v->>'level')::integer=1 and v->>'leakage_class'<>'SAFE_DIRECTION') or ((v->>'level')::integer=2 and v->>'leakage_class'<>'CONCEPT_REVEAL') then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'paths') loop if v-array['key','verdict','explanation']<>'{}' or not v ?& array['key','verdict','explanation'] then raise invalid_parameter_value;end if;end loop;
 for v in select value from jsonb_array_elements($2->'criteria') loop if v-array['criterion_id','verdict','explanation']<>'{}' or not v ?& array['criterion_id','verdict','explanation'] or jsonb_typeof(v->'verdict') is distinct from 'string' or jsonb_typeof(v->'explanation') is distinct from 'string' or v->>'verdict' not in ('satisfied','partially_satisfied','not_satisfied','not_determinable') or length(v->>'explanation')>5000 then raise invalid_parameter_value;end if;end loop;
end$math_fn$;
revoke all on function math_private.validate_output(uuid,jsonb) from public,anon,authenticated,service_role;grant execute on function math_private.validate_output(uuid,jsonb) to math_executor;
reset role;
revoke create on schema public from math_executor;
revoke create on schema math_private from math_executor;
revoke math_executor from postgres granted by postgres;
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema math_private to essay_executor;
set role essay_executor;
create or replace function math_private.authorize_billing(uuid) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; a public.math_attempts; account uuid; parent public.essay_billing_decisions; decision uuid; selected_grant uuid; quantity integer=1; reason text='paid_cycle';
begin
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select * into a from public.math_attempts where id=e.attempt_id;
 if exists(select 1 from public.math_billing_bindings where math_evaluation_id=e.id) then raise unique_violation using message='BINDING_ALREADY_EXISTS';end if;
 if e.state<>'REQUESTED' then raise invalid_parameter_value;end if;
 if e.request_kind='MATH_REEVALUATION' then
  select d.* into parent from public.essay_billing_decisions d
  join public.math_billing_bindings b on b.billing_decision_id=d.id
  join public.math_evaluations pe on pe.id=b.math_evaluation_id
  join public.math_attempts pa on pa.id=pe.attempt_id
  where d.account_id=account and d.status='settled' and d.reason='paid_cycle' and d.policy_key='essay_cycle' and d.policy_version='v2'
   and pa.lineage_id=a.lineage_id and pa.student_id=a.student_id and pa.id<>a.id and pa.created_at<a.created_at
   and pe.state='COMPLETED' and pe.request_kind='MATH_INITIAL_EVALUATION' and clock_timestamp()<pe.completed_at+interval '336 hours'
   and not exists(select 1 from public.essay_billing_decisions ch where ch.included_by_decision_id=d.id and ch.status in ('authorized','reserved','settled'))
   and not exists(select 1 from public.credit_transactions t where t.decision_id=d.id and t.transaction_type='refund')
  order by pe.completed_at desc,pe.id desc limit 1;
  if parent.id is not null then quantity=0;reason='included_revision';end if;
 end if;
 if quantity=1 then
  select g.id into selected_grant from public.credit_grants g where g.account_id=account
   and (g.expires_at is null or g.expires_at>clock_timestamp())
   and (select coalesce(sum(t.balance_delta-t.reserved_delta),0) from public.credit_transactions t where t.grant_id=g.id)>=1
  order by g.expires_at nulls last,g.created_at,g.id limit 1;
  if selected_grant is null then raise sqlstate 'PT402' using message='INSUFFICIENT_CREDIT';end if;
 end if;
 insert into public.essay_billing_decisions(account_id,evaluation_id,idempotency_key,policy_key,policy_version,reason,credits_required,status,included_by_decision_id)
 values(account,null,e.idempotency_key,'essay_cycle','v2',reason,quantity,'authorized',parent.id) returning id into decision;
 insert into public.math_billing_bindings(math_evaluation_id,billing_decision_id,account_id) values(e.id,decision,account);
 if quantity=1 then
  insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
  values(account,selected_grant,decision,'reserve',0,1,'reserve/'||decision::text,'essay_cycle_v2');
  update public.essay_billing_decisions set status='reserved',reserved_at=clock_timestamp() where id=decision;
 end if;
 return decision;
end$math_fn$;
revoke all on function math_private.authorize_billing(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.authorize_billing(uuid) to essay_executor,math_executor;
create or replace function math_private.settle_billing(uuid) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; b public.essay_billing_decisions; account uuid; t public.credit_transactions;
begin
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select d.* into b from public.essay_billing_decisions d join public.math_billing_bindings m on m.billing_decision_id=d.id and m.account_id=d.account_id where m.math_evaluation_id=e.id for update of d;
 if b.id is null or b.account_id<>account or b.evaluation_id is not null then raise invalid_parameter_value;end if;
 if b.status='settled' and e.state='COMPLETED' then return;end if;
 if e.state<>'PROCESSING' or b.status not in ('authorized','reserved') then raise invalid_parameter_value;end if;
 if b.credits_required>0 then
  if b.status<>'reserved' or (select coalesce(sum(reserved_delta),0) from public.credit_transactions where decision_id=b.id)<>b.credits_required then raise check_violation using message='INVALID_RESERVATION';end if;
  for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' order by grant_id loop
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
   values(account,t.grant_id,b.id,'consume',-t.reserved_delta,-t.reserved_delta,'consume/'||b.id::text||'/'||t.grant_id::text,'evaluation_completed');
  end loop;
 end if;
 update public.essay_billing_decisions set status='settled',settled_at=clock_timestamp() where id=b.id;
end$math_fn$;
revoke all on function math_private.settle_billing(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.settle_billing(uuid) to essay_executor,math_executor;
create or replace function math_private.release_billing(uuid) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; b public.essay_billing_decisions; account uuid; t public.credit_transactions;
begin
 select * into e from public.math_evaluations where id=$1;
 account=math_private.lock_account_attempt(e.attempt_id);
 select * into e from public.math_evaluations where id=$1 for update;
 select d.* into b from public.essay_billing_decisions d join public.math_billing_bindings m on m.billing_decision_id=d.id and m.account_id=d.account_id where m.math_evaluation_id=e.id for update of d;
 if b.id is null or b.account_id<>account or b.evaluation_id is not null then raise invalid_parameter_value;end if;
 if b.status in ('settled','released','rejected') then return;end if;
 if b.status='reserved' then
  for t in select * from public.credit_transactions where decision_id=b.id and transaction_type='reserve' order by grant_id loop
   insert into public.credit_transactions(account_id,grant_id,decision_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code)
   values(account,t.grant_id,b.id,'release',0,-t.reserved_delta,'release/'||b.id::text||'/'||t.grant_id::text,'evaluation_failed');
  end loop;
 end if;
 update public.essay_billing_decisions set status='released',released_at=clock_timestamp() where id=b.id;
end$math_fn$;
revoke all on function math_private.release_billing(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.release_billing(uuid) to essay_executor,math_executor;
create or replace function math_private.lock_account_attempt(uuid) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare a public.math_attempts; account uuid;
begin
 select * into a from public.math_attempts where id=$1;
 if a.id is null then raise no_data_found;end if;
 perform account_private.lock_subject(a.student_id);
 insert into public.credit_accounts(user_id) values(a.student_id) on conflict(user_id) do nothing;
 select id into account from public.credit_accounts where user_id=a.student_id for update;
 perform 1 from public.math_attempts where id in (a.id,a.lineage_id) order by id for update;
 perform 1 from public.credit_grants where account_id=account order by id for update;
 return account;
end$math_fn$;
revoke all on function math_private.lock_account_attempt(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.lock_account_attempt(uuid) to essay_executor,math_executor;
reset role;
revoke create on schema math_private from essay_executor;
revoke essay_executor from postgres granted by postgres;
create or replace function math_private.current_subject() returns uuid language plpgsql stable security DEFINER set search_path='' as $math_fn$begin return auth.uid();end$math_fn$;
revoke all on function math_private.current_subject() from public,anon,authenticated,service_role;grant execute on function math_private.current_subject() to postgres,math_executor;
create or replace function math_private.require_active(uuid[]) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid; permitted boolean;
begin
 if $1 is null or cardinality($1)=0 or array_position($1,null) is not null then raise insufficient_privilege;end if;
 if to_regprocedure('account_private.allowed(uuid)') is null or to_regprocedure('account_private.lock_subject(uuid)') is null then raise insufficient_privilege using message='MATH_LIFECYCLE_DEPENDENCY_MISSING';end if;
 for u in select distinct x from unnest($1) x order by x loop
  execute 'select account_private.lock_subject($1)' using u;
  execute 'select account_private.allowed($1)' into permitted using u;
  if permitted is distinct from true then raise insufficient_privilege using message='ACCOUNT_RESTRICTED';end if;
 end loop;
end$math_fn$;
revoke all on function math_private.require_active(uuid[]) from public,anon,authenticated,service_role;grant execute on function math_private.require_active(uuid[]) to postgres,math_executor,essay_executor;
create or replace function math_private.content_immutable() returns trigger language plpgsql volatile security INVOKER set search_path='' as $math_fn$begin
 if tg_op='UPDATE' and (to_jsonb(old)-'state') is distinct from (to_jsonb(new)-'state') then raise check_violation using message='IMMUTABLE_CONTENT_VERSION';end if;
 if tg_table_name in ('math_scoring_criteria','math_canonical_solutions') then if new.source_id is not null and not exists(select 1 from public.math_source_artifacts s join public.math_subproblems l on l.problem_id=s.problem_id where s.id=new.source_id and l.id=new.leaf_id) then raise check_violation using message='FOREIGN_CONTENT_SOURCE';end if;end if;
 if tg_table_name='math_canonical_solution_steps' then if new.criterion_id is not null and not exists(select 1 from public.math_scoring_criteria c join public.math_canonical_solutions s on s.leaf_id=c.leaf_id where c.id=new.criterion_id and s.id=new.solution_id) then raise check_violation using message='FOREIGN_CONTENT_CRITERION';end if;end if;
 return new;
end$math_fn$;
revoke all on function math_private.content_immutable() from public,anon,authenticated,service_role;grant execute on function math_private.content_immutable() to postgres;
create or replace function math_private.personal_immutable() returns trigger language plpgsql volatile security INVOKER set search_path='' as $math_fn$begin raise check_violation using message='IMMUTABLE_MATH_FACT';end$math_fn$;
revoke all on function math_private.personal_immutable() from public,anon,authenticated,service_role;grant execute on function math_private.personal_immutable() to postgres;
create or replace function math_private.artifact_guard() returns trigger language plpgsql volatile security DEFINER set search_path='' as $math_fn$begin
 if tg_op='DELETE' then
  if old.storage_state<>'ABSENT_VERIFIED' then raise check_violation using message='STORAGE_OBLIGATION_UNVERIFIED';end if;
  return old;
 end if;
 if tg_op='UPDATE' and (to_jsonb(old)-array['storage_state','absence_verified_at','erase_due_at']) is distinct from (to_jsonb(new)-array['storage_state','absence_verified_at','erase_due_at']) then raise check_violation;end if;
 if tg_op='INSERT' and new.object_key is distinct from
  (select student_id::text||'/'||id::text||'/'||new.namespace||'/'||new.id::text from public.math_attempts where id=new.attempt_id)
 then raise check_violation using message='INVALID_OWNED_STORAGE_PATH';end if;
 return new;
end$math_fn$;
revoke all on function math_private.artifact_guard() from public,anon,authenticated,service_role;grant execute on function math_private.artifact_guard() to postgres;
create or replace function math_private.binding_guard() returns trigger language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; b public.essay_billing_decisions; student uuid; account_student uuid; fresh boolean;
begin
 if tg_op<>'INSERT' then raise check_violation using message='IMMUTABLE_BINDING';end if;
 select * into e from public.math_evaluations where id=new.math_evaluation_id;
 select * into b from public.essay_billing_decisions where id=new.billing_decision_id for update; select xmin::text=pg_current_xact_id()::text into fresh from public.essay_billing_decisions where id=new.billing_decision_id;
 select student_id into student from public.math_attempts where id=e.attempt_id;
 select user_id into account_student from public.credit_accounts where id=new.account_id;
 if b.id is null or b.evaluation_id is not null or b.account_id<>new.account_id or student is distinct from account_student or not fresh
  or b.idempotency_key is distinct from e.idempotency_key or e.state<>'REQUESTED' or b.status<>'authorized'
 then raise check_violation using message='INVALID_MATH_FINANCIAL_BINDING';end if;
 return new;
end$math_fn$;
revoke all on function math_private.binding_guard() from public,anon,authenticated,service_role;grant execute on function math_private.binding_guard() to postgres;
create or replace function math_private.activate_profile(uuid) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$begin
 perform pg_advisory_xact_lock(7864321);
 update public.math_evaluation_profiles set state='ACTIVE' where id=$1 and state='DRAFT';
 if not found then raise invalid_parameter_value;end if;
end$math_fn$;
revoke all on function math_private.activate_profile(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.activate_profile(uuid) to postgres;
create or replace function math_private.hq_parent_guard() returns trigger language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare p public.human_quality_judgments;
begin
 if new.supersedes_judgment_id is not null then
  select * into p from public.human_quality_judgments where id=new.supersedes_judgment_id for update;
  if p.id is null or p.id=new.id or p.evaluation_id is distinct from new.evaluation_id or p.math_evaluation_id is distinct from new.math_evaluation_id or exists(select 1 from public.human_quality_judgments where supersedes_judgment_id=p.id) then raise check_violation using message='INVALID_CORRECTION_HEAD';end if;
 end if;return new;
end$math_fn$;
revoke all on function math_private.hq_parent_guard() from public,anon,authenticated,service_role;grant execute on function math_private.hq_parent_guard() to postgres;
create or replace function math_private.hq_finding_guard() returns trigger language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare j public.human_quality_judgments; v jsonb;
begin
 select * into j from public.human_quality_judgments where id=new.judgment_id;
 v=to_jsonb(new)-array['id','judgment_id'];
 if j.evaluation_id is not null then
  if essay_private.hq_finding_valid(v) is distinct from true then raise check_violation;end if;
 else perform math_private.hq_validate_context(j.math_evaluation_id,j.rubric_result,jsonb_build_array(v));end if;
 return new;
end$math_fn$;
revoke all on function math_private.hq_finding_guard() from public,anon,authenticated,service_role;grant execute on function math_private.hq_finding_guard() to postgres;
create or replace function math_private.hq_rubric_valid(jsonb) returns boolean language plpgsql immutable security INVOKER set search_path='' as $math_fn$
declare k text; req text[]:=array['diagnosis','core_priority','actionability','evidence_adherence','valid_path_preservation','hallucination_absence']; opt text[]:=array['extraction_fidelity','step_reasoning','hint_quality','progression','generated_solution'];
begin
 if $1 is null or jsonb_typeof($1)<>'object' or $1-(req||opt)<>'{}' or not $1 ?& (req||opt) then return false;end if;
 foreach k in array req loop if jsonb_typeof($1->k)<>'string' or $1->>k not in ('OK','CONCERN','FAIL') then return false;end if;end loop;
 foreach k in array opt loop if jsonb_typeof($1->k)<>'string' or $1->>k not in ('OK','CONCERN','FAIL','NA') then return false;end if;end loop;return true;
end$math_fn$;
revoke all on function math_private.hq_rubric_valid(jsonb) from public,anon,authenticated,service_role;grant execute on function math_private.hq_rubric_valid(jsonb) to postgres;
create or replace function math_private.hq_finding_valid(jsonb) returns boolean language plpgsql immutable security INVOKER set search_path='' as $math_fn$
declare t jsonb; keys text[]; k text;
begin
 if $1 is null or jsonb_typeof($1)<>'object' or $1-array['issue_category','severity','target_kind','target_ref','note']<>'{}' or not $1 ?& array['issue_category','severity','target_kind','target_ref'] then return false;end if;
 foreach k in array array['issue_category','severity','target_kind'] loop if jsonb_typeof($1->k) is distinct from 'string' then return false;end if;end loop;
 if $1->>'issue_category' not in ('FALSE_CORRECTION','INVENTED_ERROR','EVIDENCE_MISREAD','UNSUPPORTED_CLAIM','CORE_PRIORITY_ERROR','PROGRESSION_ERROR','UNDER_SPECIFIED_GUIDANCE','MISSING_IMPORTANT_ISSUE','OTHER','EXTRACTION_MISREAD','ROOT_PROPAGATION_ERROR','ALTERNATIVE_PATH_REJECTION') or $1->>'severity' not in ('MINOR','MATERIAL','CRITICAL') then return false;end if;
 if $1 ? 'note' and $1->'note'<>'null' and (jsonb_typeof($1->'note')<>'string' or length($1->>'note')>1000) then return false;end if;
 t=$1->'target_ref';if $1->>'target_kind'='OVERALL' then return t='null';end if;
 keys=case $1->>'target_kind' when 'SOLUTION_STEP' then array['step_id'] when 'ROOT_ERROR' then array['error_id'] when 'EXTRACTION_REGION' then array['extraction_run_id','region_id'] when 'ALTERNATIVE_PATH' then case t->>'path_kind' when 'REFERENCE' then array['path_kind','solution_version_id'] when 'STUDENT' then array['path_kind','evaluated_path_key'] end end;
 if keys is null or jsonb_typeof(t)<>'object' or t-keys<>'{}' or not t ?& keys then return false;end if;
 foreach k in array keys loop
  if jsonb_typeof(t->k)<>'string' then return false;end if;
  if k='evaluated_path_key' then if length(t->>k) not between 1 and 200 then return false;end if;
  elsif k<>'path_kind' and t->>k !~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' then return false;end if;
 end loop;return true;
end$math_fn$;
revoke all on function math_private.hq_finding_valid(jsonb) from public,anon,authenticated,service_role;grant execute on function math_private.hq_finding_valid(jsonb) to postgres;
create or replace function math_private.hq_validate_context(uuid,jsonb,jsonb) returns void language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare e public.math_evaluations; a public.math_attempts; p public.math_evaluation_profiles; f jsonb; t jsonb; valid boolean;
begin
 select * into e from public.math_evaluations where id=$1 and state='COMPLETED';select * into a from public.math_attempts where id=e.attempt_id;select * into p from public.math_evaluation_profiles where id=e.profile_id;
 if e.id is null or e.output_sha256 is null or not exists(select 1 from public.math_evaluation_sources where evaluation_id=e.id) then raise invalid_parameter_value using message='UNASSESSABLE';end if;
 if a.input_kind<>'TYPED' and not exists(select 1 from public.math_extraction_runs where id=e.selected_extraction_id and kind='CONFIRMED' and state='COMPLETED') then raise invalid_parameter_value;end if;
 if (($2->>'extraction_fidelity'='NA')=(a.input_kind<>'TYPED')) or (($2->>'step_reasoning'='NA')=p.reasoning_required)
  or (($2->>'hint_quality'='NA')=exists(select 1 from public.math_hints where evaluation_id=e.id)) or (($2->>'progression'='NA')=(a.prior_evaluation_id is not null)) or (($2->>'generated_solution'='NA')=(e.result->'generated_solution'<>'null')) then raise invalid_parameter_value using message='INVALID_NA';end if;
 for f in select value from jsonb_array_elements($3) loop
  if math_private.hq_finding_valid(f) is distinct from true then raise invalid_parameter_value;end if;t=f->'target_ref';valid=false;
  case f->>'target_kind'
   when 'OVERALL' then valid=true;
   when 'SOLUTION_STEP' then select exists(select 1 from public.math_solution_steps where evaluation_id=e.id and id=(t->>'step_id')::uuid) into valid;
   when 'ROOT_ERROR' then select exists(select 1 from public.math_errors where evaluation_id=e.id and id=(t->>'error_id')::uuid and classification='ROOT') into valid;
   when 'EXTRACTION_REGION' then select exists(select 1 from public.math_extraction_regions where run_id=e.selected_extraction_id and run_id=(t->>'extraction_run_id')::uuid and id=(t->>'region_id')::uuid and attempt_id=e.attempt_id) into valid;
   when 'ALTERNATIVE_PATH' then
    if t->>'path_kind'='REFERENCE' then select exists(select 1 from public.math_considered_references where evaluation_id=e.id and solution_id=(t->>'solution_version_id')::uuid) into valid;
    else select exists(select 1 from public.math_evaluated_paths where evaluation_id=e.id and path_key=t->>'evaluated_path_key') into valid;end if;
   else null;
  end case;
  if not valid then raise invalid_parameter_value using message='FOREIGN_FINDING_TARGET';end if;
 end loop;
end$math_fn$;
revoke all on function math_private.hq_validate_context(uuid,jsonb,jsonb) from public,anon,authenticated,service_role;grant execute on function math_private.hq_validate_context(uuid,jsonb,jsonb) to postgres;
create or replace function math_private.hq_require_operator(uuid) returns uuid language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid:=auth.uid(); student uuid; claims jsonb;
begin
 claims=nullif(current_setting('request.jwt.claims',true),'')::jsonb;
 if u is null or claims->>'sub' is distinct from u::text or claims->>'role' is distinct from 'authenticated' or jsonb_typeof(claims->'exp') is distinct from 'number' or (claims->>'exp')::numeric<=extract(epoch from statement_timestamp()) or not exists(select 1 from public.quality_operators where user_id=u) then raise insufficient_privilege;end if;
 if $1 is null then perform math_private.require_active(array[u]);else
  select a.student_id into student from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where e.id=$1;
  if student is null then perform math_private.require_active(array[u]);raise no_data_found;end if;
  perform math_private.require_active(array[u,student]);
 end if;perform 1 from public.quality_operators where user_id=u for key share;if not found then raise insufficient_privilege;end if;return u;
end$math_fn$;
revoke all on function math_private.hq_require_operator(uuid) from public,anon,authenticated,service_role;grant execute on function math_private.hq_require_operator(uuid) to postgres;
create or replace function public.qlm_submit_human_judgment(jsonb) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid; e public.math_evaluations; old public.human_quality_judgments; v jsonb; f jsonb; h text; key uuid; jid uuid; parent uuid;
begin
 if auth.uid() is null or not exists(select 1 from public.quality_operators where user_id=auth.uid()) then raise insufficient_privilege;end if;u=auth.uid();
 if $1 is null or jsonb_typeof($1)<>'object' or octet_length($1::text)>32768 or $1-array['dto_version','math_evaluation_id','expected_output_sha256','client_submission_id','rubric_version','overall_disposition','rubric_result','selection_reason','recommended_action','summary_note','supersedes_judgment_id','findings','reference_context_reviewed']<>'{}' or $1->>'dto_version' is distinct from 'hq-math-write-v1' or $1->'reference_context_reviewed' is distinct from 'true'::jsonb or $1->>'rubric_version' is distinct from 'hq-math-rubric-v1' or math_private.hq_rubric_valid($1->'rubric_result') is distinct from true or jsonb_typeof($1->'findings') is distinct from 'array' then raise invalid_parameter_value;end if;
 if jsonb_array_length($1->'findings')>20 or length($1->>'summary_note')>2000 then raise invalid_parameter_value;end if;
 key=($1->>'client_submission_id')::uuid;parent=($1->>'supersedes_judgment_id')::uuid;if key is null then raise invalid_parameter_value;end if;
 perform math_private.hq_require_operator(($1->>'math_evaluation_id')::uuid);
 v=$1||jsonb_build_object('math_evaluation_id',($1->>'math_evaluation_id')::uuid,'client_submission_id',key,'supersedes_judgment_id',parent,'summary_note',$1->>'summary_note','selection_reason',coalesce($1->>'selection_reason','EARLY_CENSUS'),'recommended_action',coalesce($1->>'recommended_action','NONE'),'reviewer_user_id',u);
 h=encode(sha256(convert_to(v::text,'UTF8')),'hex');perform pg_advisory_xact_lock(hashtextextended(key::text,731));
 select * into old from public.human_quality_judgments where client_submission_id=key;
 if found then
  if old.math_evaluation_id is distinct from ($1->>'math_evaluation_id')::uuid or old.reviewer_user_id is distinct from u or old.submission_payload_sha256<>h then raise unique_violation;end if;
  return jsonb_build_object('dto_version','hq-math-write-v1','judgment_id',old.id,'replayed',true);
 end if;
 select * into e from public.math_evaluations where id=($1->>'math_evaluation_id')::uuid for share;
 if e.output_sha256 is distinct from $1->>'expected_output_sha256' then raise invalid_parameter_value;end if;
 perform math_private.hq_validate_context(e.id,$1->'rubric_result',$1->'findings');
 for f in select value from jsonb_array_elements($1->'findings') loop if $1->>'overall_disposition'='PASS' or ($1->>'overall_disposition'='PASS_WITH_NOTES' and f->>'severity'<>'MINOR') then raise check_violation;end if;end loop;
 insert into public.human_quality_judgments(math_evaluation_id,reviewed_output_sha256,reviewer_user_id,rubric_version,overall_disposition,rubric_result,selection_reason,recommended_action,summary_note,supersedes_judgment_id,client_submission_id,submission_payload_sha256)
 values(e.id,e.output_sha256,u,v->>'rubric_version',v->>'overall_disposition',v->'rubric_result',v->>'selection_reason',v->>'recommended_action',v->>'summary_note',parent,key,h) returning id into jid;
 insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref,note) select jid,value->>'issue_category',value->>'severity',value->>'target_kind',value->'target_ref',value->>'note' from jsonb_array_elements(v->'findings');
 return jsonb_build_object('dto_version','hq-math-write-v1','judgment_id',jid,'replayed',false);
end$math_fn$;
revoke all on function public.qlm_submit_human_judgment(jsonb) from public,anon,authenticated,service_role;grant execute on function public.qlm_submit_human_judgment(jsonb) to postgres,authenticated;
create or replace function public.qlm_review_state(p_math_evaluation_ids uuid[]) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare eid uuid; heads jsonb; item jsonb; result jsonb:='[]'; total int; latest timestamptz; material boolean;
begin
 if auth.uid() is null or not exists(select 1 from public.quality_operators where user_id=auth.uid()) then raise insufficient_privilege;end if;
 if p_math_evaluation_ids is null or cardinality(p_math_evaluation_ids)>100 or array_position(p_math_evaluation_ids,null) is not null or coalesce(array_ndims(p_math_evaluation_ids),1)>1 then raise exception 'invalid batch' using errcode='22023';end if;
 perform math_private.require_active(array(select distinct u from (select auth.uid() u union all select a.student_id from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where e.id=any(p_math_evaluation_ids)) subjects order by u)); if not public.is_quality_operator() then raise insufficient_privilege;end if; perform 1 from public.quality_operators where user_id=auth.uid() for key share; if not found then raise insufficient_privilege;end if; for eid in select distinct x from unnest(p_math_evaluation_ids) x order by x loop
  if not exists(select 1 from public.math_evaluations where id=eid) then result=result||jsonb_build_array(jsonb_build_object('math_evaluation_id',eid,'availability','NOT_FOUND'));continue;end if;
  select count(*) into total from public.human_quality_judgments where math_evaluation_id=eid;
  select coalesce(jsonb_agg(jsonb_build_object('rubric_version',j.rubric_version,'overall_disposition',j.overall_disposition)),'[]'),max(j.created_at),coalesce(bool_or(exists(select 1 from public.human_quality_findings f where f.judgment_id=j.id and f.severity in ('MATERIAL','CRITICAL'))),false)
  into heads,latest,material from public.human_quality_judgments j where j.math_evaluation_id=eid and not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id);
  item=essay_private.hq_projection(heads)||jsonb_build_object('math_evaluation_id',eid,'availability','AVAILABLE','total_count',total,'latest_human_reviewed_at',latest,'has_material_issue',material);
  result=result||jsonb_build_array(item);
 end loop;
 return jsonb_build_object('dto_version','hq-math-read-v1','cases',result);
end$math_fn$;
revoke all on function public.qlm_review_state(uuid[]) from public,anon,authenticated,service_role;grant execute on function public.qlm_review_state(uuid[]) to postgres,authenticated;
create or replace function public.qlm_list_human_judgments(p_math_evaluation_id uuid,p_limit integer default 20,p_before timestamptz default null,p_before_id uuid default null) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare n int:=least(100,greatest(1,coalesce(p_limit,20))); v jsonb;
begin
 perform math_private.hq_require_operator(p_math_evaluation_id);
 if (p_before is null)<>(p_before_id is null) then raise exception 'paired cursor required' using errcode='22023';end if;
 if not exists(select 1 from public.math_evaluations where id=p_math_evaluation_id) then raise exception 'case not found' using errcode='P0002';end if;
 with page as materialized(select * from public.human_quality_judgments where math_evaluation_id=p_math_evaluation_id and (p_before is null or (created_at,id)<(p_before,p_before_id)) order by created_at desc,id desc limit n+1),
 shown as materialized(select * from page order by created_at desc,id desc limit n)
 select jsonb_build_object('dto_version','hq-math-read-v1','judgments',coalesce((select jsonb_agg(
  jsonb_build_object('id',j.id,'math_evaluation_id',j.math_evaluation_id,'reviewed_output_sha256',j.reviewed_output_sha256,'reviewer_user_id',j.reviewer_user_id,'rubric_version',j.rubric_version,'overall_disposition',j.overall_disposition,'rubric_result',j.rubric_result,'selection_reason',j.selection_reason,'recommended_action',j.recommended_action,'summary_note',j.summary_note,'supersedes_judgment_id',j.supersedes_judgment_id,'created_at',j.created_at)||jsonb_build_object('reviewer_state',case when j.reviewer_user_id is null then 'DELETED_OR_UNAVAILABLE' else 'AVAILABLE' end,
   'is_active',not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id),
   'findings',coalesce((select jsonb_agg(to_jsonb(f)-'judgment_id' order by f.id) from public.human_quality_findings f where f.judgment_id=j.id),'[]'::jsonb)) order by j.created_at desc,j.id desc) from shown j),'[]'::jsonb),
  'next_cursor',case when (select count(*) from page)>n then (select jsonb_build_object('created_at',created_at,'judgment_id',id) from shown order by created_at,id limit 1) else null end) into v;
 return v;
end$math_fn$;
revoke all on function public.qlm_list_human_judgments(uuid,integer,timestamp with time zone,uuid) from public,anon,authenticated,service_role;grant execute on function public.qlm_list_human_judgments(uuid,integer,timestamp with time zone,uuid) to postgres,authenticated;
create or replace function public.qlm_list_cases(integer,timestamp with time zone,uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare n integer:=least(100,greatest(1,coalesce($1,20)));v jsonb;
begin
 perform math_private.hq_require_operator(null);if ($2 is null)<>($3 is null) then raise invalid_parameter_value;end if;
 select coalesce(jsonb_agg(jsonb_build_object('evaluation_id',id,'completed_at',completed_at,'leaf_id',leaf_id)),'[]') into v from (select id,completed_at,leaf_id from public.math_evaluations where state='COMPLETED' and exists(select 1 from public.math_attempts a where a.id=attempt_id and account_private.allowed(a.student_id)) and ($2 is null or (completed_at,id)<($2,$3)) order by completed_at desc,id desc limit n) x;
 return jsonb_build_object('dto_version','qlm-read-v1','cases',v);
end$math_fn$;
revoke all on function public.qlm_list_cases(integer,timestamp with time zone,uuid) from public,anon,authenticated,service_role;grant execute on function public.qlm_list_cases(integer,timestamp with time zone,uuid) to postgres,authenticated;
create or replace function public.qlm_case_detail(uuid) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$begin perform math_private.hq_require_operator($1);return math_private.evaluation_projection($1,true);end$math_fn$;
revoke all on function public.qlm_case_detail(uuid) from public,anon,authenticated,service_role;grant execute on function public.qlm_case_detail(uuid) to postgres,authenticated;
create or replace function public.ql_submit_human_judgment(p_payload jsonb) returns jsonb language plpgsql volatile security DEFINER set search_path='' as $math_fn$
declare u uuid; eid uuid; key uuid; parent uuid; rw uuid; e public.essay_evaluations; old public.human_quality_judgments; jid uuid;
 v jsonb; f jsonb; t jsonb; h text; r jsonb; k text; cnt integer; sentence_exists boolean; progress_exists boolean;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 u=auth.uid();
 perform 1 from public.quality_operators where user_id=u for key share;
 if not found then raise exception 'not authorized' using errcode='42501';end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>32768
  or p_payload-array['dto_version','evaluation_id','expected_output_sha256','client_submission_id','rubric_version','overall_disposition','rubric_result','selection_reason','recommended_action','summary_note','supersedes_judgment_id','findings','official_source_reviewed']<>'{}'::jsonb
  or p_payload->>'dto_version' is distinct from 'hq-write-v1' or p_payload->'official_source_reviewed' is distinct from 'true'::jsonb then
  raise exception 'invalid payload or source review not confirmed' using errcode='22023';end if;
 foreach k in array array['evaluation_id','client_submission_id','expected_output_sha256','rubric_version','overall_disposition'] loop
  if jsonb_typeof(p_payload->k) is distinct from 'string' then raise exception 'missing field' using errcode='22023';end if;
 end loop;
 eid=(p_payload->>'evaluation_id')::uuid;key=(p_payload->>'client_submission_id')::uuid;parent=(p_payload->>'supersedes_judgment_id')::uuid;
 if p_payload ? 'supersedes_judgment_id' and jsonb_typeof(p_payload->'supersedes_judgment_id') not in ('string','null') then raise exception 'invalid predecessor' using errcode='22023';end if;
 if p_payload ? 'summary_note' and jsonb_typeof(p_payload->'summary_note') not in ('string','null') then raise exception 'invalid note' using errcode='22023';end if;
 foreach k in array array['selection_reason','recommended_action'] loop
  if p_payload ? k and jsonb_typeof(p_payload->k)<>'string' then raise exception 'invalid operational field' using errcode='22023';end if;
 end loop;
 if p_payload->>'rubric_version'<>'hq-rubric-v1' or not essay_private.hq_rubric_valid(p_payload->'rubric_result')
  or jsonb_typeof(p_payload->'findings') is distinct from 'array' then raise exception 'invalid rubric/findings' using errcode='22023';end if;
 if jsonb_array_length(p_payload->'findings')>20 or char_length(p_payload->>'summary_note')>2000 then raise exception 'payload bound' using errcode='22023';end if;
 v=p_payload||jsonb_build_object('evaluation_id',eid,'client_submission_id',key,'supersedes_judgment_id',parent,'summary_note',p_payload->>'summary_note','selection_reason',coalesce(p_payload->>'selection_reason','EARLY_CENSUS'),'recommended_action',coalesce(p_payload->>'recommended_action','NONE'));
 -- Transaction-scoped global key serialization; no request body stored in a second ledger.
 perform pg_advisory_xact_lock(hashtextextended(key::text,731));
 select * into old from public.human_quality_judgments where client_submission_id=key;
 if found then
  if old.evaluation_id is null then raise unique_violation;end if;
  h=encode(sha256(convert_to((v||jsonb_build_object('reviewed_generated_rewrite_id',old.reviewed_generated_rewrite_id))::text,'UTF8')),'hex');
  if old.reviewer_user_id is distinct from u or old.submission_payload_sha256<>h then raise exception 'submission key conflict' using errcode='23505';end if;
  return jsonb_build_object('dto_version','hq-write-v1','judgment_id',old.id,'replayed',true);
 end if;
 select * into e from public.essay_evaluations where id=eid for share;
 if not found then raise exception 'case not found' using errcode='P0002';end if;
 if e.status<>'completed' or e.contract_version<>'1.3' or e.output_sha256 is null
  or e.output_sha256 is distinct from p_payload->>'expected_output_sha256'
  or exists(select 1 from public.essay_improvement_progress where evaluation_id=eid and scaffolding_observation is null)
  or jsonb_typeof(e.input_snapshot->'evidence') is distinct from 'array'
  or jsonb_typeof(e.input_snapshot->'criteria') is distinct from 'array' then raise exception 'unassessable or stale subject' using errcode='22023';end if;
 if jsonb_array_length(e.input_snapshot->'evidence')=0 or jsonb_array_length(e.input_snapshot->'criteria')=0 then raise exception 'missing frozen evidence' using errcode='22023';end if;
 select exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=eid and jsonb_array_length(p.scaffolding_observation->'sentences')>0) into sentence_exists;
 select exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=eid and p.previous_progress_id is not null)
   or e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id' is not null into progress_exists;
 -- Context points to erased history: do not treat missing predecessor as absent history.
 if e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id' is not null and not exists
  (select 1 from public.essay_evaluations where id=(e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id')::uuid) then raise exception 'prior source unavailable' using errcode='22023';end if;
 select id into rw from public.essay_generated_rewrites where evaluation_id=eid and status='completed' for share;
 r=p_payload->'rubric_result';
 if ((r->>'sentence_feedback'='NA')=sentence_exists) or ((r->>'progression'='NA')=progress_exists)
  or ((r->>'generated_rewrite'='NA')=(rw is not null)) then raise exception 'invalid conditional NA' using errcode='22023';end if;
 if parent is not null then
  perform 1 from public.human_quality_judgments where id=parent and evaluation_id=eid for update;
  if not found or exists(select 1 from public.human_quality_judgments where supersedes_judgment_id=parent) then raise exception 'invalid correction head' using errcode='23514';end if;
 end if;
 for f in select value from jsonb_array_elements(p_payload->'findings') loop
  if not essay_private.hq_finding_valid(f) then raise exception 'invalid finding shape' using errcode='22023';end if;
  if p_payload->>'overall_disposition'='PASS' or (p_payload->>'overall_disposition'='PASS_WITH_NOTES' and f->>'severity'<>'MINOR') then raise exception 'finding/disposition conflict' using errcode='23514';end if;
  t=f->'target_ref';cnt=0;
  case f->>'target_kind'
   when 'OVERALL' then cnt=1;
   when 'DIMENSION' then select count(*) into cnt from public.essay_evaluation_dimensions where evaluation_id=eid and id=(t->>'dimension_id')::uuid;
   when 'PROGRESS' then select count(*) into cnt from public.essay_improvement_progress where evaluation_id=eid and id=(t->>'progress_id')::uuid;
   when 'ISSUE_KEY' then select count(*) into cnt from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id where p.evaluation_id=eid and i.issue_key=t->>'issue_key';
   when 'SENTENCE' then select count(*) into cnt from public.essay_improvement_progress p cross join lateral jsonb_array_elements(p.scaffolding_observation->'sentences') s where p.evaluation_id=eid and p.id=(t->>'progress_id')::uuid and s->>'observation_key'=t->>'observation_key';
   when 'EVIDENCE_LINK' then select count(*) into cnt from public.essay_evaluation_evidence where evaluation_id=eid and evidence_id=(t->>'evidence_id')::uuid and dimension_id is not distinct from (t->>'dimension_id')::uuid and improvement_progress_id is not distinct from (t->>'progress_id')::uuid;
   when 'GENERATED_REWRITE' then cnt=case when rw is not null then 1 else 0 end;
   else null;
  end case;
  if cnt<>1 then raise exception 'finding target not on subject' using errcode='22023';end if;
 end loop;
 h=encode(sha256(convert_to((v||jsonb_build_object('reviewed_generated_rewrite_id',rw))::text,'UTF8')),'hex');
 insert into public.human_quality_judgments(evaluation_id,reviewed_output_sha256,reviewed_generated_rewrite_id,reviewer_user_id,rubric_version,overall_disposition,rubric_result,selection_reason,recommended_action,summary_note,supersedes_judgment_id,client_submission_id,submission_payload_sha256)
 values(eid,e.output_sha256,rw,u,v->>'rubric_version',v->>'overall_disposition',r,v->>'selection_reason',v->>'recommended_action',v->>'summary_note',parent,key,h) returning id into jid;
 insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref,note)
 select jid,value->>'issue_category',value->>'severity',value->>'target_kind',value->'target_ref',value->>'note' from jsonb_array_elements(v->'findings');
 return jsonb_build_object('dto_version','hq-write-v1','judgment_id',jid,'replayed',false);
end$math_fn$;
revoke all on function public.ql_submit_human_judgment(jsonb) from public,anon,authenticated,service_role;grant execute on function public.ql_submit_human_judgment(jsonb) to postgres,authenticated;
create or replace function public.ql_list_human_judgments(p_evaluation_id uuid,p_limit integer default 20,p_before timestamptz default null,p_before_id uuid default null) returns jsonb language plpgsql stable security DEFINER set search_path='' as $math_fn$
declare n int:=least(100,greatest(1,coalesce(p_limit,20))); v jsonb;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 if (p_before is null)<>(p_before_id is null) then raise exception 'paired cursor required' using errcode='22023';end if;
 if not exists(select 1 from public.essay_evaluations where id=p_evaluation_id) then raise exception 'case not found' using errcode='P0002';end if;
 with page as materialized(select * from public.human_quality_judgments where evaluation_id=p_evaluation_id and (p_before is null or (created_at,id)<(p_before,p_before_id)) order by created_at desc,id desc limit n+1),
 shown as materialized(select * from page order by created_at desc,id desc limit n)
 select jsonb_build_object('dto_version','hq-read-v1','judgments',coalesce((select jsonb_agg(
  jsonb_build_object('id',j.id,'evaluation_id',j.evaluation_id,'reviewed_output_sha256',j.reviewed_output_sha256,'reviewed_generated_rewrite_id',j.reviewed_generated_rewrite_id,'reviewer_user_id',j.reviewer_user_id,'rubric_version',j.rubric_version,'overall_disposition',j.overall_disposition,'rubric_result',j.rubric_result,'selection_reason',j.selection_reason,'recommended_action',j.recommended_action,'summary_note',j.summary_note,'supersedes_judgment_id',j.supersedes_judgment_id,'created_at',j.created_at)||jsonb_build_object('reviewer_state',case when j.reviewer_user_id is null then 'DELETED_OR_UNAVAILABLE' else 'AVAILABLE' end,
   'is_active',not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id),
   'findings',coalesce((select jsonb_agg(to_jsonb(f)-'judgment_id' order by f.id) from public.human_quality_findings f where f.judgment_id=j.id),'[]'::jsonb)) order by j.created_at desc,j.id desc) from shown j),'[]'::jsonb),
  'next_cursor',case when (select count(*) from page)>n then (select jsonb_build_object('created_at',created_at,'judgment_id',id) from shown order by created_at,id limit 1) else null end) into v;
 return v;
end$math_fn$;
revoke all on function public.ql_list_human_judgments(uuid,integer,timestamp with time zone,uuid) from public,anon,authenticated,service_role;grant execute on function public.ql_list_human_judgments(uuid,integer,timestamp with time zone,uuid) to postgres,authenticated;
alter table public.human_quality_judgments drop constraint human_quality_judgments_rubric_version_check,drop constraint human_quality_judgments_rubric_result_check;
alter table public.human_quality_judgments add constraint hq_domain_rubric check((case when evaluation_id is not null then rubric_version='hq-rubric-v1' and essay_private.hq_rubric_valid(rubric_result) else rubric_version='hq-math-rubric-v1' and reviewed_generated_rewrite_id is null and math_private.hq_rubric_valid(rubric_result) end) is true);
alter table public.human_quality_findings drop constraint human_quality_findings_check;
alter table public.human_quality_findings add constraint hq_finding_union check((essay_private.hq_finding_valid(jsonb_build_object('issue_category',issue_category,'severity',severity,'target_kind',target_kind,'target_ref',target_ref,'note',note)) or math_private.hq_finding_valid(jsonb_build_object('issue_category',issue_category,'severity',severity,'target_kind',target_kind,'target_ref',target_ref,'note',note))) is true);
create trigger hq_domain_parent before insert on public.human_quality_judgments for each row execute function math_private.hq_parent_guard();
create trigger hq_domain_finding before insert on public.human_quality_findings for each row execute function math_private.hq_finding_guard();
create trigger math_binding before insert or update on public.math_billing_bindings for each row execute function math_private.binding_guard();
create trigger math_artifact before insert or update or delete on public.math_attempt_artifacts for each row execute function math_private.artifact_guard();

alter table public.math_problem_sets enable row level security;revoke all on public.math_problem_sets from public,anon,authenticated,service_role;
grant select on public.math_problem_sets to math_executor;create policy math_executor_scope on public.math_problem_sets for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_problem_sets for each row execute function math_private.content_immutable();
alter table public.math_problems enable row level security;revoke all on public.math_problems from public,anon,authenticated,service_role;
grant select on public.math_problems to math_executor;create policy math_executor_scope on public.math_problems for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_problems for each row execute function math_private.content_immutable();
alter table public.math_subproblems enable row level security;revoke all on public.math_subproblems from public,anon,authenticated,service_role;
grant select on public.math_subproblems to math_executor;create policy math_executor_scope on public.math_subproblems for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_subproblems for each row execute function math_private.content_immutable();
alter table public.math_source_artifacts enable row level security;revoke all on public.math_source_artifacts from public,anon,authenticated,service_role;
grant select on public.math_source_artifacts to math_executor;create policy math_executor_scope on public.math_source_artifacts for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_source_artifacts for each row execute function math_private.content_immutable();
alter table public.math_evaluation_profiles enable row level security;revoke all on public.math_evaluation_profiles from public,anon,authenticated,service_role;
grant select on public.math_evaluation_profiles to math_executor;create policy math_executor_scope on public.math_evaluation_profiles for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_evaluation_profiles for each row execute function math_private.content_immutable();
alter table public.math_scoring_criteria enable row level security;revoke all on public.math_scoring_criteria from public,anon,authenticated,service_role;
grant select on public.math_scoring_criteria to math_executor;create policy math_executor_scope on public.math_scoring_criteria for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_scoring_criteria for each row execute function math_private.content_immutable();
alter table public.math_canonical_solutions enable row level security;revoke all on public.math_canonical_solutions from public,anon,authenticated,service_role;
grant select on public.math_canonical_solutions to math_executor;create policy math_executor_scope on public.math_canonical_solutions for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_canonical_solutions for each row execute function math_private.content_immutable();
alter table public.math_canonical_solution_steps enable row level security;revoke all on public.math_canonical_solution_steps from public,anon,authenticated,service_role;
grant select on public.math_canonical_solution_steps to math_executor;create policy math_executor_scope on public.math_canonical_solution_steps for all to math_executor using(true) with check(true);
create trigger math_version_immutable before insert or update on public.math_canonical_solution_steps for each row execute function math_private.content_immutable();
alter table public.math_attempts enable row level security;revoke all on public.math_attempts from public,anon,authenticated,service_role;
grant select,insert,update on public.math_attempts to math_executor;create policy math_executor_scope on public.math_attempts for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_attempts for each row execute function math_private.personal_immutable();
alter table public.math_attempt_artifacts enable row level security;revoke all on public.math_attempt_artifacts from public,anon,authenticated,service_role;
grant select,insert,update on public.math_attempt_artifacts to math_executor;create policy math_executor_scope on public.math_attempt_artifacts for all to math_executor using(true) with check(true);
alter table public.math_extraction_runs enable row level security;revoke all on public.math_extraction_runs from public,anon,authenticated,service_role;
grant select,insert,update on public.math_extraction_runs to math_executor;create policy math_executor_scope on public.math_extraction_runs for all to math_executor using(true) with check(true);
alter table public.math_extraction_regions enable row level security;revoke all on public.math_extraction_regions from public,anon,authenticated,service_role;
grant select,insert,update on public.math_extraction_regions to math_executor;create policy math_executor_scope on public.math_extraction_regions for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_extraction_regions for each row execute function math_private.personal_immutable();
alter table public.math_evaluations enable row level security;revoke all on public.math_evaluations from public,anon,authenticated,service_role;
grant select,insert,update on public.math_evaluations to math_executor;create policy math_executor_scope on public.math_evaluations for all to math_executor using(true) with check(true);
alter table public.math_solution_steps enable row level security;revoke all on public.math_solution_steps from public,anon,authenticated,service_role;
grant select,insert,update on public.math_solution_steps to math_executor;create policy math_executor_scope on public.math_solution_steps for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_solution_steps for each row execute function math_private.personal_immutable();
alter table public.math_step_regions enable row level security;revoke all on public.math_step_regions from public,anon,authenticated,service_role;
grant select,insert,update on public.math_step_regions to math_executor;create policy math_executor_scope on public.math_step_regions for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_step_regions for each row execute function math_private.personal_immutable();
alter table public.math_step_dependencies enable row level security;revoke all on public.math_step_dependencies from public,anon,authenticated,service_role;
grant select,insert,update on public.math_step_dependencies to math_executor;create policy math_executor_scope on public.math_step_dependencies for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_step_dependencies for each row execute function math_private.personal_immutable();
alter table public.math_errors enable row level security;revoke all on public.math_errors from public,anon,authenticated,service_role;
grant select,insert,update on public.math_errors to math_executor;create policy math_executor_scope on public.math_errors for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_errors for each row execute function math_private.personal_immutable();
alter table public.math_error_propagations enable row level security;revoke all on public.math_error_propagations from public,anon,authenticated,service_role;
grant select,insert,update on public.math_error_propagations to math_executor;create policy math_executor_scope on public.math_error_propagations for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_error_propagations for each row execute function math_private.personal_immutable();
alter table public.math_core enable row level security;revoke all on public.math_core from public,anon,authenticated,service_role;
grant select,insert,update on public.math_core to math_executor;create policy math_executor_scope on public.math_core for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_core for each row execute function math_private.personal_immutable();
alter table public.math_hints enable row level security;revoke all on public.math_hints from public,anon,authenticated,service_role;
grant select,insert,update on public.math_hints to math_executor;create policy math_executor_scope on public.math_hints for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_hints for each row execute function math_private.personal_immutable();
alter table public.math_hint_exposures enable row level security;revoke all on public.math_hint_exposures from public,anon,authenticated,service_role;
grant select,insert,update on public.math_hint_exposures to math_executor;create policy math_executor_scope on public.math_hint_exposures for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_hint_exposures for each row execute function math_private.personal_immutable();
alter table public.math_considered_references enable row level security;revoke all on public.math_considered_references from public,anon,authenticated,service_role;
grant select,insert,update on public.math_considered_references to math_executor;create policy math_executor_scope on public.math_considered_references for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_considered_references for each row execute function math_private.personal_immutable();
alter table public.math_evaluated_paths enable row level security;revoke all on public.math_evaluated_paths from public,anon,authenticated,service_role;
grant select,insert,update on public.math_evaluated_paths to math_executor;create policy math_executor_scope on public.math_evaluated_paths for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_evaluated_paths for each row execute function math_private.personal_immutable();
alter table public.math_evaluation_sources enable row level security;revoke all on public.math_evaluation_sources from public,anon,authenticated,service_role;
grant select,insert,update on public.math_evaluation_sources to math_executor;create policy math_executor_scope on public.math_evaluation_sources for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_evaluation_sources for each row execute function math_private.personal_immutable();
alter table public.math_evaluation_criteria enable row level security;revoke all on public.math_evaluation_criteria from public,anon,authenticated,service_role;
grant select,insert,update on public.math_evaluation_criteria to math_executor;create policy math_executor_scope on public.math_evaluation_criteria for all to math_executor using(true) with check(true);
alter table public.math_solution_exposures enable row level security;revoke all on public.math_solution_exposures from public,anon,authenticated,service_role;
grant select,insert,update on public.math_solution_exposures to math_executor;create policy math_executor_scope on public.math_solution_exposures for all to math_executor using(true) with check(true);
create trigger math_fact_immutable before update on public.math_solution_exposures for each row execute function math_private.personal_immutable();
alter table public.math_billing_bindings enable row level security;revoke all on public.math_billing_bindings from public,anon,authenticated,service_role;
grant select,insert,update on public.math_billing_bindings to math_executor;create policy math_executor_scope on public.math_billing_bindings for all to math_executor using(true) with check(true);
grant select,update on public.math_attempts to essay_executor;
grant select,update on public.math_evaluations to essay_executor;
grant select,update on public.math_billing_bindings to essay_executor;
grant insert on public.math_billing_bindings to essay_executor;
do $postflight$declare r text;begin
 foreach r in array array['math_executor','math_extraction_worker','math_evaluation_worker'] loop
  if (select count(*) from pg_auth_members where roleid=r::regrole)<>1 or not exists(select 1 from pg_auth_members where roleid=r::regrole and member='postgres'::regrole and grantor='supabase_admin'::regrole and admin_option and not inherit_option and not set_option) then raise exception 'MATH_UNEXPECTED_FINAL_MEMBERSHIP';end if;
  if exists(select 1 from pg_roles where rolname=r and (rolcanlogin or rolbypassrls or rolsuper or rolcreatedb or rolcreaterole or rolreplication or rolinherit)) then raise exception 'MATH_ROLE_PRIVILEGE_DRIFT';end if;
 end loop;
 if has_schema_privilege('math_executor','public','CREATE') or has_schema_privilege('math_executor','math_private','CREATE') or has_schema_privilege('essay_executor','math_private','CREATE') or exists(select 1 from pg_auth_members where roleid='essay_executor'::regrole and (set_option or inherit_option)) then raise exception 'MATH_TEMPORARY_PRIVILEGE_REMAINS';end if;
end $postflight$;
commit;
