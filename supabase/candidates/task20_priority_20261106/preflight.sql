begin read only;
select count(*) as currently_released from jsonb_array_elements(math_private.release_catalog(null));
select id,essay_question_id,problem_id from public.math_subproblems where essay_question_id in ('7c112225-51cc-59d8-a985-6c459a1e0a0a'::uuid,'40290efd-36af-55a9-beb7-8c90bbb04ee4'::uuid,'a7d06546-9d61-5317-afff-e656c25964f7'::uuid,'ed63c506-ee9b-5ce7-967f-a1d53b9feac6'::uuid,'4df1296d-abe4-5499-af35-20ba573fd6ae'::uuid,'101a7dcc-1c05-5c1d-b926-3f5729158f54'::uuid);
select id,essay_exam_id,label from public.essay_questions where id in ('7c112225-51cc-59d8-a985-6c459a1e0a0a'::uuid,'40290efd-36af-55a9-beb7-8c90bbb04ee4'::uuid,'a7d06546-9d61-5317-afff-e656c25964f7'::uuid,'ed63c506-ee9b-5ce7-967f-a1d53b9feac6'::uuid,'4df1296d-abe4-5499-af35-20ba573fd6ae'::uuid,'101a7dcc-1c05-5c1d-b926-3f5729158f54'::uuid);
select md5(pg_get_functiondef('math_private.release_catalog(uuid)'::regprocedure)) as catalog_md5,md5(pg_get_functiondef('math_private.evaluation_admission()'::regprocedure)) as admission_md5;
rollback;
