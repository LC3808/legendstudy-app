-- READ ONLY: confirm Dashboard is LegendStudy / stlhijzpjfgwwdgunlsd.
-- SQL cannot prove the Dashboard project ref; Owner checks it before execution.
-- Expected: PG17+, required parents/roles, no new object collisions, adequate deployer.
begin transaction read only;
set local timezone='UTC';
select current_database(),current_user,version(),current_setting('server_version_num')::integer >= 170000 as pg17_or_newer;
select to_regclass('auth.users') as auth_users,to_regprocedure('auth.uid()') as auth_uid,
 to_regclass('public.exam_subjects') as occurrence_parent,to_regclass('public.study_sessions') as study_parent;
select rolname,rolbypassrls from pg_roles where rolname in ('anon','authenticated','service_role') order by rolname;
select has_schema_privilege(current_user,'public','CREATE') as can_create,
 has_table_privilege(current_user,'auth.users','REFERENCES') as can_reference_users,
 pg_has_role(current_user,(select relowner from pg_class where oid='public.study_sessions'::regclass),'USAGE') as can_alter_study;
-- All rows here must be NULL / following collision queries empty. Stop otherwise.
select name,to_regclass('public.'||name) as must_be_null from unnest(array['answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers','mock_exam_scoring_availability']) name;
select p.oid::regprocedure from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname in ('scoring_text','scoring_source_url','scoring_cutoffs_valid','scoring_normalize_answers','scoring_mcq5','scoring_question_guard','scoring_publication_guard','scoring_attempt_guard','scoring_answer_guard','scoring_attempt_consistency','fetch_own_mock_attempt','submit_mock_attempt');
select conname from pg_constraint where conrelid='public.study_sessions'::regclass and conname='study_sessions_id_owner';
select conrelid::regclass,conname,convalidated,pg_get_constraintdef(oid) from pg_constraint
 where conrelid in ('public.exam_subjects'::regclass,'public.resources'::regclass,'public.study_sessions'::regclass)
 order by conrelid,conname;
-- Compare these row counts/digests exactly before/after; no row contents printed.
select 'source_posts' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.source_posts t
union all
select 'content_items' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.content_items t
union all
select 'exams' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.exams t
union all
select 'subjects' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.subjects t
union all
select 'exam_subjects' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.exam_subjects t
union all
select 'resources' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.resources t
union all
select 'profiles' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.profiles t
union all
select 'bookmarks' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.bookmarks t
union all
select 'recent_views' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.recent_views t
union all
select 'ingestion_quarantine' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.ingestion_quarantine t
union all
select 'study_sessions' as relation, count(*) as row_count, md5(coalesce(string_agg(to_jsonb(t)::text,'' order by to_jsonb(t)::text),'')) as row_digest from public.study_sessions t;
-- Existing constraints remain identical except the new Study composite UNIQUE.
select c.relname,c.relrowsecurity,c.relforcerowsecurity,
 (select md5(coalesce(string_agg(pg_get_constraintdef(k.oid),'|' order by k.conname),''))
  from pg_constraint k where k.conrelid=c.oid and k.conname <> 'study_sessions_id_owner') as constraint_digest,
 (select md5(coalesce(string_agg(concat_ws('|',p.policyname,p.roles,p.cmd,p.qual,p.with_check),'|' order by p.policyname),''))
  from pg_policies p where p.schemaname='public' and p.tablename=c.relname) as policy_digest,
 (select md5(coalesce(string_agg(concat_ws('|',g.grantee,g.privilege_type),'|' order by g.grantee,g.privilege_type),''))
  from information_schema.table_privileges g where g.table_schema='public' and g.table_name=c.relname) as table_grant_digest,
 (select md5(coalesce(string_agg(concat_ws('|',g.grantee,g.column_name,g.privilege_type),'|' order by g.grantee,g.column_name,g.privilege_type),''))
  from information_schema.column_privileges g where g.table_schema='public' and g.table_name=c.relname) as column_grant_digest
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relname in ('source_posts','content_items','exams','subjects','exam_subjects','resources','profiles','bookmarks','recent_views','ingestion_quarantine','study_sessions') order by c.relname;
commit;
