-- SELECT-ONLY INSPECTION FOR A FUTURE AUTHORIZED TASK. NOT EXECUTED.
-- Run prerequisites before application; remaining catalog checks after application.
select rolname, rolbypassrls, rolsuper, rolinherit from pg_catalog.pg_roles
where rolname in ('anon', 'authenticated', 'service_role');
select current_user as deployer, to_regclass('auth.users') as auth_users,
       to_regprocedure('auth.uid()') as auth_uid,
       case when to_regclass('auth.users') is not null
            then has_table_privilege(current_user, to_regclass('auth.users'), 'REFERENCES') end as auth_users_references;
select p.oid::regprocedure as function_name, p.provolatile
from pg_catalog.pg_proc p where p.oid = to_regprocedure('pg_catalog.make_date(integer,integer,integer)');
-- make_date volatility should be i; parser cannot establish target catalog behavior.

-- Nine tables, RLS enabled. FORCE RLS is false in this draft; owners/BYPASSRLS differ from clients.
select c.relname, c.relowner::regrole as owner, c.relrowsecurity, c.relforcerowsecurity, c.relacl
from pg_catalog.pg_class c join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
  and c.relname in ('source_posts','exams','subjects','exam_subjects','resources',
                   'profiles','bookmarks','recent_views','ingestion_quarantine')
order by c.relname;
-- Fifteen policies; zero policies on source_posts/ingestion_quarantine, no content writes.
select tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_catalog.pg_policies where schemaname = 'public'
  and tablename in ('source_posts','exams','subjects','exam_subjects','resources',
                    'profiles','bookmarks','recent_views','ingestion_quarantine')
order by tablename, policyname;
select grantee, table_name, privilege_type, is_grantable
from information_schema.table_privileges where table_schema = 'public'
  and table_name in ('source_posts','exams','subjects','exam_subjects','resources',
                     'profiles','bookmarks','recent_views','ingestion_quarantine')
order by table_name, grantee, privilege_type;
select grantee, table_name, column_name, privilege_type, is_grantable
from information_schema.column_privileges where table_schema = 'public'
  and table_name in ('source_posts','exams','subjects','exam_subjects','resources',
                     'profiles','bookmarks','recent_views','ingestion_quarantine')
order by table_name, grantee, column_name, privilege_type;
-- Default privileges apply to future objects; inspect global and public defaults.
select d.defaclrole::regrole as owner, n.nspname, d.defaclobjtype, d.defaclacl
from pg_catalog.pg_default_acl d left join pg_catalog.pg_namespace n on n.oid = d.defaclnamespace
where d.defaclnamespace = 0 or n.nspname = 'public';
-- Include role inheritance when assessing effective privileges, not just direct ACLs.
select granted.rolname as granted_role, member.rolname as member_role
from pg_catalog.pg_auth_members m
join pg_catalog.pg_roles granted on granted.oid = m.roleid
join pg_catalog.pg_roles member on member.oid = m.member;
select conrelid::regclass as table_name, conname, contype, confupdtype, confdeltype,
       pg_catalog.pg_get_constraintdef(oid) as definition
from pg_catalog.pg_constraint where connamespace = 'public'::regnamespace
  and conrelid in (to_regclass('public.source_posts'),to_regclass('public.exams'),
      to_regclass('public.subjects'),to_regclass('public.exam_subjects'),to_regclass('public.resources'),
      to_regclass('public.profiles'),to_regclass('public.bookmarks'),to_regclass('public.recent_views'),
      to_regclass('public.ingestion_quarantine'))
order by table_name, conname;
-- Two invoker functions; search_path="" and no effective client EXECUTE.
select p.oid::regprocedure as function_name, p.prosecdef, p.proconfig, p.proacl,
       has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute
from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname in ('set_updated_at','set_viewed_at');
-- Seven non-internal triggers. Runtime firing still requires separate behavioral tests.
select c.relname, t.tgname, t.tgenabled, pg_catalog.pg_get_triggerdef(t.oid) as definition
from pg_catalog.pg_trigger t join pg_catalog.pg_class c on c.oid = t.tgrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and not t.tgisinternal
  and c.relname in ('source_posts','exams','subjects','exam_subjects','resources',
                   'profiles','bookmarks','recent_views','ingestion_quarantine')
order by c.relname, t.tgname;
-- Nine non-constraint indexes; show constraint indexes separately via constraint_name.
select c.relname as table_name, idx.relname as index_name, am.amname, co.conname as constraint_name,
       i.indisvalid, pg_catalog.pg_get_indexdef(i.indexrelid) as definition,
       pg_catalog.pg_get_expr(i.indpred, i.indrelid) as predicate,
       array(select ns.nspname || '.' || op.opcname
             from unnest(i.indclass::oid[]) with ordinality cls(opclass_oid, position)
             join pg_catalog.pg_opclass op on op.oid = cls.opclass_oid
             join pg_catalog.pg_namespace ns on ns.oid = op.opcnamespace
             order by cls.position) as opclasses
from pg_catalog.pg_index i join pg_catalog.pg_class c on c.oid = i.indrelid
join pg_catalog.pg_class idx on idx.oid = i.indexrelid
join pg_catalog.pg_am am on am.oid = idx.relam
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
left join pg_catalog.pg_constraint co on co.conindid = i.indexrelid and co.contype in ('p','u','x')
where n.nspname = 'public'
  and c.relname in ('source_posts','exams','subjects','exam_subjects','resources',
                   'profiles','bookmarks','recent_views','ingestion_quarantine')
order by c.relname, idx.relname;
select a.attname, a.attgenerated, pg_catalog.pg_get_expr(d.adbin, d.adrelid) as generation_expression
from pg_catalog.pg_attribute a join pg_catalog.pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
where a.attrelid = to_regclass('public.exams') and a.attname = 'sort_date';
