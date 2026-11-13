begin read only;
select 'math_problem_sets IDs absent' check_name,(not exists(select 1 from public.math_problem_sets where id=any(array['619124a8-35b5-5fbc-9fd8-0175f0c524a7'::uuid,'cd2d29cb-2020-5bfa-9390-9b28ed495cd4'::uuid,'8fb9920f-4aa3-56be-9fca-bafea75a1423'::uuid,'bf9f20a7-919f-551d-81be-d7687d8152ee'::uuid]))) passed
union all
select 'math_problems IDs absent' check_name,(not exists(select 1 from public.math_problems where id=any(array['f819a53b-c2db-5630-af84-191dd53f9b4b'::uuid,'717d4997-1507-5690-a07f-c28950df6b6c'::uuid,'dba98128-2acc-52c4-aaa9-ce957a5748f5'::uuid,'a39e1ae3-2017-5390-bc6d-2225e23a20e3'::uuid]))) passed
union all
select 'math_subproblems IDs absent' check_name,(not exists(select 1 from public.math_subproblems where id=any(array['86afdfc6-3179-525b-9db2-cc0bf5b7c068'::uuid,'761143c8-67d3-56a4-8da2-6063d560e144'::uuid,'1f5ccb52-641a-5d7c-869a-21007978e885'::uuid,'dd2e938b-4ea0-57cf-88b3-9b6cc867a3c2'::uuid]))) passed
union all
select 'math_source_artifacts IDs absent' check_name,(not exists(select 1 from public.math_source_artifacts where id=any(array['926f31ec-7ea1-57ad-a6d9-f94cadf50aa0'::uuid,'e0d56fba-e908-5895-8ba2-c121ce6788a0'::uuid,'e0f5a8bc-11e6-5259-857a-44f68460c986'::uuid,'bbde739d-437d-5e74-9ccc-9f74d42c9cf0'::uuid,'c14e8a59-af36-59ad-a9b3-34c9db84888a'::uuid,'b7079eeb-82ae-51aa-b38a-1cda4e5693f6'::uuid,'a65df94a-e492-5a9c-a2f4-f4f5c7f9951c'::uuid,'d677119d-af2f-5afd-9941-6524b79b5844'::uuid,'508aeefe-a4d5-5166-baee-97ed64725be3'::uuid,'60981aa6-d6a0-5a92-872a-afb8379592e4'::uuid,'33fa9a5f-fc2f-5faa-b9fe-055ff105fe2a'::uuid,'7980991a-79e2-55fb-ade4-98117196a2bb'::uuid,'b74845f6-e9a7-528c-a72b-411b78f0ac65'::uuid,'a3fcc17d-6ef5-58bd-ad50-020bc462cd42'::uuid,'6fa1fcb3-6557-5b9a-97a3-81f71bee1cad'::uuid,'1844be2a-14c7-51e5-8ca4-d9a316deb5a3'::uuid]))) passed
union all
select 'math_evaluation_profiles IDs absent' check_name,(not exists(select 1 from public.math_evaluation_profiles where id=any(array['e75f504a-7ac7-57a1-a002-2fef2d302244'::uuid,'f1be51b7-b6fe-5e93-be5f-342ab4b96e2b'::uuid,'a102ddb6-ab9f-586f-9594-e7c6456cfc74'::uuid,'e6290820-b375-5b3c-abd7-bc4452f63924'::uuid]))) passed
union all
select 'math_scoring_criteria IDs absent' check_name,(not exists(select 1 from public.math_scoring_criteria where id=any(array['ab6e9381-7517-5766-9117-7b9baf1f2c8f'::uuid,'67a0c39b-6095-5fdc-9b38-220a46389598'::uuid,'c15b1b2c-c533-5d40-a1ea-5e53f0a96cca'::uuid,'dcf5b0d1-55b2-58b8-ac3b-9f0183e7c483'::uuid]))) passed
union all
select 'math_canonical_solutions IDs absent' check_name,(not exists(select 1 from public.math_canonical_solutions where id=any(array['e097988d-0b24-5a79-acc9-4516b7a9fbe6'::uuid,'2a9dca76-052c-5d9c-a1be-dfe01ff4c92b'::uuid,'5f70347f-cde3-5f30-a67f-6ad3ae9fce38'::uuid,'f0d18c5b-9b74-57b1-b08f-3dc0323013ac'::uuid]))) passed
union all
select 'math_canonical_solution_steps IDs absent' check_name,(not exists(select 1 from public.math_canonical_solution_steps where id=any(array['04436a9f-b35b-5222-a2f7-b4c5a709ef6f'::uuid,'cfac1cb5-86e3-5f1e-bcbb-359a1bea5cbb'::uuid,'02e2da9a-b828-5403-b3fd-eaa89433a88d'::uuid,'6476f548-779a-5791-87bf-1f6ab3bbf167'::uuid,'f500c360-2ab3-58ef-aa28-dc48657ade0d'::uuid,'add09ce2-a2fd-580f-9494-bc991effe299'::uuid]))) passed
union all
select 'Worker rows absent' check_name,(not exists(select 1 from math_private.task20_hanyang_source_pages where question_id=any(array['8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5'::uuid,'c6b54603-e483-5a5d-b4c3-d4044b40a0d2'::uuid,'f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d'::uuid,'f7733560-15d9-530e-aaae-6d04da444d51'::uuid]))) passed
union all
select 'question binding absent' check_name,(not exists(select 1 from public.math_subproblems where essay_question_id=any(array['8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5'::uuid,'c6b54603-e483-5a5d-b4c3-d4044b40a0d2'::uuid,'f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d'::uuid,'f7733560-15d9-530e-aaae-6d04da444d51'::uuid]))) passed
union all
select 'Worker implementation unchanged' check_name,(md5(pg_get_functiondef('math_private.hanyang_worker_references(jsonb)'::regprocedure))='54acd2a1914f360e6ecd62e39acc8222') passed
union all
select 'old public catalog exact count' check_name,(jsonb_array_length(math_private.release_catalog(null))=432) passed
union all
select 'math_private.evaluation_admission() unchanged' check_name,(md5(pg_get_functiondef('math_private.evaluation_admission()'::regprocedure))='7b4641e14f2682ca527d59a4a1f3b0e7') passed
union all
select 'math_private.release_catalog(uuid) unchanged' check_name,(md5(pg_get_functiondef('math_private.release_catalog(uuid)'::regprocedure))='3cd913d0d558c14ce0363f9a35b2f2c2') passed
union all
select 'f7733560-15d9-530e-aaae-6d04da444d51 existing Registry exact' check_name,(exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id='f7733560-15d9-530e-aaae-6d04da444d51' and e.id='c47c6ed4-a3fc-5758-b773-9d7ce4762725' and q.question_key='source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:1' and e.admission_year=2022 and e.exam_kind='mock' and e.university_id='b401cc24-dd17-575e-8ac6-0fd8c9c8405d')) passed
union all
select 'f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d existing Registry exact' check_name,(exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id='f1ae8fd9-d4cb-5fb5-944b-9283e77cd59d' and e.id='c47c6ed4-a3fc-5758-b773-9d7ce4762725' and q.question_key='source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:2' and e.admission_year=2022 and e.exam_kind='mock' and e.university_id='b401cc24-dd17-575e-8ac6-0fd8c9c8405d')) passed
union all
select '8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5 existing Registry exact' check_name,(exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id='8d2b2a5b-38e1-5c2a-a7c4-92396a2eeeb5' and e.id='c47c6ed4-a3fc-5758-b773-9d7ce4762725' and q.question_key='source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:3' and e.admission_year=2022 and e.exam_kind='mock' and e.university_id='b401cc24-dd17-575e-8ac6-0fd8c9c8405d')) passed
union all
select 'c6b54603-e483-5a5d-b4c3-d4044b40a0d2 existing Registry exact' check_name,(exists(select 1 from public.essay_questions q join public.essay_exams e on e.id=q.essay_exam_id where q.id='c6b54603-e483-5a5d-b4c3-d4044b40a0d2' and e.id='c47c6ed4-a3fc-5758-b773-9d7ce4762725' and q.question_key='source:a31bdaa7716d4150af88cd0cbd85f34745dd283f5c0b072b26f0f5c0b007f5b7:4' and e.admission_year=2022 and e.exam_kind='mock' and e.university_id='b401cc24-dd17-575e-8ac6-0fd8c9c8405d')) passed;
commit;
