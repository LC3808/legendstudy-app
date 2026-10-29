-- Read-only, after separately approved install/grant; no answer bodies or identities returned.
select has_table_privilege('authenticated','essay_private.draft_access','SELECT') as must_be_false,
 has_table_privilege('authenticated','essay_private.draft_access','INSERT') as must_be_false,
 has_function_privilege('authenticated','public.essay_open_session(uuid,uuid)','EXECUTE') as must_be_true;
select q.id,q.is_published from public.essay_questions q
 where q.id in ('f529765c-7d71-5993-bef9-d2e9e926e020','19e67592-af8f-5231-b7d1-e20f91c6a523');
select tablename,policyname,cmd,qual,with_check from pg_policies
 where schemaname='public' and tablename in ('essay_drafts','essay_practice_sessions') order by tablename,policyname;
