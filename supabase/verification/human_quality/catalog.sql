-- Owner read-only pre/postflight. No student, reviewer or note rows selected.
begin read only;
select version,name from supabase_migrations.schema_migrations order by version;
select c.relname,c.relowner::regrole as owner,c.relrowsecurity,c.relforcerowsecurity,c.relacl,
 (select count(*) from pg_policy p where p.polrelid=c.oid) as policy_count
from pg_class c where c.relnamespace='public'::regnamespace
 and c.relname in ('human_quality_judgments','human_quality_findings','quality_operators') order by c.relname;
select c.relname,a.attname,format_type(a.atttypid,a.atttypmod) as type,a.attnotnull
from pg_class c join pg_attribute a on a.attrelid=c.oid
where c.relnamespace='public'::regnamespace and c.relname in ('human_quality_judgments','human_quality_findings')
 and a.attnum>0 and not a.attisdropped order by c.relname,a.attnum;
select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) as signature,
 p.proowner::regrole as owner,p.prosecdef,p.proconfig,p.proacl,md5(pg_get_functiondef(p.oid)) as definition_md5
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname in ('ql_submit_human_judgment','ql_review_state','ql_list_human_judgments','is_quality_operator','ql_list_cases','ql_case_detail'))
 or (n.nspname='essay_private' and p.proname in ('hq_rubric_valid','hq_finding_valid','hq_immutable','hq_projection')) order by n.nspname,p.proname;
select conname,pg_get_constraintdef(oid) from pg_constraint where conrelid in
 (to_regclass('public.human_quality_judgments'),to_regclass('public.human_quality_findings')) order by conname;
select indexname,indexdef from pg_indexes where schemaname='public' and tablename in ('human_quality_judgments','human_quality_findings') order by indexname;
-- Compare these pre-existing objects exactly before/after. New FK RI triggers are expected;
-- existing definitions, policies, table/function ACL and user triggers must not change.
select c.relname,c.relrowsecurity,c.relforcerowsecurity,c.relowner::regrole,c.relacl
from pg_class c where c.relnamespace='public'::regnamespace and c.relkind='r'
 and c.relname not in ('human_quality_judgments','human_quality_findings') order by c.relname;
select tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public' and tablename not in ('human_quality_judgments','human_quality_findings') order by tablename,policyname;
select n.nspname,p.proname,pg_get_function_identity_arguments(p.oid),p.proowner::regrole,p.proacl,p.proconfig,md5(pg_get_functiondef(p.oid))
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname in ('public','essay_private') and p.prokind='f'
 and p.proname not in ('ql_submit_human_judgment','ql_review_state','ql_list_human_judgments','hq_rubric_valid','hq_finding_valid','hq_immutable','hq_projection')
order by n.nspname,p.proname,pg_get_function_identity_arguments(p.oid);
rollback;
