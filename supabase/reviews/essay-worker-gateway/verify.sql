select r.rolname,r.rolsuper,r.rolbypassrls,r.rolcanlogin from pg_roles r where r.rolname='essay_worker';
select m.admin_option,m.inherit_option,m.set_option from pg_auth_members m
where m.roleid='essay_worker'::regrole and m.member='authenticator'::regrole;
select pg_has_role('authenticated','essay_worker','MEMBER') as student_worker,
 pg_has_role('anon','essay_worker','MEMBER') as anon_worker,
 pg_has_role('essay_worker','essay_executor','MEMBER') as worker_executor;
