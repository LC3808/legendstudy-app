begin read only;
with function_checks as (with expected(nsp,name,args,owner_name,definer,acl) as (values
('essay_private','credit_post_grant','p_user uuid, p_quantity integer, p_origin text, p_key text, p_reason text, p_actor text, p_expires timestamp with time zone','essay_executor',true,'{essay_executor=X/essay_executor}'),
('essay_private','credit_profile_signup','','essay_executor',true,'{essay_executor=X/essay_executor}'),
('essay_private','lock_job','p_evaluation uuid','essay_executor',false,'{essay_executor=X/essay_executor}'),
('essay_private','owner','p_session uuid','essay_executor',false,'{essay_executor=X/essay_executor}'),
('essay_private','uid','','postgres',true,'{postgres=X/postgres,essay_executor=X/postgres}'),
('public','essay_claim_signup_credit','','essay_executor',true,'{essay_executor=X/essay_executor,authenticated=X/essay_executor}'),
('public','fetch_own_mock_attempt','p_attempt_id uuid','postgres',true,'{postgres=X/postgres,authenticated=X/postgres}'),
('public','is_quality_operator','','postgres',true,'{postgres=X/postgres,authenticated=X/postgres}'),
('public','submit_mock_attempt','p_attempt_id uuid, p_study_session_id uuid, p_answer_key_version_id uuid, p_grade_cutoff_version_id uuid, p_scoring_version text, p_answers jsonb','postgres',true,'{postgres=X/postgres,authenticated=X/postgres}'))
select e.nsp,e.name,e.args,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl::text,
 p.oid is not null and pg_get_userbyid(p.proowner)=e.owner_name and p.prosecdef=e.definer and p.proconfig=array['search_path=""'] and p.proacl::text=e.acl security_match,
 md5(pg_get_functiondef(p.oid)) definition_fingerprint
from expected e left join pg_namespace n on n.nspname=e.nsp left join pg_proc p on p.pronamespace=n.oid and p.proname=e.name and pg_get_function_identity_arguments(p.oid)=e.args order by 1,2) select jsonb_build_object(
'executor',current_user,'session_user',session_user,'function_checks',(select jsonb_agg(to_jsonb(x)) from function_checks x),
'tables',(select jsonb_agg(jsonb_build_object('name',c.relname,'owner',pg_get_userbyid(c.relowner),'rls',c.relrowsecurity,'acl',c.relacl::text)) from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r'),
'policies',(select jsonb_agg(to_jsonb(x)) from pg_policies x where schemaname='storage' or tablename='day_targets'),
'capabilities',jsonb_build_object('storage_policy',current_setting('supautils.policy_grants',true)::jsonb->'postgres' ? 'storage.objects','storage_insert',has_table_privilege(current_user,'storage.buckets','INSERT'),'storage_select_grant',has_table_privilege(current_user,'storage.objects','SELECT WITH GRANT OPTION'),'storage_usage_grant',has_schema_privilege(current_user,'storage','USAGE WITH GRANT OPTION'),'public_create',has_schema_privilege(current_user,'public','CREATE'),'essay_public_create',has_schema_privilege('essay_executor','public','CREATE'),'essay_private_create',has_schema_privilege('essay_executor','essay_private','CREATE')),
'role_memberships',(select jsonb_agg(jsonb_build_object('role',pg_get_userbyid(roleid),'member',pg_get_userbyid(member),'grantor',pg_get_userbyid(grantor),'admin',admin_option,'inherit',inherit_option,'set',set_option)) from pg_auth_members where roleid in(select oid from pg_roles where rolname like 'math_%' or rolname like 'account_%' or rolname='essay_executor')),
'collisions',(select jsonb_agg(p.oid::regprocedure::text) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in('math_private','account_private') or(n.nspname='public' and(p.proname like 'account_%' or p.proname like 'math_%' or p.proname='qlm_quality'))),
'ledger',(select jsonb_agg(jsonb_build_object('version',version,'name',name) order by version) from supabase_migrations.schema_migrations)
) as preflight; commit;
