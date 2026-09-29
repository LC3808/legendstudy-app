"""Disposable-only scaffolding migration/RPC matrix. Synthetic data, never AI.
Native mode bootstraps an EMPTY guarded PG17 DB; local mode verifies CLI container identity.
Private status files and DSNs are never serialized into results.
"""
import argparse, contextlib, copy, hashlib, io, json, os, sys, uuid, re
from concurrent.futures import ThreadPoolExecutor
from threading import Barrier
from pathlib import Path
import psycopg
from psycopg import sql
from psycopg.types.json import Jsonb
ROOT=Path(__file__).resolve().parents[3]
RUNTIME=ROOT/'supabase/review/essay_lab_product/runtime'
sys.path.insert(0,str(RUNTIME));sys.path.insert(0,str(ROOT/'tool/essay_lab'))
import run_server
from scaffolding_adapter import finalize_payload
MIGRATION=ROOT/'supabase/migrations/20260929000100_essay_scaffolding_persistence.sql'
PARAMS={'essay_open_session':['p_id','p_question'],'essay_save_draft':['p_session','p_revision','p_body','p_device','p_mode','p_active_seconds'],
'essay_submit_attempt':['p_session','p_revision','p_key','p_body_hash'],'essay_request_evaluation':['p_attempt','p_key','p_regime'],
'essay_claim':['p_evaluation'],'essay_finalize_success':['p_evaluation','p_run','p_token','p_output'],
'essay_finalize_failure':['p_evaluation','p_run','p_token'],'essay_timeout':['p_evaluation','p_run','p_token'],'essay_erase':['p_session']}

class Rejected(Exception):pass

def native_rpc(c,A):
 def rpc(name,args,*,user=None,role='authenticated'):
  try:
   with psycopg.connect(c.info.dsn,autocommit=True) as con:
    with con.transaction():
     con.execute(sql.SQL('set local role {}').format(sql.Identifier(role)))
     con.execute("select set_config('request.jwt.claim.sub',%s,true)",(str(user or A),))
     value=con.execute(sql.SQL('select public.{}({})').format(sql.Identifier(name),sql.SQL(',').join(sql.Placeholder() for _ in args)),[Jsonb(a) if isinstance(a,dict) else a for a in args]).fetchone()[0]
     return str(value) if isinstance(value,uuid.UUID) else value
  except psycopg.Error as error: raise Rejected(error.sqlstate+(':'+error.diag.message_primary if error.sqlstate.startswith('PT') else '')) from None
 return rpc

def cases(c,rpc,A,B):
 checks=[]
 def ok(flag,name):
  if not flag:raise AssertionError(name)
  checks.append(name)
 def denied(fn,name):
  try:fn()
  except (Rejected,psycopg.Error,ValueError):checks.append(name);return
  raise AssertionError(name+' unexpectedly allowed')
 def scalar(q,args=()):return c.execute(q,args).fetchone()[0]
 def uid():return str(uuid.uuid4())
 q=scalar("select question_id from public.essay_question_evidence group by question_id having count(distinct role)=4 order by question_id limit 1")
 criterion=scalar('select id from public.essay_evaluation_criteria where question_id=%s order by id limit 1',(q,))
 evidence=scalar("select id from public.essay_question_evidence where question_id=%s and role='scoring_criteria'",(q,))
 c.execute('insert into public.credit_accounts(user_id) values(%s) on conflict do nothing',(A,));acc=scalar('select id from public.credit_accounts where user_id=%s',(A,));grant=uid()
 c.execute("insert into public.credit_grants(id,account_id,origin) values(%s,%s,'admin_grant')",(grant,acc))
 c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'admin_grant',100,0,%s,'synthetic_scaffold')",(acc,grant,uid()))
 def session():return rpc('essay_open_session',[uid(),str(q)])
 def submit(s,body):
  rev=scalar('select revision from public.essay_drafts where session_id=%s',(s,))
  rev=rpc('essay_save_draft',[s,rev,body,'web_desktop','practice',0]);return rpc('essay_submit_attempt',[s,rev,uid(),hashlib.sha256(body.encode()).hexdigest()])
 def request(a,regime='essay-v1.3',key=None):return rpc('essay_request_evaluation',[a,key or uid(),regime])
 def claim(e):return rpc('essay_claim',[e],role='essay_worker')
 def finish(e,l,o):return rpc('essay_finalize_success',[e,l['run_id'],l['lease_token'],o],role='essay_worker')
 def body(e):return scalar('select a.body from public.essay_evaluations e join public.essay_attempts a on a.id=e.attempt_id where e.id=%s',(e,))
 def context(e):return scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))['scaffolding_context']
 def output(e,count=1,core=1,local=False,key='root',state='open',prior=None):
  text=body(e);snap=scalar('select input_snapshot from public.essay_evaluations where id=%s',(e,))
  items=[{'issue_key':key if i==0 else f'{key}-{i}','category':'expression' if local else 'reasoning','status':state,'previous_progress_id':prior,
   'title':'문장 연결','explanation':'합성 관측 설명','action':'이번 문장의 연결을 확인해 보세요.','priority':i+1,'evidence_ids':[] if local else [str(evidence)],'claim_scope':'local_sentence' if local else 'official_criterion'} for i in range(max(core,1))]
  positions=[i for i,ch in enumerate(text) if not ch.isspace()]
  ss=[{'observation_key':f's{i}','linked_issue_key':items[i%len(items)]['issue_key'],'category':'grammar' if local else 'logic','priority':'grammar_agreement' if local else 'contradiction',
       'start':positions[i],'end':positions[i]+1,'quote':text[positions[i]:positions[i]+1],'diagnosis':'합성 문장 진단','direction':'해당 부분을 확인해 보세요.'} for i in range(count)]
  reviews=[{'previous_progress_id':prior,'outcome':state,'reason':'새 작성본을 확인한 합성 판단'}] if prior else []
  out={'contract_version':'1.3','attempt_id':snap['attempt_id'],'answer_hash':snap['answer_hash'],'summary':'합성 종합 평가','strengths':['합성 장점'],'checklist':['연결을 확인하세요.'],
   'dimensions':[{'criterion_id':str(criterion),'level':3,'explanation':'합성 기준 설명','evidence_ids':[str(evidence)]}],
   'improvements':items,'core_improvement_keys':[x['issue_key'] for x in items[:core]] if state!='resolved' else [],'previous_improvement_reviews':reviews,'sentence_feedback':ss}
  approvals=[{'issue':copy.deepcopy(x),'sentences':[s for s in ss if s['linked_issue_key']==x['issue_key']],'reviewer':'synthetic-trusted-review','decision':'local_only'} for x in items] if local else []
  return finalize_payload(out,contract_version='1.3',local_reviews=approvals)
 def fresh(text='🙂 가가 나 다.',**kw):
  s=session();a=submit(s,text);e=request(a);return s,a,e,claim(e),output(e,**kw)
 # Synthetic writing time is explicitly zero; no timing/idle behavior is simulated here.
 # Existing NULL/rounding submit defect is documented separately, not modified.
 # Strict envelope/check constraint. The valid function has no data access/security definer.
 valid={'version':1,'core_focus':False,'sentences':[]}
 can_probe=scalar("select has_function_privilege(current_user,'essay_private.scaffold_envelope_valid(jsonb)','EXECUTE')")
 if can_probe:
  ok(scalar('select essay_private.scaffold_envelope_valid(null)'),'legacy_NULL_shape')
  ok(scalar('select essay_private.scaffold_envelope_valid(%s)',(Jsonb(valid),)),'supported_empty_shape')
  for patch in [{'extra':1},{'version':2},{'version':'1'},{'core_focus':1},{'core_focus':None},{'sentences':None},{'sentences':{}},{'sentences':[{}]}]:
   ok(not scalar('select essay_private.scaffold_envelope_valid(%s)',(Jsonb(dict(valid,**patch)),)),'envelope_reject_'+next(iter(patch)))
 else:
  denied(lambda:scalar('select essay_private.scaffold_envelope_valid(null)'), 'private_helper_denied_to_migration_login')
 s,a,e,l,o=fresh()
 # Prove CHECK itself, not just helper, is enforced on a nonterminal parent.
 if can_probe:
  issue=uid();c.execute("insert into public.essay_improvement_items(id,session_id,issue_key,category) values(%s,%s,'shape-check','expression')",(issue,s))
  denied(lambda:c.execute("insert into public.essay_improvement_progress(issue_id,session_id,evaluation_id,status,title,explanation,next_action,priority,scaffolding_observation) values(%s,%s,%s,'open','x','x','x',1,%s)",(issue,s,e,Jsonb({'version':1}))), 'DB_CHECK_enforced')
 # One bad fragment must leave no progress/dimensions/consume; a valid retry still succeeds.
 for label,patch in [('fabricated',{'quote':'없는 원문'}),('UTF16_offset',{'start':1,'end':2,'quote':'🙂'}),('NFC_substitution',{'start':3,'end':5,'quote':'가'}),('whitespace_removed',{'start':0,'end':2,'quote':'🙂'}),('negative',{'start':-1}),('bool_offset',{'start':True}),('float_offset',{'start':0.0}),('unknown_category',{'category':'unknown'}),('bad_priority',{'priority':'high'}),('blank_diagnosis',{'diagnosis':''}),('whitespace_diagnosis',{'diagnosis':'\t\n'}),('numeric_link',{'linked_issue_key':1}),('unknown_key',{'extra':'x'}),('unlinked_issue',{'linked_issue_key':'other'})]:
  bad=copy.deepcopy(o);bad['sentence_feedback'][0].update(patch)
  denied(lambda:finish(e,l,bad),'quote_reject_'+label)
 for label,mutate in [('duplicate_span',lambda x:x['sentence_feedback'].append(dict(x['sentence_feedback'][0],observation_key='second'))),('duplicate_id',lambda x:x['sentence_feedback'].append(dict(x['sentence_feedback'][0],start=2,end=3,quote=body(e)[2:3]))),('duplicate_root',lambda x:x['improvements'].append(x['improvements'][0])),('six_observations',lambda x:x['sentence_feedback'].extend([x['sentence_feedback'][0]]*5)),('four_focus',lambda x:x.update(core_improvement_keys=['a','b','c','d'])),('answer_hash',lambda x:x.update(answer_hash='0'*64)),('other_attempt',lambda x:x.update(attempt_id=uid())),('foreign_evidence',lambda x:x['improvements'][0].update(evidence_ids=[uid()])),('invalid_criterion',lambda x:x['dimensions'][0].update(criterion_id=uid()))]:
  bad=copy.deepcopy(o);mutate(bad);denied(lambda:finish(e,l,bad),'reject_'+label)
 ok(scalar('select count(*) from public.essay_improvement_progress where evaluation_id=%s',(e,))==0 and scalar('select count(*) from public.essay_evaluation_dimensions where evaluation_id=%s',(e,))==0,'invalid_fragment_no_partial_result')
 # Draft changes are not inputs to a submitted evaluation.
 rev=scalar('select revision from public.essay_drafts where session_id=%s',(s,));rpc('essay_save_draft',[s,rev,'초안만 바뀜'])
 bad=copy.deepcopy(o);bad['sentence_feedback'][0].update(start=0,end=2,quote='초안');denied(lambda:finish(e,l,bad),'draft_quote_rejected')
 denied(lambda:rpc('essay_request_evaluation',[a,uid(),'essay-v1.3'],user=B),'cross_user_request')
 denied(lambda:rpc('essay_finalize_success',[e,l['run_id'],l['lease_token'],o]),'client_finalize_denied')
 # Valid whitespace, emoji, decomposed sequence preserve exact codepoints.
 o['sentence_feedback']=[dict(o['sentence_feedback'][0],start=0,end=5,quote=body(e)[0:5])]
 finish(e,l,o);ok(finish(e,l,o)==e,'idempotent_finalize')
 p=scalar('select id from public.essay_improvement_progress where evaluation_id=%s',(e,))
 stored=scalar('select scaffolding_observation from public.essay_improvement_progress where id=%s',(p,))
 ok(stored['sentences'][0]['quote']=='🙂 가가' and stored['sentences'][0]['end']==5,'emoji_decomposed_whitespace_exact')
 denied(lambda:c.execute('update public.essay_improvement_progress set scaffolding_observation=null where id=%s',(p,)),'completed_observation_immutable')
 # History cycle, fixed previous-core snapshot, skipped prior task fails closed.
 states=['open']; prior=str(p)
 for state in ['improved','resolved','recurred']:
  an=submit(s,'🙂 가가 새 작성본');en=request(an);ln=claim(en);ctx=context(en)
  ok(prior in [x['progress_id'] for x in ctx['items']],'snapshot_prior_'+state)
  out=output(en,count=0 if state=='resolved' else 1,state=state,prior=prior)
  skipped=copy.deepcopy(out);skipped['previous_improvement_reviews']=[]
  denied(lambda:finish(en,ln,skipped),'missing_previous_review_'+state)
  finish(en,ln,out);prior=str(scalar('select id from public.essay_improvement_progress where evaluation_id=%s',(en,)));states.append(state)
 ok([x[0] for x in c.execute("select p.status from public.essay_improvement_progress p join public.essay_evaluations e on e.id=p.evaluation_id where p.session_id=%s order by e.requested_at",(s,))]==states,'OPEN_IMPROVED_RESOLVED_RECURRED_preserved')
 # Unknown is no assertion; original focus remains available to the subsequent request.
 an=submit(s,'🙂 다시 작성한 답안');en=request(an);ln=claim(en);out=output(en,count=0,core=0)
 out['improvements']=[];out['previous_improvement_reviews']=[{'previous_progress_id':prior,'outcome':'not_assessable','reason':'판독 근거가 부족해요.'}]
 finish(en,ln,out)
 ok(scalar('select count(*) from public.essay_improvement_progress where evaluation_id=%s',(en,))==0 and '판독' in scalar('select uncertainty_note from public.essay_evaluations where id=%s',(en,)),'not_assessable_no_false_status')
 an=submit(s,'🙂 다음 작성본');en=request(an);ok(prior in context(en)['previous_core_progress_ids'],'unassessed_core_carried_forward')
 # Incompatible regime remains independent, with no fabricated growth or inherited focus.
 other=request(an,'essay-v1.3-next-model');ok(context(other)['availability']=='no_compatible_history' and context(other)['items']==[],'incompatible_regime_not_linked')
 lo=claim(other);oo=output(other);finish(other,lo,oo);ok(True,'same_attempt_regime_coexistence')
 # Scope cannot be self-approved by a raw provider flag.
 sl,al,el,ll,ol=fresh(local=True)
 bad=copy.deepcopy(ol);bad['local_reviews']=[];denied(lambda:finish(el,ll,bad),'unapproved_local_scope_denied')
 bad=copy.deepcopy(ol);bad['improvements'][0]['explanation']='승인 이후 바뀐 주장';denied(lambda:finish(el,ll,bad),'local_review_payload_mismatch')
 finish(el,ll,ol);pl=str(scalar('select id from public.essay_improvement_progress where evaluation_id=%s',(el,)))
 ok(scalar('select count(*) from public.essay_evaluation_evidence where improvement_progress_id=%s',(pl,))==0,'local_quote_no_fake_official_evidence')
 al2=submit(sl,'🙂 문장을 고친 답안');el2=request(al2);ll2=claim(el2);ol2=output(el2,count=0,core=0,local=True,state='resolved',prior=pl);finish(el2,ll2,ol2)
 ok(scalar('select scaffolding_observation from public.essay_improvement_progress where evaluation_id=%s',(el2,))['sentences']==[],'resolved_local_no_invented_error')
 # Explicit supported zero and cap boundaries.
 for count,core in [(0,0),(1,1),(5,3)]:
  sx,ax,ex,lx,ox=fresh(count=count,core=core)
  if count==core==0:ox['improvements']=[]
  finish(ex,lx,ox);ok(True,f'accepted_sentences_{count}_core_{core}')
 # Fault AFTER result write, before settlement; no split-brain even on new path.
 sx,ax,ex,lx,ox=fresh()
 c.execute("create function public.scaffold_test_fault() returns trigger language plpgsql as $$begin raise exception 'synthetic settlement fault';end$$")
 c.execute("create trigger scaffold_test_fault before insert on public.credit_transactions for each row when(new.transaction_type='consume') execute function public.scaffold_test_fault()")
 try:denied(lambda:finish(ex,lx,ox),'settlement_fault_injected')
 finally:c.execute('drop trigger scaffold_test_fault on public.credit_transactions; drop function public.scaffold_test_fault()')
 ok(scalar('select status from public.essay_evaluations where id=%s',(ex,))=='processing' and scalar('select count(*) from public.essay_improvement_progress where evaluation_id=%s',(ex,))==0,'result_and_progress_rollback')
 ok(scalar("select count(*) from public.credit_transactions t join public.essay_billing_decisions b on b.id=t.decision_id where b.evaluation_id=%s and t.transaction_type='consume'",(ex,))==0,'no_consume_without_result')
 finish(ex,lx,ox)
 # Learning erase keeps financial history and excludes another user's action.
 before=scalar('select count(*) from public.credit_transactions')
 denied(lambda:rpc('essay_erase',[sl],user=B),'other_user_erase_denied');rpc('essay_erase',[sl])
 ok(scalar('select count(*) from public.essay_improvement_progress where session_id=%s',(sl,))==0,'learning_observations_erased')
 ok(scalar('select count(*) from public.credit_transactions')==before,'financial_history_preserved')
 # Actual 1.3 concurrency, not just inherited v1.2 reference checks.
 sc=session();ac=submit(sc,'🙂 동시 요청 합성 답안');request_key=uid();barrier=Barrier(2)
 def duplicate(_):
  barrier.wait(timeout=10);return request(ac,key=request_key)
 with ThreadPoolExecutor(2) as pool: results=list(pool.map(duplicate,range(2)))
 ok(results[0]==results[1], 'v13_concurrent_logical_request_one')
 ec=results[0];lc=claim(ec);oc=output(ec,count=0,core=0);oc['improvements']=[];finish(ec,lc,oc)
 ok(scalar("select count(*) from public.credit_transactions t join public.essay_billing_decisions b on b.id=t.decision_id where b.evaluation_id=%s and t.transaction_type='consume'",(ec,))==1,'v13_concurrent_request_one_consume')
 ac2=submit(sc,'🙂 첫 재작성');ac3=submit(sc,'🙂 다른 재작성');barrier=Barrier(2)
 def included(a):
  barrier.wait(timeout=10);return request(a)
 with ThreadPoolExecutor(2) as pool: results=list(pool.map(included,[ac2,ac3]))
 reasons=[scalar('select reason from public.essay_billing_decisions where evaluation_id=%s',(ev,)) for ev in results]
 ok(sorted(reasons)==['additional_revision','included_revision'],'v13_included_claim_max_one')
 # One remaining unit on another synthetic user's account.
 c.execute('insert into public.credit_accounts(user_id) values(%s) on conflict do nothing',(B,));ba=scalar('select id from public.credit_accounts where user_id=%s',(B,));bg=uid()
 c.execute("insert into public.credit_grants(id,account_id,origin) values(%s,%s,'admin_grant')",(bg,ba))
 c.execute("insert into public.credit_transactions(account_id,grant_id,transaction_type,balance_delta,reserved_delta,idempotency_key,reason_code) values(%s,%s,'admin_grant',1,0,%s,'synthetic')",(ba,bg,uid()))
 bs=[]
 for _ in range(2):
  sb=rpc('essay_open_session',[uid(),str(q)],user=B);text='🙂 다른 학생의 합성 문장'
  rb=rpc('essay_save_draft',[sb,1,text,'web_desktop','practice',0],user=B)
  bs.append(rpc('essay_submit_attempt',[sb,rb,uid(),hashlib.sha256(text.encode()).hexdigest()],user=B))
 barrier=Barrier(2)
 def last(a):
  barrier.wait(timeout=10)
  try:return rpc('essay_request_evaluation',[a,uid(),'essay-v1.3'],user=B)
  except Rejected as err:
   if '402' not in str(err):raise
   return 'insufficient'
 with ThreadPoolExecutor(2) as pool: results=list(pool.map(last,bs))
 ok(results.count('insufficient')==1 and scalar('select sum(balance_delta-reserved_delta) from public.credit_transactions where grant_id=%s',(bg,))==0,'v13_last_credit_one_winner')
 # Exact ownership links remain server-selected, not supplied by a provider.
 sx,ax,ex,lx,ox=fresh();foreign=copy.deepcopy(ox)
 foreign['sentence_feedback'][0].update(start=0,end=8,quote='다른 학생의 문장')
 denied(lambda:finish(ex,lx,foreign),'other_student_quote_rejected')
 # A successful failure transition releases reservation; timeout makes old run unpublishable.
 rpc('essay_timeout',[ex,lx['run_id'],lx['lease_token']],role='essay_worker')
 denied(lambda:finish(ex,lx,ox),'v13_timeout_late_success_denied')
 sx2,ax2,ex2,lx2,ox2=fresh();rpc('essay_finalize_failure',[ex2,lx2['run_id'],lx2['lease_token']],role='essay_worker')
 ok(scalar('select status from public.essay_billing_decisions where evaluation_id=%s',(ex2,))=='released','v13_failure_release')
 # New helpers/dispatchers retain the narrow role and fixed-path boundary.
 helper_rows=c.execute("select p.oid::regprocedure::text,pg_get_userbyid(p.proowner),p.proconfig from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='essay_private' and p.proname like 'scaffold_%'").fetchall()
 ok(len(helper_rows)==9 and all(row[1]=='essay_executor' and row[2]==['search_path=""'] for row in helper_rows),'new_helper_owners_fixed_path')
 for role in ['anon','authenticated','service_role','essay_worker','essay_finance']:
  ok(all(not scalar("select has_function_privilege(%s,%s,'execute')",(role,row[0])) for row in helper_rows),'new_helpers_denied_'+role)
 # Fixed snapshot: requesting a later answer before an older evaluation completes does not move.
 sf=session();af=submit(sf,'🙂 먼저 작성한 답안');ef=request(af);lf=claim(ef)
 af2=submit(sf,'🙂 다음에 작성한 답안');ef2=request(af2);snap=scalar('select input_snapshot from public.essay_evaluations where id=%s',(ef2,))
 finish(ef,lf,output(ef));ok(scalar('select input_snapshot from public.essay_evaluations where id=%s',(ef2,))==snap,'snapshot_not_moving_latest')
 lf2=claim(ef2);of2=output(ef2);of2['previous_improvement_reviews']=[{'previous_progress_id':str(scalar('select id from public.essay_improvement_progress where evaluation_id=%s',(ef,))),'outcome':'improved','reason':'늦게 생긴 관측'}]
 denied(lambda:finish(ef2,lf2,of2),'late_history_injection_denied')
 return checks

class SQLText:
 def read_text(self):
  return '\n'.join((ROOT/'supabase/migrations'/f).read_text() for f in ['20260928000300_essay_server_operations.sql','20260928000400_essay_helper_execute_boundary.sql',MIGRATION.name])

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--native',action='store_true');args=parser.parse_args()
 if not args.native:raise SystemExit('Use --native; Supabase transport is in scaffolding_supabase.py')
 original=run_server.baseline.main
 run_server.baseline.main=lambda **kw: original(schema_paths=[ROOT/'supabase/migrations/20260928000100_student_essay_product.sql',ROOT/'supabase/migrations/20260928000200_essay_entitlements.sql'],additional_draft=SQLText())
 output=io.StringIO()
 with contextlib.redirect_stdout(output):
  code=run_server.main()
 if code:raise SystemExit(code)
 regression=json.loads(output.getvalue())
 c=psycopg.connect(os.environ['ESSAY_REVIEW_TEST_DSN'],autocommit=True)
 A=str(uuid.uuid4());B=str(uuid.uuid4())
 for u in (A,B):
  c.execute('insert into auth.users(id) values(%s)',(u,));c.execute('insert into public.profiles(id) values(%s)',(u,))
 checks=cases(c,native_rpc(c,A),A,B);c.close()
 print(json.dumps({'environment':'disposable_pg17','runtime':'PASS','regression':regression,'scaffolding_checks':checks,'scaffolding_check_count':len(checks),'production_apply':False,'AI_executed':False},indent=2))
if __name__=='__main__':main()
