#!/usr/bin/env python3
"""Operator metadata + exact rollback; disposable PG17, synthetic fixtures only."""
import inspect, json, hashlib
import psycopg
from psycopg.types.json import Jsonb
import test_math_persistence as m
R=m.R; V=R/'supabase/verification/quality_metadata'
M=R/'supabase/migrations/20261010134235_quality_console_metadata.sql'
def cases(c,rpc,new,scalar,A,B,OP,ev,at,cl,out,p,leaf,pr,profile,sock):
 checks=[]
 def ok(n,b=True):
  assert b,n
  checks.append(n);print(n,'PASS',flush=True)
 def deny(n,fn,states=('42501','22023','P0001')):
  try:fn()
  except psycopg.Error as e:
   c.execute('rollback');assert e.sqlstate in states,(n,e.sqlstate,str(e));ok(n);return
  raise AssertionError(n+' allowed')
 admin=psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True)
 m.o.execute_as_production(c,admin,(R/'supabase/migrations/20261002000200_math_runtime_surface.sql').read_text())
 c.execute((V/'original_functions.sql').read_text())
 def fixture(user=A,parent=None,prior=None,root=None,pf=profile):
  aid,eid=new(),new()
  with c.transaction():
   c.execute("insert into public.math_attempts select (jsonb_populate_record(null::public.math_attempts,to_jsonb(a)||%s)).* from public.math_attempts a where id=%s",(Jsonb(dict(id=aid,student_id=user,kind='SHORT_ANSWER_RESOLVE' if parent else 'INITIAL',predecessor_id=parent,prior_evaluation_id=prior,lineage_id=root or aid,client_submission_id=new())),at))
   c.execute("insert into public.math_evaluations select (jsonb_populate_record(null::public.math_evaluations,to_jsonb(e)||%s)).* from public.math_evaluations e where id=%s",(Jsonb(dict(id=eid,attempt_id=aid,profile_id=pf,idempotency_key=new(),request_kind='MATH_REEVALUATION' if parent else 'MATH_INITIAL_EVALUATION')),ev))
  return aid,eid
 # Four independent roots and explicit pairs, followed by other-user and rubric fixtures.
 pairs=[(at,ev)]+[fixture() for _ in range(3)]
 revisions=[fixture(parent=a,prior=e,root=a) for a,e in pairs]
 other=fixture(user=B)
 forged=fixture(user=B,parent=at,prior=ev,root=at)
 ids=[e for a,e in pairs+revisions]
 def listing(n=100,ts=None,eid=None):return rpc('qlm_list_cases',[n,ts,eid],uid=OP)
 baseline=listing();details={e:rpc('qlm_case_detail',[e],uid=OP) for e in ids}
 student=rpc('math_evaluation_detail',[ev]);review=rpc('qlm_list_human_judgments',[ev],uid=OP)
 def funcs():return c.execute("select oid,pg_get_functiondef(oid),proowner,proacl::text from pg_proc where oid in ('public.qlm_list_cases(integer,timestamptz,uuid)'::regprocedure,'public.qlm_case_detail(uuid)'::regprocedure) order by oid").fetchall()
 original=funcs()
 def otherfuncs():return scalar("select md5(string_agg(pg_get_functiondef(oid)||coalesce(proacl::text,''),'' order by oid)) from pg_proc where prokind='f' and pronamespace in ('public'::regnamespace,'math_private'::regnamespace,'essay_private'::regnamespace,'account_private'::regnamespace) and proname not in ('qlm_list_cases','qlm_case_detail')")
 untouched=otherfuncs()
 def facts():
  return {t:scalar('select md5(coalesce(jsonb_agg(to_jsonb(t) order by id)::text,\'[]\')) from public.'+t+' t') for t in ['math_attempts','math_evaluations','human_quality_judgments','credit_transactions']}
 data=facts()
 admin=psycopg.connect(host=str(sock),user='supabase_admin',dbname='postgres',autocommit=True)
 m.o.execute_as_production(c,admin,M.read_text())
 ok('non_superuser_production_owner_install')
 candidate=funcs();ok('OIDs_owner_ACL_preserved',[(x[0],x[2:]) for x in original]==[(x[0],x[2:]) for x in candidate])
 result=listing();rows=result['cases'];meta={r['evaluation_id']:r['quality_metadata'] for r in rows}
 ok('legacy_list_wire_exact',{**result,'cases':[{k:v for k,v in r.items() if k!='quality_metadata'} for r in rows]}==baseline)
 for e in ids:
  d=rpc('qlm_case_detail',[e],uid=OP);assert d.pop('quality_metadata')==meta[e];assert d==details[e]
 ok('legacy_detail_wire_exact_and_list_detail_metadata_equal')
 ok('four_lineages_eight_evaluations',len({meta[e]['root_attempt_id'] for e in ids})==4 and len({meta[e]['student_reference'] for e in ids})==1)
 ok('four_explicit_pairs',sum(meta[e]['relationship_state']=='LINKED' for e in ids)==4)
 ok('cross_user_lineage_fails_closed',meta[forged[1]]['root_attempt_id'] is None and meta[forged[1]]['prior_evaluation_id'] is None and meta[forged[1]]['relationship_state']=='UNLINKED')
 ok('other_user_separated',meta[other[1]]['student_reference']!=meta[ev]['student_reference'])
 ok('pseudonym_no_direct_identity',all(str(A) not in json.dumps(v) and str(B) not in json.dumps(v) and v['student_reference'].startswith('qs1_') for v in meta.values()))
 pages=[];last=None
 while True:
  rr=listing(2,last['completed_at'] if last else None,last['evaluation_id'] if last else None)['cases']
  if not rr:break
  pages+=rr;last=rr[-1]
 ok('cursor_ties_pagination_exact',pages==rows)
 deny('partial_cursor_denied',lambda:listing(2,None,ev))
 ok('limit_clamped',len(listing(0)['cases'])==1 and listing(1000)==listing(100))
 ok('student_API_unchanged',rpc('math_evaluation_detail',[ev])==student and 'quality_metadata' not in student)
 ok('human_review_contract_unchanged',rpc('qlm_list_human_judgments',[ev],uid=OP)==review)
 wrapper=rpc('qlm_quality',[dict(dto_version='qlm-runtime-v1',action='detail',payload={'evaluation_id':ev})],uid=OP)
 ok('existing_wrapper_additive',wrapper['result']['quality_metadata']==meta[ev])
 for uid,role,label in [(None,'anon','anonymous'),(A,'authenticated','nonoperator')]:
  deny(label+'_list',lambda:rpc('qlm_list_cases',[10,None,None],uid=uid,role=role))
  deny(label+'_detail',lambda:rpc('qlm_case_detail',[ev],uid=uid,role=role))
  deny(label+'_wrapper',lambda:rpc('qlm_quality',[dict(dto_version='qlm-runtime-v1',action='detail',payload={'evaluation_id':ev})],uid=uid,role=role))
 deny('expired_operator_denied',lambda:rpc('qlm_case_detail',[ev],uid=OP,exp=1))
 c.execute('delete from public.quality_operators where user_id=%s',(OP,))
 deny('revoked_operator_denied',lambda:rpc('qlm_case_detail',[ev],uid=OP));c.execute('insert into public.quality_operators values(%s)',(OP,))
 ok('all_other_functions_unchanged',otherfuncs()==untouched)
 ok('evaluation_attempt_review_ledger_unchanged',facts()==data)
 # Use review-state exam fixture to prove unverified labels remain NULL.
 exam=str(scalar('select exam_id from (select (%s::jsonb->>\'exam_id\')::uuid exam_id) x',(Jsonb(meta[ev]),)))
 ok('verified_exam_label',meta[ev]['exam_metadata_verified'] and meta[ev]['university_name'] is not None and meta[ev]['academic_year']==2026)
 c.execute("update public.essay_exams set verification_status='review',verified_at=null,is_active=false where id=%s",(exam,))
 q=rpc('qlm_case_detail',[ev],uid=OP)['quality_metadata']
 ok('unverified_exam_null',q['university_name'] is None and q['academic_year'] is None and not q['exam_metadata_verified'])
 c.execute('update account_private.dispatch_health set enabled=true');rpc('account_deletion_request',uid=A)
 deny('pending_subject_detail_denied',lambda:rpc('qlm_case_detail',[ev],uid=OP))
 ok('pending_subject_excluded_from_list',ev not in [r['evaluation_id'] for r in listing()['cases']])
 sid=new();rpc('account_reauth_attest',[A,sid],role='account_lifecycle_worker');rpc('account_deletion_cancel',uid=A,extra={'session_id':sid})
 deny('migration_drift_fail_closed',lambda:c.execute(M.read_text()))
 c.execute((V/'rollback.sql').read_text())
 ok('rollback_exact_definitions_owner_ACL',funcs()==original)
 ok('rollback_exact_list_wire',listing()==baseline)
 ok('rollback_student_unchanged',rpc('math_evaluation_detail',[ev])==student)
 deny('rollback_drift_fail_closed',lambda:c.execute((V/'rollback.sql').read_text()))
 (V/'candidate_function_fingerprints.json').write_text(json.dumps({str(c.execute('select %s::oid::regprocedure::text',(x[0],)).fetchone()[0]):hashlib.md5(x[1].encode()).hexdigest() for x in candidate},indent=2)+'\n')
 return checks
source=inspect.getsource(m.verify).replace("R/'supabase/verification/math_essay/behavior_validation.json'","V/'behavior_validation.json'").replace("20261002000100_math_essay_persistence.sql').read_bytes()","20261010134235_quality_console_metadata.sql').read_bytes()")
ns=dict(m.__dict__);ns.update(V=V,verify_math_cases=cases)
exec(source,ns)
if __name__=='__main__':
 m.h.verify_hqp=ns['verify'];m.h.main(bootstrap_user='supabase_admin')
