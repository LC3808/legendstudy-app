-- REVIEW ONLY. Close approved WEB release scope first. No DELETE, DROP or global ACL change.
begin;
set local lock_timeout='5s';
do $guard$ begin
 if md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure)) <> '54acd2a1914f360e6ecd62e39acc8222' then raise exception 'WORKER_DEFINITION_DRIFT'; end if;
 if has_table_privilege('anon','math_private.task20_hanyang_source_pages','SELECT') or has_table_privilege('authenticated','math_private.task20_hanyang_source_pages','SELECT') then raise exception 'PRIVATE_SOURCE_ACL_DRIFT'; end if;
end $guard$;
update public.math_problem_sets set state='RETIRED' where id in ('aefe7825-c853-52e6-984f-9be765ca0c6b','9854067d-321b-5bf7-a9d1-cc92ba18c8e2','663bee71-ed6e-5612-8560-8cd6be8b493b') and state in ('DRAFT','ACTIVE');
update public.math_problems set state='RETIRED' where id in ('63f360d7-b85f-57b7-ad60-cb1660f415c4','a39a896a-4910-5110-a753-ec6a9350c595','5944a864-940e-5267-be8d-1a0c35d83522') and state in ('DRAFT','ACTIVE');
update public.math_evaluation_profiles set state='RETIRED' where id in ('bcac9c02-5f6b-5fdf-8f1e-7efda9cf44b3','c9c543fa-6c73-519e-8e25-bb347041e679','b30d7b4c-4b0d-5753-b22b-478bb54be15f') and state in ('DRAFT','ACTIVE');
update public.math_canonical_solutions set state='RETIRED' where id in ('5c734ec9-7537-55ce-9cb1-fb29534e64ca','29efbd33-3f14-5b10-b88d-42069a8037e1','bacc4e90-3f5c-5281-bd0f-b9bb769dc7ab') and state in ('DRAFT','ACTIVE');
-- Candidate sources, Registry, attempts, evaluations and credit history are retained.
commit;
