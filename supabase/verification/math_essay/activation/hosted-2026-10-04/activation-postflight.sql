begin read only;
select jsonb_build_object(
'bucket',(select to_jsonb(b) from (select id,public,file_size_limit,allowed_mime_types from storage.buckets where id='math-private') b),
'memberships',(select jsonb_agg(jsonb_build_array(pg_get_userbyid(roleid),pg_get_userbyid(member),pg_get_userbyid(grantor),admin_option,inherit_option,set_option) order by roleid,member) from pg_auth_members where roleid in ('essay_executor'::regrole,'account_lifecycle_worker'::regrole,'math_executor'::regrole,'math_extraction_worker'::regrole,'math_evaluation_worker'::regrole)),
'functions',(select jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,'signature',p.oid::regprocedure::text,'owner',pg_get_userbyid(p.proowner),'definer',p.prosecdef,'config',p.proconfig,'acl',p.proacl::text,'executors',(select jsonb_agg(case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end order by a.grantee) from aclexplode(p.proacl) a))) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='math_private' or (n.nspname='public' and (p.proname like 'math_%' or p.proname like 'qlm_%'))),
'policies',(select jsonb_agg(to_jsonb(p)) from pg_policies p where p.schemaname='storage'),
'schemas',(select jsonb_agg(jsonb_build_object('name',nspname,'owner',pg_get_userbyid(nspowner),'acl',nspacl::text)) from pg_namespace where nspname in ('public','essay_private','storage','math_private','account_private')),
'storage_tables',(select jsonb_agg(jsonb_build_object('name',relname,'owner',pg_get_userbyid(relowner),'rls',relrowsecurity,'acl',relacl::text)) from pg_class where oid in ('storage.objects'::regclass,'storage.buckets'::regclass)),
'attempts',(select count(*) from public.math_attempts),'evaluations',(select count(*) from public.math_evaluations),'objects',(select count(*) from storage.objects where bucket_id='math-private'),
'control',(select to_jsonb(c) from math_private.runtime_control c),
'privileged_access',(select jsonb_agg(jsonb_build_object('role',r,'signature',s,'access',has_function_privilege(r,s,'EXECUTE'))) from unnest(array['anon','authenticated','service_role']) r cross join unnest(array['public.math_artifact_storage(uuid,uuid,text,bigint,text)','public.math_account_erasure(uuid,uuid,text)','public.math_recover_evaluation(uuid)']) s),
'admission_trigger',(select pg_get_triggerdef(oid) from pg_trigger where tgname='math_runtime_admission'),
'ledger',(select jsonb_agg(version order by version) from supabase_migrations.schema_migrations)
) postflight;
commit;
