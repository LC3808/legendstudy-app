begin read only;
set local statement_timeout='15s';
with expected(nsp,name,args,owner_name,definer,acl) as (values
('essay_private','credit_post_grant','p_user uuid, p_quantity integer, p_origin text, p_key text, p_reason text, p_actor text, p_expires timestamp with time zone','essay_executor',true,'{essay_executor=X/essay_executor}'),
('essay_private','credit_profile_signup','','essay_executor',true,'{essay_executor=X/essay_executor}'),
('essay_private','lock_job','p_evaluation uuid','essay_executor',false,'{essay_executor=X/essay_executor}'),
('essay_private','owner','p_session uuid','essay_executor',false,'{essay_executor=X/essay_executor}'),
('essay_private','uid','','postgres',true,'{postgres=X/postgres,essay_executor=X/postgres}'),
('public','essay_claim_signup_credit','','essay_executor',true,'{essay_executor=X/essay_executor,authenticated=X/essay_executor}'),
('public','fetch_own_mock_attempt','p_attempt_id uuid','postgres',true,'{postgres=X/postgres,authenticated=X/postgres}'),
('public','is_quality_operator','','postgres',true,'{postgres=X/postgres,authenticated=X/postgres}'),
('public','submit_mock_attempt','p_attempt_id uuid, p_study_session_id uuid, p_answer_key_version_id uuid, p_grade_cutoff_version_id uuid, p_scoring_version text, p_answers jsonb','postgres',true,'{postgres=X/postgres,authenticated=X/postgres}')), audited as (
select e.nsp,e.name,e.args,pg_get_userbyid(p.proowner) owner,p.prosecdef,p.proconfig,p.proacl::text,
 p.oid is not null and pg_get_userbyid(p.proowner)=e.owner_name and p.prosecdef=e.definer and p.proconfig=array['search_path=""'] and p.proacl::text=e.acl security_match,
 md5(pg_get_functiondef(p.oid)) definition_fingerprint
from expected e left join pg_namespace n on n.nspname=e.nsp left join pg_proc p on p.pronamespace=n.oid and p.proname=e.name and pg_get_function_identity_arguments(p.oid)=e.args) select jsonb_agg(to_jsonb(a)) as functions from audited a;
commit;
