-- ADMIN-P0-A object inventory: ownership, security, volatility, search_path, ACL.
\pset format aligned
select p.proname,
       pg_get_function_identity_arguments(p.oid) args,
       pg_get_userbyid(p.proowner) owner,
       p.prosecdef definer,
       p.provolatile volatility,
       p.proconfig config,
       coalesce(array_to_string(p.proacl,' | '),'(default)') acl
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname like 'admin\_%'
order by p.proname;
select p.proname, r.rolname, has_function_privilege(r.rolname,p.oid,'execute') can_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
cross join (values('anon'),('authenticated'),('service_role')) r(rolname)
where n.nspname='public' and p.proname like 'admin\_%'
order by p.proname, r.rolname;
