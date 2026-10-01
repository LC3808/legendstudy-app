-- Read-only Owner pre/postflight: compare all nine rows/security_match=true.
-- Expected pre-apply ledger23 / tracked=false / objects absent. Post: exact version24 only after Owner tracking.
begin read only;
select current_user,session_user,(select rolsuper from pg_roles where rolname=current_user) superuser;
with expected(nsp,name,args,owner_name,definer,acl) as (values
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
from expected e left join pg_namespace n on n.nspname=e.nsp left join pg_proc p on p.pronamespace=n.oid and p.proname=e.name and pg_get_function_identity_arguments(p.oid)=e.args order by 1,2;
select pg_get_userbyid(roleid) role,pg_get_userbyid(member) member,pg_get_userbyid(grantor) grantor,admin_option,inherit_option,set_option from pg_auth_members where roleid in (select oid from pg_roles where rolname in ('essay_executor','account_erasure_executor')) order by 1,2,3;
-- essay_executor must have exactly the original supabase_admin->postgres admin-only grant.
-- New finance role may have automatic creator admin-only membership, never SET/INHERIT.
select nspname,pg_get_userbyid(nspowner) owner,nspacl::text,
 has_schema_privilege('essay_executor',oid,'CREATE') essay_create
from pg_namespace where nspname in ('public','essay_private','account_private') order by 1;
-- Compare existing schema ACL entries; original ADR-2 adds public USAGE to its two new executor roles only.
select count(*) ledger_count,bool_or(version='20261001000300') adr2_tracked,
 bool_or(version='20260930000100') day_targets_tracked,bool_or(name ilike '%provider005%') provider005_tracked,
 to_regnamespace('account_private') account_schema,to_regclass('public.account_deletion_requests') requests
from supabase_migrations.schema_migrations;
select p.oid::regprocedure,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl::text from pg_proc p where p.oid=to_regprocedure('account_private.detach_finance(uuid)');
select setting::jsonb->'postgres' ? 'storage.objects' storage_policy_authority from pg_settings where name='supautils.policy_grants';
commit;
-- POST ONLY (read-only): select enabled from account_private.dispatch_health; -- false
-- POST ONLY: select count(*) from public.account_deletion_requests; -- 0
-- POST ONLY: select count(*) from account_private.benefit_claims; -- 0
