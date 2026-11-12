-- REVIEW ONLY: Stage 1 DRAFT retirement, no activation/publication. Owner approval required.
begin isolation level repeatable read;
set local lock_timeout='5s';
set local statement_timeout='120s';
select pg_advisory_xact_lock(20261112,53);
do $check$ declare failed text;begin select string_agg(check_name,', ') into failed from (select 'math_problem_sets stage1 DRAFT or RETIRED' check_name,((select count(*) from public.math_problem_sets where id in ('663bee71-ed6e-5612-8560-8cd6be8b493b','9854067d-321b-5bf7-a9d1-cc92ba18c8e2','aefe7825-c853-52e6-984f-9be765ca0c6b'))=3 and not exists(select 1 from public.math_problem_sets where id in ('663bee71-ed6e-5612-8560-8cd6be8b493b','9854067d-321b-5bf7-a9d1-cc92ba18c8e2','aefe7825-c853-52e6-984f-9be765ca0c6b') and state not in ('DRAFT','RETIRED'))) passed
union all
select 'math_problems stage1 DRAFT or RETIRED' check_name,((select count(*) from public.math_problems where id in ('5944a864-940e-5267-be8d-1a0c35d83522','a39a896a-4910-5110-a753-ec6a9350c595','63f360d7-b85f-57b7-ad60-cb1660f415c4'))=3 and not exists(select 1 from public.math_problems where id in ('5944a864-940e-5267-be8d-1a0c35d83522','a39a896a-4910-5110-a753-ec6a9350c595','63f360d7-b85f-57b7-ad60-cb1660f415c4') and state not in ('DRAFT','RETIRED'))) passed
union all
select 'math_evaluation_profiles stage1 DRAFT or RETIRED' check_name,((select count(*) from public.math_evaluation_profiles where id in ('b30d7b4c-4b0d-5753-b22b-478bb54be15f','c9c543fa-6c73-519e-8e25-bb347041e679','bcac9c02-5f6b-5fdf-8f1e-7efda9cf44b3'))=3 and not exists(select 1 from public.math_evaluation_profiles where id in ('b30d7b4c-4b0d-5753-b22b-478bb54be15f','c9c543fa-6c73-519e-8e25-bb347041e679','bcac9c02-5f6b-5fdf-8f1e-7efda9cf44b3') and state not in ('DRAFT','RETIRED'))) passed
union all
select 'math_canonical_solutions stage1 DRAFT or RETIRED' check_name,((select count(*) from public.math_canonical_solutions where id in ('bacc4e90-3f5c-5281-bd0f-b9bb769dc7ab','29efbd33-3f14-5b10-b88d-42069a8037e1','5c734ec9-7537-55ce-9cb1-fb29534e64ca'))=3 and not exists(select 1 from public.math_canonical_solutions where id in ('bacc4e90-3f5c-5281-bd0f-b9bb769dc7ab','29efbd33-3f14-5b10-b88d-42069a8037e1','5c734ec9-7537-55ce-9cb1-fb29534e64ca') and state not in ('DRAFT','RETIRED'))) passed) checks where passed is distinct from true;if failed is not null then raise exception 'ROLLBACK_SCOPE_CHANGED %',failed;end if;end $check$;
create temp table _approval_before on commit drop as select 'public.math_canonical_solution_steps' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solution_steps x where id not in ('e54bd795-9bdb-531d-9a7d-4121883ed615','2576d83f-a357-5f11-a903-8fe2ab9ec370','18e24494-1d45-5574-8bee-64bf9eb596be')
union all
select 'public.math_canonical_solutions' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solutions x where id not in ('bacc4e90-3f5c-5281-bd0f-b9bb769dc7ab','29efbd33-3f14-5b10-b88d-42069a8037e1','5c734ec9-7537-55ce-9cb1-fb29534e64ca')
union all
select 'public.math_evaluation_profiles' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_evaluation_profiles x where id not in ('b30d7b4c-4b0d-5753-b22b-478bb54be15f','c9c543fa-6c73-519e-8e25-bb347041e679','bcac9c02-5f6b-5fdf-8f1e-7efda9cf44b3')
union all
select 'public.math_problem_sets' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problem_sets x where id not in ('663bee71-ed6e-5612-8560-8cd6be8b493b','9854067d-321b-5bf7-a9d1-cc92ba18c8e2','aefe7825-c853-52e6-984f-9be765ca0c6b')
union all
select 'public.math_problems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problems x where id not in ('5944a864-940e-5267-be8d-1a0c35d83522','a39a896a-4910-5110-a753-ec6a9350c595','63f360d7-b85f-57b7-ad60-cb1660f415c4')
union all
select 'public.math_scoring_criteria' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_scoring_criteria x where id not in ('fd2c159c-10ee-54d5-9410-94dd6260083c','6d8bb5af-99c3-5008-aa13-bc9e80f45591','e28e36a4-6b00-5f9c-8e8c-b92c2543eff2')
union all
select 'public.math_source_artifacts' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_source_artifacts x where id not in ('cf8e37af-fd0a-5ff8-89cc-f9b89b52a180','802a0f46-cc95-5120-9b07-8b373b57a79b','213653b5-3b8f-5a8d-847c-01adb9344121','d2d1cb1c-c98e-5ee6-b616-b7c2bde4851c','601990f2-9585-5e8f-97f8-8970d7eef0dd','efd45bd2-e812-5b7f-92c6-5a415d7aec3e','2b3877cd-fdec-57a5-9139-e205a996e087','70aa4997-a540-50cc-b7bb-a08f6ae140c8','e61fdfb1-9213-5d87-86ac-ff9b0050c6ea','f9020fd3-4747-5422-9f8e-7be8c0204779','f0deea3e-3057-5aee-a11d-cc09e6d79d81','fb539117-a12f-5830-a44f-bd9338c6e15d')
union all
select 'public.math_subproblems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_subproblems x where id not in ('65e9cdb8-20c3-5d5f-82a2-884142070d98','98dd8662-3976-5884-9bfc-945dcc19c59b','edb40a2a-9f42-5170-8e8a-ea1c7c696669')
union all
select 'math_private.task20_hanyang_source_pages' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by question_id),'')) digest from math_private.task20_hanyang_source_pages x where question_id not in ('ee907ec5-88f2-5097-83be-9b8c9a03ec93','6c7d310f-d055-595c-8aa5-49d901b19f36','318473c0-46ea-55e7-ab06-53520ea2373f')
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
select 'function definitions/owners/ACL' name,count(*) n,md5(coalesce(string_agg(md5(pg_get_functiondef(p.oid)||p.proowner::text||coalesce(p.proacl::text,'')),'' order by p.oid),'')) digest from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.prokind='f' and n.nspname in ('public','math_private','essay_private','account_private')
union all
select 'RLS policies' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(p)::text),'' order by schemaname,tablename,policyname),'')) digest from pg_policies p
union all
select 'table owners/RLS/ACL' name,count(*) n,md5(coalesce(string_agg(md5(jsonb_build_array(c.oid,c.relowner,c.relrowsecurity,c.relforcerowsecurity,c.relacl)::text),'' order by c.oid),'')) digest from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','math_private','essay_private','account_private') and c.relkind in ('r','p');
update public.math_problem_sets set state='RETIRED' where id in ('663bee71-ed6e-5612-8560-8cd6be8b493b','9854067d-321b-5bf7-a9d1-cc92ba18c8e2','aefe7825-c853-52e6-984f-9be765ca0c6b') and state='DRAFT';
update public.math_problems set state='RETIRED' where id in ('5944a864-940e-5267-be8d-1a0c35d83522','a39a896a-4910-5110-a753-ec6a9350c595','63f360d7-b85f-57b7-ad60-cb1660f415c4') and state='DRAFT';
update public.math_evaluation_profiles set state='RETIRED' where id in ('b30d7b4c-4b0d-5753-b22b-478bb54be15f','c9c543fa-6c73-519e-8e25-bb347041e679','bcac9c02-5f6b-5fdf-8f1e-7efda9cf44b3') and state='DRAFT';
update public.math_canonical_solutions set state='RETIRED' where id in ('bacc4e90-3f5c-5281-bd0f-b9bb769dc7ab','29efbd33-3f14-5b10-b88d-42069a8037e1','5c734ec9-7537-55ce-9cb1-fb29534e64ca') and state='DRAFT';
do $preserve$ begin if exists(select 1 from (select 'public.math_canonical_solution_steps' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solution_steps x where id not in ('e54bd795-9bdb-531d-9a7d-4121883ed615','2576d83f-a357-5f11-a903-8fe2ab9ec370','18e24494-1d45-5574-8bee-64bf9eb596be')
union all
select 'public.math_canonical_solutions' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_canonical_solutions x where id not in ('bacc4e90-3f5c-5281-bd0f-b9bb769dc7ab','29efbd33-3f14-5b10-b88d-42069a8037e1','5c734ec9-7537-55ce-9cb1-fb29534e64ca')
union all
select 'public.math_evaluation_profiles' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_evaluation_profiles x where id not in ('b30d7b4c-4b0d-5753-b22b-478bb54be15f','c9c543fa-6c73-519e-8e25-bb347041e679','bcac9c02-5f6b-5fdf-8f1e-7efda9cf44b3')
union all
select 'public.math_problem_sets' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problem_sets x where id not in ('663bee71-ed6e-5612-8560-8cd6be8b493b','9854067d-321b-5bf7-a9d1-cc92ba18c8e2','aefe7825-c853-52e6-984f-9be765ca0c6b')
union all
select 'public.math_problems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_problems x where id not in ('5944a864-940e-5267-be8d-1a0c35d83522','a39a896a-4910-5110-a753-ec6a9350c595','63f360d7-b85f-57b7-ad60-cb1660f415c4')
union all
select 'public.math_scoring_criteria' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_scoring_criteria x where id not in ('fd2c159c-10ee-54d5-9410-94dd6260083c','6d8bb5af-99c3-5008-aa13-bc9e80f45591','e28e36a4-6b00-5f9c-8e8c-b92c2543eff2')
union all
select 'public.math_source_artifacts' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_source_artifacts x where id not in ('cf8e37af-fd0a-5ff8-89cc-f9b89b52a180','802a0f46-cc95-5120-9b07-8b373b57a79b','213653b5-3b8f-5a8d-847c-01adb9344121','d2d1cb1c-c98e-5ee6-b616-b7c2bde4851c','601990f2-9585-5e8f-97f8-8970d7eef0dd','efd45bd2-e812-5b7f-92c6-5a415d7aec3e','2b3877cd-fdec-57a5-9139-e205a996e087','70aa4997-a540-50cc-b7bb-a08f6ae140c8','e61fdfb1-9213-5d87-86ac-ff9b0050c6ea','f9020fd3-4747-5422-9f8e-7be8c0204779','f0deea3e-3057-5aee-a11d-cc09e6d79d81','fb539117-a12f-5830-a44f-bd9338c6e15d')
union all
select 'public.math_subproblems' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by id),'')) digest from public.math_subproblems x where id not in ('65e9cdb8-20c3-5d5f-82a2-884142070d98','98dd8662-3976-5884-9bfc-945dcc19c59b','edb40a2a-9f42-5170-8e8a-ea1c7c696669')
union all
select 'math_private.task20_hanyang_source_pages' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(x)::text),'' order by question_id),'')) digest from math_private.task20_hanyang_source_pages x where question_id not in ('ee907ec5-88f2-5097-83be-9b8c9a03ec93','6c7d310f-d055-595c-8aa5-49d901b19f36','318473c0-46ea-55e7-ab06-53520ea2373f')
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
select 'function definitions/owners/ACL' name,count(*) n,md5(coalesce(string_agg(md5(pg_get_functiondef(p.oid)||p.proowner::text||coalesce(p.proacl::text,'')),'' order by p.oid),'')) digest from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.prokind='f' and n.nspname in ('public','math_private','essay_private','account_private')
union all
select 'RLS policies' name,count(*) n,md5(coalesce(string_agg(md5(to_jsonb(p)::text),'' order by schemaname,tablename,policyname),'')) digest from pg_policies p
union all
select 'table owners/RLS/ACL' name,count(*) n,md5(coalesce(string_agg(md5(jsonb_build_array(c.oid,c.relowner,c.relrowsecurity,c.relforcerowsecurity,c.relacl)::text),'' order by c.oid),'')) digest from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','math_private','essay_private','account_private') and c.relkind in ('r','p')) now_rows full join _approval_before old_rows using(name) where now_rows.n is distinct from old_rows.n or now_rows.digest is distinct from old_rows.digest) then raise exception 'PRESERVATION_DRIFT';end if;end $preserve$;
commit;
