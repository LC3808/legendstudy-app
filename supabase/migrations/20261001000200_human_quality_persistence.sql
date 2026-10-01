-- HQP-3. Owner-reviewed application only; Production NOT_APPLIED.
-- No pending migration replay; no change to ql-read-v1 or existing authorization.
begin;
set local lock_timeout='5s';
set local statement_timeout='30s';

create function essay_private.hq_rubric_valid(v jsonb) returns boolean
language plpgsql immutable set search_path='' as $$
declare k text; required text[]:=array['diagnosis','core_priority','actionability','evidence_adherence','stance_preservation','hallucination_absence']; optional text[]:=array['sentence_feedback','progression','generated_rewrite'];
begin
 if v is null or jsonb_typeof(v)<>'object' or v-(required||optional)<>'{}'::jsonb then return false;end if;
 foreach k in array required loop if jsonb_typeof(v->k) is distinct from 'string' or v->>k not in ('OK','CONCERN','FAIL') then return false;end if;end loop;
 foreach k in array optional loop if jsonb_typeof(v->k) is distinct from 'string' or v->>k not in ('OK','CONCERN','FAIL','NA') then return false;end if;end loop;
 return true;
end$$;

create function essay_private.hq_finding_valid(v jsonb) returns boolean
language plpgsql immutable set search_path='' as $$
declare t jsonb; k text; keys text[];
begin
 if v is null or jsonb_typeof(v)<>'object' or v-array['issue_category','severity','target_kind','target_ref','note']<>'{}'::jsonb then return false;end if;
 foreach k in array array['issue_category','severity','target_kind'] loop if jsonb_typeof(v->k) is distinct from 'string' then return false;end if;end loop;
 if v->>'issue_category' not in ('FALSE_CORRECTION','INVENTED_ERROR','EVIDENCE_MISREAD','UNSUPPORTED_CLAIM','STANCE_CHANGE','CORE_PRIORITY_ERROR','SENTENCE_SPAN_ERROR','PROGRESSION_ERROR','OVER_REWRITE','UNDER_SPECIFIED_GUIDANCE','MISSING_IMPORTANT_ISSUE','OTHER') or v->>'severity' not in ('MINOR','MATERIAL','CRITICAL') then return false;end if;
 if v ? 'note' and v->'note'<>'null'::jsonb and (jsonb_typeof(v->'note')<>'string' or char_length(v->>'note')>1000) then return false;end if;
 t=v->'target_ref';
 if v->>'target_kind' in ('OVERALL','GENERATED_REWRITE') then return coalesce(t='null'::jsonb,false);end if;
 keys=case v->>'target_kind' when 'DIMENSION' then array['dimension_id'] when 'PROGRESS' then array['progress_id'] when 'ISSUE_KEY' then array['issue_key'] when 'SENTENCE' then array['progress_id','observation_key'] when 'EVIDENCE_LINK' then array['evidence_id','dimension_id','progress_id'] else null end;
 if keys is null or t is null or jsonb_typeof(t)<>'object' or t-keys<>'{}'::jsonb then return false;end if;
 foreach k in array keys loop
  if not t ? k then return false;end if;
  if k in ('issue_key','observation_key') then
   if jsonb_typeof(t->k)<>'string' or char_length(t->>k) not between 1 and 200 or btrim(t->>k)='' then return false;end if;
  elsif v->>'target_kind'='EVIDENCE_LINK' and k<>'evidence_id' and t->k='null'::jsonb then null;
  else
   if jsonb_typeof(t->k)<>'string' or (t->>k)!~'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' then return false;end if;
  end if;
 end loop;
 return true;
end$$;

create table public.human_quality_judgments (
 id uuid primary key default gen_random_uuid(),
 evaluation_id uuid not null references public.essay_evaluations(id) on delete cascade,
 reviewed_output_sha256 text not null check(reviewed_output_sha256 ~ '^[0-9a-f]{64}$'),
 reviewed_generated_rewrite_id uuid references public.essay_generated_rewrites(id) on delete set null,
 reviewer_user_id uuid references auth.users(id) on delete set null,
 rubric_version text not null check(rubric_version='hq-rubric-v1'),
 overall_disposition text not null check(overall_disposition in ('PASS','PASS_WITH_NOTES','NEEDS_REVIEW','FAIL')),
 rubric_result jsonb not null check(essay_private.hq_rubric_valid(rubric_result)),
 selection_reason text not null check(selection_reason in ('EARLY_CENSUS','RANDOM_SAMPLE','ANOMALY','USER_REPORT','OPERATOR_REQUEST','MODEL_CHANGE_AUDIT','DISPUTE','OTHER')),
 recommended_action text not null check(recommended_action in ('NONE','MONITOR','REVIEW_PROMPT','REVIEW_EVIDENCE','RE_EVALUATE','INVALIDATE_CANDIDATE','ESCALATE')),
 summary_note text check(char_length(summary_note)<=2000),
 supersedes_judgment_id uuid unique,
 client_submission_id uuid not null unique,
 submission_payload_sha256 text not null check(submission_payload_sha256 ~ '^[0-9a-f]{64}$'),
 created_at timestamptz not null default clock_timestamp(),
 unique(id,evaluation_id),
 foreign key(supersedes_judgment_id,evaluation_id) references public.human_quality_judgments(id,evaluation_id),
 check(supersedes_judgment_id is distinct from id),
 check(overall_disposition not in ('PASS','PASS_WITH_NOTES') or not jsonb_path_exists(rubric_result,'$.* ? (@ == "FAIL")')),
 check(overall_disposition<>'PASS' or not jsonb_path_exists(rubric_result,'$.* ? (@ == "CONCERN")'))
);
create index human_quality_history on public.human_quality_judgments(evaluation_id,created_at desc,id desc);
create table public.human_quality_findings (
 id uuid primary key default gen_random_uuid(),
 judgment_id uuid not null references public.human_quality_judgments(id) on delete cascade,
 issue_category text not null,
 severity text not null,
 target_kind text not null,
 target_ref jsonb not null,
 note text,
 check(essay_private.hq_finding_valid(jsonb_build_object('issue_category',issue_category,'severity',severity,'target_kind',target_kind,'target_ref',target_ref,'note',note)))
);
create index human_quality_findings_judgment on public.human_quality_findings(judgment_id);

create function essay_private.hq_immutable() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_table_name='human_quality_judgments' then
  -- RI SET NULL executes after source deletion. Only the exact erased FK may change.
  if old.reviewer_user_id is not null and new.reviewer_user_id is null
   and not exists(select 1 from auth.users where id=old.reviewer_user_id)
   and (to_jsonb(old)-'reviewer_user_id')=(to_jsonb(new)-'reviewer_user_id') then return new;end if;
  if old.reviewed_generated_rewrite_id is not null and new.reviewed_generated_rewrite_id is null
   and not exists(select 1 from public.essay_generated_rewrites where id=old.reviewed_generated_rewrite_id)
   and (to_jsonb(old)-'reviewed_generated_rewrite_id')=(to_jsonb(new)-'reviewed_generated_rewrite_id') then return new;end if;
 end if;
 raise exception 'immutable judgment: insert correction' using errcode='23514';
end$$;
create trigger human_quality_judgments_immutable before update on public.human_quality_judgments for each row execute function essay_private.hq_immutable();
create trigger human_quality_findings_immutable before update on public.human_quality_findings for each row execute function essay_private.hq_immutable();

create function public.ql_submit_human_judgment(p_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare u uuid; eid uuid; key uuid; parent uuid; rw uuid; e public.essay_evaluations; old public.human_quality_judgments; jid uuid;
 v jsonb; f jsonb; t jsonb; h text; r jsonb; k text; cnt integer; sentence_exists boolean; progress_exists boolean;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 u=auth.uid();
 perform 1 from public.quality_operators where user_id=u for key share;
 if not found then raise exception 'not authorized' using errcode='42501';end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' or octet_length(p_payload::text)>32768
  or p_payload-array['dto_version','evaluation_id','expected_output_sha256','client_submission_id','rubric_version','overall_disposition','rubric_result','selection_reason','recommended_action','summary_note','supersedes_judgment_id','findings','official_source_reviewed']<>'{}'::jsonb
  or p_payload->>'dto_version' is distinct from 'hq-write-v1' or p_payload->'official_source_reviewed' is distinct from 'true'::jsonb then
  raise exception 'invalid payload or source review not confirmed' using errcode='22023';end if;
 foreach k in array array['evaluation_id','client_submission_id','expected_output_sha256','rubric_version','overall_disposition'] loop
  if jsonb_typeof(p_payload->k) is distinct from 'string' then raise exception 'missing field' using errcode='22023';end if;
 end loop;
 eid=(p_payload->>'evaluation_id')::uuid;key=(p_payload->>'client_submission_id')::uuid;parent=(p_payload->>'supersedes_judgment_id')::uuid;
 if p_payload ? 'supersedes_judgment_id' and jsonb_typeof(p_payload->'supersedes_judgment_id') not in ('string','null') then raise exception 'invalid predecessor' using errcode='22023';end if;
 if p_payload ? 'summary_note' and jsonb_typeof(p_payload->'summary_note') not in ('string','null') then raise exception 'invalid note' using errcode='22023';end if;
 foreach k in array array['selection_reason','recommended_action'] loop
  if p_payload ? k and jsonb_typeof(p_payload->k)<>'string' then raise exception 'invalid operational field' using errcode='22023';end if;
 end loop;
 if p_payload->>'rubric_version'<>'hq-rubric-v1' or not essay_private.hq_rubric_valid(p_payload->'rubric_result')
  or jsonb_typeof(p_payload->'findings') is distinct from 'array' then raise exception 'invalid rubric/findings' using errcode='22023';end if;
 if jsonb_array_length(p_payload->'findings')>20 or char_length(p_payload->>'summary_note')>2000 then raise exception 'payload bound' using errcode='22023';end if;
 v=p_payload||jsonb_build_object('evaluation_id',eid,'client_submission_id',key,'supersedes_judgment_id',parent,'summary_note',p_payload->>'summary_note','selection_reason',coalesce(p_payload->>'selection_reason','EARLY_CENSUS'),'recommended_action',coalesce(p_payload->>'recommended_action','NONE'));
 -- Transaction-scoped global key serialization; no request body stored in a second ledger.
 perform pg_advisory_xact_lock(hashtextextended(key::text,731));
 select * into old from public.human_quality_judgments where client_submission_id=key;
 if found then
  h=encode(sha256(convert_to((v||jsonb_build_object('reviewed_generated_rewrite_id',old.reviewed_generated_rewrite_id))::text,'UTF8')),'hex');
  if old.reviewer_user_id is distinct from u or old.submission_payload_sha256<>h then raise exception 'submission key conflict' using errcode='23505';end if;
  return jsonb_build_object('dto_version','hq-write-v1','judgment_id',old.id,'replayed',true);
 end if;
 select * into e from public.essay_evaluations where id=eid for share;
 if not found then raise exception 'case not found' using errcode='P0002';end if;
 if e.status<>'completed' or e.contract_version<>'1.3' or e.output_sha256 is null
  or e.output_sha256 is distinct from p_payload->>'expected_output_sha256'
  or exists(select 1 from public.essay_improvement_progress where evaluation_id=eid and scaffolding_observation is null)
  or jsonb_typeof(e.input_snapshot->'evidence') is distinct from 'array'
  or jsonb_typeof(e.input_snapshot->'criteria') is distinct from 'array' then raise exception 'unassessable or stale subject' using errcode='22023';end if;
 if jsonb_array_length(e.input_snapshot->'evidence')=0 or jsonb_array_length(e.input_snapshot->'criteria')=0 then raise exception 'missing frozen evidence' using errcode='22023';end if;
 select exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=eid and jsonb_array_length(p.scaffolding_observation->'sentences')>0) into sentence_exists;
 select exists(select 1 from public.essay_improvement_progress p where p.evaluation_id=eid and p.previous_progress_id is not null)
   or e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id' is not null into progress_exists;
 -- Context points to erased history: do not treat missing predecessor as absent history.
 if e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id' is not null and not exists
  (select 1 from public.essay_evaluations where id=(e.input_snapshot->'scaffolding_context'->>'selected_previous_evaluation_id')::uuid) then raise exception 'prior source unavailable' using errcode='22023';end if;
 select id into rw from public.essay_generated_rewrites where evaluation_id=eid and status='completed' for share;
 r=p_payload->'rubric_result';
 if ((r->>'sentence_feedback'='NA')=sentence_exists) or ((r->>'progression'='NA')=progress_exists)
  or ((r->>'generated_rewrite'='NA')=(rw is not null)) then raise exception 'invalid conditional NA' using errcode='22023';end if;
 if parent is not null then
  perform 1 from public.human_quality_judgments where id=parent and evaluation_id=eid for update;
  if not found or exists(select 1 from public.human_quality_judgments where supersedes_judgment_id=parent) then raise exception 'invalid correction head' using errcode='23514';end if;
 end if;
 for f in select value from jsonb_array_elements(p_payload->'findings') loop
  if not essay_private.hq_finding_valid(f) then raise exception 'invalid finding shape' using errcode='22023';end if;
  if p_payload->>'overall_disposition'='PASS' or (p_payload->>'overall_disposition'='PASS_WITH_NOTES' and f->>'severity'<>'MINOR') then raise exception 'finding/disposition conflict' using errcode='23514';end if;
  t=f->'target_ref';cnt=0;
  case f->>'target_kind'
   when 'OVERALL' then cnt=1;
   when 'DIMENSION' then select count(*) into cnt from public.essay_evaluation_dimensions where evaluation_id=eid and id=(t->>'dimension_id')::uuid;
   when 'PROGRESS' then select count(*) into cnt from public.essay_improvement_progress where evaluation_id=eid and id=(t->>'progress_id')::uuid;
   when 'ISSUE_KEY' then select count(*) into cnt from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id where p.evaluation_id=eid and i.issue_key=t->>'issue_key';
   when 'SENTENCE' then select count(*) into cnt from public.essay_improvement_progress p cross join lateral jsonb_array_elements(p.scaffolding_observation->'sentences') s where p.evaluation_id=eid and p.id=(t->>'progress_id')::uuid and s->>'observation_key'=t->>'observation_key';
   when 'EVIDENCE_LINK' then select count(*) into cnt from public.essay_evaluation_evidence where evaluation_id=eid and evidence_id=(t->>'evidence_id')::uuid and dimension_id is not distinct from (t->>'dimension_id')::uuid and improvement_progress_id is not distinct from (t->>'progress_id')::uuid;
   when 'GENERATED_REWRITE' then cnt=case when rw is not null then 1 else 0 end;
   else null;
  end case;
  if cnt<>1 then raise exception 'finding target not on subject' using errcode='22023';end if;
 end loop;
 h=encode(sha256(convert_to((v||jsonb_build_object('reviewed_generated_rewrite_id',rw))::text,'UTF8')),'hex');
 insert into public.human_quality_judgments(evaluation_id,reviewed_output_sha256,reviewed_generated_rewrite_id,reviewer_user_id,rubric_version,overall_disposition,rubric_result,selection_reason,recommended_action,summary_note,supersedes_judgment_id,client_submission_id,submission_payload_sha256)
 values(eid,e.output_sha256,rw,u,v->>'rubric_version',v->>'overall_disposition',r,v->>'selection_reason',v->>'recommended_action',v->>'summary_note',parent,key,h) returning id into jid;
 insert into public.human_quality_findings(judgment_id,issue_category,severity,target_kind,target_ref,note)
 select jid,value->>'issue_category',value->>'severity',value->>'target_kind',value->'target_ref',value->>'note' from jsonb_array_elements(v->'findings');
 return jsonb_build_object('dto_version','hq-write-v1','judgment_id',jid,'replayed',false);
end$$;

create function essay_private.hq_projection(heads jsonb) returns jsonb
language plpgsql immutable set search_path='' as $$
declare n int; versions int; buckets int; bucket text; state text;
begin
 n=jsonb_array_length(heads);
 select count(distinct x->>'rubric_version'),count(distinct case x->>'overall_disposition' when 'PASS' then 'ACCEPTABLE' when 'PASS_WITH_NOTES' then 'ACCEPTABLE' when 'NEEDS_REVIEW' then 'WITH_CONCERNS' else 'FAILED' end),min(case x->>'overall_disposition' when 'PASS' then 'ACCEPTABLE' when 'PASS_WITH_NOTES' then 'ACCEPTABLE' when 'NEEDS_REVIEW' then 'WITH_CONCERNS' else 'FAILED' end)
 into versions,buckets,bucket from jsonb_array_elements(heads) x;
 state=case when n=0 then 'UNREVIEWED' when n=1 then 'REVIEWED_'||bucket when versions>1 then 'MULTIPLE_REVIEWS' when buckets>1 then 'DISAGREEMENT' else 'MULTIPLE_REVIEWS' end;
 return jsonb_build_object('human_review_state',state,'active_count',n,'comparison_status',case when versions>1 then 'NOT_COMPARABLE' else 'COMPARABLE' end,'consensus_bucket',case when versions<=1 and buckets=1 then bucket else null end);
end$$;
create function public.ql_review_state(p_evaluation_ids uuid[]) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare eid uuid; heads jsonb; item jsonb; result jsonb:='[]'; total int; latest timestamptz; material boolean;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 if p_evaluation_ids is null or cardinality(p_evaluation_ids)>100 or array_position(p_evaluation_ids,null) is not null or coalesce(array_ndims(p_evaluation_ids),1)>1 then raise exception 'invalid batch' using errcode='22023';end if;
 for eid in select distinct x from unnest(p_evaluation_ids) x order by x loop
  if not exists(select 1 from public.essay_evaluations where id=eid) then result=result||jsonb_build_array(jsonb_build_object('evaluation_id',eid,'availability','NOT_FOUND'));continue;end if;
  select count(*) into total from public.human_quality_judgments where evaluation_id=eid;
  select coalesce(jsonb_agg(jsonb_build_object('rubric_version',j.rubric_version,'overall_disposition',j.overall_disposition)),'[]'),max(j.created_at),coalesce(bool_or(exists(select 1 from public.human_quality_findings f where f.judgment_id=j.id and f.severity in ('MATERIAL','CRITICAL'))),false)
  into heads,latest,material from public.human_quality_judgments j where j.evaluation_id=eid and not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id);
  item=essay_private.hq_projection(heads)||jsonb_build_object('evaluation_id',eid,'availability','AVAILABLE','total_count',total,'latest_human_reviewed_at',latest,'has_material_issue',material);
  result=result||jsonb_build_array(item);
 end loop;
 return jsonb_build_object('dto_version','hq-read-v1','cases',result);
end$$;
create function public.ql_list_human_judgments(p_evaluation_id uuid,p_limit integer default 20,p_before timestamptz default null,p_before_id uuid default null) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare n int:=least(100,greatest(1,coalesce(p_limit,20))); v jsonb;
begin
 if not public.is_quality_operator() then raise exception 'not authorized' using errcode='42501';end if;
 if (p_before is null)<>(p_before_id is null) then raise exception 'paired cursor required' using errcode='22023';end if;
 if not exists(select 1 from public.essay_evaluations where id=p_evaluation_id) then raise exception 'case not found' using errcode='P0002';end if;
 with page as materialized(select * from public.human_quality_judgments where evaluation_id=p_evaluation_id and (p_before is null or (created_at,id)<(p_before,p_before_id)) order by created_at desc,id desc limit n+1),
 shown as materialized(select * from page order by created_at desc,id desc limit n)
 select jsonb_build_object('dto_version','hq-read-v1','judgments',coalesce((select jsonb_agg(
  (to_jsonb(j)-array['submission_payload_sha256','client_submission_id'])||jsonb_build_object('reviewer_state',case when j.reviewer_user_id is null then 'DELETED_OR_UNAVAILABLE' else 'AVAILABLE' end,
   'is_active',not exists(select 1 from public.human_quality_judgments s where s.supersedes_judgment_id=j.id),
   'findings',coalesce((select jsonb_agg(to_jsonb(f)-'judgment_id' order by f.id) from public.human_quality_findings f where f.judgment_id=j.id),'[]'::jsonb)) order by j.created_at desc,j.id desc) from shown j),'[]'::jsonb),
  'next_cursor',case when (select count(*) from page)>n then (select jsonb_build_object('created_at',created_at,'judgment_id',id) from shown order by created_at,id limit 1) else null end) into v;
 return v;
end$$;

alter table public.human_quality_judgments owner to postgres;
alter table public.human_quality_findings owner to postgres;
alter table public.human_quality_judgments enable row level security;
alter table public.human_quality_findings enable row level security;
revoke all on public.human_quality_judgments,public.human_quality_findings from public,anon,authenticated,service_role;
alter function essay_private.hq_rubric_valid(jsonb) owner to postgres;
alter function essay_private.hq_finding_valid(jsonb) owner to postgres;
alter function essay_private.hq_immutable() owner to postgres;
alter function essay_private.hq_projection(jsonb) owner to postgres;
revoke all on function essay_private.hq_rubric_valid(jsonb),essay_private.hq_finding_valid(jsonb),essay_private.hq_immutable(),essay_private.hq_projection(jsonb) from public,anon,authenticated,service_role;
alter function public.ql_submit_human_judgment(jsonb) owner to postgres;
alter function public.ql_review_state(uuid[]) owner to postgres;
alter function public.ql_list_human_judgments(uuid,integer,timestamptz,uuid) owner to postgres;
revoke all on function public.ql_submit_human_judgment(jsonb),public.ql_review_state(uuid[]),public.ql_list_human_judgments(uuid,integer,timestamptz,uuid) from public,anon,authenticated,service_role;
grant execute on function public.ql_submit_human_judgment(jsonb),public.ql_review_state(uuid[]),public.ql_list_human_judgments(uuid,integer,timestamptz,uuid) to authenticated;
commit;
