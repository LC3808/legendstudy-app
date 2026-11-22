-- OWNER APPROVAL REQUIRED. No production student action or backfill.
begin;
set local lock_timeout='5s';
do $$declare x record;begin
 for x in select * from (values ('essay_exam_private.finish(uuid,jsonb,boolean)','d97e32341f90484d1d3523265172d6a3'),('essay_ops_private.guard_run_action()','a1c345df384e9696a8ed728edc3466bd'),('admin_lab_manage_run(uuid,text,uuid)','d8292b35fd49688f562a9bf5c90dd77e'),('admin_lab_run_capabilities(uuid)','0b405804182b44684361fad93a189199'),('essay_exam_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb)','c3bfd5bac836e575beedec18579177f8'),('essay_exam_claim(uuid,uuid,uuid)','c464c30ec66964791641febe4e89eea6'),('essay_exam_finish(uuid,uuid,uuid,jsonb,boolean)','b2ff3dce059d8a5d6b3652094c6a757a'),('essay_exam_retry(uuid,uuid,uuid,uuid)','b505a07b40ff3bbb9490705adf426164'),('essay_exam_session_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb)','f91ff6befbf0e476fbf0b2e374630a52'),('essay_exam_session_claim(uuid,uuid,uuid)','a24b1173fbe782846526d228c7b00a64')) v(signature,expected_md5) loop
  if md5(pg_get_functiondef(x.signature::regprocedure))<>x.expected_md5 then raise exception 'PREIMAGE_CHANGED: %',x.signature;end if;
 end loop;
 if to_regprocedure('public.admin_lab_run_recovery(uuid)') is not null then raise exception 'RECOVERY_ALREADY_INSTALLED';end if;
 if (select pg_get_constraintdef(oid) from pg_constraint where conrelid='essay_ops_private.run_actions'::regclass and conname='run_actions_action_check') is distinct from 'CHECK ((action = ANY (ARRAY[''retry''::text, ''delete''::text, ''archive''::text, ''restore''::text])))' then raise exception 'AUDIT_CONSTRAINT_CHANGED';end if;
end$$;
do $$declare x record;p pg_proc;begin for x in select * from (values ('essay_exam_private.finish(uuid,jsonb,boolean)','postgres','["postgres=X/postgres"]'::jsonb),('essay_ops_private.guard_run_action()','postgres','["postgres=X/postgres"]'::jsonb),('admin_lab_manage_run(uuid,text,uuid)','postgres','["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb),('admin_lab_run_capabilities(uuid)','postgres','["postgres=X/postgres", "authenticated=X/postgres"]'::jsonb),('essay_exam_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb)','postgres','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb),('essay_exam_claim(uuid,uuid,uuid)','postgres','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb),('essay_exam_finish(uuid,uuid,uuid,jsonb,boolean)','postgres','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb),('essay_exam_retry(uuid,uuid,uuid,uuid)','postgres','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb),('essay_exam_session_checkpoint(uuid,uuid,uuid,text,text,uuid,jsonb)','postgres','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb),('essay_exam_session_claim(uuid,uuid,uuid)','postgres','["postgres=X/postgres", "essay_worker=X/postgres"]'::jsonb)) v(signature,owner_name,acl) loop select * into p from pg_proc where oid=x.signature::regprocedure;if pg_get_userbyid(p.proowner)<>x.owner_name or to_jsonb(p.proacl) is distinct from x.acl then raise exception 'PREIMAGE_ACL_CHANGED: %',x.signature;end if;end loop;end$$;
do $$declare x record;begin for x in select * from (values ('checkpoints_check','CHECK (((state = ''checkpoint''::text) = (payload IS NOT NULL)))'),('checkpoints_payload_check','CHECK (((payload IS NULL) OR ((jsonb_typeof(payload) = ''object''::text) AND (octet_length((payload)::text) <= 8388608))))'),('checkpoints_state_check','CHECK ((state = ANY (ARRAY[''pending''::text, ''checkpoint''::text])))')) v(name,definition) loop if (select pg_get_constraintdef(oid) from pg_constraint where conrelid='essay_exam_private.checkpoints'::regclass and conname=x.name) is distinct from x.definition then raise exception 'CHECKPOINT_INVARIANT_CHANGED: %',x.name;end if;end loop;end$$;
alter table essay_ops_private.run_actions drop constraint run_actions_action_check;
alter table essay_ops_private.run_actions add constraint run_actions_action_check check(action in('retry','delete','archive','restore','recover'));
-- New helpers are private and never grant raw recovery context to authenticated users.
create function essay_ops_private.recovery_key(p_key uuid) returns uuid language sql immutable set search_path='' as $$select md5('essay-recovery-terminal/'||p_key)::uuid$$;
create function essay_ops_private.recovery_retry_key(p_key uuid) returns uuid language sql immutable set search_path='' as $$select md5('essay-recovery-retry/'||p_key)::uuid$$;

create function essay_ops_private.recovery_replay(p_outcome jsonb) returns jsonb language plpgsql stable set search_path='' as $$
declare r essay_exam_private.runs;t essay_exam_private.retry_requests;
begin
 if p_outcome->>'state'<>'queued' then return p_outcome-'diagnosis_token';end if;
 select * into r from essay_exam_private.runs where id=(p_outcome->>'run_id')::uuid;
 select * into t from essay_exam_private.retry_requests where run_id=r.id order by generation desc limit 1;
 if r.id is null or t.request_key::text is distinct from p_outcome->>'retry_key' or t.generation::text is distinct from p_outcome->>'generation' or exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=r.id and h.hidden) then
  return (p_outcome-'diagnosis_token')||jsonb_build_object('state','blocked','operation','blocked','dispatch_required',false,'success',false,'reason','REPLAY_NOT_DISPATCHABLE');
 elsif r.state='completed' then return (p_outcome-'diagnosis_token')||jsonb_build_object('state','completed','operation','completed','dispatch_required',false,'success',true,'reason',null,'after_state','completed');
 elsif r.state='reserved' and t.lease_until>now() then return p_outcome-'diagnosis_token';
 end if;
 return (p_outcome-'diagnosis_token')||jsonb_build_object('state','blocked','operation','blocked','dispatch_required',false,'success',false,'reason','REPLAY_NOT_DISPATCHABLE');
end$$;

create function essay_ops_private.recovery_digest(p_run uuid) returns text language sql stable set search_path='' as $$
 select encode(extensions.digest(jsonb_build_object('run',to_jsonb(r),
 'parent_result',(select p.result from essay_exam_private.runs p where p.id=r.parent_id),
 'checkpoints',(select jsonb_agg(to_jsonb(c) order by key) from essay_exam_private.checkpoints c where c.run_id=r.id),
 'retries',(select jsonb_agg(to_jsonb(t) order by generation) from essay_exam_private.retry_requests t where t.run_id=r.id),
 'billing',(select to_jsonb(b) from public.essay_billing_decisions b where b.id=r.decision_id),
 'ledger',(select jsonb_agg(to_jsonb(t) order by id) from public.credit_transactions t where t.decision_id=r.decision_id),
 'hidden',(select to_jsonb(h) from essay_ops_private.hidden_runs h where h.run_id=r.id))::text,'sha256'),'hex')
 from essay_exam_private.runs r where r.id=p_run
$$;

create function essay_ops_private.recovery_diagnosis(p_run uuid) returns jsonb language plpgsql stable set search_path='' as $$
declare r essay_exam_private.runs;b public.essay_billing_decisions; a jsonb; q jsonb; c essay_exam_private.checkpoints;rv essay_exam_private.checkpoints;us essay_exam_private.checkpoints;
 attempts jsonb; retry_time timestamptz; retry_lease timestamptz; live boolean; hidden boolean; reason text; typ text; method text;
 qs jsonb='[]';targets jsonb='[]';i int;n int;k text; readiness text;qreason text; total int;done int=0;failed int=0;recoverable int=0;unresolved int=0;
 lc int;reserved int;consumed int;released int;refunded int;bad_ledger boolean;consistent boolean;recovery_eligible boolean;reserved_current int; final_cp essay_exam_private.checkpoints;err jsonb;
begin
 select * into r from essay_exam_private.runs where id=p_run;
 if r.id is null then raise sqlstate 'PT404' using message='RUN_NOT_FOUND';end if;
 select * into b from public.essay_billing_decisions where id=r.decision_id;
 select t.attempts,t.created_at,t.lease_until into attempts,retry_time,retry_lease from essay_exam_private.retry_requests t where run_id=p_run order by generation desc limit 1;
 attempts=coalesce(attempts,'{}');total=jsonb_array_length(r.snapshot->'answers');
 live=coalesce(r.lease_until>now(),false) or exists(select 1 from essay_exam_private.retry_requests where run_id=p_run and lease_until>now());
 hidden=exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=p_run and h.hidden);
 select count(*),coalesce(sum(reserved_delta) filter(where transaction_type='reserve'),0),coalesce(-sum(balance_delta) filter(where transaction_type='consume'),0),coalesce(-sum(reserved_delta) filter(where transaction_type='release'),0),coalesce(sum(balance_delta) filter(where transaction_type='refund'),0),
 coalesce(bool_or(account_id<>r.account_id or transaction_type<>'reserve' or balance_delta<>0 or reserved_delta<=0),false)
 into lc,reserved,consumed,released,refunded,bad_ledger from public.credit_transactions where decision_id=r.decision_id;
 recovery_eligible=b.id is not null and b.account_id=r.account_id and b.status='reserved' and b.credits_required in(0,1) and not bad_ledger and reserved=b.credits_required and lc=b.credits_required
 and not exists(select 1 from essay_exam_private.runs x where x.decision_id=r.decision_id and x.id<>r.id);
 select coalesce(sum(reserved_delta),0) into reserved_current from public.credit_transactions where decision_id=r.decision_id;
consistent=b.id is not null and b.account_id=r.account_id and b.credits_required in(0,1) and
case b.status when 'reserved' then recovery_eligible
when 'settled' then reserved=b.credits_required and consumed=b.credits_required and released=0 and refunded=0 and reserved_current=0 and not exists(select 1 from public.credit_transactions t where t.decision_id=r.decision_id and (t.account_id<>r.account_id or t.transaction_type not in('reserve','consume')))
when 'released' then reserved=b.credits_required and released=b.credits_required and consumed=0 and refunded=0 and reserved_current=0 and not exists(select 1 from public.credit_transactions t where t.decision_id=r.decision_id and (t.account_id<>r.account_id or t.transaction_type not in('reserve','release')))
when 'authorized' then lc=0 when 'rejected' then lc=0 else false end;
 select * into final_cp from essay_exam_private.checkpoints where run_id=p_run and key='final';
 for i in 0..total-1 loop
  a=r.snapshot->'answers'->i;n=coalesce((attempts->>i::text)::int,0);k='q'||i||case when n=0 then '' else '-retry-'||n end;
  select * into c from essay_exam_private.checkpoints where run_id=p_run and key=k;
  select * into rv from essay_exam_private.checkpoints where run_id=p_run and key=k||'-reviewed';
  select * into us from essay_exam_private.checkpoints where run_id=p_run and key=k||'-usage';
  qreason=null;
  if c.state='checkpoint' and c.payload->>'state'='completed' then
   readiness='completed';done=done+1;
  elsif c.state='checkpoint' and c.payload->>'state'='failed' and c.payload->'output'='null'::jsonb then
   readiness='retryable';failed=failed+1;targets=targets||jsonb_build_array(a->>'questionId');
   select case when x.payload->>'code' ~ '^[A-Z_0-9]{1,80}$' then x.payload->>'code' end into qreason from essay_exam_private.checkpoints x where x.run_id=p_run and x.key like 'q'||i||'-a'||n||'-validation-failure-%' limit 1;
  elsif c.state='pending' and rv.state='checkpoint' and us.state='checkpoint'
    and rv.payload->>'p_run'=p_run::text and rv.payload->>'p_token'=r.lease_token::text
    and us.payload->>'p_run'=p_run::text and us.payload->>'p_token'=r.lease_token::text
    and rv.payload->>'p_evaluation'=us.payload->>'p_evaluation'
    and jsonb_typeof(rv.payload->'p_output')='object' and rv.payload->'p_output'<>'{}'::jsonb
    and (rv.payload#>>'{p_output,contract_version}'='math-eval-v1' or exists(select 1 from essay_exam_private.checkpoints x where x.run_id=p_run and x.key='q'||i||'-a'||n||'-review' and x.state='checkpoint')) then
   readiness='recoverable';recoverable=recoverable+1;targets=targets||jsonb_build_array(a->>'questionId');
  elsif c.state='checkpoint' and c.payload->>'state'='reconciling' and c.payload->'output'='null'::jsonb
    and rv.run_id is null and us.run_id is null
    and not exists(select 1 from essay_exam_private.checkpoints x where x.run_id=p_run and x.key like 'q'||i||'-a'||n||'-%' and x.key<>'q'||i||'-a'||n||'-execution-failure')
    and exists(select 1 from essay_exam_private.checkpoints x where x.run_id=p_run and x.key='q'||i||'-a'||n||'-execution-failure' and x.payload->>'stage'='provider' and x.payload->>'provider_call'='possible') then
   readiness='uncertain';unresolved=unresolved+1;qreason='OWNER_EXECUTION_APPROVAL_REQUIRED';
  else readiness='unresolved';unresolved=unresolved+1;qreason='RECONCILIATION_REQUIRED';end if;
  qs=qs||jsonb_build_array(jsonb_build_object('index',i,'question_id',a->>'questionId','attempt',n,'key',k,'state',coalesce(c.payload->>'state',c.state,'missing'),'readiness',readiness,'reason',qreason,
   'review_failures',(select coalesce(jsonb_agg(jsonb_build_object('check',z.key,'decision',z.value->>'decision','reason',left(z.value->>'reason',600))),'[]') from jsonb_each(coalesce((select x.payload#>'{assessment,checks}' from essay_exam_private.checkpoints x where x.run_id=p_run and x.state='checkpoint' and x.key ~ ('^q'||i||'-a'||n||'-quality-review-[0-3]$') and x.payload->>'accepted'='false' order by x.key desc limit 1),'{}'))z where z.value->>'decision' in('fail','uncertain'))));
 end loop;
 if hidden then reason='RUN_ARCHIVED';elsif r.state<>'reserved' then reason='FINALIZED_RUN';elsif live then reason='ACTIVE_LEASE';
 elsif r.dispatch_key is null or r.lease_token is null then reason='DISPATCH_NOT_CONFIRMED';
 elsif recovery_eligible is not true then reason='LEDGER_RECONCILIATION_REQUIRED';
 elsif total=0 or unresolved>0 then reason='RECONCILIATION_REQUIRED';
 elsif exists(select 1 from essay_exam_private.checkpoints x where x.run_id=p_run and x.state='pending' and x.key not in('final','summary') and not exists(select 1 from jsonb_array_elements(qs) z where z->>'key'=x.key and z->>'readiness'='recoverable')) then reason='RECONCILIATION_REQUIRED';
 elsif exists(select 1 from jsonb_array_elements(qs) z join essay_exam_private.checkpoints x on x.run_id=p_run and x.key='q'||(z->>'index')||'-a'||(z->>'attempt')||'-execution-failure' where x.payload->>'provider_call'='possible' and z->>'readiness' not in('completed','retryable')) then reason='RECONCILIATION_REQUIRED';
 end if;
 if failed>0 and exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and key ~ '^q[0-9]+-a[0-9]+-quality-policy$') then reason=coalesce(reason,'ADMIN_QUALITY_REVIEW_REQUIRED');end if;
 if failed>0 then typ=case when recoverable>0 then 'D' when done>0 then 'B' else 'C' end;method=case when recoverable>0 then 'verify_then_retry' else 'retry_failed' end;
  if final_cp.run_id is not null or exists(select 1 from essay_exam_private.checkpoints where run_id=p_run and key='summary') then reason=coalesce(reason,'FINAL_CHECKPOINT_CONFLICT');end if;
 else typ=case when final_cp.state='checkpoint' and final_cp.payload->'failed'='false'::jsonb then 'A' else 'D' end;method=case when typ='A' then 'finish_saved' else 'restore_reviewed' end;
  if final_cp.state='checkpoint' and final_cp.payload->'failed' is distinct from 'false'::jsonb then reason=coalesce(reason,'FINAL_CHECKPOINT_CONFLICT');end if;
 end if;
 select jsonb_build_object('code',case when payload->>'code'~'^[A-Z_0-9]{1,80}$' then payload->>'code' end,'stage',case when payload->>'stage'~'^[a-z_]{1,40}$' then payload->>'stage' end) into err
 from essay_exam_private.checkpoints cp where cp.run_id=p_run and cp.payload->>'component' in('execution_failure','validation_failure') and exists(select 1 from jsonb_array_elements(qs) z where cp.key like 'q'||(z->>'index')||'-a'||(z->>'attempt')||'-%') order by cp.key limit 1;
 return jsonb_build_object('version','admin-run-recovery-v1','run_id',p_run,'subject_id',(select user_id from public.credit_accounts where id=r.account_id),'exam_id',r.exam_id,
 'as_of',now(),'created_at',r.created_at,'last_execution_at',null,'last_retry_at',retry_time,'last_state_change_at',r.completed_at,'state',r.state,'hidden',hidden,'active_lease',live,'lease_until',greatest(r.lease_until,retry_lease),
 'retry_count',(select count(*) from essay_exam_private.retry_requests where run_id=p_run),'diagnosis_token',essay_ops_private.recovery_digest(p_run),
 'worker_state',case when live then 'active' when unresolved>0 then 'response_uncertain' when r.lease_until is null then 'unknown' else 'inactive' end,'recent_error',err,'error_scope','One confirmed diagnostic from current question attempts; occurrence time is not recorded.',
 'counts',jsonb_build_object('total',total,'completed',done,'failed',failed,'recoverable',recoverable,'unresolved',unresolved,'stored_result',case when jsonb_typeof(r.result->'questions')='array' then jsonb_array_length(r.result->'questions') else 0 end),
 'questions',qs,'billing',jsonb_build_object('status',b.status,'credits_required',b.credits_required,'reserved',reserved_current,'reserved_total',reserved,'recovery_eligible',recovery_eligible,'consumed',consumed,'released',released,'refunded',refunded,'ledger_count',lc,'consistent',consistent),
 'recovery',jsonb_build_object('allowed',reason is null,'type',typ,'method',method,'reason',reason,'target_question_ids',targets,'rerun_question_count',failed,'additional_credit',0,'preserve_existing',true),
 'quality_review',jsonb_build_object('waiting',coalesce(reason='ADMIN_QUALITY_REVIEW_REQUIRED',false),
 'partial_calls',(select count(*) from essay_exam_private.checkpoints where run_id=p_run and key ~ '-quality-partial-[12]$'),
 'full_calls',(select count(*) from essay_exam_private.checkpoints where run_id=p_run and key ~ '-quality-full-1$'),
 'last_execution_at',(select max(payload->>'started_at') from essay_exam_private.checkpoints where run_id=p_run and key ~ '-quality-(policy|.*-started)$'),
 'recommendation','Review failed checks and preserved candidates; no automatic completion or extra retry.'),
 'uncertain_recovery',jsonb_build_object('allowed',reason='RECONCILIATION_REQUIRED' and not live and not hidden and recovery_eligible and r.state='reserved'
  and r.dispatch_key is not null and r.lease_token is not null and final_cp.run_id is null
  and not exists(select 1 from essay_exam_private.checkpoints x where x.run_id=p_run and (x.state='pending' or x.key='summary'))
  and exists(select 1 from jsonb_array_elements(qs) z where z->>'readiness'='uncertain')
  and not exists(select 1 from jsonb_array_elements(qs) z where z->>'readiness' not in('completed','retryable','uncertain')),
  'reason','OWNER_EXECUTION_APPROVAL_REQUIRED'),
 'history',(select coalesce(jsonb_agg(jsonb_build_object('action_id',x.outcome->>'action_id','actor',x.actor,'recorded_at',x.recorded_at,'state',x.outcome->>'state','operation',x.outcome->>'operation','recovery_type',x.outcome->>'recovery_type','reason',x.outcome->>'reason','before_state',x.outcome->>'before_state','after_state',x.outcome->>'after_state') order by x.recorded_at desc),'[]') from(select * from essay_ops_private.run_actions where run_id=p_run and action='recover' order by recorded_at desc limit 20)x));
end $$;

create function public.admin_lab_run_recovery(p_run uuid) returns jsonb language plpgsql stable security definer set search_path='' set statement_timeout='8s' as $$
begin perform essay_ops_private.require_admin();return essay_ops_private.recovery_diagnosis(p_run);end$$;

create function essay_ops_private.recovery_receipt(p_run uuid,p_key uuid,p_diag jsonb,p_state text,p_operation text,p_reason text default null) returns jsonb language sql stable set search_path='' as $$
 select jsonb_build_object('version','admin-run-recovery-v1','run_id',p_run,'subject_id',p_diag->'subject_id','exam_id',p_diag->'exam_id','action','recover','action_id',p_key,'operation',p_operation,'state',p_state,
 'recovery_type',p_diag#>>'{recovery,type}','dispatch_required',false,'reason',p_reason,'success',p_state='completed','before_state',p_diag->>'state','after_state',case when p_state='completed' then 'completed' else p_diag->>'state' end)
$$;

create function public.admin_lab_recover_run(p_run uuid,p_key uuid,p_diagnosis_token text,p_allow_uncertain boolean default false) returns jsonb language plpgsql security definer set search_path='' set statement_timeout='12s' as $$
declare r essay_exam_private.runs;actor uuid;subject uuid;d jsonb;outcome jsonb;old essay_ops_private.run_actions;terminal essay_ops_private.run_actions;retry jsonb;retry_key uuid;
begin
 perform essay_ops_private.require_admin();actor=auth.uid();
 if p_run is null or p_key is null or p_diagnosis_token is null or p_diagnosis_token !~ '^[0-9a-f]{64}$' then raise invalid_parameter_value;end if;
 select a.user_id into subject from essay_exam_private.runs x join public.credit_accounts a on a.id=x.account_id where x.id=p_run;
 if subject is null then raise sqlstate 'PT404' using message='RUN_NOT_FOUND';end if;
 perform math_private.require_active(array[actor,subject]);
 perform 1 from public.credit_accounts where user_id=subject for update;
 select * into r from essay_exam_private.runs where id=p_run for update;
 perform 1 from public.essay_billing_decisions where id=r.decision_id for update;
 select * into old from essay_ops_private.run_actions where id=p_key;
 if found then
  if old.actor<>actor or old.run_id<>p_run or old.action<>'recover' or old.outcome->>'diagnosis_token' is distinct from p_diagnosis_token or coalesce((old.outcome->>'uncertain_approved')::boolean,false) is distinct from p_allow_uncertain then raise sqlstate 'PT409' using message='ACTION_KEY_CONFLICT';end if;
  select * into terminal from essay_ops_private.run_actions where id=essay_ops_private.recovery_key(p_key);
  if terminal.id is not null then if terminal.actor<>old.actor or terminal.run_id<>old.run_id or terminal.action<>'recover' or terminal.outcome->>'action_id'<>p_key::text then raise sqlstate 'PT409' using message='ACTION_KEY_CONFLICT';end if;outcome=terminal.outcome;else outcome=old.outcome;end if;
  return essay_ops_private.recovery_replay(outcome);
 end if;
 if exists(select 1 from essay_ops_private.run_actions where id=essay_ops_private.recovery_key(p_key)) then raise sqlstate 'PT409' using message='ACTION_KEY_CONFLICT';end if;
 d=essay_ops_private.recovery_select(essay_ops_private.recovery_diagnosis(p_run),p_allow_uncertain);
 if d->>'diagnosis_token'<>p_diagnosis_token then outcome=essay_ops_private.recovery_receipt(p_run,p_key,d,'blocked','blocked','DIAGNOSIS_CHANGED');
 elsif (d#>>'{recovery,allowed}')::boolean is not true then outcome=essay_ops_private.recovery_receipt(p_run,p_key,d,'blocked','blocked',d#>>'{recovery,reason}');
 else outcome=essay_ops_private.recovery_receipt(p_run,p_key,d,'verification_required',case when d#>>'{recovery,method}' in('verify_then_retry','retry_failed') then 'verify_then_retry' else 'verify_saved' end);
 end if;
 outcome=outcome||jsonb_build_object('diagnosis_token',p_diagnosis_token,'uncertain_approved',p_allow_uncertain);
 insert into essay_ops_private.run_actions(id,run_id,actor,action,outcome) values(p_key,p_run,actor,'recover',outcome);
 return outcome-'diagnosis_token';
end$$;

create function public.essay_exam_recovery_finish(p_key uuid,p_diagnosis_token text,p_result jsonb,p_proof jsonb) returns jsonb language plpgsql security definer set search_path='' set statement_timeout='15s' as $$
declare a essay_ops_private.run_actions; terminal essay_ops_private.run_actions;r essay_exam_private.runs;d jsonb;outcome jsonb;subject uuid;
 q jsonb;proof jsonb;result_q jsonb;c essay_exam_private.checkpoints;rv essay_exam_private.checkpoints;us essay_exam_private.checkpoints;review essay_exam_private.checkpoints;fc essay_exam_private.checkpoints;
 k text;prefix text;count_ready int=0;summary text='';result_state text;retry jsonb;retry_key uuid;restored int=0;recovery_stage text='validation';mixed boolean;is_math boolean;expected_telemetry jsonb;
begin
 a=essay_ops_private.recovery_intent(p_key);
 select u.user_id into subject from essay_exam_private.runs x join public.credit_accounts u on u.id=x.account_id where x.id=a.run_id;
 perform 1 from public.credit_accounts where user_id=subject for update;
 select * into r from essay_exam_private.runs where id=a.run_id for update;
 perform 1 from public.essay_billing_decisions where id=r.decision_id for update;
 select * into terminal from essay_ops_private.run_actions where id=essay_ops_private.recovery_key(p_key);
 if terminal.id is not null then
  if terminal.actor<>a.actor or terminal.run_id<>r.id or terminal.action<>'recover' or terminal.outcome->>'action_id'<>p_key::text then raise sqlstate 'PT409' using message='ACTION_KEY_CONFLICT';end if;
  outcome=terminal.outcome;
  return essay_ops_private.recovery_replay(outcome);
 end if;
 d=essay_ops_private.recovery_select(essay_ops_private.recovery_diagnosis(r.id),coalesce((a.outcome->>'uncertain_approved')::boolean,false));mixed=a.outcome->>'operation'='verify_then_retry';
 if p_diagnosis_token is distinct from a.outcome->>'diagnosis_token' or d->>'diagnosis_token' is distinct from p_diagnosis_token then outcome=essay_ops_private.recovery_receipt(r.id,p_key,d,'blocked','blocked','DIAGNOSIS_CHANGED');
 elsif (d#>>'{recovery,allowed}')::boolean is not true then outcome=essay_ops_private.recovery_receipt(r.id,p_key,d,'blocked','blocked',d#>>'{recovery,reason}');
 elsif p_result is null and jsonb_typeof(p_proof)='object' and (select count(*) from jsonb_object_keys(p_proof))=1 and p_proof->>'failure_code' in('ARTIFACT_VERIFICATION_FAILED','RECOVERY_RUNTIME_UNAVAILABLE','UNSUPPORTED_RECOVERY_ENGINE') then outcome=essay_ops_private.recovery_receipt(r.id,p_key,d,'blocked','blocked',p_proof->>'failure_code');
 else
  begin
   if jsonb_typeof(p_result) is distinct from 'object' or jsonb_typeof(p_result->'questions') is distinct from 'array' or jsonb_typeof(p_proof->'questions') is distinct from 'array' or coalesce(p_proof->>'result_sha256','') !~ '^[0-9a-f]{64}$' then raise exception 'RECOVERY_PROOF_INVALID';end if;
   if mixed is distinct from (d#>>'{recovery,method}' in('verify_then_retry','retry_failed')) then raise exception 'RECOVERY_OPERATION_CHANGED';end if;
   for q in select value from jsonb_array_elements(d->'questions') order by (value->>'index')::int loop
    if q->>'readiness' in('retryable','uncertain') and mixed then continue;end if;
    if q->>'readiness' not in('completed','recoverable') then raise exception 'RECOVERY_PROOF_INVALID';end if;
    recovery_stage='validation';count_ready=count_ready+1;k=q->>'key';prefix='q'||(q->>'index')||'-a'||(q->>'attempt');
    select * into c from essay_exam_private.checkpoints where run_id=r.id and key=k;
    select * into rv from essay_exam_private.checkpoints where run_id=r.id and key=k||'-reviewed';
    select * into us from essay_exam_private.checkpoints where run_id=r.id and key=k||'-usage';
    select * into review from essay_exam_private.checkpoints where run_id=r.id and key=prefix||'-review';
    select x into proof from jsonb_array_elements(p_proof->'questions') x where x->>'question_id'=q->>'question_id';
    select x into result_q from jsonb_array_elements(p_result->'questions') x where x->>'questionId'=q->>'question_id';
    is_math=rv.payload#>>'{p_output,contract_version}'='math-eval-v1';
    if proof is null or result_q is null or rv.state is distinct from 'checkpoint' or us.state is distinct from 'checkpoint' or (not coalesce(is_math,false) and review.state is distinct from 'checkpoint')
     or coalesce(proof->>'claim_sha256','') !~ '^[0-9a-f]{64}$' or coalesce(proof->>'output_sha256','') !~ '^[0-9a-f]{64}$' or coalesce(proof->>'package_sha256','') !~ '^[0-9a-f]{64}$'
     or rv.payload->>'p_run' is distinct from r.id::text or rv.payload->>'p_token' is distinct from r.lease_token::text
     or us.payload->>'p_run' is distinct from r.id::text or us.payload->>'p_token' is distinct from r.lease_token::text
     or rv.payload->>'p_evaluation' is distinct from proof->>'evaluation_id' or us.payload->>'p_evaluation' is distinct from proof->>'evaluation_id'
     or (not coalesce(is_math,false) and (false or review.payload->>'evaluation_id' is distinct from proof->>'evaluation_id' or review.payload->>'output_sha256' is distinct from proof->>'output_sha256' or review.payload->>'package_sha256' is distinct from proof->>'package_sha256'
 or jsonb_typeof(review.payload->'quality') is distinct from 'object' or (select count(*) from jsonb_each(review.payload->'quality'))<>8 or exists(select 1 from jsonb_each(review.payload->'quality') x where x.value<>'true'::jsonb)
))
     or result_q->'evaluation' is distinct from rv.payload->'p_output' or jsonb_typeof(result_q->'evaluation') is distinct from 'object' or result_q->'evaluation'='{}'::jsonb
     or result_q->>'rubricVersion' is distinct from r.snapshot->'answers'->((q->>'index')::int)->>'rubricVersion' or result_q->>'evidenceVersion' is distinct from r.snapshot->'answers'->((q->>'index')::int)->>'evidenceVersion'
     or jsonb_typeof(result_q->'criteria') is distinct from 'array' or jsonb_array_length(result_q->'criteria')=0 then raise exception 'RECOVERY_PROOF_INVALID';end if;
    expected_telemetry=jsonb_build_object('input_tokens',us.payload->'p_input_tokens','output_tokens',us.payload->'p_output_tokens','total_tokens',us.payload->'p_total_tokens','latency_ms',us.payload->'p_latency_ms','cost_amount',us.payload->'p_cost_amount','currency',us.payload->'p_currency');
    if result_q->'telemetry' is distinct from expected_telemetry then raise exception 'RECOVERY_USAGE_MISMATCH';end if;
    if c.state='checkpoint' then
     if c.payload->>'state'<>'completed' or c.payload->>'evaluation_id' is distinct from proof->>'evaluation_id' or c.payload->>'claim_sha256' is distinct from proof->>'claim_sha256' or c.payload->'output' is distinct from result_q->'evaluation' then raise exception 'RECOVERY_CHECKPOINT_MISMATCH';end if;
    elsif c.state='pending' then
     -- Proven original reviewed output; use the unchanged writer/token RPC, never steal or create a claim.
     recovery_stage='restore';perform public.essay_exam_checkpoint(subject,r.id,r.lease_token,k,'write',c.writer,jsonb_build_object('evaluation_id',proof->>'evaluation_id','claim_sha256',proof->>'claim_sha256','state','completed','output',result_q->'evaluation'));
     restored=restored+1;
    else raise exception 'RECOVERY_CHECKPOINT_MISSING';end if;
    if jsonb_typeof(result_q#>'{evaluation,summary}') is distinct from 'string' or length(btrim(result_q#>>'{evaluation,summary}'))=0 then raise exception 'RECOVERY_SUMMARY_INVALID';end if;
    summary=summary||case when count_ready=1 then '' else E'\n\n' end||(result_q#>>'{evaluation,summary}');
   end loop;
   if (count_ready=0 and not mixed) or jsonb_array_length(p_result->'questions')<>count_ready or jsonb_array_length(p_proof->'questions')<>count_ready or (select count(distinct x->>'questionId') from jsonb_array_elements(p_result->'questions')x)<>count_ready or (select count(distinct x->>'question_id') from jsonb_array_elements(p_proof->'questions')x)<>count_ready or p_result->>'summary' is distinct from summary then raise exception 'RECOVERY_RESULT_SET_MISMATCH';end if;
   select * into fc from essay_exam_private.checkpoints where run_id=r.id and key='final';
   if mixed then
    if fc.run_id is not null or exists(select 1 from essay_exam_private.checkpoints where run_id=r.id and key='summary') then raise exception 'FINAL_CHECKPOINT_CONFLICT';end if;
    retry_key=essay_ops_private.recovery_retry_key(p_key);
    recovery_stage='retry';
    if coalesce((a.outcome->>'uncertain_approved')::boolean,false) then retry=essay_ops_private.recovery_retry_uncertain(r.id,retry_key,d);
    else retry=public.essay_exam_retry(subject,r.id,retry_key,r.exam_id);end if;
    outcome=essay_ops_private.recovery_receipt(r.id,p_key,d,'queued','retry')||jsonb_build_object('dispatch_required',true,'generation',retry->'generation','retry_key',retry_key,'restored_questions',restored,'uncertain_approved',coalesce((a.outcome->>'uncertain_approved')::boolean,false),'fenced_attempts',case when coalesce((a.outcome->>'uncertain_approved')::boolean,false) then (select jsonb_object_agg(z->>'index',z->'attempt') from jsonb_array_elements(d->'questions') z where z->>'readiness'='uncertain') else '{}'::jsonb end);
   else
    if count_ready<>(d#>>'{counts,total}')::int or (fc.state='checkpoint' and (fc.payload->'result' is distinct from p_result or fc.payload->'failed' is distinct from 'false'::jsonb)) then raise exception 'RECOVERY_FINAL_MISMATCH';end if;
    if exists(select 1 from essay_exam_private.checkpoints x where x.run_id=r.id and x.key='summary' and x.state='checkpoint' and x.payload->>'summary' is distinct from summary) then raise exception 'RECOVERY_SUMMARY_MISMATCH';end if;
    recovery_stage='settlement';result_state=public.essay_exam_finish(subject,r.id,r.lease_token,p_result,false);
    if result_state<>'completed' then raise exception 'RECOVERY_NOT_COMPLETED';end if;
    outcome=essay_ops_private.recovery_receipt(r.id,p_key,d,'completed','completed')||jsonb_build_object('restored_questions',restored);
   end if;
  exception when insufficient_privilege then raise;when others then
   -- The subtransaction rolls back ALL restored checkpoints/retry/finish changes before recording rejection.
   outcome=essay_ops_private.recovery_receipt(r.id,p_key,d,'blocked','blocked',case recovery_stage when 'settlement' then 'RECOVERY_SETTLEMENT_FAILED' when 'retry' then 'RECOVERY_RETRY_FAILED' when 'restore' then 'RECOVERY_RESTORE_FAILED' else 'ARTIFACT_VERIFICATION_FAILED' end)||jsonb_build_object('sqlstate',sqlstate);
  end;
 end if;
 insert into essay_ops_private.run_actions(id,run_id,actor,action,outcome) values(essay_ops_private.recovery_key(p_key),r.id,a.actor,'recover',outcome);
 return outcome;
end$$;

create function public.admin_lab_recovery_operations(p_from timestamptz,p_to timestamptz) returns jsonb language plpgsql stable security definer set search_path='' set statement_timeout='8s' as $$
declare result jsonb;
begin
 perform essay_ops_private.require_admin();
 if p_from is null or p_to is null or p_from>=p_to or p_to-p_from>interval '93 days' then raise invalid_parameter_value;end if;
 with attention as materialized(select r.*,greatest(r.lease_until,(select max(lease_until) from essay_exam_private.retry_requests where run_id=r.id)) latest_lease
  from essay_exam_private.runs r where r.state='reserved' and not exists(select 1 from essay_ops_private.hidden_runs h where h.run_id=r.id and h.hidden)
  and not coalesce(r.lease_until>now(),false) and not exists(select 1 from essay_exam_private.retry_requests t where t.run_id=r.id and t.lease_until>now())),
 success as(select distinct r.id from essay_exam_private.runs r join essay_ops_private.run_actions a on a.run_id=r.id and a.action='recover' where r.state='completed' and r.completed_at>=p_from and r.completed_at<p_to and
  (a.outcome->>'state'='completed' or (a.outcome->>'state'='queued' and exists(select 1 from essay_exam_private.retry_requests t where t.run_id=r.id and t.request_key::text=a.outcome->>'retry_key' and t.generation::text=a.outcome->>'generation' and t.generation=(select max(generation) from essay_exam_private.retry_requests where run_id=r.id)))))
 select jsonb_build_object('version','admin-run-recovery-v1','as_of',now(),'from',p_from,'to',p_to,
 'attention_total',(select count(*) from attention),'attention_limit',25,'stale_lease_count',(select count(*) from attention where latest_lease<=now()-interval '15 minutes'),
 'attention_scope','All-time visible reserved requests with no active run/retry lease; not proof a Worker stopped.',
 'stale_lease_scope','Visible reserved requests whose latest recorded lease expired at least 15 minutes ago; unknown lease timestamps excluded.',
 'attention',(select coalesce(jsonb_agg(jsonb_build_object('run_id',x.id,'state',x.state,'created_at',x.created_at,'lease_until',x.latest_lease,'reason',case when x.latest_lease is null then 'LEASE_UNKNOWN' else 'INACTIVE_LEASE' end,'question_total',jsonb_array_length(x.snapshot->'answers'),'question_completed',f.questions)),'[]') from(select * from attention order by created_at limit 25)x left join lateral(select count(*) as questions from jsonb_array_elements(essay_ops_private.recovery_diagnosis(x.id)->'questions') q where q->>'readiness'='completed')f on true),
 'recover_success',(select count(*) from success),'recover_success_scope','Distinct completed runs by completed_at in [from,to), attributable to completed recovery or matching latest recovery retry key/generation; queued/prepared alone excluded.',
 'recovery_history',(select coalesce(jsonb_agg(jsonb_build_object('run_id',a.run_id,'action_id',a.outcome->>'action_id','actor',a.actor,'recorded_at',a.recorded_at,'state',a.outcome->>'state','operation',a.outcome->>'operation','recovery_type',a.outcome->>'recovery_type','reason',a.outcome->>'reason','before_state',a.outcome->>'before_state','after_state',a.outcome->>'after_state') order by recorded_at desc),'[]') from(select * from essay_ops_private.run_actions where action='recover' and recorded_at>=p_from and recorded_at<p_to order by recorded_at desc limit 25)a)) into result;
 return result;
end$$;

create function essay_ops_private.recovery_intent(p_key uuid) returns essay_ops_private.run_actions language plpgsql set search_path='' as $$
declare a essay_ops_private.run_actions;subject uuid;
begin
 select * into a from essay_ops_private.run_actions where id=p_key;
 if a.id is null or a.action<>'recover' or a.outcome->>'state'<>'verification_required' or not exists(select 1 from public.admin_users where user_id=a.actor) then raise insufficient_privilege using message='RECOVERY_INTENT_REQUIRED';end if;
 select u.user_id into subject from essay_exam_private.runs r join public.credit_accounts u on u.id=r.account_id where r.id=a.run_id;
 perform math_private.require_active(array[a.actor,subject]);return a;
end$$;

create function public.essay_exam_recovery_context(p_key uuid) returns jsonb language plpgsql security definer set search_path='' set statement_timeout='8s' as $$
declare a essay_ops_private.run_actions;r essay_exam_private.runs;d jsonb;terminal essay_ops_private.run_actions;
begin
 a=essay_ops_private.recovery_intent(p_key);
 select * into terminal from essay_ops_private.run_actions where id=essay_ops_private.recovery_key(p_key);
 if terminal.id is not null then if terminal.actor<>a.actor or terminal.run_id<>a.run_id or terminal.action<>'recover' or terminal.outcome->>'action_id'<>p_key::text then raise sqlstate 'PT409' using message='ACTION_KEY_CONFLICT';end if;return jsonb_build_object('version','admin-run-recovery-v1','terminal',essay_ops_private.recovery_replay(terminal.outcome));end if;
 select * into r from essay_exam_private.runs where id=a.run_id;
 d=essay_ops_private.recovery_select(essay_ops_private.recovery_diagnosis(r.id),coalesce((a.outcome->>'uncertain_approved')::boolean,false));
 if d->>'diagnosis_token'<>a.outcome->>'diagnosis_token' or (d#>>'{recovery,allowed}')::boolean is not true then return jsonb_build_object('version','admin-run-recovery-v1','terminal',public.essay_exam_recovery_finish(p_key,a.outcome->>'diagnosis_token',null,jsonb_build_object('failure_code','ARTIFACT_VERIFICATION_FAILED')));end if;
 return jsonb_build_object('version','admin-run-recovery-v1','action_id',p_key,'run_id',r.id,'diagnosis_token',d->>'diagnosis_token','operation',a.outcome->>'operation',
 'claimed',jsonb_build_object('state',r.state,'run_id',r.id,'subject_id',d->'subject_id','exam_id',r.exam_id,'snapshot',r.snapshot,'parent_id',r.parent_id,'parent_result',(select p.result from essay_exam_private.runs p where p.id=r.parent_id and p.account_id=r.account_id),'lease_token',r.lease_token,'lease_until',r.lease_until,'session_version','exam-session-v1','attempts',coalesce((select attempts from essay_exam_private.retry_requests where run_id=r.id order by generation desc limit 1),'{}'::jsonb)),
 'uncertain_question_ids',case when coalesce((a.outcome->>'uncertain_approved')::boolean,false) then (select coalesce(jsonb_agg(z->>'question_id'),'[]') from jsonb_array_elements(d->'questions')z where z->>'readiness'='uncertain') else '[]'::jsonb end,
 'checkpoints',(select coalesce(jsonb_object_agg(key,jsonb_build_object('state',state,'payload',payload)),'{}') from essay_exam_private.checkpoints where run_id=r.id));
end$$;


create function essay_ops_private.recovery_select(d jsonb,approved boolean) returns jsonb language plpgsql immutable set search_path='' as $$
begin
 if approved is null then raise invalid_parameter_value;end if;
 if not approved then return d;end if;
 if (d#>>'{uncertain_recovery,allowed}')::boolean is not true then
  return jsonb_set(d,'{recovery}',(d->'recovery')||jsonb_build_object('allowed',false,'reason','UNCERTAIN_RECOVERY_NOT_AVAILABLE'));
 end if;
 return jsonb_set(d,'{recovery}',(d->'recovery')||jsonb_build_object('allowed',true,'reason',null,'type','E','method','verify_then_retry',
 'rerun_question_count',(select count(*) from jsonb_array_elements(d->'questions') q where q->>'readiness' in('retryable','uncertain')),
 'target_question_ids',(select jsonb_agg(q->>'question_id') from jsonb_array_elements(d->'questions') q where q->>'readiness' in('retryable','uncertain'))));
end$$;

create function essay_ops_private.recovery_retry_uncertain(p_run uuid,p_key uuid,d jsonb) returns jsonb language plpgsql set search_path='' as $$
declare previous essay_exam_private.retry_requests;a jsonb;q jsonb;
begin
 -- Caller holds account/run/billing locks and has verified the current diagnosis and retained results.
 select * into previous from essay_exam_private.retry_requests where run_id=p_run order by generation desc limit 1;
 a=coalesce(previous.attempts,'{}');
 for q in select value from jsonb_array_elements(d->'questions') loop
  if q->>'readiness' in('retryable','uncertain') then a=jsonb_set(a,array[q->>'index'],to_jsonb((q->>'attempt')::int+1));end if;
 end loop;
 insert into essay_exam_private.retry_requests(run_id,request_key,generation,attempts)
 values(p_run,p_key,coalesce(previous.generation,0)+1,a) returning * into previous;
 return jsonb_build_object('run_id',p_run,'generation',previous.generation);
end$$;

create function essay_ops_private.recovery_current_result(p_run uuid,p_result jsonb default null) returns boolean language plpgsql stable set search_path='' as $$
declare r essay_exam_private.runs;a jsonb;c essay_exam_private.checkpoints;i int;n int;matched jsonb;
begin
 select * into r from essay_exam_private.runs where id=p_run;
 select attempts into a from essay_exam_private.retry_requests where run_id=p_run order by generation desc limit 1;
 if p_result is not null and (jsonb_typeof(p_result->'questions') is distinct from 'array' or jsonb_array_length(p_result->'questions')<>jsonb_array_length(r.snapshot->'answers')) then return false;end if;
 for i in 0..jsonb_array_length(r.snapshot->'answers')-1 loop
  n=coalesce((a->>i::text)::int,0);
  select * into c from essay_exam_private.checkpoints where run_id=p_run and key='q'||i||case when n=0 then '' else '-retry-'||n end;
  if c.state is distinct from 'checkpoint' or c.payload->>'state' is distinct from 'completed' then return false;end if;
  if p_result is not null then
   select x into matched from jsonb_array_elements(p_result->'questions') x where x->>'questionId'=r.snapshot#>>array['answers',i::text,'questionId'];
   if matched is null or matched->'evaluation' is distinct from c.payload->'output' then return false;end if;
  end if;
 end loop;
 return true;
end$$;

create function essay_ops_private.recovery_fence() returns trigger language plpgsql security definer set search_path='' as $$
declare rid uuid;entry record;idx text;attempt int;fenced boolean;
begin
 if TG_TABLE_NAME='runs' then rid=new.id;else rid=new.run_id;end if;
 perform 1 from essay_exam_private.runs where id=rid for update;
 select exists(select 1 from essay_ops_private.run_actions where run_id=rid and action='recover' and outcome->>'state'='queued' and outcome->>'uncertain_approved'='true') into fenced;
 if not fenced then return new;end if;
 if TG_TABLE_NAME='runs' then
  if new.state is distinct from old.state and (new.state<>'completed' or not essay_ops_private.recovery_current_result(rid,new.result)) then raise sqlstate 'PT409' using message='STALE_RECOVERY_RESULT';end if;
 else
  for entry in select e.key,e.value from essay_ops_private.run_actions a cross join lateral jsonb_each(a.outcome->'fenced_attempts') e where a.run_id=rid and a.action='recover' and a.outcome->>'state'='queued' and a.outcome->>'uncertain_approved'='true' loop
   idx=entry.key;
   if new.key ~ ('^q'||idx||'($|-)') then
    attempt=case when new.key ~ ('^q'||idx||'-a[0-9]+-') then substring(new.key from '-a([0-9]+)-')::int
     when new.key ~ ('^q'||idx||'-retry-[0-9]+') then substring(new.key from '-retry-([0-9]+)')::int else 0 end;
    if attempt<=entry.value::text::int then raise sqlstate 'PT409' using message='STALE_QUESTION_ATTEMPT';end if;
   end if;
  end loop;
  if new.key in('summary','final') and (not essay_ops_private.recovery_current_result(rid) or (new.key='final' and new.state='checkpoint' and (new.payload->'failed' is distinct from 'false'::jsonb or not essay_ops_private.recovery_current_result(rid,new.payload->'result')))) then raise sqlstate 'PT409' using message='STALE_RECOVERY_RESULT';end if;
 end if;
 return new;
end$$;
create trigger recovery_attempt_fence before insert or update on essay_exam_private.checkpoints for each row execute function essay_ops_private.recovery_fence();
create trigger recovery_result_fence before update on essay_exam_private.runs for each row execute function essay_ops_private.recovery_fence();

create function essay_ops_private.quality_retry_guard() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if exists(select 1 from essay_exam_private.checkpoints where run_id=new.run_id and key ~ '^q[0-9]+-a[0-9]+-quality-policy$') then
  raise sqlstate 'PT409' using message='ADMIN_QUALITY_REVIEW_REQUIRED';
 end if;
 return new;
end$$;
create trigger quality_retry_budget before insert on essay_exam_private.retry_requests for each row execute function essay_ops_private.quality_retry_guard();
create function public.essay_exam_recovery_quality_ready() returns text language sql stable security definer set search_path='' as $$select 'quality-repair-2-1-v1'::text$$;

alter function essay_ops_private.recovery_key(uuid) owner to postgres;
revoke all on function essay_ops_private.recovery_key(uuid) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_retry_key(uuid) owner to postgres;
revoke all on function essay_ops_private.recovery_retry_key(uuid) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_replay(jsonb) owner to postgres;
revoke all on function essay_ops_private.recovery_replay(jsonb) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_digest(uuid) owner to postgres;
revoke all on function essay_ops_private.recovery_digest(uuid) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_diagnosis(uuid) owner to postgres;
revoke all on function essay_ops_private.recovery_diagnosis(uuid) from public,anon,authenticated,essay_worker,service_role;
alter function public.admin_lab_run_recovery(uuid) owner to postgres;
revoke all on function public.admin_lab_run_recovery(uuid) from public,anon,authenticated,essay_worker,service_role;
grant execute on function public.admin_lab_run_recovery(uuid) to authenticated;
alter function essay_ops_private.recovery_receipt(uuid,uuid,jsonb,text,text,text) owner to postgres;
revoke all on function essay_ops_private.recovery_receipt(uuid,uuid,jsonb,text,text,text) from public,anon,authenticated,essay_worker,service_role;
alter function public.admin_lab_recover_run(uuid,uuid,text,boolean) owner to postgres;
revoke all on function public.admin_lab_recover_run(uuid,uuid,text,boolean) from public,anon,authenticated,essay_worker,service_role;
grant execute on function public.admin_lab_recover_run(uuid,uuid,text,boolean) to authenticated;
alter function public.essay_exam_recovery_finish(uuid,text,jsonb,jsonb) owner to postgres;
revoke all on function public.essay_exam_recovery_finish(uuid,text,jsonb,jsonb) from public,anon,authenticated,essay_worker,service_role;
grant execute on function public.essay_exam_recovery_finish(uuid,text,jsonb,jsonb) to essay_worker;
alter function public.admin_lab_recovery_operations(timestamptz,timestamptz) owner to postgres;
revoke all on function public.admin_lab_recovery_operations(timestamptz,timestamptz) from public,anon,authenticated,essay_worker,service_role;
grant execute on function public.admin_lab_recovery_operations(timestamptz,timestamptz) to authenticated;
alter function essay_ops_private.recovery_intent(uuid) owner to postgres;
revoke all on function essay_ops_private.recovery_intent(uuid) from public,anon,authenticated,essay_worker,service_role;
alter function public.essay_exam_recovery_context(uuid) owner to postgres;
revoke all on function public.essay_exam_recovery_context(uuid) from public,anon,authenticated,essay_worker,service_role;
grant execute on function public.essay_exam_recovery_context(uuid) to essay_worker;
alter function essay_ops_private.recovery_select(jsonb,boolean) owner to postgres;
revoke all on function essay_ops_private.recovery_select(jsonb,boolean) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_retry_uncertain(uuid,uuid,jsonb) owner to postgres;
revoke all on function essay_ops_private.recovery_retry_uncertain(uuid,uuid,jsonb) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_current_result(uuid,jsonb) owner to postgres;
revoke all on function essay_ops_private.recovery_current_result(uuid,jsonb) from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.recovery_fence() owner to postgres;
revoke all on function essay_ops_private.recovery_fence() from public,anon,authenticated,essay_worker,service_role;
alter function essay_ops_private.quality_retry_guard() owner to postgres;
revoke all on function essay_ops_private.quality_retry_guard() from public,anon,authenticated,essay_worker,service_role;
alter function public.essay_exam_recovery_quality_ready() owner to postgres;
revoke all on function public.essay_exam_recovery_quality_ready() from public,anon,authenticated,essay_worker,service_role;
grant execute on function public.essay_exam_recovery_quality_ready() to essay_worker;
notify pgrst,'reload schema';
commit;
