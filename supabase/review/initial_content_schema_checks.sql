-- READ-ONLY REVIEW QUERIES FOR A FUTURE AUTHORIZED TASK. NOT EXECUTED IN DAY 3.
-- Before applying the draft: check prerequisite extension schema and auth roles.
select e.extname, n.nspname as extension_schema
from pg_catalog.pg_extension e
join pg_catalog.pg_namespace n on n.oid = e.extnamespace
where e.extname = 'pg_trgm';
-- Expected: absent, or one row in extensions. Any other schema requires review.
select rolname, rolbypassrls from pg_catalog.pg_roles
where rolname in ('anon', 'authenticated', 'service_role');
-- Expected: all three exist; service_role bypasses RLS, clients do not.
select to_regclass('auth.users') as auth_users, to_regprocedure('auth.uid()') as auth_uid;

-- After explicit user application: eight application tables, all RLS enabled.
select c.relname, c.relrowsecurity
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
  and c.relname in ('source_posts', 'exams', 'subjects', 'exam_subjects',
                   'resources', 'profiles', 'bookmarks', 'recent_views')
order by c.relname;
-- Expected: 15 explicit policies, zero source_posts policies, no content writes.
select tablename, policyname, roles, cmd, qual, with_check
from pg_catalog.pg_policies where schemaname = 'public'
  and tablename in ('source_posts', 'exams', 'subjects', 'exam_subjects',
                    'resources', 'profiles', 'bookmarks', 'recent_views')
order by tablename, policyname;
-- Inspect exact table and column grants, including defaults inherited from Supabase.
select grantee, table_name, privilege_type
from information_schema.table_privileges where table_schema = 'public'
  and table_name in ('source_posts', 'exams', 'subjects', 'exam_subjects',
                     'resources', 'profiles', 'bookmarks', 'recent_views')
order by table_name, grantee, privilege_type;
select grantee, table_name, column_name, privilege_type
from information_schema.column_privileges where table_schema = 'public'
  and table_name in ('profiles', 'bookmarks', 'recent_views')
order by table_name, grantee, column_name, privilege_type;
select conrelid::regclass as table_name, conname, pg_catalog.pg_get_constraintdef(oid)
from pg_catalog.pg_constraint where connamespace = 'public'::regnamespace
  and conrelid in ('public.source_posts'::regclass, 'public.exams'::regclass,
      'public.subjects'::regclass, 'public.exam_subjects'::regclass,
      'public.resources'::regclass, 'public.profiles'::regclass,
      'public.bookmarks'::regclass, 'public.recent_views'::regclass)
order by table_name, conname;
