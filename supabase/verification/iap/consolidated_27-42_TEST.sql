-- =====================================================================
-- CONSOLIDATED MIGRATIONS #27-42  —  TEST PROJECT ONLY: kpqbedylxlyntrrfybpn
-- Generated from canonical files (verbatim, byte-faithful). DO NOT run on
-- production (stlhijzpjfgwwdgunlsd). Run once in the Supabase SQL Editor of
-- the TEST project. Each migration keeps its own begin/commit (temp tables,
-- set local, reset role rely on it); the SQL Editor runs as session_user=postgres
-- so the reset-role bridges (#27-30) succeed. Per-migration history is recorded
-- only AFTER that migration commits, so a failed migration is NOT recorded and
-- execution stops at the first error (earlier ones stay applied+recorded).
-- Re-running is blocked by the pre-flight guard below (duplicate prevention).
-- =====================================================================

-- ---- PRE-FLIGHT GUARD: baseline must be exactly #1-26, and #27-42 must be absent ----
do $preflight$
begin
  if (select count(*) from supabase_migrations.schema_migrations) <> 26
     or not exists (select 1 from supabase_migrations.schema_migrations where version = '20261001000300') then
    raise exception 'ABORT: baseline is not exactly 26 migrations through 20261001000300 (found % rows)',
      (select count(*) from supabase_migrations.schema_migrations);
  end if;
  if exists (select 1 from supabase_migrations.schema_migrations
             where version in ('20261002000100','20261002000200','20261002000300','20261003000100','20261004000100','20261005000100','20261006000100','20261006000200','20261008000500','20261008000600','20261008000700','20261008000800','20261008000900','20261008001000','20261009000100','20261009000200')) then
    raise exception 'ABORT: at least one of #27-42 is already applied — this consolidated script was already run (duplicate prevention). Report the current state for a resume script.';
  end if;
end
$preflight$;


-- ========== #27  20261002000100_math_essay_persistence  (version 20261002000100) ==========
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

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261002000100','math_essay_persistence', array['-- consolidated apply of canonical 20261002000100_math_essay_persistence.sql, sha256=73fae66a4a9198885c6bf505ac87d9a3abcc453dd1017e666a217bac486c7d51']);


-- ========== #28  20261002000200_math_runtime_surface  (version 20261002000200) ==========
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

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261002000200','math_runtime_surface', array['-- consolidated apply of canonical 20261002000200_math_runtime_surface.sql, sha256=b40bf7224a84658308ff1640b639acb857e379998211131d97a688a9711fe049']);


-- ========== #29  20261002000300_math_learning_runtime  (version 20261002000300) ==========
-- MATH-2E: learning delivery/resolve surface, NOT Production activation.
begin;
do $$begin
 if current_user<>'postgres' or (select rolsuper from pg_roles where rolname=current_user) then raise exception 'NON_SUPERUSER_POSTGRES_REQUIRED';end if;
 if to_regprocedure('public.math_input(jsonb)') is null then raise exception 'MATH_2D_REQUIRED';end if;
 if has_schema_privilege('math_executor','math_private','CREATE') or exists(select 1 from pg_auth_members where roleid='math_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'UNEXPECTED_TOPOLOGY';end if;
end$$;
-- Explicit typed generated-reference binding, no copied answer or detached hash.
alter table public.math_evaluations add constraint math_evaluation_output_identity unique(id,output_sha256);
alter table public.math_solution_exposures alter column solution_id drop not null;
alter table public.math_solution_exposures add column generated_output_sha256 text;
alter table public.math_solution_exposures add constraint math_solution_exposure_one_binding check(num_nonnulls(solution_id,generated_output_sha256)=1);
alter table public.math_solution_exposures add constraint math_solution_generated_output_fk foreign key(evaluation_id,generated_output_sha256) references public.math_evaluations(id,output_sha256) on delete cascade;
create index math_hint_delivery_history on public.math_hint_exposures(hint_id,delivered_at,id);
create index math_solution_delivery_history on public.math_solution_exposures(evaluation_id,delivered_at,id);

grant math_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema math_private to math_executor;
set role math_executor;
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
 if jsonb_typeof($2->'overall')<>'object' or ($2->'overall')-array['status','explanation','answer_status','coverage','review_status']<>'{}' or ($2->'overall')->>'status' not in ('ANSWER_CORRECT_AND_REASONING_SUFFICIENT','ANSWER_CORRECT_REASONING_INCOMPLETE','ANSWER_INCORRECT_APPROACH_MOSTLY_VALID','FUNDAMENTAL_APPROACH_ERROR','NOT_DETERMINABLE') or length(($2->'overall')->>'explanation') not between 1 and 10000 then raise invalid_parameter_value;end if;
 foreach k in array array['status','explanation','answer_status','coverage'] loop if jsonb_typeof($2->'overall'->k) is distinct from 'string' then raise invalid_parameter_value;end if;end loop;
 if jsonb_typeof($2->'provenance')<>'object' or ($2->'provenance')-array['provider','model','model_version','prompt_version']<>'{}' then raise invalid_parameter_value;end if;
 foreach k in array array['provider','model','model_version','prompt_version'] loop if jsonb_typeof(($2->'provenance')->k) is distinct from 'string' or length(($2->'provenance')->>k) not between 1 and 200 then raise invalid_parameter_value;end if;end loop;
 if a.kind='INITIAL' and $2->'progression'<>'null' then raise invalid_parameter_value;end if;
 if a.kind<>'INITIAL' and (jsonb_typeof($2->'progression')<>'object' or ($2->'progression')-array['prior_evaluation_id','target_step_id','downstream','summary','delta']<>'{}' or (($2->'progression')->>'prior_evaluation_id')::uuid is distinct from a.prior_evaluation_id or (($2->'progression')->>'target_step_id')::uuid is distinct from a.target_step_id or (a.kind='STEP_RETRY' and ($2->'progression')->>'downstream' is distinct from 'NOT_REASSESSED')) then raise invalid_parameter_value using message='INVALID_PROGRESSION';end if;
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

 if ($2->'overall') ? 'review_status' and (jsonb_typeof($2->'overall'->'review_status') is distinct from 'string' or $2->'overall'->>'review_status' not in ('NOT_REQUIRED','HUMAN_REVIEW_REQUIRED')) then raise invalid_parameter_value using message='INVALID_REVIEW_STATUS';end if;
 if ($2->'progression') ? 'delta' then
  if jsonb_typeof($2->'progression'->'delta') is distinct from 'array' or jsonb_array_length($2->'progression'->'delta')>20 then raise invalid_parameter_value;end if;
  for v in select value from jsonb_array_elements($2->'progression'->'delta') loop
   if jsonb_typeof(v)<>'object' or v-array['kind','prior_error_id','current_error_id','explanation']<>'{}' or not v ?& array['kind','explanation'] or jsonb_typeof(v->'explanation') is distinct from 'string' or length(v->>'explanation') not between 1 and 2000 or jsonb_typeof(v->'kind') is distinct from 'string' or v->>'kind' not in ('CORE_CORRECTED','ROOT_ERROR_REMOVED','ROOT_ERROR_REMAINS','PROPAGATED_ERROR_REMOVED','NEW_INDEPENDENT_ERROR','ANSWER_CHANGED','ANSWER_NOW_CORRECT','JUSTIFICATION_IMPROVED','NO_MATERIAL_CHANGE','PATH_VALIDITY_CHANGED') then raise invalid_parameter_value using message='INVALID_DELTA';end if;
   if v->>'prior_error_id' is not null and not exists(select 1 from public.math_errors where id=(v->>'prior_error_id')::uuid and evaluation_id=a.prior_evaluation_id) then raise invalid_parameter_value;end if;
   if v->>'current_error_id' is not null and not exists(select 1 from jsonb_array_elements($2->'errors') x where x->>'id'=v->>'current_error_id') then raise invalid_parameter_value;end if;
  end loop;
 end if;
end$math_fn$;
reset role;
revoke create on schema math_private from math_executor;
revoke math_executor from postgres granted by postgres;
create function math_private.learning_eligibility(p_evaluation_id uuid,p_at timestamptz) returns jsonb
language plpgsql stable security invoker set search_path='' as $$
declare initial public.math_evaluations; decision public.essay_billing_decisions; lineage uuid; student uuid; eligibility_status text; expires timestamptz;
begin
 select a.lineage_id,a.student_id into lineage,student from public.math_attempts a join public.math_evaluations e on e.attempt_id=a.id where e.id=p_evaluation_id;
 select e.* into initial from public.math_evaluations e join public.math_attempts a on a.id=e.attempt_id where a.lineage_id=lineage and a.student_id=student and e.request_kind='MATH_INITIAL_EVALUATION' and e.state='COMPLETED' order by e.completed_at desc,e.id desc limit 1;
 select d.* into decision from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=initial.id;
 expires=initial.completed_at+interval '336 hours';
 eligibility_status=case when initial.id is null or decision.id is null or decision.status<>'settled' or decision.reason<>'paid_cycle' or decision.policy_key<>'essay_cycle' or decision.policy_version<>'v2' or exists(select 1 from public.credit_transactions where decision_id=decision.id and transaction_type='refund') then 'UNAVAILABLE'
 when exists(select 1 from public.essay_billing_decisions where included_by_decision_id=decision.id and status='settled') then 'CONSUMED'
 when exists(select 1 from public.essay_billing_decisions where included_by_decision_id=decision.id and status in ('authorized','reserved')) then 'AUTHORIZED_PENDING'
 when p_at>=expires then 'EXPIRED' else 'AVAILABLE' end;
 return jsonb_build_object('status',eligibility_status,'eligible',eligibility_status='AVAILABLE','included_count',1,'initial_evaluation_id',initial.id,'expires_at',expires,'as_of',p_at,'request_route',case when eligibility_status='AVAILABLE' then 'math_learning.request_reevaluation' else 'math_input.request_evaluation' end);
end$$;
revoke all on function math_private.learning_eligibility(uuid,timestamptz) from public,anon,authenticated,service_role;

create function math_private.learning_state(p_evaluation_id uuid) returns jsonb
language plpgsql volatile security invoker set search_path='' as $$
declare e public.math_evaluations;a public.math_attempts;response text;u uuid;refs jsonb;hints jsonb;cores jsonb;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 select er.* into e from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=p_evaluation_id and ar.student_id=u;
 if not found then raise no_data_found;end if;
 select * into a from public.math_attempts where id=e.attempt_id;
 select response_format into response from public.math_subproblems where id=e.leaf_id;
 select coalesce(jsonb_agg(jsonb_build_object('core_id',id,'position',position,'error_id',error_id,'step_id',step_id,'title',title,'diagnosis',diagnosis,'why',why,'next_action',next_action) order by position),'[]') into cores from public.math_core where evaluation_id=e.id;
 select coalesce(jsonb_agg(jsonb_build_object('hint_id',h.id,'core_id',h.core_id,'level',h.level,'available',h.validated and e.state='COMPLETED','revealed',exists(select 1 from public.math_hint_exposures where hint_id=h.id),'can_reveal',h.validated and e.state='COMPLETED' and (h.level<2 or exists(select 1 from public.math_hint_exposures x join public.math_hints prior on prior.id=x.hint_id where prior.core_id=h.core_id and prior.level=1))) order by h.core_id,h.level),'[]') into hints from public.math_hints h where h.evaluation_id=e.id;
 select coalesce(jsonb_agg(jsonb_build_object('solution_id',s.id,'target','REFERENCE','provenance',case s.origin when 'OFFICIAL' then 'OFFICIAL_SOLUTION' when 'VERIFIED_INTERNAL' then 'VERIFIED_INTERNAL_SOLUTION' else 'AI_GENERATED_REFERENCE' end,'physical_origin',s.origin,'reveal_state',case when e.state='COMPLETED' then 'AVAILABLE_ON_EXPLICIT_REQUEST' else 'UNAVAILABLE' end,'revealed',exists(select 1 from public.math_solution_exposures where evaluation_id=e.id and solution_id=s.id)) order by s.id),'[]') into refs from public.math_considered_references x join public.math_canonical_solutions s on s.id=x.solution_id where x.evaluation_id=e.id;
 if e.result->'generated_solution'<>'null' then refs=refs||jsonb_build_array(jsonb_build_object('solution_id',null,'target','GENERATED','provenance','AI_GENERATED_REFERENCE','physical_origin','AI_GENERATED','reveal_state',case when e.state='COMPLETED' then 'AVAILABLE_ON_EXPLICIT_REQUEST' else 'UNAVAILABLE' end,'revealed',exists(select 1 from public.math_solution_exposures where evaluation_id=e.id and generated_output_sha256=e.output_sha256)));end if;
 return jsonb_build_object('evaluation_id',e.id,'attempt_id',a.id,'lineage_id',a.lineage_id,'leaf_id',a.leaf_id,'problem_id',(select problem_id from public.math_subproblems where id=a.leaf_id),'response_format',response,'resolve_kind',a.kind,'prior_attempt_id',a.predecessor_id,'prior_evaluation_id',a.prior_evaluation_id,'target_step_id',a.target_step_id,'submitted_scope',case when a.kind='STEP_RETRY' then 'TARGET_STEP' else 'WHOLE_LEAF' end,'downstream',case when a.kind='STEP_RETRY' then 'NOT_REASSESSED' else null end,
 'evaluation_state',e.state,'completed_at',e.completed_at,'valid_evaluation_available',e.state in ('COMPLETED','INVALIDATED'),'review_status',coalesce(e.result->'overall'->>'review_status','NOT_RECORDED'),
 'core',cores,'hints',hints,'hint_availability',case when jsonb_array_length(cores)=0 then 'NOT_APPLICABLE' when jsonb_array_length(hints)=0 then 'UNAVAILABLE' else 'FROM_FROZEN_HINTS' end,'solutions',refs,
 'resolve_kinds',case when e.state<>'COMPLETED' then '[]'::jsonb when response='SHORT_ANSWER' then '["SHORT_ANSWER_RESOLVE","FULL_RESOLVE"]'::jsonb else '["FULL_RESOLVE"]'::jsonb end || case when e.state='COMPLETED' and exists(select 1 from public.math_solution_steps where evaluation_id=e.id) then '["STEP_RETRY"]'::jsonb else '[]'::jsonb end,
 'included_reevaluation',math_private.learning_eligibility(e.id,clock_timestamp()),'reevaluation_delta',e.result->'progression',
 'reference_solution_revealed_before_resolve',exists(select 1 from public.math_solution_exposures where evaluation_id=a.prior_evaluation_id and delivered_at<=a.created_at),
 'hint_levels_before_resolve',(select coalesce(jsonb_agg(distinct h.level),'[]') from public.math_hint_exposures x join public.math_hints h on h.id=x.hint_id where h.evaluation_id=a.prior_evaluation_id and x.delivered_at<=a.created_at));
end$$;
revoke all on function math_private.learning_state(uuid) from public,anon,authenticated,service_role;

create function public.math_learning(p_request jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare v jsonb=p_request->'payload';action text=p_request->>'action';u uuid;allowed text[];e public.math_evaluations;a public.math_attempts;h public.math_hints;s public.math_canonical_solutions;exposure public.math_solution_exposures;
 answer jsonb;key uuid;target text;sid uuid;gh text;newid uuid;lim integer;before_at timestamptz;before_id uuid;page jsonb;item record;last_at timestamptz;last_id uuid;basis uuid;decision public.essay_billing_decisions;
begin
 u=math_private.current_subject();perform math_private.require_active(array[u]);
 if p_request is null or jsonb_typeof(p_request)<>'object' or octet_length(p_request::text)>70000 or p_request-array['dto_version','action','payload']<>'{}' or p_request->>'dto_version' is distinct from 'math-learning-v1' or jsonb_typeof(v) is distinct from 'object' then raise invalid_parameter_value using message='INVALID_LEARNING_CONTRACT';end if;
 allowed=case action when 'read_learning_state' then array['evaluation_id'] when 'reveal_hint' then array['evaluation_id','hint_id','level','client_submission_id'] when 'reveal_solution' then array['evaluation_id','target','solution_id','client_submission_id'] when 'create_resolve_attempt' then array['client_submission_id','leaf_id','kind','predecessor_id','prior_evaluation_id','target_step_id','typed_answer','input_kind'] when 'request_reevaluation' then array['attempt_id','client_submission_id'] when 'read_learning_history' then array['evaluation_id','limit','before_at','before_id'] else null end;
 if allowed is null or v-allowed<>'{}' then raise invalid_parameter_value;end if;
 if action in ('read_learning_state','read_learning_history','reveal_hint','reveal_solution') then
  select er.* into e from public.math_evaluations er join public.math_attempts ar on ar.id=er.attempt_id where er.id=(v->>'evaluation_id')::uuid and ar.student_id=u;
  if not found then raise no_data_found;end if;select * into a from public.math_attempts where id=e.attempt_id;
 end if;
 case action
 when 'read_learning_state' then answer=math_private.learning_state(e.id);
 when 'reveal_hint' then
  if jsonb_typeof(v->'level') is distinct from 'number' or v->>'level' not in ('0','1','2') then raise invalid_parameter_value;end if;
  select * into h from public.math_hints where id=(v->>'hint_id')::uuid and evaluation_id=e.id and level=(v->>'level')::integer and validated;
  if not found then raise invalid_parameter_value using message='HINT_UNAVAILABLE';end if;
  answer=public.math_reveal_hint(h.id,(v->>'client_submission_id')::uuid);
 when 'reveal_solution' then
  if e.state<>'COMPLETED' then raise invalid_parameter_value;end if;
  key=(v->>'client_submission_id')::uuid;target=v->>'target';sid=(v->>'solution_id')::uuid;
  if key is null or target is null or target not in ('REFERENCE','GENERATED') then raise invalid_parameter_value;end if;
  if target='REFERENCE' then
   select sr.* into s from public.math_canonical_solutions sr join public.math_considered_references cr on cr.solution_id=sr.id where cr.evaluation_id=e.id and sr.id=sid;
   if not found then raise invalid_parameter_value using message='SOLUTION_UNAVAILABLE';end if;
  else
   if sid is not null or e.result->'generated_solution' is null or e.result->'generated_solution'='null' then raise invalid_parameter_value using message='SOLUTION_UNAVAILABLE';end if;gh=e.output_sha256;
  end if;
  perform pg_advisory_xact_lock(hashtextextended(key::text,735));
  select * into exposure from public.math_solution_exposures where client_key=key;
  if found then
   if exposure.evaluation_id<>e.id or exposure.solution_id is distinct from sid or exposure.generated_output_sha256 is distinct from gh then raise unique_violation using message='REVEAL_RETRY_CONFLICT';end if;
  else
   insert into public.math_solution_exposures(evaluation_id,solution_id,generated_output_sha256,client_key) values(e.id,sid,gh,key) returning * into exposure;
  end if;
  answer=jsonb_build_object('exposure_id',exposure.id,'evaluation_id',e.id,'solution_id',sid,'target',target,'delivered_at',exposure.delivered_at,'provenance',case when target='GENERATED' or s.origin='AI_PROPOSED' then 'AI_GENERATED_REFERENCE' when s.origin='OFFICIAL' then 'OFFICIAL_SOLUTION' else 'VERIFIED_INTERNAL_SOLUTION' end,'physical_origin',case when target='GENERATED' then 'AI_GENERATED' else s.origin end,'body',case when target='GENERATED' then e.result->'generated_solution'->>'body' else s.body end,'learning_context','REFERENCE_SOLUTION_REVEALED');
 when 'create_resolve_attempt' then
  if v->>'kind' is null or v->>'kind' not in ('STEP_RETRY','FULL_RESOLVE','SHORT_ANSWER_RESOLVE') then raise invalid_parameter_value using message='INVALID_RESOLVE_KIND';end if;
  -- Reuse immutable attempt + exact canonical lineage validation and idempotency.
  newid=public.math_submit_attempt(v);answer=jsonb_build_object('attempt_id',newid);
 when 'request_reevaluation' then
  select * into a from public.math_attempts where id=(v->>'attempt_id')::uuid and student_id=u;
  if not found or a.kind='INITIAL' then raise invalid_parameter_value;end if;
  -- The canonical request owns lifecycle -> account -> attempt -> evaluation -> decision locking.
  -- A paid fallback is rejected atomically here; existing math_input is the separately explicit ordinary route.
  newid=public.math_request_evaluation(a.id,(v->>'client_submission_id')::uuid);
  select d.* into decision from public.essay_billing_decisions d join public.math_billing_bindings b on b.billing_decision_id=d.id where b.math_evaluation_id=newid;
  if decision.reason<>'included_revision' or decision.credits_required<>0 then raise invalid_parameter_value using message='INCLUDED_REEVALUATION_UNAVAILABLE';end if;
  answer=jsonb_build_object('evaluation_id',newid,'commercial_context','INCLUDED_REEVALUATION','additional_credit',0);
 when 'read_learning_history' then
  lim=coalesce((v->>'limit')::integer,20);before_at=(v->>'before_at')::timestamptz;before_id=(v->>'before_id')::uuid;
  if lim not between 1 and 50 or (before_at is null)<>(before_id is null) then raise invalid_parameter_value;end if;
  page='[]';
  for item in select ar.*,er.id as current_evaluation_id,er.state as evaluation_state,er.result->'progression' as progression,er.completed_at
   from public.math_attempts ar left join lateral(select id,state,result,completed_at from public.math_evaluations where attempt_id=ar.id order by requested_at desc,id desc limit 1) er on true
   where ar.student_id=u and ar.lineage_id=a.lineage_id and (before_at is null or (ar.created_at,ar.id)<(before_at,before_id)) order by ar.created_at desc,ar.id desc limit lim loop
   page=page||jsonb_build_array(jsonb_build_object('attempt_id',item.id,'created_at',item.created_at,'resolve_kind',item.kind,'prior_attempt_id',item.predecessor_id,'prior_evaluation_id',item.prior_evaluation_id,'target_step_id',item.target_step_id,'submitted_scope',case when item.kind='STEP_RETRY' then 'TARGET_STEP' else 'WHOLE_LEAF' end,'evaluation_id',item.current_evaluation_id,'evaluation_state',item.evaluation_state,'completed_at',item.completed_at,'reevaluation_delta',item.progression,
    'core_ids',(select coalesce(jsonb_agg(id order by position),'[]') from public.math_core where evaluation_id=item.current_evaluation_id),
    'exposed_hint_levels',(select coalesce(jsonb_agg(distinct hint_row.level),'[]') from public.math_hint_exposures x join public.math_hints hint_row on hint_row.id=x.hint_id where hint_row.evaluation_id=item.current_evaluation_id),
    'solution_revealed',exists(select 1 from public.math_solution_exposures where evaluation_id=item.current_evaluation_id),
    'reference_solution_revealed_before_resolve',exists(select 1 from public.math_solution_exposures where evaluation_id=item.prior_evaluation_id and delivered_at<=item.created_at)));
   last_at=item.created_at;last_id=item.id;
  end loop;
  answer=jsonb_build_object('lineage_id',a.lineage_id,'attempts',page,'included_reevaluation',math_private.learning_eligibility(e.id,clock_timestamp()),'next_cursor',case when jsonb_array_length(page)=lim then jsonb_build_object('created_at',last_at,'attempt_id',last_id) else null end);
 end case;
 if octet_length(answer::text)>2097152 then raise program_limit_exceeded using message='LEARNING_RESPONSE_BOUND';end if;
 return jsonb_build_object('dto_version','math-learning-v1','action',action,'result',answer);
end$$;
revoke all on function public.math_learning(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.math_learning(jsonb) to authenticated;
do $$begin
 if has_schema_privilege('math_executor','math_private','CREATE') or exists(select 1 from pg_auth_members where roleid='math_executor'::regrole and (member<>'postgres'::regrole or not admin_option or inherit_option or set_option)) then raise exception 'TOPOLOGY_NOT_RESTORED';end if;
end$$;
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261002000300','math_learning_runtime', array['-- consolidated apply of canonical 20261002000300_math_learning_runtime.sql, sha256=fa0fbb507dd650d2e684f7dc9bc9375c6c5db09eac64405a438ad63206933f7d']);


-- ========== #30  20261003000100_payment_foundation  (version 20261003000100) ==========
-- PAYMENT APP foundation. NOT APPLIED. No provider/network calls or LIVE activation.
begin;
create schema payment_private;
revoke all on schema payment_private from public,anon,authenticated,service_role;
grant usage on schema payment_private to essay_executor;
create table payment_private.configuration(singleton boolean primary key check(singleton), mode text not null check(mode in ('TEST','LIVE')));
insert into payment_private.configuration values(true,'TEST');
create table public.payment_orders(
 id uuid primary key default gen_random_uuid(),
 subject_id uuid references public.profiles(id) on delete set null,
 request_key uuid not null,
 provider text not null default 'TOSS' check(provider in ('TOSS','APPLE_IAP','GOOGLE_PLAY')),
 mode text not null check(mode in ('TEST','LIVE')),
 sku text not null check(sku in ('1c','3c','5c','10c')),
 amount integer not null check(amount>0), quantity integer not null check(quantity in (1,3,5,10)),
 currency text not null default 'KRW' check(currency='KRW'),
 policy_version text not null default 'commerce-2026-10-03' check(policy_version='commerce-2026-10-03'),
 deduction_unit integer not null default 4900 check(deduction_unit=4900), validity_months integer not null default 3 check(validity_months=3),
 state text not null default 'ORDER_CREATED' check(state in ('ORDER_CREATED','AUTHORIZATION_PENDING','PAID','CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED','FAILED','EXPIRED')),
 grant_state text not null default 'NONE' check(grant_state in ('NONE','TEST_RECORDED','POSTED','REVOKED')),
 provider_purchase_id text check(length(provider_purchase_id) between 1 and 1024),
 grant_id uuid unique references public.credit_grants(id) on delete restrict,
 created_at timestamptz not null default clock_timestamp(), expires_at timestamptz not null default clock_timestamp()+interval '30 minutes',
 paid_at timestamptz, credit_expires_at timestamptz,
 unique(subject_id,request_key),
 unique(provider,mode,provider_purchase_id),
 check(mode<>'TEST' or (grant_id is null and grant_state in ('NONE','TEST_RECORDED','REVOKED'))),
 check(grant_state<>'POSTED' or (mode='LIVE' and grant_id is not null)),
 check(state not in ('PAID','CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED') or (paid_at is not null and provider_purchase_id is not null))
);
create table public.payment_operations(
 id uuid primary key default gen_random_uuid(),order_id uuid not null references public.payment_orders(id) on delete restrict,
 kind text not null check(kind in ('CONFIRM','CANCEL')), request_key uuid not null,
 state text not null check(state in ('PENDING','SUCCEEDED','FAILED')),
 provider_idempotency_key text not null unique default gen_random_uuid()::text,
 amount integer not null check(amount>0), consumed integer not null default 0 check(consumed>=0), revoke_quantity integer not null default 0 check(revoke_quantity>=0),
 reason text not null check(reason in ('PURCHASE','GENERAL_REFUND')),
 error_code text check(error_code in ('PROVIDER_REJECTED','PROVIDER_UNAVAILABLE','OUTCOME_UNKNOWN')),
 created_at timestamptz not null default clock_timestamp(), completed_at timestamptz,
 unique(order_id,kind,request_key)
);
create unique index payment_one_pending_operation on public.payment_operations(order_id) where state='PENDING';
create unique index payment_one_confirm on public.payment_operations(order_id) where kind='CONFIRM';
create unique index payment_one_cancel_success on public.payment_operations(order_id) where kind='CANCEL' and state='SUCCEEDED';
create table public.payment_events(
 id bigint generated always as identity primary key,order_id uuid not null references public.payment_orders(id) on delete restrict,
 operation_id uuid references public.payment_operations(id) on delete restrict,
 event text not null check(event in ('CREATED','CONFIRM_STARTED','CONFIRMED','CANCEL_STARTED','CANCELLED','UNKNOWN','REJECTED')),
 created_at timestamptz not null default clock_timestamp()
);
create index payment_owner_history on public.payment_orders(subject_id,created_at,id);
create index payment_reconcile on public.payment_operations(created_at,id) where state='PENDING';
create index payment_events_order on public.payment_events(order_id,id);
alter table public.payment_orders enable row level security;
alter table public.payment_operations enable row level security;
alter table public.payment_events enable row level security;
alter table payment_private.configuration enable row level security;
revoke all on public.payment_orders,public.payment_operations,public.payment_events,payment_private.configuration from public,anon,authenticated,service_role;
revoke all on sequence public.payment_events_id_seq from public,anon,authenticated,service_role;
grant select on payment_private.configuration to essay_executor;
grant select,insert,update on public.payment_orders,public.payment_operations to essay_executor;
grant select,insert on public.payment_events to essay_executor;
grant usage on sequence public.payment_events_id_seq to essay_executor;

create function payment_private.result(p_id uuid) returns jsonb language sql stable security definer set search_path='' as $$
 select jsonb_build_object('dto_version','payment-v1','order_id','ls_'||replace(id::text,'-',''),'id',id,'provider',provider,'mode',mode,'sku',sku,'amount',amount,'quantity',quantity,'currency',currency,'state',state,'grant_state',grant_state,'expires_at',expires_at,'paid_at',paid_at,'credit_expires_at',credit_expires_at) from public.payment_orders where id=p_id
$$;
revoke all on function payment_private.result(uuid) from public,anon,authenticated,service_role;
grant execute on function payment_private.result(uuid) to essay_executor;
-- A pending refund must freeze new consumption authorizations. Existing reservations
-- cause cancel_begin to fail; all operations first lock the canonical account.
create function payment_private.spend_guard() returns trigger language plpgsql security definer set search_path='' as $$
declare purchase public.payment_orders; operation public.payment_operations;
begin
 select * into purchase from public.payment_orders where grant_id=new.grant_id;
 if purchase.state in ('CANCEL_PENDING','PARTIALLY_CANCELLED','CANCELLED') then
  select * into operation from public.payment_operations where order_id=purchase.id and kind='CANCEL' and state='PENDING';
  if purchase.state<>'CANCEL_PENDING' or operation.id is null or new.transaction_type<>'adjustment'
   or new.balance_delta<>-operation.revoke_quantity or new.reserved_delta<>0
   or new.idempotency_key is distinct from 'payment_cancel/'||operation.id::text
   or new.reason_code<>'purchase_cancel_v1' then
   raise sqlstate 'PT409' using message='PURCHASE_REFUND_FENCED';
  end if;
 end if;
 return new;end$$;
revoke all on function payment_private.spend_guard() from public,anon,authenticated,service_role;
create trigger payment_purchase_spend_guard before insert on public.credit_transactions for each row execute function payment_private.spend_guard();

-- Exact bootstrap allowlist: payment_order(jsonb), payment_process(jsonb).
-- Fail rather than modifying an unexpected starting ownership topology.
do $$begin
 if current_user<>'postgres' or pg_has_role('postgres','essay_executor','SET') or has_schema_privilege('essay_executor','public','CREATE') then raise exception 'PAYMENT_BOOTSTRAP_TOPOLOGY';end if;
end$$;
create temporary table payment_bootstrap_before on commit drop as select (select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m) memberships,(select nspacl::text from pg_namespace where nspname='public') acl;
grant essay_executor to postgres with admin false,inherit false,set true granted by postgres;
grant create on schema public to essay_executor;
set role essay_executor;
create function public.payment_order(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid();o public.payment_orders;v_mode text;n integer;a integer;
begin
 if u is null then raise sqlstate 'PT401' using message='UNAUTHENTICATED';end if;
 -- Match account lifecycle lock order; no implicit ADR installation/activation.
 if to_regprocedure('account_private.lock_subject(uuid)') is null then raise sqlstate 'PT503' using message='LIFECYCLE_PREREQUISITE';end if;
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>2048 or p->>'dto_version' is distinct from 'payment-v1' then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 if p->>'action'='create' then
  if p-array['dto_version','action','sku','request_key']<>'{}'::jsonb or nullif(p->>'request_key','') is null then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
  select mode into v_mode from payment_private.configuration where singleton;
  if v_mode is null then raise sqlstate 'PT503' using message='MODE_UNAVAILABLE';end if;
  select quantity,price into n,a from (values('1c',1,4900),('3c',3,11900),('5c',5,17900),('10c',10,29900)) x(sku,quantity,price) where sku=p->>'sku';
  if n is null then raise sqlstate 'PT422' using message='INVALID_SKU';end if;
  insert into public.payment_orders(subject_id,request_key,mode,sku,amount,quantity) values(u,(p->>'request_key')::uuid,v_mode,p->>'sku',a,n) on conflict(subject_id,request_key) do nothing returning * into o;
  if o.id is null then
   select * into o from public.payment_orders where subject_id=u and request_key=(p->>'request_key')::uuid;
   if o.sku is distinct from p->>'sku' then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
  else insert into public.payment_events(order_id,event) values(o.id,'CREATED');end if;
 elsif p->>'action'='get' then
  if p-array['dto_version','action','id']<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
  select * into o from public.payment_orders where id=(p->>'id')::uuid and subject_id=u;
  if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 else raise sqlstate 'PT422' using message='INVALID_ACTION';end if;
 return payment_private.result(o.id);
end$$;
revoke all on function public.payment_order(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_order(jsonb) to authenticated;

-- Trusted gateway only: independently authenticate the buyer and verify Toss by
-- server-held matching TEST credentials before reporting canonical provider facts.
-- Browser/anon/service_role have no EXECUTE. No raw provider payload accepted.
create function public.payment_process(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare allowed_keys text[];o public.payment_orders;op public.payment_operations;account uuid;remaining integer;reserved integer;used integer;amount integer;g uuid;result jsonb;paid timestamptz;action text=p->>'action';k uuid;
begin
 if essay_private.uid() is null then raise sqlstate 'PT401' using message='GATEWAY_IDENTITY_REQUIRED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>4096 or p->>'dto_version' is distinct from 'payment-v1' or p-array['dto_version','action','id','request_key','payment_key','amount','paid_at','operation_id','outcome','error_code']<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 allowed_keys=case action
 when 'confirm_begin' then array['dto_version','action','id','request_key','payment_key','amount']
 when 'confirm_finish' then array['dto_version','action','id','operation_id','payment_key','amount','paid_at']
 when 'cancel_begin' then array['dto_version','action','id','request_key']
 when 'cancel_finish' then array['dto_version','action','id','operation_id','payment_key','amount']
 when 'outcome' then array['dto_version','action','id','operation_id','outcome']
 when 'get' then array['dto_version','action','id'] end;
 if allowed_keys is null or p-allowed_keys<>'{}'::jsonb then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 select * into o from public.payment_orders where id=(p->>'id')::uuid;
 if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 -- Lifecycle -> account -> order -> operation/grant; gateway identity is a
 -- dedicated authenticated operator, not caller-supplied account authority.
 if o.subject_id is not null and to_regprocedure('account_private.lock_subject(uuid)') is not null then perform account_private.lock_subject(o.subject_id);end if;
 select id into account from public.credit_accounts where id=coalesce((select account_id from public.credit_grants where id=o.grant_id),(select id from public.credit_accounts where user_id=o.subject_id)) for update;
 select * into o from public.payment_orders where id=o.id for update;
 if o.provider<>'TOSS' then raise sqlstate 'PT403' using message='PROVIDER_NOT_ENABLED';end if;
 if o.mode is distinct from (select mode from payment_private.configuration where singleton) then raise sqlstate 'PT403' using message='MODE_DISABLED';end if;
 if action='confirm_begin' then
  if nullif(p->>'payment_key','') is null or length(p->>'payment_key')>200 or (p->>'amount')::integer is distinct from o.amount or nullif(p->>'request_key','') is null then raise sqlstate 'PT422' using message='CONFIRM_MISMATCH';end if;
  k=(p->>'request_key')::uuid;
  if o.provider_purchase_id is not null and o.provider_purchase_id is distinct from p->>'payment_key' then raise sqlstate 'PT409' using message='PAYMENT_IDENTITY_CONFLICT';end if;
  select * into op from public.payment_operations where order_id=o.id and kind='CONFIRM';
  if op.id is null then
   if o.state<>'ORDER_CREATED' or clock_timestamp()>=o.expires_at then raise sqlstate 'PT409' using message='ORDER_EXPIRED_OR_CONFLICT';end if;
   if o.subject_id is null or not account_private.allowed(o.subject_id) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
   update public.payment_orders set state='AUTHORIZATION_PENDING',provider_purchase_id=p->>'payment_key' where id=o.id;
   insert into public.payment_operations(order_id,kind,request_key,state,amount,reason) values(o.id,'CONFIRM',k,'PENDING',o.amount,'PURCHASE') returning * into op;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CONFIRM_STARTED');
  elsif op.request_key<>k then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
 elsif action='confirm_finish' then
  select * into op from public.payment_operations where id=(p->>'operation_id')::uuid and order_id=o.id and kind='CONFIRM' for update;
  if op.id is null or p->>'payment_key' is distinct from o.provider_purchase_id or (p->>'amount')::integer is distinct from o.amount then raise sqlstate 'PT422' using message='CONFIRM_MISMATCH';end if;
  paid=(p->>'paid_at')::timestamptz;
  if paid is null or paid<o.created_at-interval '5 minutes' or paid>clock_timestamp()+interval '5 minutes' then raise sqlstate 'PT422' using message='INVALID_PAID_AT';end if;
  if op.state='SUCCEEDED' then
   if paid is distinct from o.paid_at then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
  else
   if op.state<>'PENDING' or o.state<>'AUTHORIZATION_PENDING' then raise sqlstate 'PT409' using message='ORDER_STATE_CONFLICT';end if;
   if o.mode='LIVE' then
    if o.subject_id is null or not account_private.allowed(o.subject_id) then raise sqlstate 'PT409' using message='PAID_REQUIRES_REFUND_RECONCILIATION';end if;
    g=essay_private.credit_post_grant(o.subject_id,o.quantity,'purchase','payment/'||o.id::text,'purchase_v1','system/payment',(paid at time zone 'UTC'+interval '3 months') at time zone 'UTC');
   end if;
   update public.payment_orders set state='PAID',paid_at=paid,credit_expires_at=(paid at time zone 'UTC'+interval '3 months') at time zone 'UTC',grant_id=g,grant_state=case when mode='TEST' then 'TEST_RECORDED' else 'POSTED' end where id=o.id;
   update public.payment_operations set state='SUCCEEDED',completed_at=clock_timestamp(),error_code=null where id=op.id;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CONFIRMED');
  end if;
 elsif action='cancel_begin' then
  if nullif(p->>'request_key','') is null then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
  k=(p->>'request_key')::uuid;
  select * into op from public.payment_operations where order_id=o.id and kind='CANCEL' and request_key=k;
  if op.id is null then
   if o.state<>'PAID' or clock_timestamp()>=o.credit_expires_at then raise sqlstate 'PT409' using message='REFUND_UNAVAILABLE';end if;
   if o.mode='TEST' then used=0;remaining=o.quantity;reserved=0;
   else
    perform 1 from public.credit_grants where id=o.grant_id for update;
    select coalesce(sum(balance_delta),0),coalesce(sum(reserved_delta),0),greatest(0,-coalesce(sum(balance_delta) filter(where transaction_type in ('consume','refund')),0)) into remaining,reserved,used from public.credit_transactions where grant_id=o.grant_id;
   end if;
   amount=greatest(0,o.amount-used*o.deduction_unit);
   if reserved<>0 then raise sqlstate 'PT409' using message='CREDIT_RESERVED';end if;
   if amount=0 then raise sqlstate 'PT409' using message='NO_REFUND_DUE';end if;
   if remaining<0 or used>o.quantity or remaining<>o.quantity-used then raise sqlstate 'PT409' using message='LEDGER_RECONCILIATION_REQUIRED';end if;
   insert into public.payment_operations(order_id,kind,request_key,state,amount,consumed,revoke_quantity,reason) values(o.id,'CANCEL',k,'PENDING',amount,used,remaining,'GENERAL_REFUND') returning * into op;
   update public.payment_orders set state='CANCEL_PENDING' where id=o.id;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CANCEL_STARTED');
  end if;
 elsif action='cancel_finish' then
  select * into op from public.payment_operations where id=(p->>'operation_id')::uuid and order_id=o.id and kind='CANCEL' for update;
  if op.id is null or (p->>'amount')::integer is distinct from op.amount or p->>'payment_key' is distinct from o.provider_purchase_id then raise sqlstate 'PT422' using message='CANCEL_MISMATCH';end if;
  if op.state<>'SUCCEEDED' then
   if op.state<>'PENDING' or o.state<>'CANCEL_PENDING' then raise sqlstate 'PT409' using message='ORDER_STATE_CONFLICT';end if;
   if o.mode='LIVE' and op.revoke_quantity>0 then
    insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code,actor_reference)
    values(account,o.grant_id,'adjustment',-op.revoke_quantity,0,'payment_cancel/'||op.id::text,'purchase_cancel_v1','system/payment');
   end if;
   update public.payment_orders set state=case when op.amount=o.amount then 'CANCELLED' else 'PARTIALLY_CANCELLED' end,grant_state='REVOKED' where id=o.id;
   update public.payment_operations set state='SUCCEEDED',completed_at=clock_timestamp(),error_code=null where id=op.id;
   insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CANCELLED');
  end if;
 elsif action='outcome' then
  select * into op from public.payment_operations where id=(p->>'operation_id')::uuid and order_id=o.id for update;
  if op.id is null or op.state<>'PENDING' or p->>'outcome' not in ('UNKNOWN','REJECTED') or p->>'outcome' is null then raise sqlstate 'PT422' using message='INVALID_OUTCOME';end if;
  if p->>'outcome'='UNKNOWN' then update public.payment_operations set error_code='OUTCOME_UNKNOWN' where id=op.id;
  else
   update public.payment_operations set state='FAILED',error_code='PROVIDER_REJECTED',completed_at=clock_timestamp() where id=op.id;
   update public.payment_orders set state=case when op.kind='CONFIRM' then 'FAILED' else 'PAID' end where id=o.id;
  end if;
  insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,p->>'outcome');
 elsif action='get' then
  select * into op from public.payment_operations where order_id=o.id order by created_at desc,id desc limit 1;
 else raise sqlstate 'PT422' using message='INVALID_ACTION';end if;
 select * into op from public.payment_operations where id=op.id;
 return payment_private.result(o.id)||jsonb_build_object('operation_id',op.id,'operation_state',op.state,'provider_idempotency_key',op.provider_idempotency_key,'operation_amount',op.amount,'consumed',op.consumed,'payment_key',(select provider_purchase_id from public.payment_orders where id=o.id));
end$$;
revoke all on function public.payment_process(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_process(jsonb) to essay_finance;
reset role;
revoke create on schema public from essay_executor;
revoke essay_executor from postgres granted by postgres;
do $$begin
 if (select jsonb_agg(to_jsonb(m) order by roleid,member,grantor) from pg_auth_members m) is distinct from (select memberships from payment_bootstrap_before) or (select nspacl::text from pg_namespace where nspname='public') is distinct from (select acl from payment_bootstrap_before) then raise exception 'PAYMENT_BOOTSTRAP_RESTORE';end if;
end$$;
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261003000100','payment_foundation', array['-- consolidated apply of canonical 20261003000100_payment_foundation.sql, sha256=77b460bf2bf437a8d6dd03d78454ece17c6c4143fe50d7f28b6ea30a51509c75']);


-- ========== #31  20261004000100_payment_runtime  (version 20261004000100) ==========
-- Additive read/support boundary. No activation, grant, or second wallet.
begin;
create function public.credit_summary() returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid=essay_private.uid(); result jsonb;
begin
 if u is null then raise sqlstate 'PT401' using message='AUTH_REQUIRED';end if;
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 with grants as (
 select g.id,g.origin,g.expires_at,coalesce(sum(t.balance_delta),0) balance,coalesce(sum(t.reserved_delta),0) reserved,
 exists(select 1 from public.payment_orders o where o.grant_id=g.id and o.state='CANCEL_PENDING') fenced
 from public.credit_accounts a join public.credit_grants g on g.account_id=a.id
 left join public.credit_transactions t on t.grant_id=g.id where a.user_id=u
 group by g.id
 ), spend as(select *,greatest(0,balance-reserved) available from grants where (expires_at is null or expires_at>statement_timestamp()) and not fenced)
 select jsonb_build_object('dto_version','credit-v1','as_of',statement_timestamp(),
 'spendable',coalesce(sum(available),0),'paid',coalesce(sum(available) filter(where origin='purchase'),0),
 'free',coalesce(sum(available) filter(where origin='signup_bonus'),0),
 'other',coalesce(sum(available) filter(where origin not in ('purchase','signup_bonus')),0),
 'reserved',coalesce(sum(reserved),0),'next_expiry',min(expires_at) filter(where available>0)) into result from spend;
 return result;
end$$;
revoke all on function public.credit_summary() from public,anon,authenticated,service_role;
grant execute on function public.credit_summary() to authenticated;

-- Operator identity comes only from fresh server Auth verification and allowlist.
-- Immutable bounded audit: no provider secrets, user learning data or raw payload.
create table payment_private.support_audit(
 id bigint generated always as identity primary key,
 operator_id uuid not null, request_key uuid not null, order_id uuid not null references public.payment_orders(id),
 action text not null check(action in ('inspect','cancel','reconcile')),
 created_at timestamptz not null default clock_timestamp(), unique(operator_id,request_key)
);
alter table payment_private.support_audit enable row level security;
revoke all on payment_private.support_audit from public,anon,authenticated,service_role,essay_finance;
create function public.payment_support(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.payment_orders; a uuid; used integer=0; remaining integer=0; reserved integer=0; audit payment_private.support_audit; result jsonb;
begin
 if essay_private.uid() is null then raise sqlstate 'PT401' using message='GATEWAY_IDENTITY_REQUIRED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>2048 or p->>'dto_version' is distinct from 'payment-v1' or
 p-array['dto_version','action','id','operator_id','request_key']<>'{}'::jsonb or not(p ?& array['action','id','operator_id','request_key']) or
 p->>'action' not in ('inspect','cancel','reconcile') then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 select * into o from public.payment_orders where id=(p->>'id')::uuid;
 if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 if o.subject_id is not null then perform account_private.lock_subject(o.subject_id);end if;
 select id into a from public.credit_accounts where id=coalesce((select account_id from public.credit_grants where id=o.grant_id),(select id from public.credit_accounts where user_id=o.subject_id)) for update;
 select * into o from public.payment_orders where id=o.id for update;
 insert into payment_private.support_audit(operator_id,request_key,order_id,action) values((p->>'operator_id')::uuid,(p->>'request_key')::uuid,o.id,p->>'action') on conflict(operator_id,request_key) do nothing;
 select * into audit from payment_private.support_audit where operator_id=(p->>'operator_id')::uuid and request_key=(p->>'request_key')::uuid;
 if audit.order_id<>o.id or audit.action<>p->>'action' then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
 if o.mode='LIVE' and o.grant_id is not null then
  select coalesce(sum(balance_delta),0),coalesce(sum(reserved_delta),0),greatest(0,coalesce(-sum(balance_delta) filter(where transaction_type in ('consume','refund')),0))
   into remaining,reserved,used from public.credit_transactions where grant_id=o.grant_id;
 else remaining=o.quantity;end if;
 result=payment_private.result(o.id);
 return jsonb_build_object('order',result,'owner_id',o.subject_id,'used',used,'remaining',remaining,'reserved',reserved,
 'refund_amount',greatest(0,o.amount-used*o.deduction_unit),
 'eligible',o.state='PAID' and o.amount-used*o.deduction_unit>0 and o.credit_expires_at>statement_timestamp() and reserved=0 and remaining=o.quantity-used,
 'compensation_required',o.mode='LIVE' and o.state='AUTHORIZATION_PENDING' and o.grant_id is null and (o.subject_id is null or not account_private.allowed(o.subject_id)),
 'reason','GENERAL_REFUND');
end$$;
revoke all on function public.payment_support(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_support(jsonb) to essay_finance;
-- Provider-approved purchase whose account became restricted before grant.
-- Trusted server verifies DONE receipt first; never grant or revive the account.
-- Durable full-refund claim then uses the existing cancel_finish (revoke_quantity=0).
create function public.payment_compensate(p jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.payment_orders; op public.payment_operations; paid timestamptz; a uuid;
begin
 if essay_private.uid() is null then raise sqlstate 'PT401' using message='GATEWAY_IDENTITY_REQUIRED';end if;
 if p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>2048 or p->>'dto_version' is distinct from 'payment-v1' or
 p-array['dto_version','id','payment_key','amount','paid_at','request_key']<>'{}'::jsonb or not(p ?& array['id','payment_key','amount','paid_at','request_key']) then raise sqlstate 'PT422' using message='INVALID_REQUEST';end if;
 select * into o from public.payment_orders where id=(p->>'id')::uuid;
 if o.id is null then raise sqlstate 'PT404' using message='ORDER_NOT_FOUND';end if;
 if o.subject_id is not null then perform account_private.lock_subject(o.subject_id);end if;
 select id into a from public.credit_accounts where user_id=o.subject_id for update;
 select * into o from public.payment_orders where id=o.id for update;
 paid=(p->>'paid_at')::timestamptz;
 if o.provider<>'TOSS' or o.mode<>'LIVE' or o.grant_id is not null or p->>'payment_key' is distinct from o.provider_purchase_id or (p->>'amount')::integer is distinct from o.amount or paid is null or paid<o.created_at-interval '5 minutes' or paid>clock_timestamp()+interval '5 minutes' then raise sqlstate 'PT422' using message='COMPENSATION_MISMATCH';end if;
 select * into op from public.payment_operations where order_id=o.id and kind='CANCEL' and request_key=(p->>'request_key')::uuid;
 if op.id is not null then
  if paid is distinct from o.paid_at then raise sqlstate 'PT409' using message='IDEMPOTENCY_CONFLICT';end if;
  return payment_private.result(o.id);
 end if;
 if o.state<>'AUTHORIZATION_PENDING' or o.grant_state<>'NONE' or (o.subject_id is not null and account_private.allowed(o.subject_id)) then raise sqlstate 'PT409' using message='COMPENSATION_NOT_REQUIRED';end if;
 select * into op from public.payment_operations where order_id=o.id and kind='CONFIRM' and state='PENDING' for update;
 if op.id is null then raise sqlstate 'PT409' using message='PENDING_CONFIRM_REQUIRED';end if;
 update public.payment_operations set state='SUCCEEDED',completed_at=clock_timestamp(),error_code=null where id=op.id;
 insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CONFIRMED');
 insert into public.payment_operations(order_id,kind,request_key,state,amount,consumed,revoke_quantity,reason)
 values(o.id,'CANCEL',(p->>'request_key')::uuid,'PENDING',o.amount,0,0,'GENERAL_REFUND') returning * into op;
 update public.payment_orders set state='CANCEL_PENDING',paid_at=paid,credit_expires_at=(paid at time zone 'UTC'+interval '3 months') at time zone 'UTC' where id=o.id;
 insert into public.payment_events(order_id,operation_id,event) values(o.id,op.id,'CANCEL_STARTED');
 return payment_private.result(o.id);
end$$;
revoke all on function public.payment_compensate(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.payment_compensate(jsonb) to essay_finance;
notify pgrst,'reload schema';
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261004000100','payment_runtime', array['-- consolidated apply of canonical 20261004000100_payment_runtime.sql, sha256=b1613b352ceed6ab300c08c04decf5bb036d019e4318da159b6f3f859f4a6ab3']);


-- ========== #32  20261005000100_account_provider_revocation  (version 20261005000100) ==========
-- APP-RELEASE-BLOCKER-CLOSEOUT-1 — Apple revoke material (additive, worker-only).
--
-- Companion to 20261001000300_account_deletion_lifecycle. Adds a single private,
-- worker-only store for provenance-bound Apple revoke tokens plus two SECURITY DEFINER
-- RPCs, so the deletion worker's PROVIDER phase can revoke Sign in with Apple grants.
-- Dormant until the worker runs; the client never touches this material. Erasure never
-- depends on it (a missing/failed revoke is retained as unknown, never faked).
--
-- NOT APPLIED. Owner staged apply required (after 20261001000300). It does not alter any
-- existing ADR-2 object; it only adds one table, two functions and their grants.

begin;

create table if not exists account_private.provider_revocation_material(
  subject_id uuid primary key references auth.users(id) on delete cascade,
  provider text not null check(provider in ('apple')),
  token text not null,
  token_type text not null check(token_type in ('refresh_token','access_token')),
  captured_at timestamptz not null default clock_timestamp()
);
alter table account_private.provider_revocation_material enable row level security;
revoke all on table account_private.provider_revocation_material from public,anon,authenticated,service_role;

-- Trusted server (worker role) stores a subject's Apple revoke token, captured during a
-- fresh Apple reauthentication. Overwrites any prior token for that subject.
create or replace function public.account_store_apple_revocation(p_subject uuid,p_token text,p_token_type text)
returns void language plpgsql security definer set search_path='' as $$
begin
  if p_subject is null or coalesce(p_token,'')='' or p_token_type not in ('refresh_token','access_token') then
    raise invalid_parameter_value using message='INVALID_PROVIDER_MATERIAL';
  end if;
  insert into account_private.provider_revocation_material(subject_id,provider,token,token_type)
  values(p_subject,'apple',p_token,p_token_type)
  on conflict(subject_id) do update
    set provider='apple',token=excluded.token,token_type=excluded.token_type,captured_at=clock_timestamp();
end;$$;

-- Trusted server (worker role) reads a subject's revoke material for an ERASING request,
-- lease-fenced via the existing ADR-2 fence. NULL when none is stored. The row is removed
-- by the auth.users FK cascade once the AUTH phase deletes the subject.
create or replace function public.account_provider_material(p_id uuid,p_token uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.account_deletion_requests; m account_private.provider_revocation_material;
begin
  r=account_private.fenced(p_id,p_token);
  select * into m from account_private.provider_revocation_material where subject_id=r.subject_id;
  if m.subject_id is null then return null; end if;
  return jsonb_build_object('provider',m.provider,'token',m.token,'token_type',m.token_type);
end;$$;

revoke all on function public.account_store_apple_revocation(uuid,text,text) from public,anon,authenticated,service_role;
revoke all on function public.account_provider_material(uuid,uuid) from public,anon,authenticated,service_role;
grant execute on function public.account_store_apple_revocation(uuid,text,text) to account_lifecycle_worker;
grant execute on function public.account_provider_material(uuid,uuid) to account_lifecycle_worker;

commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261005000100','account_provider_revocation', array['-- consolidated apply of canonical 20261005000100_account_provider_revocation.sql, sha256=114f172320b62771e949887fb0541499877807744c31538d1aec8196737c31cc']);


-- ========== #33  20261006000100_math_attempts_cascade_on_profile_delete  (version 20261006000100) ==========
-- Math erasure fix: math_attempts.student_id RESTRICT -> CASCADE so the ADR-2
-- auth.users -> profiles deletion cascade also erases the student's Math data.
alter table public.math_attempts
  drop constraint math_attempts_student_id_fkey,
  add constraint math_attempts_student_id_fkey
    foreign key (student_id) references public.profiles(id) on delete cascade;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261006000100','math_attempts_cascade_on_profile_delete', array['-- consolidated apply of canonical 20261006000100_math_attempts_cascade_on_profile_delete.sql, sha256=faa92d69706675724eb81bdea39d4f2a03d65f05ba33ce2c1dfc01ecf7f2401d']);


-- ========== #34  20261006000200_profiles_intended_major  (version 20261006000200) ==========
-- APP-FIRST-RUN-PERSONALIZATION-1
-- Desired major / interest field. Personalization data, not an application record.
alter table public.profiles
  add column if not exists intended_major text;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261006000200','profiles_intended_major', array['-- consolidated apply of canonical 20261006000200_profiles_intended_major.sql, sha256=0e13f74f080a36cbb4ac1833a7e05d18bc66b9170912d6cbb9b90b665844b062']);


-- ========== #35  20261008000500_target_division_identity  (version 20261008000500) ==========
-- Candidate only. Owner §74 approval required before replacing the old unique constraint.
-- Preserve rows/IDs/nullable legacy year/division and APP insert/delete-by-ID behavior.
begin;
do $$begin
 if not exists(select 1 from pg_constraint where conrelid='public.student_target_universities'::regclass
 and conname='student_target_universities_user_id_university_id_admission_key'
 and pg_get_constraintdef(oid)='UNIQUE NULLS NOT DISTINCT (user_id, university_id, admission_year)') then
 raise exception 'TARGET_UNIQUE_AUTHORITY_DRIFT';end if;
 if exists(select 1 from pg_constraint where confrelid='public.student_target_universities'::regclass and contype='f'
 and confkey=(select conkey from pg_constraint where conrelid='public.student_target_universities'::regclass and conname='student_target_universities_user_id_university_id_admission_key')) then
 raise exception 'TARGET_UNIQUE_HAS_DEPENDENCIES';end if;
 if exists(select 1 from public.student_target_universities where octet_length(intended_division)>1024) then
 raise exception 'TARGET_DIVISION_INDEX_REVIEW_REQUIRED';end if;
end$$;
create unique index student_target_division_identity on public.student_target_universities
 (user_id,university_id,admission_year,(lower(btrim(coalesce(intended_division,''))))) nulls not distinct;
alter table public.student_target_universities drop constraint student_target_universities_user_id_university_id_admission_key;
commit;
-- Rollback only when no university/year has multiple rows. Never delete rows to roll back.

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008000500','target_division_identity', array['-- consolidated apply of canonical 20261008000500_target_division_identity.sql, sha256=469b5def1cd90f7247a970e2bed348a5ab6f0a01cd3a07aa0ebc11b09fafd833']);


-- ========== #36  20261008000600_student_application_foundation  (version 20261008000600) ==========
-- Shared self-reported Application facts, distinct from interests and Essay practice.
-- Additive; no replacement of existing profile/target/payment/deletion functions.
begin;
create schema student_private;
revoke all on schema student_private from public,anon,authenticated;

create table public.student_applications (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles(id) on delete cascade,
 admission_year smallint not null check(admission_year between 1900 and 2200),
 university_id uuid not null references public.universities(id) on delete restrict,
 university_name_snapshot text not null,
 intended_division text not null check(char_length(intended_division) between 1 and 120),
 admission_type text not null check(char_length(admission_type) between 1 and 80),
 admission_name text not null check(char_length(admission_name) between 1 and 120),
 revision integer not null default 1 check(revision>0),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(id,user_id)
);
create index student_applications_owner on public.student_applications(user_id,created_at desc,id);
create table public.student_application_events (
 id uuid primary key default gen_random_uuid(),
 application_id uuid not null,
 user_id uuid not null,
 request_key uuid not null,
 kind text not null check(kind in ('created','details_changed','planned','submitted','stage_pass','accepted','additional_acceptance','rejected','not_registered','registered')),
 occurred_at timestamptz check(occurred_at is null or isfinite(occurred_at)),
 recorded_at timestamptz not null default clock_timestamp(),
 supersedes_event_id uuid,
 -- Server-built snapshot/command for idempotency and historical reconstruction.
 payload jsonb not null,
 unique(user_id,request_key),
 unique(id,application_id,user_id),
 unique(supersedes_event_id),
 foreign key(application_id,user_id) references public.student_applications(id,user_id) on delete cascade,
 foreign key(supersedes_event_id,application_id,user_id) references public.student_application_events(id,application_id,user_id) on delete cascade,
 check(supersedes_event_id is null or supersedes_event_id<>id)
);
create index student_application_events_timeline on public.student_application_events(application_id,recorded_at desc,id desc);
alter table public.student_applications enable row level security;
alter table public.student_application_events enable row level security;
revoke all on public.student_applications,public.student_application_events from public,anon,authenticated;
grant select on public.student_applications,public.student_application_events to authenticated;
create policy application_owner_read on public.student_applications for select to authenticated using(user_id=auth.uid() and public.account_service_allowed());
create policy application_event_owner_read on public.student_application_events for select to authenticated using(user_id=auth.uid() and public.account_service_allowed());

create function public.my_application_save(p_id uuid,p_revision integer,p_year integer,p_university uuid,p_division text,p_admission_type text,p_admission_name text,p_request_key uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); a public.student_applications; old_event public.student_application_events; cmd jsonb; previous jsonb; university_name text;
begin
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise insufficient_privilege; end if;
 if p_request_key is null or p_year is null or p_year not between 1900 and 2200 or p_revision is null or p_revision<0
 or coalesce(char_length(btrim(p_division)),0) not between 1 and 120
 or coalesce(char_length(btrim(p_admission_type)),0) not between 1 and 80
 or coalesce(char_length(btrim(p_admission_name)),0) not between 1 and 120 then raise check_violation using message='INVALID_APPLICATION';end if;
 cmd=jsonb_build_object('id',p_id,'revision',p_revision,'year',p_year,'university',p_university,'division',btrim(p_division),'type',btrim(p_admission_type),'name',btrim(p_admission_name));
 select * into old_event from public.student_application_events where user_id=u and request_key=p_request_key;
 if found then
  if old_event.kind not in ('created','details_changed') or old_event.payload->'command' is distinct from cmd then raise check_violation using message='REQUEST_KEY_REUSED';end if;
  return old_event.application_id;
 end if;
 if p_id is null then
  if p_revision<>0 then raise check_violation;end if;
  select name into university_name from public.universities where id=p_university and is_active;
  if not found then raise check_violation using message='UNIVERSITY_NOT_FOUND';end if;
  insert into public.student_applications(user_id,admission_year,university_id,university_name_snapshot,intended_division,admission_type,admission_name)
   values(u,p_year,p_university,university_name,btrim(p_division),btrim(p_admission_type),btrim(p_admission_name)) returning * into a;
 else
  select * into a from public.student_applications where id=p_id and user_id=u for update;
  if not found then raise insufficient_privilege;end if;
  if a.revision<>p_revision then raise exception 'APPLICATION_CHANGED' using errcode='40001';end if;
  previous=to_jsonb(a)-'user_id';
  -- Preserve the year-specific historical name on edits; resolve only a new identity.
  university_name=a.university_name_snapshot;
  if a.university_id<>p_university then
   select name into university_name from public.universities where id=p_university and is_active;
   if not found then raise check_violation using message='UNIVERSITY_NOT_FOUND';end if;
  end if;
  update public.student_applications set admission_year=p_year,university_id=p_university,university_name_snapshot=university_name,
   intended_division=btrim(p_division),admission_type=btrim(p_admission_type),admission_name=btrim(p_admission_name),revision=revision+1,updated_at=clock_timestamp()
   where id=p_id and user_id=u returning * into a;
 end if;
 insert into public.student_application_events(application_id,user_id,request_key,kind,payload)
 values(a.id,u,p_request_key,case when p_id is null then 'created' else 'details_changed' end,jsonb_build_object('command',cmd,'before',previous,'after',to_jsonb(a)-'user_id'));
 return a.id;
end$$;

create function public.my_application_event(p_id uuid,p_kind text,p_occurred_at timestamptz,p_supersedes uuid,p_request_key uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare u uuid=auth.uid(); e public.student_application_events; cmd jsonb; result uuid;
begin
 perform account_private.lock_subject(u);
 if not account_private.allowed(u) then raise insufficient_privilege;end if;
 if p_request_key is null or p_kind is null or p_kind not in ('planned','submitted','stage_pass','accepted','additional_acceptance','rejected','not_registered','registered')
 or (p_occurred_at is not null and not isfinite(p_occurred_at)) then raise check_violation;end if;
 perform 1 from public.student_applications where id=p_id and user_id=u for update;
 if not found then raise insufficient_privilege;end if;
 cmd=jsonb_build_object('kind',p_kind,'occurred_at',p_occurred_at,'supersedes',p_supersedes);
 select * into e from public.student_application_events where user_id=u and request_key=p_request_key;
 if found then
  if e.application_id<>p_id or e.payload is distinct from cmd then raise check_violation using message='REQUEST_KEY_REUSED';end if;
  return e.id;
 end if;
 if p_supersedes is not null then
  perform 1 from public.student_application_events old where old.id=p_supersedes and old.application_id=p_id and old.user_id=u
   and old.kind not in ('created','details_changed') and not exists(select 1 from public.student_application_events replacement where replacement.supersedes_event_id=old.id);
  if not found then raise check_violation using message='INVALID_EVENT_CORRECTION';end if;
 end if;
 insert into public.student_application_events(application_id,user_id,request_key,kind,occurred_at,supersedes_event_id,payload)
 values(p_id,u,p_request_key,p_kind,p_occurred_at,p_supersedes,cmd) returning id into result;
 return result;
end$$;

create function public.my_application_delete(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
begin
 perform account_private.lock_subject(auth.uid());
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 delete from public.student_applications where id=p_id and user_id=auth.uid();
 if not found then raise insufficient_privilege;end if;
end$$;

-- Pure private read model, bounded per page. No student answer data.
create function student_private.applications(p_user uuid,p_offset integer default 0) returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('version','applications-v1','offset',p_offset,'limit',25,
 'has_more',exists(select 1 from public.student_applications where user_id=p_user order by created_at desc,id desc offset p_offset+25 limit 1),
 'items',coalesce((select jsonb_agg(to_jsonb(a)-'user_id'||jsonb_build_object('latest_event',
 (select jsonb_build_object('id',e.id,'kind',e.kind,'occurred_at',e.occurred_at,'recorded_at',e.recorded_at)
 from public.student_application_events e where e.application_id=a.id and e.kind not in ('created','details_changed')
 and not exists(select 1 from public.student_application_events replacement where replacement.supersedes_event_id=e.id)
 order by coalesce(e.occurred_at,e.recorded_at) desc,e.recorded_at desc,e.id desc limit 1)) order by a.created_at desc,a.id desc)
 from (select * from public.student_applications where user_id=p_user order by created_at desc,id desc limit 25 offset p_offset) a),'[]'::jsonb))
$$;
create function public.my_applications(p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise check_violation;end if;
 return student_private.applications(auth.uid(),p_offset);
end$$;
create function public.my_application_events(p_id uuid,p_offset integer default 0) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 if p_offset is null or p_offset<0 or p_offset>10000 then raise check_violation;end if;
 if not exists(select 1 from public.student_applications where id=p_id and user_id=auth.uid()) then raise insufficient_privilege;end if;
 return jsonb_build_object('version','application-events-v1','offset',p_offset,'limit',100,
 'has_more',exists(select 1 from public.student_application_events where application_id=p_id order by recorded_at desc,id desc offset p_offset+100 limit 1),
 'items',coalesce((select jsonb_agg(to_jsonb(e)-'user_id'-'request_key' order by e.recorded_at desc,e.id desc)
 from (select * from public.student_application_events where application_id=p_id order by recorded_at desc,id desc limit 100 offset p_offset) e),'[]'::jsonb));
end$$;

revoke all on function student_private.applications(uuid,integer) from public,anon,authenticated;
revoke all on function public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid),public.my_application_event(uuid,text,timestamptz,uuid,uuid),public.my_application_delete(uuid),public.my_applications(integer),public.my_application_events(uuid,integer) from public,anon,authenticated;
grant execute on function public.my_application_save(uuid,integer,integer,uuid,text,text,text,uuid),public.my_application_event(uuid,text,timestamptz,uuid,uuid),public.my_application_delete(uuid),public.my_applications(integer),public.my_application_events(uuid,integer) to authenticated;
commit;
-- Rollback: revoke the five public RPC grants to disable new writes/reads; preserve facts.
-- Do not DROP these tables after real data has been entered. No existing runtime is replaced.

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008000600','student_application_foundation', array['-- consolidated apply of canonical 20261008000600_student_application_foundation.sql, sha256=92a8cfd6a235564609fd171a9ada4a17451d49bb2f3c931083ef1d044e6ba7b5']);


-- ========== #37  20261008000700_shared_study_summary  (version 20261008000700) ==========
-- APP completed Study snapshots -> one shared KST union read model for MY/Admin.
-- No timer writes, profile changes or changes to existing APP functions.
begin;
create function student_private.study_summary(p_user uuid,p_now timestamptz) returns jsonb
language plpgsql stable set search_path='' as $$
declare today date=(p_now at time zone 'Asia/Seoul')::date; first_day timestamptz; last_day timestamptz; n integer; result jsonb;
begin
 first_day=(today-29)::timestamp at time zone 'Asia/Seoul';
 last_day=(today+1)::timestamp at time zone 'Asia/Seoul';
 -- Match APP's bounded 2,000 completed-record contract; never silently truncate totals.
 select count(*) into n from (select 1 from public.study_sessions where user_id=p_user
 and started_at>=first_day-interval '24 hours' and started_at<last_day and ended_at>first_day limit 2001) r;
 if n>2000 then raise exception 'STUDY_HISTORY_LIMIT' using errcode='54000';end if;
 with intervals as (
  select int8range(floor(extract(epoch from s.started_at)*1000)::bigint+(v->>0)::bigint,
   floor(extract(epoch from s.started_at)*1000)::bigint+(v->>1)::bigint,'[)') span
  from public.study_sessions s cross join lateral jsonb_array_elements(s.active_segments) v
  where s.user_id=p_user and s.started_at>=first_day-interval '24 hours' and s.started_at<last_day and s.ended_at>first_day
  and s.include_in_study_total
 ), merged as (select range_agg(span) spans from intervals), bounds as (
  select today-i as bucket_day,
   (extract(epoch from ((today-i)::timestamp at time zone 'Asia/Seoul'))*1000)::bigint lo,
   (extract(epoch from ((today-i+1)::timestamp at time zone 'Asia/Seoul'))*1000)::bigint hi
  from generate_series(0,29) i
 ), totals as (
  select b.bucket_day,coalesce((select sum(greatest(0,least(upper(s),b.hi)-greatest(lower(s),b.lo)))
   from merged cross join lateral unnest(spans) s),0)::bigint ms from bounds b
 ) select jsonb_build_object('version','study-summary-v1','as_of',p_now,'timezone','Asia/Seoul','unit','milliseconds',
 'source','completed_synced_sessions','record_count',n,
 'today_ms',sum(ms) filter(where bucket_day=today),
 'week_ms',sum(ms) filter(where bucket_day>=date_trunc('week',today::timestamp)::date),
 'last30_ms',sum(ms),
 'daily7',jsonb_agg(jsonb_build_object('date',bucket_day,'milliseconds',ms) order by bucket_day) filter(where bucket_day>=today-6)) into result from totals;
 return result;
end$$;
create function public.my_study_summary() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not account_private.allowed(auth.uid()) then raise insufficient_privilege;end if;
 return student_private.study_summary(auth.uid(),statement_timestamp());
end$$;
revoke all on function student_private.study_summary(uuid,timestamptz),public.my_study_summary() from public,anon,authenticated;
grant execute on function public.my_study_summary() to authenticated;
commit;
-- Safe disable: revoke execute on public.my_study_summary() from authenticated.
-- Original APP Study storage and functions remain untouched.

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008000700','shared_study_summary', array['-- consolidated apply of canonical 20261008000700_shared_study_summary.sql, sha256=e5de76ce66a59646f7548618ea0434fca99ec54204a7e2a09ec5daf8be5bfe47']);


-- ========== #38  20261008000800_student360_read_foundation  (version 20261008000800) ==========
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

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008000800','student360_read_foundation', array['-- consolidated apply of canonical 20261008000800_student360_read_foundation.sql, sha256=b56f72b08fde37511fef02133e608f07c1af9e8db488bd2699819a560e8e11f4']);


-- ========== #39  20261008000900_admin_member_directory  (version 20261008000900) ==========
-- Additive directory only. Existing Admin search/detail, financial helpers and
-- Application/Study/Student360 functions stay byte-identical. Target005 excluded.
begin;
-- Small display cache of only referenced schools, resolved from the existing NEIS
-- proxy by an operator-reviewed import. Not a new school identity/master/profile.
create table student_private.school_display_cache (
 office_code text not null check(length(office_code) between 1 and 32),
 school_code text not null check(length(school_code) between 1 and 32),
 school_name text not null check(length(btrim(school_name)) between 1 and 200),
 source text not null check(source='NEIS'),
 resolved_at timestamptz not null,
 primary key(office_code,school_code)
);
alter table student_private.school_display_cache enable row level security;
revoke all on student_private.school_display_cache from public,anon,authenticated,service_role;

-- Public school metadata resolved through existing Production NEIS proxy 2026-10-08.
-- No member identity/count is stored here. New unresolved schools stay explicit.
insert into student_private.school_display_cache values
 ('J10','7530932','진접고등학교','NEIS','2026-10-08T00:00:00Z'),
 ('R10','8750182','순심고등학교','NEIS','2026-10-08T00:00:00Z');

create function public.admin_member_list(
 p_query text default '',p_limit integer default 25,p_offset integer default 0,
 p_sort text default 'newest',p_account_state text default null,
 p_academic_status text default null,p_grade integer default null,
 p_office text default null,p_school text default null,p_school_unset boolean default false
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare q text; qid uuid; result jsonb;
begin
 if not public.admin_operator() or not account_private.allowed(auth.uid()) then
  raise sqlstate '42501' using message='OPERATOR_REQUIRED';
 end if;
 q:=btrim(coalesce(p_query,''));
 if length(q)>254 or p_limit is null or p_limit not between 1 and 50
  or p_offset is null or p_offset<0
  or p_sort is null or p_sort not in ('newest','oldest')
  or (p_account_state is not null and p_account_state not in ('NORMAL','DELETION_PENDING','ERASING','ERASED','CANCELLED'))
  or (p_academic_status is not null and p_academic_status not in ('student','retaker','other','unset'))
  or (p_grade is not null and p_grade not between 1 and 3)
  or ((p_office is null) <> (p_school is null))
  or (p_office is not null and (length(btrim(p_office)) not between 1 and 32 or length(btrim(p_school)) not between 1 and 32))
  or p_school_unset is null or (p_school_unset and p_school is not null)
 then raise sqlstate '22023' using message='INVALID_FILTER'; end if;
 if q ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then qid:=q::uuid; end if;
 with latest_state as (
  select distinct on(subject_id) subject_id,state from public.account_deletion_requests
  where subject_id is not null order by subject_id,requested_at desc,id desc
 ), members as materialized (
  select u.id account_id,u.email::text email,u.created_at,p.display_name,p.academic_status,
   p.grade_level,p.intended_major,p.neis_office_code office_code,p.neis_school_code school_code,
   case when d.state in ('ERASED','ERASING','DELETION_PENDING','CANCELLED') then d.state else 'NORMAL' end account_state
  from auth.users u left join public.profiles p on p.id=u.id
  left join latest_state d on d.subject_id=u.id
 ), filtered as materialized (
  select m.* from members m where
   (q='' or (qid is not null and m.account_id=qid) or (qid is null and
    (strpos(lower(coalesce(m.email,'')),lower(q))>0 or strpos(lower(coalesce(m.display_name,'')),lower(q))>0)))
   and (p_account_state is null or m.account_state=p_account_state)
   and (p_academic_status is null or m.academic_status=p_academic_status or (p_academic_status='unset' and m.academic_status is null))
   and (p_grade is null or m.grade_level=p_grade)
   and (not p_school_unset or m.school_code is null)
   and (p_school is null or (m.school_code=p_school and m.office_code=p_office))
 ), page as (
  select * from filtered order by
   case when p_sort='newest' then created_at end desc,
   case when p_sort='oldest' then created_at end asc,account_id
  limit p_limit offset p_offset
 )
 select jsonb_build_object(
  'version','admin-members-v1','as_of',statement_timestamp(),
  'total',(select count(*) from members),'filtered_total',(select count(*) from filtered),
  'limit',p_limit,'offset',p_offset,
  'items',coalesce((select jsonb_agg(jsonb_build_object(
   'account_id',m.account_id,'email',m.email,'display_name',m.display_name,'created_at',m.created_at,
   'account_state',m.account_state,'academic_status',m.academic_status,'grade_level',m.grade_level,
   'intended_major',m.intended_major,'school_name',c.school_name,
   'school_state',case when m.school_code is null then 'unset' when c.school_name is null then 'unresolved' else 'resolved' end
  ) order by case when p_sort='newest' then m.created_at end desc,case when p_sort='oldest' then m.created_at end asc,m.account_id)
  from page m left join student_private.school_display_cache c on c.office_code=m.office_code and c.school_code=m.school_code),'[]'::jsonb)
 ) into result;
 return result;
end $$;
alter function public.admin_member_list(text,integer,integer,text,text,text,integer,text,text,boolean) owner to postgres;
revoke all on function public.admin_member_list(text,integer,integer,text,text,text,integer,text,text,boolean) from public,anon,authenticated,service_role;
grant execute on function public.admin_member_list(text,integer,integer,text,text,text,integer,text,text,boolean) to authenticated;
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008000900','admin_member_directory', array['-- consolidated apply of canonical 20261008000900_admin_member_directory.sql, sha256=1209d9890f17c40eb8be01ea27d4caa0b7ce579dd332a3d28a3d3b7a0557f70e']);


-- ========== #40  20261008001000_essay_web_runtime_status  (version 20261008001000) ==========
-- Additive read projection only; does not activate providers, change Credit, or open the Math kill switch.
begin;
set local lock_timeout='5s';
set local statement_timeout='15s';
do $$begin
 if current_user<>'postgres' then raise exception 'OWNER_REQUIRED';end if;
 if to_regprocedure('public.essay_web_runtime_status()') is not null then raise exception 'ESSAY_WEB_RUNTIME_COLLISION';end if;
 if to_regclass('math_private.runtime_control') is null or to_regprocedure('math_private.require_active(uuid[])') is null then raise exception 'MATH_ACTIVATION_AUTHORITY_REQUIRED';end if;
end$$;
create function public.essay_web_runtime_status() returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 perform math_private.require_active(array[auth.uid()]);
 return jsonb_build_object('version','essay-web-runtime-v1','math_evaluations_enabled',
   coalesce((select evaluations_enabled from math_private.runtime_control where singleton),false));
end$$;
alter function public.essay_web_runtime_status() owner to postgres;
revoke all on function public.essay_web_runtime_status() from public,anon,service_role;
grant execute on function public.essay_web_runtime_status() to authenticated;
comment on function public.essay_web_runtime_status() is 'Authenticated active-account read of existing runtime kill switch; no content, credentials or student records.';
notify pgrst,'reload schema';
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261008001000','essay_web_runtime_status', array['-- consolidated apply of canonical 20261008001000_essay_web_runtime_status.sql, sha256=cc911a6d7ad90c768b388e52520a7e72c40ebb885b4d862c0e07231b34e49734']);


-- ========== #41  20261009000100_admin_manual_credit_grant  (version 20261009000100) ==========
-- Owner-approved operator grant. Reuses the canonical ledger; no finance JWT,
-- wallet, payment change or direct-table access is introduced.
begin;
create function public.admin_manual_credit_grant(
 p_user uuid, p_email text, p_quantity integer, p_reason text, p_key uuid
) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid := auth.uid(); target_email text; reason text := btrim(p_reason);
begin
 if not public.admin_operator() or not account_private.allowed(actor) then
  raise sqlstate 'PT403' using message='OPERATOR_REQUIRED';
 end if;
 if p_user is null or p_key is null or p_quantity is null or p_quantity not between 1 and 100
 or reason is null or reason !~ '[^[:space:]]' or char_length(reason) not between 1 and 500
 or p_email is null or char_length(btrim(p_email)) not between 1 and 320 then
  raise sqlstate 'PT422' using message='INVALID_GRANT';
 end if;
 select email into target_email from auth.users where id=p_user;
 if target_email is null or lower(btrim(target_email)) <> lower(btrim(p_email)) then
  raise sqlstate 'PT409' using message='TARGET_CONFIRMATION_CHANGED';
 end if;
 -- Fixed non-purchase type, existing nullable expiry contract. Quantity, reason,
 -- operator, target, timestamp and idempotency all live in the canonical ledger.
 return essay_private.credit_post_grant(p_user,p_quantity,'admin_grant',
  'admin_manual/'||p_key::text,'manual_support: '||reason,'operator/'||actor::text,null);
end $$;
alter function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) owner to postgres;
revoke all on function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) from public,anon,service_role;
grant execute on function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) to authenticated;
comment on function public.admin_manual_credit_grant(uuid,text,integer,text,uuid) is
 'Admin-only 1..100 manual support credit; canonical atomic ledger and idempotency; null expiry.';
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261009000100','admin_manual_credit_grant', array['-- consolidated apply of canonical 20261009000100_admin_manual_credit_grant.sql, sha256=6f25a4a97ca0c94e92ee9874fec749df8a43d87dd48f1a5ba2ff41db8cd8b388']);


-- ========== #42  20261009000200_iap_verified_credit  (version 20261009000200) ==========
-- Server verified Production Store purchases only. No wallet/table or payment mutation.
begin;
create function public.iap_post_verified_purchase(p_user uuid,p_platform text,p_product text,p_transaction text,p_purchased_at timestamptz)
returns text language plpgsql security definer set search_path='' as $$
declare quantity integer; reference text; account uuid; existing public.credit_grants; expiry timestamptz;
begin
 if auth.role() is distinct from 'service_role' then raise sqlstate 'PT403' using message='VERIFIER_REQUIRED'; end if;
 quantity=case p_product when 'com.legendstudy.essay.credit1' then 1 when 'com.legendstudy.essay.credit3' then 3 when 'com.legendstudy.essay.credit5' then 5 when 'com.legendstudy.essay.credit10' then 10 else null end;
 if p_user is null or quantity is null or p_platform is null or p_platform not in ('apple','google') or p_transaction is null or char_length(p_transaction) not between 1 and 256 or p_transaction !~ '^[A-Za-z0-9._-]+$' or p_purchased_at is null or not isfinite(p_purchased_at) or p_purchased_at>clock_timestamp()+interval '1 minute' then raise sqlstate 'PT422' using message='INVALID_PURCHASE';end if;
 perform account_private.lock_subject(p_user);
 if not account_private.allowed(p_user) then raise sqlstate 'PT403' using message='ACCOUNT_RESTRICTED';end if;
 reference='iap/'||p_platform||'/'||encode(pg_catalog.sha256(pg_catalog.convert_to(p_transaction,'UTF8')),'hex');
 -- Global receipt lock serializes simultaneous claims from different accounts.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(reference,0));
 expiry=(p_purchased_at at time zone 'UTC'+interval '3 months') at time zone 'UTC';
 select id into account from public.credit_accounts where user_id=p_user;
 select * into existing from public.credit_grants where external_reference=reference;
 if found then
  if existing.account_id is distinct from account or existing.origin<>'purchase' or existing.expires_at is distinct from expiry
   or not exists(select 1 from public.credit_transactions where grant_id=existing.id and transaction_type='purchase' and balance_delta=quantity and reason_code='iap_'||p_platform||'_v1') then
   raise sqlstate 'PT409' using message='RECEIPT_CONFLICT';end if;
  return 'already_processed';
 end if;
 if expiry<=clock_timestamp() then raise sqlstate 'PT422' using message='PURCHASE_EXPIRED';end if;
 perform essay_private.credit_post_grant(p_user,quantity,'purchase',reference,'iap_'||p_platform||'_v1','system/iap',expiry);
 return 'granted';
end$$;
alter function public.iap_post_verified_purchase(uuid,text,text,text,timestamptz) owner to postgres;
revoke all on function public.iap_post_verified_purchase(uuid,text,text,text,timestamptz) from public,anon,authenticated;
grant execute on function public.iap_post_verified_purchase(uuid,text,text,text,timestamptz) to service_role;
commit;

insert into supabase_migrations.schema_migrations(version,name,statements) values('20261009000200','iap_verified_credit', array['-- consolidated apply of canonical 20261009000200_iap_verified_credit.sql, sha256=ff03ee2f928d9bad7b37c388657dc03d95dfb9b3e172b4f1973febdd13a9f849']);


-- ---- POST-FLIGHT: confirm all 42 applied (only reached if every migration above succeeded) ----
do $postflight$
begin
  if (select count(*) from supabase_migrations.schema_migrations) <> 42 then
    raise exception 'POST: expected 42 migrations, found %', (select count(*) from supabase_migrations.schema_migrations);
  end if;
end
$postflight$;
select 'OK: #27-42 applied; schema_migrations now has ' || count(*) || ' rows' as result
from supabase_migrations.schema_migrations;
