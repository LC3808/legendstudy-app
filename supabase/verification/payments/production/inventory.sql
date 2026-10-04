-- READ ONLY. Owner target: LegendStudy Production stlhijzpjfgwwdgunlsd.
begin transaction read only;
set local statement_timeout='15s';
select jsonb_build_object(
 'executor',current_user,'database',current_database(),'server_version',current_setting('server_version'),
 'schemas',(select jsonb_agg(jsonb_build_object('name',nspname,'owner',pg_get_userbyid(nspowner),'acl',nspacl::text)) from pg_namespace where nspname in ('public','essay_private','account_private','payment_private')),
 'roles',(select jsonb_agg(jsonb_build_object('name',rolname,'login',rolcanlogin,'super',rolsuper,'bypass',rolbypassrls,'create_role',rolcreaterole,'inherit',rolinherit)) from pg_roles where rolname in ('postgres','essay_executor','essay_finance','account_executor','authenticator')),
 'memberships',(select jsonb_agg(jsonb_build_object('role',pg_get_userbyid(roleid),'member',pg_get_userbyid(member),'grantor',pg_get_userbyid(grantor),'admin',admin_option,'inherit',inherit_option,'set',set_option)) from pg_auth_members where pg_get_userbyid(roleid) in ('essay_executor','essay_finance','account_executor')),
 'relations',(select jsonb_agg(jsonb_build_object('name',n.nspname||'.'||c.relname,'owner',pg_get_userbyid(c.relowner),'rls',c.relrowsecurity,'acl',c.relacl::text)) from pg_class c join pg_namespace n on n.oid=c.relnamespace where (n.nspname='public' and c.relname in ('profiles','credit_accounts','credit_grants','credit_transactions','payment_orders','payment_operations','payment_events')) or (n.nspname='account_private' and c.relkind='r') or n.nspname='payment_private'),
 'functions',(select jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'owner',pg_get_userbyid(p.proowner),'security_definer',p.prosecdef,'config',p.proconfig,'acl',p.proacl::text,'definition_md5',md5(pg_get_functiondef(p.oid)))) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where p.prokind='f' and (n.nspname in ('account_private','payment_private') or n.nspname='essay_private' and p.proname in ('credit_post_grant','credit_post_consume','credit_post_refund','uid') or n.nspname='public' and p.proname in ('payment_order','payment_process','credit_balance'))),
 'ledger_present',to_regclass('supabase_migrations.schema_migrations') is not null,
 'auth_users_present',to_regclass('auth.users') is not null
) as inventory;
commit;
