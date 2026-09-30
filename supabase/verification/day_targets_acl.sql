-- Read-only BEFORE/AFTER metadata check; NEVER tests TRUNCATE or writes rows.
begin read only;
set local statement_timeout='30s';
select jsonb_build_object(
 'captured_at',clock_timestamp(),'read_only',current_setting('transaction_read_only'),'server_version',current_setting('server_version'),
 'table',(select jsonb_build_object('owner',pg_get_userbyid(c.relowner),'rls',c.relrowsecurity,'force_rls',c.relforcerowsecurity,'acl',c.relacl::text) from pg_class c where c.oid='public.day_targets'::regclass),
 'acl',(select jsonb_agg(jsonb_build_object('role',case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end,'privilege',a.privilege_type,'grantable',a.is_grantable)) from pg_class c cross join lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) a where c.oid='public.day_targets'::regclass),
 'policies',(select jsonb_agg(to_jsonb(p)) from pg_policies p where schemaname='public' and tablename='day_targets'),
 'schema',(select jsonb_build_object('owner',pg_get_userbyid(nspowner),'acl',nspacl::text) from pg_namespace where nspname='public'),
 'defaults',(select jsonb_agg(jsonb_build_object('creator',pg_get_userbyid(d.defaclrole),'schema',n.nspname,'kind',d.defaclobjtype,'acl',d.defaclacl::text)) from pg_default_acl d left join pg_namespace n on n.oid=d.defaclnamespace where d.defaclobjtype='r'),
 'memberships',(select jsonb_agg(jsonb_build_object('role',pg_get_userbyid(roleid),'member',pg_get_userbyid(member),'inherit',inherit_option,'set',set_option)) from pg_auth_members),
 'other_client_excess',(select jsonb_agg(jsonb_build_object('table',c.relname,'role',pg_get_userbyid(a.grantee),'privilege',a.privilege_type)) from pg_class c join pg_namespace n on n.oid=c.relnamespace cross join lateral aclexplode(coalesce(c.relacl,acldefault('r',c.relowner))) a where n.nspname='public' and c.relkind='r' and pg_get_userbyid(a.grantee) in ('anon','authenticated') and a.privilege_type in ('TRUNCATE','TRIGGER','REFERENCES','MAINTAIN')),
 'effective_privileges',(select jsonb_agg(jsonb_build_object('role',r,'privilege',p,'allowed',has_table_privilege(r,'public.day_targets',p))) from unnest(array['anon','authenticated','service_role','postgres']) r cross join unnest(array['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES','MAINTAIN']) p),
 'column_acl',(select jsonb_agg(jsonb_build_object('column',attname,'acl',attacl::text)) from pg_attribute where attrelid='public.day_targets'::regclass and attnum>0 and not attisdropped and attacl is not null),
 'migration_versions',(select jsonb_agg(version order by version) from supabase_migrations.schema_migrations)
) as metadata;
rollback;
