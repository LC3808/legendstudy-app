begin read only;
select 'public.math_canonical_solution_steps' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solution_steps x where id not in ('fdcf5f33-a019-5b3c-a679-92c5c5d3a7db')
union all
select 'public.math_canonical_solutions' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solutions x where id not in ('8d643a0d-451b-5d2d-b73f-e260337c9043')
union all
select 'public.math_evaluation_profiles' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_evaluation_profiles x where id not in ('4390a320-b8e7-55f9-9187-535ec9c0ed78')
union all
select 'public.math_problem_sets' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problem_sets x where id not in ('718fe647-ed23-57bc-a211-7d531f2155d1')
union all
select 'public.math_problems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problems x where id not in ('9d2042a5-16e3-5727-8152-1e1b3cd7e2ca')
union all
select 'public.math_scoring_criteria' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_scoring_criteria x where id not in ('e1f171e7-6a94-5640-a463-3d46818c5f90','2447a1ba-967c-5234-8ac9-77e09554e142')
union all
select 'public.math_source_artifacts' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_source_artifacts x where id not in ('874506cc-7fe9-5cb8-b78f-dd9faec24912','4d48b1fd-b47d-50ca-9fb2-eaa4b44f7f9d','d599321f-fd51-58b4-a5b9-48e7ac5c4a8b','f2ad6996-3a4b-574b-92ab-0f47fd96deb1')
union all
select 'public.math_subproblems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_subproblems x where id not in ('645d7b6a-2c7a-5a0e-9d34-0eead5c142e5')
union all
select 'math_private.task20_hanyang_source_pages' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by question_id),'')) digest from math_private.task20_hanyang_source_pages x where question_id<>'49ea9aaa-1c46-51e7-b148-a03aef20ae4e'
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
