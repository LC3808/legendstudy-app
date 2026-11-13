begin read only;
select 'public.math_problem_sets' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problem_sets x where id <> all(array['73b9832a-9796-5c96-8a2a-451d2e247200'::uuid,'740d7904-4212-5a8d-b671-aadc3aad1c85'::uuid])
union all
select 'public.math_problems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problems x where id <> all(array['3fbbed47-e157-5af9-a28b-2e82b005e68f'::uuid,'7443a1cb-ff84-5950-bc2a-a222c7d6c0ab'::uuid])
union all
select 'public.math_subproblems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_subproblems x where id <> all(array['b5c82f4d-fb81-5d04-b0b1-3af5369379f1'::uuid,'6df6f2da-0744-54f5-83ae-f40ff03d210c'::uuid])
union all
select 'public.math_source_artifacts' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_source_artifacts x where id <> all(array['a78cc498-0453-57b9-abf5-c6a287d0af80'::uuid,'8b342710-0862-52a7-a5d5-fd50cfc0cb9f'::uuid,'f9db9034-d480-5736-86ee-e8668502afc6'::uuid,'ed5929ba-50c6-564f-89e6-08f1804bf890'::uuid,'2a45f638-8312-58f4-8c12-af2a617de116'::uuid,'f0987720-cddc-5fcd-8081-5ec8f42d569c'::uuid,'1336b1b9-21de-5d80-9c7c-f43c6666dcd3'::uuid,'96b1f4dd-24a3-52b0-a6cb-3ea0bb7caffa'::uuid])
union all
select 'public.math_evaluation_profiles' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_evaluation_profiles x where id <> all(array['b624884a-78da-5158-baf9-1873e73b86d2'::uuid,'3b9f9168-ea0e-56a9-a61a-f22fa5e6895c'::uuid])
union all
select 'public.math_scoring_criteria' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_scoring_criteria x where id <> all(array['f2005b8d-f1f0-55af-a1aa-ce1c4bdb5751'::uuid,'b717fdb7-bc8e-5116-8c97-9f76b47d2493'::uuid])
union all
select 'public.math_canonical_solutions' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solutions x where id <> all(array['c040abeb-c3c0-56bf-a0f6-3c77f65b2c23'::uuid,'e7f4a6d0-5d22-5595-bf08-93385a237fe5'::uuid])
union all
select 'public.math_canonical_solution_steps' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solution_steps x where id <> all(array['06280e00-29e2-5484-af98-bd6833b2b824'::uuid,'196c7f72-70e7-5d0e-b27c-de541227ed8f'::uuid,'56497325-8d08-52b0-a669-2510a6180f33'::uuid,'e27b4b76-6bce-5a58-9fcc-ed22b3a3a81f'::uuid,'d8283d0a-379b-57e4-8cbb-387389bee71d'::uuid,'64cd51a7-1cda-574d-b7c3-06b8688c948b'::uuid,'01d69425-4c33-5bee-9db0-35884ceb493f'::uuid])
union all
select 'math_private.task20_hanyang_source_pages' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by question_id),'')) digest from math_private.task20_hanyang_source_pages x where question_id <> all(array['48512d94-959c-5a94-b985-7e1bd005c6b7'::uuid,'74e16370-a1be-57f9-b6c7-b2e035bfbb06'::uuid])
union all
select 'public.universities' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.universities x where true
union all
select 'public.essay_exams' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.essay_exams x where true
union all
select 'public.essay_questions' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.essay_questions x where true
union all
select 'public.essay_attempts' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.essay_attempts x where true
union all
select 'public.essay_evaluations' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.essay_evaluations x where true
union all
select 'public.credit_transactions' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.credit_transactions x where true
union all
select 'public.math_attempts' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_attempts x where true
union all
select 'public.math_evaluations' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_evaluations x where true
union all
select 'function definitions/owners/ACL' name,count(*) n,md5(coalesce(string_agg(md5(pg_get_functiondef(p.oid)||p.proowner::text||coalesce(p.proacl::text,'')),'' order by p.oid),'')) digest from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.oid not in ('math_private.evaluation_admission()'::regprocedure,'math_private.release_catalog(uuid)'::regprocedure) and p.prokind='f' and n.nspname in ('public','math_private','essay_private','account_private')
union all
select 'RLS policies' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(p)::text),'' order by schemaname,tablename,policyname),'')) digest from pg_policies p
union all
select 'table owners/RLS/ACL' name,count(*) n,md5(coalesce(string_agg(md5(jsonb_build_array(c.oid,c.relowner,c.relrowsecurity,c.relforcerowsecurity,c.relacl)::text),'' order by c.oid),'')) digest from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','math_private','essay_private','account_private') and c.relkind in ('r','p')
union all
select 'changed functions identity/ACL' name,count(*) n,md5(string_agg(jsonb_build_array(p.oid,p.proowner,p.proacl)::text,'' order by p.oid)) digest from pg_proc p where p.oid in ('math_private.evaluation_admission()'::regprocedure,'math_private.release_catalog(uuid)'::regprocedure);
commit;
