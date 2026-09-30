begin read only;
set local statement_timeout='30s';
select jsonb_build_object(
 'read_only',current_setting('transaction_read_only'),
 'migration_history',(select jsonb_agg(jsonb_build_object('version',version,'name',name,'statements',statements) order by version) from supabase_migrations.schema_migrations),
 'views',(select jsonb_agg(jsonb_build_object('name',c.relname,'options',c.reloptions,'definition',pg_get_viewdef(c.oid))) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='v'),
 'schemas',(select jsonb_agg(jsonb_build_object('name',nspname,'owner',pg_get_userbyid(nspowner),'acl',nspacl::text)) from pg_namespace where nspname in ('public','essay_private','storage')),
 'roles',(select jsonb_agg(jsonb_build_object('name',rolname,'login',rolcanlogin,'inherit',rolinherit,'bypassrls',rolbypassrls,'superuser',rolsuper,'createrole',rolcreaterole)) from pg_roles where rolname in ('anon','authenticated','service_role','authenticator','postgres','essay_executor','essay_worker','essay_finance')),
 'memberships',(select jsonb_agg(jsonb_build_object('role',pg_get_userbyid(roleid),'member',pg_get_userbyid(member),'admin_option',admin_option)) from pg_auth_members where pg_get_userbyid(roleid) like 'essay_%' or pg_get_userbyid(member) like 'essay_%'),
 'storage_policies',(select jsonb_agg(to_jsonb(p)) from pg_policies p where schemaname='storage')
) as metadata;
rollback;
