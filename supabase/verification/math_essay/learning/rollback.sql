begin;
do $$begin if exists(select 1 from public.math_attempts) then raise exception 'EMPTY_MATH_INSTALL_ONLY';end if;end$$;
drop function public.math_learning(jsonb);
drop function math_private.learning_state(uuid);
drop function math_private.learning_eligibility(uuid,timestamptz);
drop index public.math_hint_delivery_history;
drop index public.math_solution_delivery_history;
alter table public.math_solution_exposures drop constraint math_solution_generated_output_fk;
alter table public.math_solution_exposures drop constraint math_solution_exposure_one_binding;
alter table public.math_solution_exposures drop column generated_output_sha256;
alter table public.math_solution_exposures alter column solution_id set not null;
alter table public.math_evaluations drop constraint math_evaluation_output_identity;
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
reset role;
revoke create on schema math_private from math_executor;
revoke math_executor from postgres granted by postgres;
commit;
