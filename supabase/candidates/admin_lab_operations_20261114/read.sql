-- Candidate: admin-only reads, no student/ledger/engine mutation.
CREATE FUNCTION public.admin_lab_runs(p_user uuid DEFAULT NULL,p_university uuid DEFAULT NULL,p_exam uuid DEFAULT NULL,p_state text DEFAULT NULL,p_source text DEFAULT NULL,p_offset integer DEFAULT 0)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' SET statement_timeout='5s' AS $$
DECLARE answer jsonb;
BEGIN
 PERFORM essay_ops_private.require_admin();
 IF p_offset IS NULL OR p_offset<0 OR p_offset>100000 OR (p_state IS NOT NULL AND p_state NOT IN ('completed','failed','reserved')) OR (p_source IS NOT NULL AND p_source NOT IN ('beta','other')) THEN RAISE invalid_parameter_value; END IF;
 WITH facts AS MATERIALIZED (
 SELECT r.id,r.exam_id,r.parent_id,r.created_at,r.completed_at,r.state,ca.user_id,
 e.university_id,v.name university,e.exam_name title,e.admission_year as year,
 b.reason billing_reason,b.credits_required,b.status billing_status,
 b.reason='included_revision' AND b.credits_required=0 free_revision,
 EXISTS(SELECT 1 FROM public.credit_transactions t JOIN essay_beta_private.daily_grants g ON g.grant_id=t.grant_id WHERE t.decision_id=coalesce((SELECT parent.decision_id FROM essay_exam_private.runs parent WHERE parent.id=r.parent_id AND parent.account_id=r.account_id),r.decision_id)) beta_credit,
 coalesce(jsonb_array_length(r.snapshot->'answers'),0) question_count,
 coalesce(jsonb_array_length(r.result->'questions'),0) result_question_count,
 (SELECT max(t.created_at) FROM public.credit_transactions t WHERE t.decision_id=r.decision_id AND t.transaction_type='consume') last_consumed_at
 FROM essay_exam_private.runs r JOIN public.credit_accounts ca ON ca.id=r.account_id
 LEFT JOIN public.essay_exams e ON e.id=r.exam_id LEFT JOIN public.universities v ON v.id=e.university_id
 LEFT JOIN public.essay_billing_decisions b ON b.id=r.decision_id
 WHERE (p_user IS NULL OR ca.user_id=p_user)
 ), filtered AS MATERIALIZED (
 SELECT * FROM facts WHERE (p_university IS NULL OR university_id=p_university) AND (p_exam IS NULL OR exam_id=p_exam)
 AND (p_state IS NULL OR state=p_state) AND (p_source IS NULL OR beta_credit=(p_source='beta'))
 ), page AS (SELECT * FROM filtered ORDER BY created_at DESC,id LIMIT 25 OFFSET p_offset)
 SELECT jsonb_build_object('version','admin-lab-v1','as_of',statement_timestamp(),'total',(SELECT count(*) FROM filtered),'offset',p_offset,'limit',25,
 'summary',(SELECT jsonb_build_object('requested',count(*),'initial',count(*) FILTER(WHERE parent_id IS NULL),'completed',count(*) FILTER(WHERE state='completed'),
 'failed',count(*) FILTER(WHERE state='failed'),'pending',count(*) FILTER(WHERE state NOT IN ('completed','failed')),
 'free_revisions',count(*) FILTER(WHERE free_revision),'beta_credit',count(*) FILTER(WHERE beta_credit),
 'last_requested_at',max(created_at),'last_consumed_at',max(last_consumed_at)) FROM filtered),
 'universities',(SELECT coalesce(jsonb_agg(to_jsonb(u) ORDER BY university),'[]') FROM (SELECT DISTINCT university_id,university FROM facts) u),
 'items',(SELECT coalesce(jsonb_agg(to_jsonb(p) ORDER BY created_at DESC,id),'[]') FROM page p)) INTO answer;
 RETURN answer;
END $$;

CREATE FUNCTION public.admin_lab_run_detail(p_run uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' SET statement_timeout='5s' AS $$
DECLARE r essay_exam_private.runs; subject uuid; body jsonb; result_body jsonb;
BEGIN
 PERFORM essay_ops_private.require_admin();
 SELECT x.* INTO r FROM essay_exam_private.runs x WHERE x.id=p_run;
 IF NOT FOUND THEN RAISE no_data_found; END IF;
 SELECT user_id INTO subject FROM public.credit_accounts WHERE id=r.account_id;
 IF subject IS NULL OR account_private.allowed(subject) IS NOT TRUE THEN RAISE insufficient_privilege; END IF;
 -- Preserve frozen answers/criteria; never expose dispatch keys or raw telemetry.
 SELECT jsonb_build_object('questions',coalesce(jsonb_agg((q-'telemetry')||jsonb_build_object('evaluation',(q->'evaluation')-'local_reviews')),'[]')) INTO result_body FROM jsonb_array_elements(r.result->'questions') q;
 SELECT jsonb_build_object('version','admin-lab-detail-v1','user_id',subject,
 'run',jsonb_build_object('id',r.id,'exam_id',r.exam_id,'parent_id',r.parent_id,'previous_paid_run_id',r.previous_paid_run_id,
 'submission_index',r.submission_index,'created_at',r.created_at,'completed_at',r.completed_at,'state',r.state,
 'university',v.name,'year',e.admission_year,'title',e.exam_name,'answers',r.snapshot->'answers','result',result_body),
 'billing',(SELECT jsonb_build_object('id',b.id,'reason',b.reason,'credits_required',b.credits_required,'status',b.status,'created_at',b.created_at,'reserved_at',b.reserved_at,'settled_at',b.settled_at,'released_at',b.released_at) FROM public.essay_billing_decisions b WHERE b.id=r.decision_id),
 'ledger',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',t.id,'at',t.created_at,'type',t.transaction_type,'balance_delta',t.balance_delta,'reserved_delta',t.reserved_delta,'origin',g.origin,'reversal_of',t.reversal_of) ORDER BY t.created_at,t.id),'[]') FROM public.credit_transactions t LEFT JOIN public.credit_grants g ON g.id=t.grant_id WHERE t.decision_id=r.decision_id),
 'calls',(SELECT coalesce(jsonb_agg(to_jsonb(c) ORDER BY c.called_at,c.call_id),'[]') FROM essay_ops_private.calls c WHERE c.evaluation_id=r.id),
 'retries',(SELECT coalesce(jsonb_agg(jsonb_build_object('generation',generation,'at',created_at) ORDER BY generation),'[]') FROM essay_exam_private.retry_requests WHERE run_id=r.id),
 'diagnostics',(SELECT coalesce(jsonb_agg(jsonb_build_object('stage',case when payload->>'stage' ~ '^[a-z_]{1,40}$' then payload->>'stage' end,'code',case when payload->>'code' ~ '^[A-Z_0-9]{1,80}$' then payload->>'code' end)),'[]') FROM essay_exam_private.checkpoints WHERE run_id=r.id AND state='checkpoint' AND payload->>'component' IN ('execution_failure','validation_failure')),
 'children',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'at',created_at,'state',state) ORDER BY created_at,id),'[]') FROM essay_exam_private.runs WHERE parent_id=r.id AND account_id=r.account_id),
 'reviewed_questions',(SELECT coalesce(jsonb_agg(DISTINCT exam_question_id),'[]') FROM public.human_quality_judgments WHERE exam_run_id=r.id),
 'result_viewed_at',null) INTO body FROM public.essay_exams e LEFT JOIN public.universities v ON v.id=e.university_id WHERE e.id=r.exam_id;
 IF body IS NULL THEN RAISE no_data_found; END IF;
 IF octet_length(body::text)>8388608 THEN RAISE program_limit_exceeded; END IF;
 RETURN body;
END $$;
ALTER FUNCTION public.admin_lab_runs(uuid,uuid,uuid,text,text,integer) OWNER TO postgres;
ALTER FUNCTION public.admin_lab_run_detail(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.admin_lab_runs(uuid,uuid,uuid,text,text,integer),public.admin_lab_run_detail(uuid) FROM PUBLIC,anon,service_role;
GRANT EXECUTE ON FUNCTION public.admin_lab_runs(uuid,uuid,uuid,text,text,integer),public.admin_lab_run_detail(uuid) TO authenticated;
