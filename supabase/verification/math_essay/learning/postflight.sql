-- Read-only exact E object/security inventory; no student rows.
begin read only;
select p.oid::regprocedure as signature,pg_get_userbyid(p.proowner) as owner,p.prosecdef,p.provolatile,p.proconfig,p.proacl
 from pg_proc p where p.oid in (to_regprocedure('public.math_learning(jsonb)'),to_regprocedure('math_private.learning_state(uuid)'),to_regprocedure('math_private.learning_eligibility(uuid,timestamptz)'),to_regprocedure('math_private.validate_output(uuid,jsonb)')) order by 1;
select relname,pg_get_userbyid(relowner),relrowsecurity,relacl from pg_class where oid in ('public.math_solution_exposures'::regclass,'public.math_hint_exposures'::regclass);
select conname,pg_get_constraintdef(oid) from pg_constraint where conname in ('math_evaluation_output_identity','math_solution_exposure_one_binding','math_solution_generated_output_fk');
select indexname,indexdef from pg_indexes where indexname in ('math_hint_delivery_history','math_solution_delivery_history');
select pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option from pg_auth_members where roleid in ('math_executor'::regrole,'math_extraction_worker'::regrole,'math_evaluation_worker'::regrole) order by 1,2,3;
select has_schema_privilege('math_executor','math_private','CREATE') as must_be_false;
commit;
