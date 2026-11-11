-- Owner approved 2026-11-12: exact 78 additions, excluding 7 held identities.
-- Catalog rows only; no existing row UPDATE, no user data, no LAB/Registry writes.
begin isolation level repeatable read;
set local lock_timeout = '5s';
set local statement_timeout = '30s';
lock table public.universities in share row exclusive mode;
create temporary table protected_before on commit drop as select 'profiles'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.profiles t
union all
select 'student_applications'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.student_applications t
union all
select 'student_target_universities'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.student_target_universities t
union all
select 'essay_exams'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.essay_exams t
union all
select 'essay_questions'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.essay_questions t;
create temporary table catalog_before on commit drop as select * from public.universities;
create temporary table catalog_candidate(id uuid primary key,slug text unique,name text unique) on commit drop;
insert into catalog_candidate values
('a5935a6e-4ea8-58f5-8834-48f61b58087a'::uuid,'kr-a5935a6e4ea858f5','가톨릭꽃동네대학교'),
('c6e0afa7-50a6-5d3c-bcf7-f2c7f45b906f'::uuid,'kr-c6e0afa750a65d3c','감리교신학대학교'),
('35719d49-35d4-5abc-a8e7-2af3bf8dfcf1'::uuid,'kr-35719d4935d45abc','강남대학교'),
('3f68e863-400c-5cdf-8819-70973dda0a8a'::uuid,'kr-3f68e863400c5cdf','강서대학교'),
('56dfa180-d38a-570c-88c3-368b5d375555'::uuid,'kr-56dfa180d38a570c','건양대학교'),
('30861c68-2a45-57cd-8ee7-249f6336a429'::uuid,'kr-30861c682a4557cd','경인교육대학교'),
('e793a393-8867-5476-ae5b-992dbf38bed7'::uuid,'kr-e793a39388675476','고신대학교'),
('c1e82a8d-642c-5e9d-b0c0-eb6134ebb71b'::uuid,'kr-c1e82a8d642c5e9d','공주교육대학교'),
('d4060d95-64c4-500c-89dd-223e8c4a4ade'::uuid,'kr-d4060d9564c4500c','광신대학교'),
('9c5364f0-fbce-5b1d-abe6-fb47490b6342'::uuid,'kr-9c5364f0fbce5b1d','광주가톨릭대학교'),
('ce9b01dd-6959-5973-a045-5fae80177f8a'::uuid,'kr-ce9b01dd69595973','광주교육대학교'),
('b00f6855-eac3-5cfb-a15c-a0507295a538'::uuid,'kr-b00f6855eac35cfb','국립공주대학교'),
('eea452a3-f248-5df2-a957-f7d9ed944fa1'::uuid,'kr-eea452a3f2485df2','국립군산대학교'),
('88362264-c0d3-538c-b162-4e0bcb52438c'::uuid,'kr-88362264c0d3538c','국립금오공과대학교'),
('20678ccd-0508-5ec1-aeb6-c3496aeb0668'::uuid,'kr-20678ccd05085ec1','국립목포대학교'),
('e899736e-eb7f-59ea-871c-7a27116b6bf3'::uuid,'kr-e899736eeb7f59ea','국립순천대학교'),
('7f83aced-91b0-52b2-9ecc-316beefefdef'::uuid,'kr-7f83aced91b052b2','국립창원대학교'),
('73c63f47-364e-57af-b697-5d629b531460'::uuid,'kr-73c63f47364e57af','국립한국교통대학교'),
('0e2e8189-55ce-5659-b875-b16685030979'::uuid,'kr-0e2e818955ce5659','국립한국해양대학교'),
('63f7deb0-d5f5-541c-94d9-d955a1d0982f'::uuid,'kr-63f7deb0d5f5541c','국립한밭대학교'),
('1c99a50f-dd93-5079-bec2-370b4c8b2625'::uuid,'kr-1c99a50fdd935079','극동대학교'),
('c8ccbce9-2530-5ea4-a4cd-6e98e4818fbd'::uuid,'kr-c8ccbce925305ea4','나사렛대학교'),
('7b631cff-4e98-5e01-9008-638d1791d3cd'::uuid,'kr-7b631cff4e985e01','남부대학교'),
('3c8daec0-cbbf-5389-a310-fd18bd92f99d'::uuid,'kr-3c8daec0cbbf5389','남서울대학교'),
('991fd37c-cabf-58ec-ab4d-a154d3e5fe3f'::uuid,'kr-991fd37ccabf58ec','대구교육대학교'),
('839dfc3d-352e-5729-b5ab-b2978f76acd0'::uuid,'kr-839dfc3d352e5729','대구대학교'),
('24b3e9d8-fe3c-59f0-b673-e584d18213c5'::uuid,'kr-24b3e9d8fe3c59f0','대구예술대학교'),
('07a2b00d-dd61-5fd9-9ccc-2b9b22c3b5ef'::uuid,'kr-07a2b00ddd615fd9','덕성여자대학교'),
('165a9dbc-2a45-5cee-ac9d-1eeffe5b6cd5'::uuid,'kr-165a9dbc2a455cee','루터대학교'),
('ecaa0a39-26e4-5a3f-90ed-7902d2b55956'::uuid,'kr-ecaa0a3926e45a3f','목원대학교'),
('7113ca0e-193f-5ab9-9b6d-4bedc5c2a0fe'::uuid,'kr-7113ca0e193f5ab9','배재대학교'),
('69c0bf0d-c416-5257-8f72-e5062007acba'::uuid,'kr-69c0bf0dc4165257','부산교육대학교'),
('bf2b6373-d508-5587-a627-41dd3a94eca1'::uuid,'kr-bf2b6373d5085587','부산장신대학교'),
('eeed8e73-3d9a-5b57-b7c9-77a574ed0713'::uuid,'kr-eeed8e733d9a5b57','삼육대학교'),
('d45dbe0e-984c-574d-8a3f-f92956fff5ff'::uuid,'kr-d45dbe0e984c574d','상명대학교'),
('cfee98de-ef5a-5058-8669-a0745e50dda3'::uuid,'kr-cfee98deef5a5058','상지대학교'),
('3aa0057c-6cb3-52ba-992a-b6cad357f6ca'::uuid,'kr-3aa0057c6cb352ba','서울교육대학교'),
('ea3108f4-68ba-53ed-81b8-2af6187f0b57'::uuid,'kr-ea3108f468ba53ed','서울신학대학교'),
('314a7f11-a893-5e95-bbcd-1e141a86eba7'::uuid,'kr-314a7f11a8935e95','서울장신대학교'),
('e56f45af-20f5-5b9b-aef1-62c01de722a6'::uuid,'kr-e56f45af20f55b9b','서울한영대학교'),
('286d0564-b9ef-56ef-8df6-faaad10d04fc'::uuid,'kr-286d0564b9ef56ef','선문대학교'),
('666c6c34-b181-5b8e-8c74-b64d6373a1d7'::uuid,'kr-666c6c34b1815b8e','성신여자대학교'),
('112a721a-aa55-5849-941c-642e8bb7861e'::uuid,'kr-112a721aaa555849','세명대학교'),
('593c303a-0780-546e-9532-dfd29dcf4b0d'::uuid,'kr-593c303a0780546e','신라대학교'),
('30be621c-b416-52f8-9dcb-f227089ecab4'::uuid,'kr-30be621cb41652f8','예원예술대학교'),
('a9d593a2-ea24-5413-9899-8a901122ad40'::uuid,'kr-a9d593a2ea245413','용인대학교'),
('46123429-6f37-5688-ba46-b4d3151adf0c'::uuid,'kr-461234296f375688','우석대학교'),
('07c96792-fb47-5e44-9407-cb65c098cdbc'::uuid,'kr-07c96792fb475e44','우송대학교'),
('1d1b78c6-2fd8-5496-8fd5-df58bbce5aea'::uuid,'kr-1d1b78c62fd85496','위덕대학교'),
('5e34b005-6aec-585a-a719-ff78ac97316a'::uuid,'kr-5e34b0056aec585a','유원대학교'),
('194026ec-992a-52b2-92cb-a7e3bd55a360'::uuid,'kr-194026ec992a52b2','인천가톨릭대학교'),
('67f75888-2b11-569a-9b75-47f28ff7014e'::uuid,'kr-67f758882b11569a','장로회신학대학교'),
('ec2b8034-2936-5403-8297-11cdcd79908b'::uuid,'kr-ec2b803429365403','전주교육대학교'),
('48f1dc2c-3c5b-5a5c-a480-c2b1b2672c9a'::uuid,'kr-48f1dc2c3c5b5a5c','전주대학교'),
('c5337ec2-e3a6-5d3e-b815-dfdcb45c6d09'::uuid,'kr-c5337ec2e3a65d3e','중부대학교'),
('dd5e9eed-04a0-59fa-85d4-56384f25eff4'::uuid,'kr-dd5e9eed04a059fa','중원대학교'),
('e4eba5ae-bd18-585a-a8f2-dac786aff1d0'::uuid,'kr-e4eba5aebd18585a','진주교육대학교'),
('21b2d0b3-89d8-57a4-bb00-8b499c6a6efe'::uuid,'kr-21b2d0b389d857a4','청운대학교'),
('6a6737d0-a39b-5517-acca-6dab29b463f1'::uuid,'kr-6a6737d0a39b5517','청주교육대학교'),
('5ff1b07c-7a44-550b-baff-fcabbaa7d533'::uuid,'kr-5ff1b07c7a44550b','총신대학교'),
('b6f76080-7068-5b34-afdd-dd8d2edae666'::uuid,'kr-b6f7608070685b34','추계예술대학교'),
('d0e5f7b0-afff-598a-8ba4-fe50554276a0'::uuid,'kr-d0e5f7b0afff598a','춘천교육대학교'),
('3973ad34-3ffd-56e7-8c8a-e7869949d34d'::uuid,'kr-3973ad343ffd56e7','칼빈대학교'),
('ab774189-2570-54c7-8ed3-26665fc24bae'::uuid,'kr-ab774189257054c7','평택대학교'),
('811ba69e-b016-5a0f-bb67-6429cb682b88'::uuid,'kr-811ba69eb0165a0f','한경국립대학교'),
('d8c6085f-eb45-5d6e-82f9-e5033d82963e'::uuid,'knue','한국교원대학교'),
('9edd981f-362b-55b1-bedf-912197cd19d4'::uuid,'kr-9edd981f362b55b1','한국기술교육대학교'),
('abf5f0cc-23af-531b-8dbd-f9ba055b7d14'::uuid,'kr-abf5f0cc23af531b','한국성서대학교'),
('2068064d-cbe9-537c-bd6a-9153ff0358fa'::uuid,'kr-2068064dcbe9537c','한국체육대학교'),
('e18cddd5-df2d-5b86-88c2-754171e96cf5'::uuid,'kr-e18cddd5df2d5b86','한국침례신학대학교'),
('78415995-fe0b-5a4a-bfc0-cca9503b1924'::uuid,'kr-78415995fe0b5a4a','한남대학교'),
('4b0b7917-88b0-5922-8b0e-9ffd2cdb0e9a'::uuid,'kr-4b0b791788b05922','한동대학교'),
('f8391837-4911-5df3-9aa7-0dd29732d057'::uuid,'kr-f839183749115df3','한라대학교'),
('d616c8f6-2de7-58ea-b41a-97637786f9e2'::uuid,'kr-d616c8f62de758ea','한세대학교'),
('05e259b9-3b53-5054-b618-bbd078e6cef8'::uuid,'kr-05e259b93b535054','한일장신대학교'),
('ec1325bf-bf08-51a1-ab9b-fc893e28a0d5'::uuid,'kr-ec1325bfbf0851a1','협성대학교'),
('4ad2cdb0-3c87-5dab-a6b1-68896caf1aba'::uuid,'kr-4ad2cdb03c875dab','한국에너지공과대학교'),
('212f1633-c0e4-579b-b884-edef1044f4bd'::uuid,'kr-212f1633c0e4579b','한국예술종합학교');
-- Fail closed on identity collision, including renamed/active/inactive existing rows.
do $$ begin
 if exists(select 1 from catalog_candidate c join public.universities u
 on u.id=c.id or u.slug=c.slug or regexp_replace(u.name,'^국립','')=regexp_replace(c.name,'^국립','')
 where (u.id,u.slug,u.name) is distinct from (c.id,c.slug,c.name)) then
 raise exception 'CATALOG_IDENTITY_COLLISION_REVIEW_REQUIRED'; end if;
end $$;
insert into public.universities(id,slug,name,is_active)
select c.id,c.slug,c.name,true from catalog_candidate c
where not exists(select 1 from public.universities u where u.id=c.id);
-- Existing records (including inactive universities) must stay byte-equivalent.
do $$ begin
 if exists(select * from catalog_before except select * from public.universities) then
 raise exception 'EXISTING_CATALOG_CHANGED'; end if;
 if exists(select 1 from public.essay_exams e join catalog_candidate c on c.id=e.university_id) then
 raise exception 'UNEXPECTED_LAB_LINK'; end if;
end $$;
create temporary table protected_after on commit drop as select 'profiles'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.profiles t
union all
select 'student_applications'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.student_applications t
union all
select 'student_target_universities'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.student_target_universities t
union all
select 'essay_exams'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.essay_exams t
union all
select 'essay_questions'::text as table_name,count(*) as rows,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' order by md5(to_jsonb(t)::text)),'')) as digest from public.essay_questions t;
do $$ begin
 if (select count(*) from catalog_candidate) <> 78 or (select count(*) from catalog_before) <> 53 or (select count(*) from public.universities) <> 131 or (select count(*) from public.universities where is_active) <> 128 then raise exception 'UNEXPECTED_COUNTS'; end if;
 if exists(select * from protected_before except select * from protected_after) then raise exception 'PROTECTED_DATA_CHANGED'; end if;
end $$;
select jsonb_build_object('before',53,'added',78,'after',(select count(*) from public.universities),'active',(select count(*) from public.universities where is_active),'existing_rows_unchanged',not exists(select * from catalog_before except select * from public.universities),'protected_tables',(select jsonb_agg(to_jsonb(p)) from protected_after p),'new_essay_links',(select count(*) from public.essay_exams e join catalog_candidate c on c.id=e.university_id)) as receipt;
commit;
