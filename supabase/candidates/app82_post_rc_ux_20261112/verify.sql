-- Read-only verification after a separately approved application.
select n.nspname, p.proname, p.prosecdef, p.provolatile, p.proconfig,
  has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
  has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
  md5(pg_get_functiondef(p.oid)) as definition_digest
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in ('student_school_ranking_page','my_study_percentile');
-- Expected exactly two rows: security definer=true, volatile=s, empty search_path,
-- statement_timeout=8s, anon=false, authenticated=true.

select n.nspname,p.proname,md5(pg_get_functiondef(p.oid)) as definition_digest
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where (n.nspname='public' and p.proname in ('student_school_ranking','student_school_card','my_study_summary'))
   or (n.nspname='student_private' and p.proname='study_summary');
-- Expected existing digests identical to apply.sql preflight. No source row writes.
