begin read only;
select '011b01a5-3714-5aab-821d-b459979df5e2 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('321dfcff-62eb-564d-a40a-b683cf721316')) x where x->>'leaf_id'='17e48ce1-4876-51a4-8c83-dce98de36a6a' and x->>'essay_question_id'='011b01a5-3714-5aab-821d-b459979df5e2')=1) passed
union all
select '011b01a5-3714-5aab-821d-b459979df5e2 profile' check_name,(math_private.resolve_profile('17e48ce1-4876-51a4-8c83-dce98de36a6a')='917f413f-76ec-570e-9053-ef747f21bf70'::uuid) passed
union all
select '011b01a5-3714-5aab-821d-b459979df5e2 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='17e48ce1-4876-51a4-8c83-dce98de36a6a' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '09140d75-579d-5570-bf90-7228c99478a6 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('9288300f-76c8-5321-8c28-2ed4f2587ef3')) x where x->>'leaf_id'='b53a1368-8d6f-5a24-a957-3e3b5074db5b' and x->>'essay_question_id'='09140d75-579d-5570-bf90-7228c99478a6')=1) passed
union all
select '09140d75-579d-5570-bf90-7228c99478a6 profile' check_name,(math_private.resolve_profile('b53a1368-8d6f-5a24-a957-3e3b5074db5b')='9c64b0a5-0c1c-5d8a-951a-c5f369c76ef0'::uuid) passed
union all
select '09140d75-579d-5570-bf90-7228c99478a6 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='b53a1368-8d6f-5a24-a957-3e3b5074db5b' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '1bee0815-02e0-502a-b4ac-5090bfb69212 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('b628acde-5861-5f14-8d35-31da62259867')) x where x->>'leaf_id'='a10ff564-a20a-51f9-a5d3-501a3dc93fe8' and x->>'essay_question_id'='1bee0815-02e0-502a-b4ac-5090bfb69212')=1) passed
union all
select '1bee0815-02e0-502a-b4ac-5090bfb69212 profile' check_name,(math_private.resolve_profile('a10ff564-a20a-51f9-a5d3-501a3dc93fe8')='62ae7992-b9da-58ee-ac43-749388538f72'::uuid) passed
union all
select '1bee0815-02e0-502a-b4ac-5090bfb69212 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='a10ff564-a20a-51f9-a5d3-501a3dc93fe8' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '1dcae52c-5937-5d83-854f-f77c0ede42d4 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('9288300f-76c8-5321-8c28-2ed4f2587ef3')) x where x->>'leaf_id'='6556b977-f2cd-5e01-a3f6-6359d0ad3178' and x->>'essay_question_id'='1dcae52c-5937-5d83-854f-f77c0ede42d4')=1) passed
union all
select '1dcae52c-5937-5d83-854f-f77c0ede42d4 profile' check_name,(math_private.resolve_profile('6556b977-f2cd-5e01-a3f6-6359d0ad3178')='cdf4953d-dbfb-5128-9c60-d7d928e7a289'::uuid) passed
union all
select '1dcae52c-5937-5d83-854f-f77c0ede42d4 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='6556b977-f2cd-5e01-a3f6-6359d0ad3178' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '2837c76a-7fd1-51d3-9d89-567524e6d00a public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('9288300f-76c8-5321-8c28-2ed4f2587ef3')) x where x->>'leaf_id'='a46a15f5-446b-59ba-8c9d-c0f2e39d194c' and x->>'essay_question_id'='2837c76a-7fd1-51d3-9d89-567524e6d00a')=1) passed
union all
select '2837c76a-7fd1-51d3-9d89-567524e6d00a profile' check_name,(math_private.resolve_profile('a46a15f5-446b-59ba-8c9d-c0f2e39d194c')='898c78e5-edc1-598f-ad91-1d10deac380c'::uuid) passed
union all
select '2837c76a-7fd1-51d3-9d89-567524e6d00a Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='a46a15f5-446b-59ba-8c9d-c0f2e39d194c' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '28f34ddb-5de8-5d3d-8ae1-9578bd879174 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('168f2eb0-34be-5015-bf42-db002faa9868')) x where x->>'leaf_id'='a41cab90-213f-59aa-9c92-9b77ae6e95cb' and x->>'essay_question_id'='28f34ddb-5de8-5d3d-8ae1-9578bd879174')=1) passed
union all
select '28f34ddb-5de8-5d3d-8ae1-9578bd879174 profile' check_name,(math_private.resolve_profile('a41cab90-213f-59aa-9c92-9b77ae6e95cb')='32fb3935-9c1b-58b1-9b5e-64fd793fed80'::uuid) passed
union all
select '28f34ddb-5de8-5d3d-8ae1-9578bd879174 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='a41cab90-213f-59aa-9c92-9b77ae6e95cb' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '3df812ba-7ac3-5737-a50e-3db7e6a2c733 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('529fc5f3-79b3-5ff4-8ef2-4a5ce843c7b8')) x where x->>'leaf_id'='b8e11e62-ca37-5e81-a0b3-2eda70136465' and x->>'essay_question_id'='3df812ba-7ac3-5737-a50e-3db7e6a2c733')=1) passed
union all
select '3df812ba-7ac3-5737-a50e-3db7e6a2c733 profile' check_name,(math_private.resolve_profile('b8e11e62-ca37-5e81-a0b3-2eda70136465')='10d76c6e-ad69-5f14-a703-a5409af3e49b'::uuid) passed
union all
select '3df812ba-7ac3-5737-a50e-3db7e6a2c733 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='b8e11e62-ca37-5e81-a0b3-2eda70136465' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '404cfc21-77d6-55da-9ba6-84198a1b3a01 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('529fc5f3-79b3-5ff4-8ef2-4a5ce843c7b8')) x where x->>'leaf_id'='47da9563-5d18-55d1-a541-29796e7d16a0' and x->>'essay_question_id'='404cfc21-77d6-55da-9ba6-84198a1b3a01')=1) passed
union all
select '404cfc21-77d6-55da-9ba6-84198a1b3a01 profile' check_name,(math_private.resolve_profile('47da9563-5d18-55d1-a541-29796e7d16a0')='051f214e-d110-53ec-ab30-fd525ecff423'::uuid) passed
union all
select '404cfc21-77d6-55da-9ba6-84198a1b3a01 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='47da9563-5d18-55d1-a541-29796e7d16a0' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '47d0af04-d836-5c5a-9cfa-4a5c4c986597 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('b628acde-5861-5f14-8d35-31da62259867')) x where x->>'leaf_id'='74b6e267-98ec-5751-88f2-182b33289210' and x->>'essay_question_id'='47d0af04-d836-5c5a-9cfa-4a5c4c986597')=1) passed
union all
select '47d0af04-d836-5c5a-9cfa-4a5c4c986597 profile' check_name,(math_private.resolve_profile('74b6e267-98ec-5751-88f2-182b33289210')='c102d525-4fcd-5472-8f2b-2f4293853be0'::uuid) passed
union all
select '47d0af04-d836-5c5a-9cfa-4a5c4c986597 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='74b6e267-98ec-5751-88f2-182b33289210' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '488c350e-9c3f-5eba-96ef-01960ede29b6 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('168f2eb0-34be-5015-bf42-db002faa9868')) x where x->>'leaf_id'='fb4c1641-7e5e-54bf-bb67-c7901cb094dd' and x->>'essay_question_id'='488c350e-9c3f-5eba-96ef-01960ede29b6')=1) passed
union all
select '488c350e-9c3f-5eba-96ef-01960ede29b6 profile' check_name,(math_private.resolve_profile('fb4c1641-7e5e-54bf-bb67-c7901cb094dd')='d4f7d015-c177-5fba-9582-429816b4bc61'::uuid) passed
union all
select '488c350e-9c3f-5eba-96ef-01960ede29b6 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='fb4c1641-7e5e-54bf-bb67-c7901cb094dd' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '48937249-a641-5425-bffd-acaf096190a4 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('b628acde-5861-5f14-8d35-31da62259867')) x where x->>'leaf_id'='8eeb7450-ddb7-5c66-afcd-cd5793fa8b4b' and x->>'essay_question_id'='48937249-a641-5425-bffd-acaf096190a4')=1) passed
union all
select '48937249-a641-5425-bffd-acaf096190a4 profile' check_name,(math_private.resolve_profile('8eeb7450-ddb7-5c66-afcd-cd5793fa8b4b')='c38d3866-6ac4-5722-9c53-c0af3ac451d8'::uuid) passed
union all
select '48937249-a641-5425-bffd-acaf096190a4 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='8eeb7450-ddb7-5c66-afcd-cd5793fa8b4b' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '4ec222eb-b5be-5a50-b2c6-883fd359b31d public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('321dfcff-62eb-564d-a40a-b683cf721316')) x where x->>'leaf_id'='7a8b78e8-7132-5959-8f85-9dbdf37201ef' and x->>'essay_question_id'='4ec222eb-b5be-5a50-b2c6-883fd359b31d')=1) passed
union all
select '4ec222eb-b5be-5a50-b2c6-883fd359b31d profile' check_name,(math_private.resolve_profile('7a8b78e8-7132-5959-8f85-9dbdf37201ef')='7382a9a4-c283-5f24-a3b3-c94a8cf9199a'::uuid) passed
union all
select '4ec222eb-b5be-5a50-b2c6-883fd359b31d Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='7a8b78e8-7132-5959-8f85-9dbdf37201ef' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '59855528-951c-516d-b4cf-721a086253bb public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('168f2eb0-34be-5015-bf42-db002faa9868')) x where x->>'leaf_id'='f989feba-f014-5c5b-beec-b8cf2cc8fb39' and x->>'essay_question_id'='59855528-951c-516d-b4cf-721a086253bb')=1) passed
union all
select '59855528-951c-516d-b4cf-721a086253bb profile' check_name,(math_private.resolve_profile('f989feba-f014-5c5b-beec-b8cf2cc8fb39')='55cd2e57-7d8f-5fca-aedc-6b0dc36c650f'::uuid) passed
union all
select '59855528-951c-516d-b4cf-721a086253bb Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='f989feba-f014-5c5b-beec-b8cf2cc8fb39' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '707f9eea-3bcc-581e-b50e-4a5fccbdca7e public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('56402c57-6ecc-5e20-96d8-26a5fbeb957b')) x where x->>'leaf_id'='be75562e-e3d7-51f2-b1a7-0a2b8b5467dd' and x->>'essay_question_id'='707f9eea-3bcc-581e-b50e-4a5fccbdca7e')=1) passed
union all
select '707f9eea-3bcc-581e-b50e-4a5fccbdca7e profile' check_name,(math_private.resolve_profile('be75562e-e3d7-51f2-b1a7-0a2b8b5467dd')='abdf1610-4bc5-5f5c-885b-fb76a03e4631'::uuid) passed
union all
select '707f9eea-3bcc-581e-b50e-4a5fccbdca7e Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='be75562e-e3d7-51f2-b1a7-0a2b8b5467dd' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '7c74e44d-375d-5f9c-83c2-60b8fc06977f public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('9288300f-76c8-5321-8c28-2ed4f2587ef3')) x where x->>'leaf_id'='14451865-b2b7-544b-908f-ab1de714690d' and x->>'essay_question_id'='7c74e44d-375d-5f9c-83c2-60b8fc06977f')=1) passed
union all
select '7c74e44d-375d-5f9c-83c2-60b8fc06977f profile' check_name,(math_private.resolve_profile('14451865-b2b7-544b-908f-ab1de714690d')='25754675-0407-5917-b097-7cefa7fa0eba'::uuid) passed
union all
select '7c74e44d-375d-5f9c-83c2-60b8fc06977f Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='14451865-b2b7-544b-908f-ab1de714690d' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '84f6b941-8aae-5663-a6db-ac0c2e17fedf public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('529fc5f3-79b3-5ff4-8ef2-4a5ce843c7b8')) x where x->>'leaf_id'='92b76920-4e1e-5f53-b43c-d8174aaf6ddc' and x->>'essay_question_id'='84f6b941-8aae-5663-a6db-ac0c2e17fedf')=1) passed
union all
select '84f6b941-8aae-5663-a6db-ac0c2e17fedf profile' check_name,(math_private.resolve_profile('92b76920-4e1e-5f53-b43c-d8174aaf6ddc')='1ef109dd-c096-5f74-968e-be02a2b4ab3a'::uuid) passed
union all
select '84f6b941-8aae-5663-a6db-ac0c2e17fedf Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='92b76920-4e1e-5f53-b43c-d8174aaf6ddc' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select '982a78ca-012f-5683-bd31-4f00bdf711e2 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('56402c57-6ecc-5e20-96d8-26a5fbeb957b')) x where x->>'leaf_id'='0784ba96-7248-51eb-84f4-dbb15a5b0723' and x->>'essay_question_id'='982a78ca-012f-5683-bd31-4f00bdf711e2')=1) passed
union all
select '982a78ca-012f-5683-bd31-4f00bdf711e2 profile' check_name,(math_private.resolve_profile('0784ba96-7248-51eb-84f4-dbb15a5b0723')='b9edf3e7-4444-52d3-8203-9c7347ae1b6e'::uuid) passed
union all
select '982a78ca-012f-5683-bd31-4f00bdf711e2 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='0784ba96-7248-51eb-84f4-dbb15a5b0723' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'a42806ac-63c2-5fd5-a383-ca3c5df4468a public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('b628acde-5861-5f14-8d35-31da62259867')) x where x->>'leaf_id'='5cafb19e-fd73-53dc-be81-f00ca2c42584' and x->>'essay_question_id'='a42806ac-63c2-5fd5-a383-ca3c5df4468a')=1) passed
union all
select 'a42806ac-63c2-5fd5-a383-ca3c5df4468a profile' check_name,(math_private.resolve_profile('5cafb19e-fd73-53dc-be81-f00ca2c42584')='ff57c0be-ccb1-5266-9da5-e82ad9667e09'::uuid) passed
union all
select 'a42806ac-63c2-5fd5-a383-ca3c5df4468a Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='5cafb19e-fd73-53dc-be81-f00ca2c42584' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'b3a88056-a671-57ea-9a59-03cf1fb322ff public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('321dfcff-62eb-564d-a40a-b683cf721316')) x where x->>'leaf_id'='eda6f2e5-4246-5127-bf90-9d0a8323d0fb' and x->>'essay_question_id'='b3a88056-a671-57ea-9a59-03cf1fb322ff')=1) passed
union all
select 'b3a88056-a671-57ea-9a59-03cf1fb322ff profile' check_name,(math_private.resolve_profile('eda6f2e5-4246-5127-bf90-9d0a8323d0fb')='4634c3e1-e3e7-5a11-8dde-e8ca3e4616bf'::uuid) passed
union all
select 'b3a88056-a671-57ea-9a59-03cf1fb322ff Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='eda6f2e5-4246-5127-bf90-9d0a8323d0fb' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'beb96180-87b8-5877-94fe-1d8cce9db925 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('168f2eb0-34be-5015-bf42-db002faa9868')) x where x->>'leaf_id'='cc567fe8-6a48-5d55-9f4c-6b850ef11f0c' and x->>'essay_question_id'='beb96180-87b8-5877-94fe-1d8cce9db925')=1) passed
union all
select 'beb96180-87b8-5877-94fe-1d8cce9db925 profile' check_name,(math_private.resolve_profile('cc567fe8-6a48-5d55-9f4c-6b850ef11f0c')='83359d74-d1a5-5d9f-8bb3-68b7e81ac665'::uuid) passed
union all
select 'beb96180-87b8-5877-94fe-1d8cce9db925 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='cc567fe8-6a48-5d55-9f4c-6b850ef11f0c' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'cfa4839f-c292-5a95-b8b0-e408aa1df009 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('56402c57-6ecc-5e20-96d8-26a5fbeb957b')) x where x->>'leaf_id'='7f075986-b0fa-5d57-a428-1548bad12ee4' and x->>'essay_question_id'='cfa4839f-c292-5a95-b8b0-e408aa1df009')=1) passed
union all
select 'cfa4839f-c292-5a95-b8b0-e408aa1df009 profile' check_name,(math_private.resolve_profile('7f075986-b0fa-5d57-a428-1548bad12ee4')='48fb5897-2898-5d4a-b00a-c92df69743f7'::uuid) passed
union all
select 'cfa4839f-c292-5a95-b8b0-e408aa1df009 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='7f075986-b0fa-5d57-a428-1548bad12ee4' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'd685fdad-23c9-56bf-8f68-a372cdf3edfa public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('529fc5f3-79b3-5ff4-8ef2-4a5ce843c7b8')) x where x->>'leaf_id'='54fc60e4-e0e2-5b24-aa15-5ea737140f47' and x->>'essay_question_id'='d685fdad-23c9-56bf-8f68-a372cdf3edfa')=1) passed
union all
select 'd685fdad-23c9-56bf-8f68-a372cdf3edfa profile' check_name,(math_private.resolve_profile('54fc60e4-e0e2-5b24-aa15-5ea737140f47')='0dfe35a7-5716-5166-a0b8-4b1f91082fd5'::uuid) passed
union all
select 'd685fdad-23c9-56bf-8f68-a372cdf3edfa Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='54fc60e4-e0e2-5b24-aa15-5ea737140f47' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'ddae2f2e-bbc6-5769-b779-bd9b997ab202 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('56402c57-6ecc-5e20-96d8-26a5fbeb957b')) x where x->>'leaf_id'='414cbed4-5aab-5989-b725-9649c72cf31c' and x->>'essay_question_id'='ddae2f2e-bbc6-5769-b779-bd9b997ab202')=1) passed
union all
select 'ddae2f2e-bbc6-5769-b779-bd9b997ab202 profile' check_name,(math_private.resolve_profile('414cbed4-5aab-5989-b725-9649c72cf31c')='fdea2420-e28c-5549-ab4e-c4bf99d0dfc7'::uuid) passed
union all
select 'ddae2f2e-bbc6-5769-b779-bd9b997ab202 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='414cbed4-5aab-5989-b725-9649c72cf31c' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed
union all
select 'f8e90b86-1a36-533d-a8c1-9847e1dd4014 public mapping' check_name,((select count(*) from jsonb_array_elements(math_private.release_catalog('321dfcff-62eb-564d-a40a-b683cf721316')) x where x->>'leaf_id'='87df6788-19a6-5fe0-8855-508afe59fb70' and x->>'essay_question_id'='f8e90b86-1a36-533d-a8c1-9847e1dd4014')=1) passed
union all
select 'f8e90b86-1a36-533d-a8c1-9847e1dd4014 profile' check_name,(math_private.resolve_profile('87df6788-19a6-5fe0-8855-508afe59fb70')='5bafe131-a069-5453-ad2d-dd24557eb7d4'::uuid) passed
union all
select 'f8e90b86-1a36-533d-a8c1-9847e1dd4014 Worker evidence' check_name,(exists(select 1 from public.math_subproblems l join public.math_problems pr on pr.id=l.problem_id where l.id='87df6788-19a6-5fe0-8855-508afe59fb70' and jsonb_array_length(math_private.hanyang_worker_references(jsonb_build_object('leaf',to_jsonb(l),'problem',to_jsonb(pr),'sources',(select jsonb_agg(to_jsonb(s)) from public.math_source_artifacts s where s.problem_id=pr.id)))->'official_images')>0)) passed;
commit;
