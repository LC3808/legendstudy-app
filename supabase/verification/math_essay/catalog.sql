-- Owner read-only preflight; no application rows or secret values.
begin read only;
select jsonb_build_object(
'ledger',(select jsonb_agg(version order by version) from supabase_migrations.schema_migrations),
'roles',(select jsonb_agg(jsonb_build_object('name',rolname,'superuser',rolsuper,'createrole',rolcreaterole,'bypassrls',rolbypassrls,'login',rolcanlogin)) from pg_roles where rolname in ('postgres','essay_executor','essay_worker','essay_finance','account_erasure_executor','math_executor','math_extraction_worker','math_evaluation_worker')),
'memberships',(select jsonb_agg(jsonb_build_object('role',pg_get_userbyid(roleid),'member',pg_get_userbyid(member),'grantor',pg_get_userbyid(grantor),'admin',admin_option,'inherit',inherit_option,'set',set_option)) from pg_auth_members where roleid='essay_executor'::regrole),
'schemas',(select jsonb_agg(jsonb_build_object('schema',nspname,'owner',pg_get_userbyid(nspowner),'acl',nspacl::text)) from pg_namespace where nspname in ('public','essay_private','account_private','math_private')),
'collisions',(select coalesce(jsonb_agg(x),'[]'::jsonb) from (select 'relation' kind, c.oid::regclass::text name from pg_class c where c.relname like 'math\_%' escape '\' union all select 'function',p.oid::regprocedure::text from pg_proc p where p.proname like 'math\_%' escape '\' or p.proname like 'qlm\_%' escape '\') x),
'prerequisites',(select jsonb_agg(jsonb_build_object('name',c.relname,'owner',pg_get_userbyid(c.relowner),'rls',c.relrowsecurity,'acl',c.relacl::text)) from pg_class c where c.relnamespace='public'::regnamespace and c.relname in('universities','essay_exams','credit_accounts','credit_grants','credit_transactions','essay_billing_decisions','human_quality_judgments','human_quality_findings','account_deletion_requests')),
'functions',(select jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'owner',pg_get_userbyid(p.proowner),'acl',p.proacl::text,'config',p.proconfig,'definer',p.prosecdef)) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in('essay_private','public') and p.proname in('hq_immutable','hq_finding_valid','hq_rubric_valid','ql_submit_human_judgment','ql_list_human_judgments','ql_review_state','is_quality_operator','essay_billing_history_guard','credit_request_v2','release'))
) as evidence;
-- Save these exact legacy security/body fingerprints before the reviewed application.
select oid::regprocedure::text as signature,pg_get_userbyid(proowner) as owner,
 prosecdef,provolatile,proconfig,proacl::text,md5(pg_get_functiondef(oid)) as definition_fingerprint
from pg_proc where oid in (to_regprocedure('public.ql_list_cases(integer,timestamptz,uuid)'),to_regprocedure('public.ql_case_detail(uuid)'),to_regprocedure('public.ql_review_state(uuid[])'),to_regprocedure('public.ql_submit_human_judgment(jsonb)'),to_regprocedure('public.ql_list_human_judgments(uuid,integer,timestamptz,uuid)')) order by 1;
commit;
