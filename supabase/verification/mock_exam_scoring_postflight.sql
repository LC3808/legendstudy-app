-- READ ONLY: run after the exact migration, same LegendStudy project.
-- Expected: five RLS tables, six policies, twelve functions, seven triggers,
-- one security_invoker view; no new rows. Compare baseline digests to preflight.
begin transaction read only;
set local timezone='UTC';
select table_name,column_name,data_type,is_nullable,is_generated,generation_expression
 from information_schema.columns where table_schema='public' and table_name in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by table_name,ordinal_position;
select c.relname,c.relrowsecurity,c.relforcerowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relname in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by c.relname;
select conrelid::regclass,conname,convalidated,pg_get_constraintdef(oid) from pg_constraint
 where conrelid in (select oid from pg_class where relnamespace='public'::regnamespace and relname in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers'))
 or (conrelid='public.study_sessions'::regclass and conname='study_sessions_id_owner') order by conrelid,conname;
select tablename,indexname,indexdef from pg_indexes where schemaname='public'
 and (tablename in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') or indexname='study_sessions_id_owner') order by tablename,indexname;
select tablename,policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' and tablename in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by tablename,policyname;
select p.oid::regprocedure,p.provolatile,p.prosecdef,p.proconfig,pg_get_userbyid(p.proowner) as owner,
 has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
 has_function_privilege('authenticated',p.oid,'EXECUTE') as auth_execute,
 has_function_privilege('service_role',p.oid,'EXECUTE') as backend_execute
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('scoring_text','scoring_source_url','scoring_cutoffs_valid','scoring_normalize_answers','scoring_mcq5','scoring_question_guard','scoring_publication_guard','scoring_attempt_guard','scoring_answer_guard','scoring_attempt_consistency','fetch_own_mock_attempt','submit_mock_attempt') order by p.proname;
select c.relname,t.tgname,t.tgenabled,t.tgdeferrable,t.tginitdeferred,pg_get_triggerdef(t.oid)
 from pg_trigger t join pg_class c on c.oid=t.tgrelid where not t.tgisinternal and c.relnamespace='public'::regnamespace
 and c.relname in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by c.relname,t.tgname;
select table_name,grantee,privilege_type from information_schema.table_privileges
 where table_schema='public' and table_name in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by 1,2,3;
select table_name,grantee,column_name,privilege_type from information_schema.column_privileges
 where table_schema='public' and table_name in ('answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers') order by 1,2,3,4;
select relname,reloptions,pg_get_viewdef(oid,true) from pg_class where oid='public.mock_exam_scoring_availability'::regclass;
select has_table_privilege('authenticated','public.mock_exam_attempts','INSERT') as must_be_false_insert,
 has_table_privilege('authenticated','public.mock_exam_attempts','UPDATE') as must_be_false_update,
 has_table_privilege('authenticated','public.mock_exam_attempts','DELETE') as must_be_true_delete,
 has_any_column_privilege('anon','public.mock_exam_attempts','SELECT') as must_be_false_anon_personal,
 has_any_column_privilege('authenticated','public.mock_exam_answers','INSERT') as must_be_false_answer_insert;
-- Pure synthetic computation, no INSERT, not a real exam key/cutoff.
select public.scoring_mcq5('[[1,1,2],[2,2,3],[3,3,4]]','[1,5,null]',null,'unavailable') as expected_raw2_max9_correct1_blank1;
select 'answer_key_versions' as relation,count(*) as must_be_zero from public.answer_key_versions
union all
select 'exam_questions' as relation,count(*) as must_be_zero from public.exam_questions
union all
select 'grade_cutoff_versions' as relation,count(*) as must_be_zero from public.grade_cutoff_versions
union all
select 'mock_exam_attempts' as relation,count(*) as must_be_zero from public.mock_exam_attempts
union all
select 'mock_exam_answers' as relation,count(*) as must_be_zero from public.mock_exam_answers;
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
