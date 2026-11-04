-- Phase 2: reference existing exam results; append-only HQP, no evaluation/credit writes.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';
alter table public.human_quality_judgments add column exam_run_id uuid references essay_exam_private.runs(id) on delete cascade;
alter table public.human_quality_judgments add column exam_question_id text;
alter table public.human_quality_judgments add column review_evidence jsonb;
alter table public.human_quality_judgments drop constraint hq_exact_domain;
alter table public.human_quality_judgments add constraint hq_exact_domain check(num_nonnulls(evaluation_id,math_evaluation_id,exam_run_id)=1 and ((exam_run_id is null)=(exam_question_id is null)));
alter table public.human_quality_judgments drop constraint hq_domain_rubric;
alter table public.human_quality_judgments add constraint hq_domain_rubric check((case
 when evaluation_id is not null then rubric_version='hq-rubric-v1' and essay_private.hq_rubric_valid(rubric_result)
 when math_evaluation_id is not null then rubric_version='hq-math-rubric-v1' and reviewed_generated_rewrite_id is null and math_private.hq_rubric_valid(rubric_result)
 else rubric_version='hq-exam-rubric-v1' and reviewed_generated_rewrite_id is null and essay_private.hq_rubric_valid(rubric_result) end) is true);
alter table public.human_quality_judgments add constraint hq_exam_identity unique(id,exam_run_id,exam_question_id);
alter table public.human_quality_judgments add constraint hq_exam_correction foreign key(supersedes_judgment_id,exam_run_id,exam_question_id) references public.human_quality_judgments(id,exam_run_id,exam_question_id);
alter table public.human_quality_judgments add constraint hq_review_evidence_bound check(review_evidence is null or (jsonb_typeof(review_evidence)='object' and octet_length(review_evidence::text)<=4096));
create index hq_exam_history on public.human_quality_judgments(exam_run_id,exam_question_id,created_at desc,id desc) where exam_run_id is not null;

create function essay_private.hq_exam_subject(p_run uuid,p_question text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare r essay_exam_private.runs; student uuid; a jsonb; q jsonb; v jsonb;
begin
 if not public.is_quality_operator() then raise insufficient_privilege;end if;
 perform 1 from public.quality_operators where user_id=auth.uid() for key share;
 if not found then raise insufficient_privilege;end if;
 select ca.user_id into student from essay_exam_private.runs x join public.credit_accounts ca on ca.id=x.account_id where x.id=p_run;
 if student is null then raise no_data_found;end if;
 perform math_private.require_active(array[auth.uid(),student]);
 select * into r from essay_exam_private.runs where id=p_run for share;
 if not found then raise no_data_found;end if;
 select value into strict a from jsonb_array_elements(r.snapshot->'answers') where value->>'questionId'=p_question;
 select value into q from jsonb_array_elements(r.result->'questions') where value->>'questionId'=p_question;
 v=jsonb_build_object('run_id',r.id,'question_id',p_question,'state',r.state,'created_at',r.created_at,'completed_at',r.completed_at,
 'parent_id',r.parent_id,'previous_paid_run_id',r.previous_paid_run_id,'submission_index',r.submission_index,
 'exam_id',r.exam_id,'university_id',r.snapshot->'universityId','year',r.snapshot->'year','kind',r.snapshot->'kind',
 'official_label',(select label from public.essay_questions where id::text=p_question),
 'answer',a,'result',q,'result_available',q is not null,
 'snapshot_sha256',encode(sha256(convert_to(jsonb_build_object('answer',a,'result',q,'state',r.state)::text,'UTF8')),'hex'));
 if octet_length(v::text)>2097152 then raise program_limit_exceeded;end if;
 return v;
end$$;

create function public.ql_exam_cases(p_from timestamptz,p_to timestamptz,p_offset integer default 0,p_unreviewed boolean default false) returns jsonb
language plpgsql security definer set search_path='' set statement_timeout='8s' as $$
declare v jsonb;
begin
 if not public.is_quality_operator() then raise insufficient_privilege;end if;
 if p_from is null or p_to is null or not isfinite(p_from) or not isfinite(p_to) or p_from>=p_to or p_to-p_from>interval '400 days' or p_offset is null or p_offset<0 or p_offset>100000 or p_unreviewed is null then raise invalid_parameter_value;end if;
 with subjects as materialized (
 select r.id run_id,a->>'questionId' question_id,r.created_at,r.completed_at,r.state,r.exam_id,r.parent_id,
 r.snapshot->>'universityId' university_id,r.snapshot->>'year' as year,r.snapshot->>'kind' kind,
 (select label from public.essay_questions where id::text=a->>'questionId') official_label,
 exists(select 1 from public.human_quality_judgments j where j.exam_run_id=r.id and j.exam_question_id=a->>'questionId') reviewed
 from essay_exam_private.runs r join public.credit_accounts ca on ca.id=r.account_id
 cross join lateral jsonb_array_elements(r.snapshot->'answers') a
 where r.created_at>=p_from and r.created_at<p_to and account_private.allowed(ca.user_id)
 ), filtered as materialized(select * from subjects where not p_unreviewed or not reviewed),
 page as (select * from filtered order by created_at desc,run_id,question_id offset p_offset limit 50)
 select jsonb_build_object('dto_version','ql-exam-v1','as_of',statement_timestamp(),'source','exam_question','total',(select count(*) from filtered),
 'coverage',jsonb_build_object('subjects',(select count(*) from subjects),'reviewed',(select count(*) from subjects where reviewed)),
 'rows',coalesce((select jsonb_agg(to_jsonb(p) order by created_at desc,run_id,question_id) from page p),'[]')) into v;
 return v;
end$$;

create function public.ql_exam_detail(p_run_id uuid,p_question_id text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v jsonb; h jsonb;
begin
 v=essay_private.hq_exam_subject(p_run_id,p_question_id);
 select coalesce(jsonb_agg(item order by created_at desc,id desc),'[]') into h from (
 select j.id,j.created_at,(to_jsonb(j)-array['client_submission_id','submission_payload_sha256','reviewer_user_id'])||jsonb_build_object(
 'is_active',not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id),
 'findings',coalesce((select jsonb_agg(to_jsonb(f)-'judgment_id') from public.human_quality_findings f where f.judgment_id=j.id),'[]')) item
 from public.human_quality_judgments j where j.exam_run_id=p_run_id and j.exam_question_id=p_question_id order by created_at desc,id desc limit 100) x;
 return jsonb_build_object('dto_version','ql-exam-v1','subject',v,'history',h,'history_limit',100);
end$$;

create function public.ql_exam_submit(p_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare s jsonb; u uuid; k uuid; rid uuid; qid text; parent uuid; prior public.human_quality_judgments; h text; jid uuid; f jsonb; evidence jsonb; link text; rubric jsonb;
begin
 if not public.is_quality_operator() then raise insufficient_privilege;end if;
 u=auth.uid();
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>32768
 or p_payload-array['run_id','question_id','expected_snapshot_sha256','client_submission_id','supersedes_judgment_id','rubric_result','overall_disposition','summary_note','findings','review_evidence','official_source_reviewed','recommended_action']<>'{}'
 or p_payload->'official_source_reviewed' is distinct from 'true'::jsonb then raise invalid_parameter_value;end if;
 k=(p_payload->>'client_submission_id')::uuid;rid=(p_payload->>'run_id')::uuid;qid=p_payload->>'question_id';parent=(p_payload->>'supersedes_judgment_id')::uuid;
 if k is null or rid is null or qid is null then raise invalid_parameter_value;end if;
 s=essay_private.hq_exam_subject(rid,qid);
 perform pg_advisory_xact_lock(hashtextextended(k::text,731));
 h=encode(sha256(convert_to(p_payload::text,'UTF8')),'hex');
 select * into prior from public.human_quality_judgments where client_submission_id=k;
 if found then
 if prior.reviewer_user_id is distinct from u or prior.submission_payload_sha256<>h then raise unique_violation using message='submission key conflict';end if;
 return jsonb_build_object('judgment_id',prior.id,'replayed',true);end if;
 if s->>'snapshot_sha256' is distinct from p_payload->>'expected_snapshot_sha256' then raise invalid_parameter_value using message='stale subject';end if;
 rubric=p_payload->'rubric_result';
 if not essay_private.hq_rubric_valid(rubric) or jsonb_typeof(p_payload->'findings') is distinct from 'array' then raise invalid_parameter_value;end if;
 if jsonb_array_length(p_payload->'findings')>20 then raise invalid_parameter_value;end if;
 -- Missing/failing output is reviewable only as NEEDS_REVIEW; completion is not a quality PASS.
 if (s->>'state'<>'completed' or s->'result_available'<>'true' or s#>>'{answer,evidenceVersion}' is null or s#>>'{answer,rubricVersion}' is null or s#>'{result,criteria}' is null) and p_payload->>'overall_disposition' is distinct from 'NEEDS_REVIEW' then raise invalid_parameter_value;end if;
 if parent is not null then
 perform 1 from public.human_quality_judgments where id=parent and exam_run_id=rid and exam_question_id=qid for update;
 if not found or exists(select 1 from public.human_quality_judgments where supersedes_judgment_id=parent) then raise check_violation using message='invalid correction head';end if;end if;
 evidence=coalesce(p_payload->'review_evidence','{}');
 if jsonb_typeof(evidence)<>'object' or evidence-array['issue_url','regression_url','fixture_sha256','commit_sha']<>'{}' or octet_length(evidence::text)>4096 then raise invalid_parameter_value;end if;
 foreach link in array array['issue_url','regression_url'] loop
 if evidence ? link and (jsonb_typeof(evidence->link)<>'string' or length(evidence->>link)>1000 or evidence->>link !~ '^https://[^[:space:]]+$') then raise invalid_parameter_value;end if;end loop;
 if evidence ? 'fixture_sha256' and evidence->>'fixture_sha256' !~ '^[0-9a-f]{64}$' then raise invalid_parameter_value;end if;
 if evidence ? 'commit_sha' and evidence->>'commit_sha' !~ '^[0-9a-f]{40}$' then raise invalid_parameter_value;end if;
 for f in select value from jsonb_array_elements(p_payload->'findings') loop
 if not essay_private.hq_finding_valid(f) or f->>'target_kind'<>'OVERALL' then raise invalid_parameter_value;end if;
 if p_payload->>'overall_disposition'='PASS' or (p_payload->>'overall_disposition'='PASS_WITH_NOTES' and f->>'severity'<>'MINOR') then raise check_violation;end if;end loop;
 insert into public.human_quality_judgments(exam_run_id,exam_question_id,reviewed_output_sha256,reviewer_user_id,rubric_version,rubric_result,overall_disposition,selection_reason,recommended_action,summary_note,supersedes_judgment_id,client_submission_id,submission_payload_sha256,review_evidence)
 values(rid,qid,s->>'snapshot_sha256',u,'hq-exam-rubric-v1',rubric,p_payload->>'overall_disposition','OPERATOR_REQUEST',coalesce(p_payload->>'recommended_action','NONE'),p_payload->>'summary_note',parent,k,h,evidence) returning id into jid;
 insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref,note)
 select jid,value->>'issue_category',value->>'severity',value->>'target_kind',value->'target_ref',value->>'note' from jsonb_array_elements(p_payload->'findings');
 return jsonb_build_object('judgment_id',jid,'replayed',false);
end$$;
revoke all on function essay_private.hq_exam_subject(uuid,text) from public,anon,authenticated,service_role;
revoke all on function public.ql_exam_cases(timestamptz,timestamptz,integer,boolean),public.ql_exam_detail(uuid,text),public.ql_exam_submit(jsonb) from public,anon,authenticated,service_role;
grant execute on function public.ql_exam_cases(timestamptz,timestamptz,integer,boolean),public.ql_exam_detail(uuid,text),public.ql_exam_submit(jsonb) to authenticated;
commit;
