-- REVIEW ONLY. Close approved WEB release scope first. No DELETE, DROP or global ACL change.
begin;
set local lock_timeout='5s';
do $guard$ begin
 if md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure)) <> '54acd2a1914f360e6ecd62e39acc8222' then raise exception 'WORKER_DEFINITION_DRIFT'; end if;
 if has_table_privilege('anon','math_private.task20_hanyang_source_pages','SELECT') or has_table_privilege('authenticated','math_private.task20_hanyang_source_pages','SELECT') then raise exception 'PRIVATE_SOURCE_ACL_DRIFT'; end if;
end $guard$;
update public.math_problem_sets set state='RETIRED' where id in ('020f9898-20b3-5c65-86cf-7837ad949f53','daf89623-5cbb-5e68-bc7c-3690753d8541','0f204a1c-8971-5282-bf9c-e47c236f1480','4f7f0311-2399-598e-b748-09aa9e062062','c7dcc13c-c0ea-5264-8d7c-43a568ef1c39','c9d05f7e-7516-55fd-8fec-e482bc3d4c73','9700dcaf-9fe9-5f70-929d-fad98a5c2233') and state in ('DRAFT','ACTIVE');
update public.math_problems set state='RETIRED' where id in ('c1cb705e-dbe7-566d-bb85-70245e0aeb49','d2074ce2-da5a-5509-8520-9f3b5ba6bdc4','049234f5-1f8b-5422-8128-c53113c1eb05','281c782c-c8d6-59d1-9ebb-3869848fd7a9','abd49a07-5106-5462-afc0-d1d4e16f012f','c9cea0e8-d31a-55db-a573-d8d7903ed7fc','a45096a3-f667-5e8d-8508-36612bf28830') and state in ('DRAFT','ACTIVE');
update public.math_evaluation_profiles set state='RETIRED' where id in ('0a47f8a6-8d29-529b-b8ab-b523cb216f00','4b191a1d-ae07-5b91-be9c-c57606867072','7c3b0c1b-9ee6-5dd6-8751-9e611a9f6680','75c71472-f51c-5c87-b485-ddd0a220553d','db866e4c-20f9-5d99-8545-59cc31360140','087af77f-7000-58ce-8fdf-535becf4fe80','e4eba427-fe89-58c6-a1bb-ee86fa1ddd69') and state in ('DRAFT','ACTIVE');
update public.math_canonical_solutions set state='RETIRED' where id in ('1569140c-19f9-5bca-8caf-05587ad35e6f','53ab7329-7e48-50d0-94c1-5b4ad0c108b0','a1731fa9-f750-5a4c-8bf7-4fe9dfd8b8e0','28629634-150c-570c-8966-1d3e579abebf','eb4df809-0087-579a-beb7-faf7296e71f1','ae56cc1a-8d1e-5b99-b06d-e11cdcb8fcff','54945ab0-4f1b-501c-9c75-90bdf5f21e7c') and state in ('DRAFT','ACTIVE');
-- Candidate sources, Registry, attempts, evaluations and credit history are retained.
commit;
