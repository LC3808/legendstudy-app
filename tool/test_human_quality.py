#!/usr/bin/env python3
"""HQP-3: fresh Unix-only PG17, actual canonical Essay migrations/RPCs.
No Production DSN, provider calls or real student material. Requires psycopg.
"""
import argparse, hashlib, json, os, subprocess, tempfile, uuid, time
from pathlib import Path
import psycopg
from psycopg.types.json import Jsonb
from psycopg import sql
R=Path(__file__).resolve().parents[1]
M=R/'supabase/migrations/20261001000100_quality_read_authorization.sql'
V=R/'supabase/verification/quality_authorization'
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--pg-bin',type=Path,required=True);args=ap.parse_args()
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(cmd,**kw):return subprocess.run(list(map(str,cmd)),check=True,capture_output=True,text=True,env=env,**kw).stdout
 assert ' 17.' in run([args.pg_bin/'postgres','--version'])
 with tempfile.TemporaryDirectory(prefix='hqp3-',dir='/private/tmp') as temp:
  root=Path(temp);sock=root/'socket';sock.mkdir();data=root/'db';started=False
  run([args.pg_bin/'initdb','-D',data,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
  try:
   run([args.pg_bin/'pg_ctl','-D',data,'-l',root/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']);started=True
   with psycopg.connect(host=str(sock),port=5432,user='postgres',dbname='postgres',autocommit=True) as c:
    def scalar(q,p=()):return c.execute(q,p or None).fetchone()[0]
    def put(table,**v):
     c.execute(sql.SQL('insert into public.{} ({}) values ({}) returning id').format(sql.Identifier(table),sql.SQL(',').join(map(sql.Identifier,v)),sql.SQL(',').join(sql.Placeholder() for _ in v)),[Jsonb(x) if isinstance(x,dict) else x for x in v.values()])
    def new():return str(uuid.uuid4())
    A,B,OP=new(),new(),new()
    def rpc(name,values=(),uid=A,role='authenticated',exp=None,extra=None):
     with c.transaction():
      c.execute(sql.SQL('set local role {}').format(sql.Identifier(role)))
      claims={'sub':uid,'role':'authenticated','exp':int(time.time())+600 if exp is None else exp};claims.update(extra or {})
      c.execute("select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claims',%s,true)",(uid or '',json.dumps(claims)))
      return scalar(sql.SQL('select public.{}({})').format(sql.Identifier(name),sql.SQL(',').join(sql.Placeholder() for _ in values)),[Jsonb(v) if isinstance(v,dict) else v for v in values])
    def denied(fn):
     try:fn()
     except psycopg.Error as e:assert e.sqlstate in ['42501','42883','22P02','22023'];return
     raise AssertionError('Unexpected authorization')
    c.execute("""create role anon nologin;create role authenticated nologin;create role service_role nologin bypassrls;
     create schema auth;create table auth.users(id uuid primary key,created_at timestamptz default now());
     create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
     grant usage on schema auth,public to anon,authenticated,service_role;
     alter default privileges in schema public grant all on tables to anon,authenticated,service_role;
     alter default privileges in schema public grant all on functions to anon,authenticated,service_role;""")
    names=['20260912000100','20260913000100','20260917000100','20260927000100','20260927000200','20260928000100','20260928000200','20260928000300','20260928000400','20260929000100','20260929000200','20260929000300','20260929000400']
    for version in names:c.execute(next((R/'supabase/migrations').glob(version+'_*.sql')).read_text())
    for u in [A,B,OP]:c.execute('insert into auth.users(id) values(%s)',(u,));put('profiles',id=u)
    ids=[new() for _ in range(7)];source,content,resource,univ,exam,q,criterion=ids
    put('source_posts',id=source,source='synthetic',external_post_id='test',url='https://example.edu/source',title='Synthetic')
    put('content_items',id=content,source_post_id=source,source_content_key='fixture',slug='fixture',content_type='university_essay',title='Synthetic',source_url='https://example.edu/source',is_active=True)
    put('resources',id=resource,content_item_id=content,source_post_id=source,source_resource_key='fixture',title='Synthetic',source_url='https://example.edu/file',is_active=True)
    put('universities',id=univ,slug='synthetic',name='Synthetic',is_active=True)
    put('essay_exams',id=exam,university_id=univ,admission_year=2026,exam_key='synthetic',exam_name='Synthetic',exam_kind='admission',provenance='official',verification_status='verified',verified_at='2026-01-01T00:00:00Z',official_source_url='https://example.edu/source',evidence_note='Synthetic only',is_active=True)
    put('essay_questions',id=q,essay_exam_id=exam,question_key='1',label='Synthetic',display_order=1,metadata_version='v1',is_published=True)
    evidence=None
    for role in ['question','passage','exam_intent','scoring_criteria']:
     # composite-key table has no id: explicit insert
     c.execute("insert into public.essay_exam_resources(essay_exam_id,resource_id,role,provenance,verification_status,verified_at,official_source_url,source_locator,evidence_note,is_active) values(%s,%s,%s,'official','verified',now(),'https://example.edu/source','p1','Synthetic',true)",(exam,resource,role))
     eid=new();put('essay_question_evidence',id=eid,question_id=q,essay_exam_id=exam,resource_id=resource,role=role,source_locator='p1',mapping_version='v1',source_sha256='a'*64)
     if role=='scoring_criteria':evidence=eid
    put('essay_evaluation_criteria',id=criterion,question_id=q,criterion_key='reasoning',definition_version='v1',label='Criterion',description='Synthetic',origin='official',source_evidence_id=evidence,display_order=1,verified_at='2026-01-01T00:00:00Z')
    def evaluate(session,body,items,cores,reviews=[]):
     revision=scalar('select revision from public.essay_drafts where session_id=%s',(session,))
     revision=rpc('essay_save_draft',[session,revision,body,'web_desktop','practice',0])
     attempt=rpc('essay_submit_attempt',[session,revision,new(),hashlib.sha256(body.encode()).hexdigest()])
     evaluation=rpc('essay_request_evaluation',[str(attempt),new(),'essay-v1.3'])
     claim=rpc('essay_claim',[str(evaluation)],role='essay_worker')
     output={'contract_version':'1.3','attempt_id':str(attempt),'answer_hash':hashlib.sha256(body.encode()).hexdigest(),'summary':'Synthetic summary','strengths':['Concept → application works because of criterion'],'checklist':['Reuse the reasoning'],'dimensions':[{'criterion_id':criterion,'level':4,'explanation':'Synthetic','evidence_ids':[evidence]}],'improvements':items,'core_improvement_keys':cores,'previous_improvement_reviews':reviews,'sentence_feedback':[],'local_reviews':[]}
     if any(x['issue_key']=='polish' for x in items):output['sentence_feedback']=[{'observation_key':'s1','linked_issue_key':'polish','category':'expression','priority':'wording','start':2,'end':3,'quote':body[2:3],'diagnosis':'Synthetic diagnosis','direction':'Synthetic direction','example':'Optional'}]
     rpc('essay_finalize_success',[str(evaluation),claim['run_id'],claim['lease_token'],output],role='essay_worker')
     return str(evaluation),str(attempt)
    def item(key,priority,status='open',prev=None):return {'issue_key':key,'category':'reasoning','status':status,'previous_progress_id':prev,'title':key,'explanation':'Why','action':'How','priority':priority,'claim_scope':'official_criterion','evidence_ids':[evidence]}
    session=str(rpc('essay_open_session',[new(),q]));body='🙂 가가 논리 연결.'
    first,attempt=evaluate(session,body,[item('polish',1),item('coreA',1),item('coreB',2)],['coreA','coreB'])
    previous={key:str(pid) for key,pid in c.execute('select i.issue_key,p.id from public.essay_improvement_progress p join public.essay_improvement_items i on i.id=p.issue_id where p.evaluation_id=%s',(first,))}
    second,attempt2=evaluate(session,'🙂 가가 개선 답안.',[item('coreB',1,'improved',previous['coreB'])],['coreB'],[{'previous_progress_id':previous['coreA'],'outcome':'not_assessable','reason':'Unavailable comparison'},{'previous_progress_id':previous['coreB'],'outcome':'improved','reason':'Improved link'}])
    zero,_=evaluate(str(rpc('essay_open_session',[new(),q])),'충분한 합성 답안.',[],[])
    # Additional same-timestamp pending cases, actual schema (no shim), to test ties/cap.
    c.execute("""insert into public.essay_evaluations(attempt_id,session_id,question_id,idempotency_key,request_kind,request_hash,status,evaluation_version,contract_version,regime_key,evidence_manifest_sha256,evidence_completeness,requested_at)
      select %s,%s,%s,gen_random_uuid(),'operator_reevaluation',repeat('a',64),'requested','1.3','1.3','fixture',repeat('a',64),'complete','2026-01-01T00:00:00Z' from generate_series(1,105)""",(attempt,session,q))
    c.execute(M.read_text())
    c.execute('insert into public.quality_operators(user_id) values(%s)',(OP,))
    verify_hqp(c,rpc,new,scalar,first,second,zero,A,B,OP,session,previous,args,sock)
  finally:
   if started:run([args.pg_bin/'pg_ctl','-D',data,'-m','fast','-w','stop'])

def verify_hqp(c,rpc,new,scalar,first,second,zero,A,B,OP,session,previous,args,sock):
 import copy, concurrent.futures
 H=R/'supabase/migrations/20261001000200_human_quality_persistence.sql';V=R/'supabase/verification/human_quality'
 passed=[]
 def check(label,condition=True):
  assert condition,label
  passed.append(label);print(label,'PASS')
 def deny(label,fn,states=('42501','22023','23514','23505','22P02','P0002')):
  try:fn()
  except psycopg.Error as e:assert e.sqlstate in states,(label,e.sqlstate);check(label);return
  raise AssertionError(label+' unexpectedly allowed')
 # Comprehensive pre-existing public/private schema security/body snapshot, excluding only HQP objects.
 def catalog():
  return {name:scalar(q) for name,q in {
   'relations':"select jsonb_agg(jsonb_build_array(oid,relname,relkind,relowner,relacl::text,relrowsecurity,relforcerowsecurity) order by oid) from pg_class where relnamespace in ('public'::regnamespace,'essay_private'::regnamespace) and relname not like 'human_quality_%'",
   'columns':"select jsonb_agg(jsonb_build_array(attrelid,attnum,attname,atttypid,attnotnull) order by attrelid,attnum) from pg_attribute where attrelid in (select oid from pg_class where relnamespace='public'::regnamespace and relname not like 'human_quality_%') and attnum>0 and not attisdropped",
   'policies':"select jsonb_agg(to_jsonb(p) order by schemaname,tablename,policyname) from pg_policies p where schemaname='public' and tablename not like 'human_quality_%'",
   'functions':"select jsonb_agg(jsonb_build_array(oid,pg_get_functiondef(oid),proowner,proacl::text,prosecdef,proconfig) order by oid) from pg_proc where pronamespace in ('public'::regnamespace,'essay_private'::regnamespace) and proname not like 'hq_%' and proname not in ('ql_submit_human_judgment','ql_review_state','ql_list_human_judgments')",
   'constraints':"select jsonb_agg(jsonb_build_array(oid,conname,pg_get_constraintdef(oid)) order by oid) from pg_constraint where connamespace='public'::regnamespace and conrelid not in (select oid from pg_class where relname like 'human_quality_%') and conname not like 'human_quality_%'",
   'triggers':"select jsonb_agg(jsonb_build_array(t.oid,pg_get_triggerdef(t.oid)) order by t.oid) from pg_trigger t join pg_class r on r.oid=t.tgrelid where r.relnamespace='public'::regnamespace and not t.tgisinternal and r.relname not like 'human_quality_%'"
  }.items()}
 baseline=catalog();c.execute(H.read_text());check('T11_T12_existing_catalog_unchanged',catalog()==baseline)
 OP2=new();c.execute('insert into auth.users(id) values(%s)',(OP2,));c.execute('insert into public.profiles(id) values(%s)',(OP2,));c.execute('insert into public.quality_operators(user_id) values(%s)',(OP2,))
 required=['diagnosis','core_priority','actionability','evidence_adherence','stance_preservation','hallucination_absence']
 def payload(e=zero,disposition='PASS'):
  d=rpc('ql_case_detail',[e],uid=OP)
  rub={k:'OK' for k in required};rub.update(sentence_feedback='OK' if d['sentence_feedback'] else 'NA',progression='OK' if d['history_context'].get('selected_previous_evaluation_id') else 'NA',generated_rewrite='OK' if d['generated_rewrite'] and d['generated_rewrite']['status']=='completed' else 'NA')
  return dict(dto_version='hq-write-v1',evaluation_id=e,expected_output_sha256=d['provenance']['output_sha256'],client_submission_id=new(),rubric_version='hq-rubric-v1',overall_disposition=disposition,rubric_result=rub,findings=[],official_source_reviewed=True)
 def submit(p,uid=OP):return rpc('ql_submit_human_judgment',[p],uid=uid)
 def history(e=zero,uid=OP,limit=20,cursor=None):return rpc('ql_list_human_judgments',[e,limit,cursor['created_at'] if cursor else None,cursor['judgment_id'] if cursor else None],uid=uid)
 def state(e):return rpc('ql_review_state',[[e]],uid=OP)['cases'][0]
 def clone():
  eid=new();c.execute("insert into public.essay_evaluations select (jsonb_populate_record(null::public.essay_evaluations,to_jsonb(e)||jsonb_build_object('id',%s::text,'idempotency_key',%s::text,'request_kind','operator_reevaluation'))).* from public.essay_evaluations e where id=%s",(eid,new(),zero));return eid
 def facts():
  tables=[x[0] for x in c.execute("select tablename from pg_tables where schemaname='public' and (tablename like 'essay_%' or tablename like 'credit_%')")]
  return {t:scalar(sql.SQL("select md5(coalesce(string_agg(to_jsonb(x)::text,'|' order by to_jsonb(x)::text),'')) from public.{} x").format(sql.Identifier(t))) for t in tables}
 before_facts=facts()
 p=payload()
 deny('T1',lambda:rpc('ql_submit_human_judgment',[p],uid=None,role='anon'))
 deny('T2',lambda:submit(p,B))
 j=submit(p)['judgment_id'];check('T3',bool(j));check('no_essay_credit_side_effect',facts()==before_facts)
 bad=copy.deepcopy(p);bad['reviewer_user_id']=OP2;deny('T4',lambda:submit(bad))
 c.execute("update public.profiles set neis_office_code='B10',neis_school_code='SYNTHETIC',grade_level=3 where id=%s",(B,))
 c.execute('insert into public.admin_users(user_id) values(%s)',(B,))
 deny('T5',lambda:submit(payload(),B));check('T5_helper_not_profile_admin', 'admin_users' not in scalar("select prosrc from pg_proc where oid='public.is_quality_operator()'::regprocedure"))
 for role in ['anon','authenticated','service_role']:
  for table in ['human_quality_judgments','human_quality_findings']:
   for priv in ['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER','MAINTAIN']:
    assert not scalar('select has_table_privilege(%s,%s,%s)',(role,'public.'+table,priv))
 def direct(query):
  with c.transaction():c.execute('set local role authenticated');c.execute(query)
 for label,query in [('T6','insert into public.human_quality_judgments default values'),('T7','update public.human_quality_judgments set summary_note=null'),('T8','delete from public.human_quality_findings')]:deny(label,lambda q=query:direct(q))
 for sig in ['ql_submit_human_judgment(jsonb)','ql_review_state(uuid[])','ql_list_human_judgments(uuid,integer,timestamptz,uuid)']:
  for role,want in [('anon',False),('authenticated',True),('service_role',False)]:assert scalar('select has_function_privilege(%s,%s,\'EXECUTE\')',(role,'public.'+sig))==want
  assert scalar("select prosecdef and proowner='postgres'::regrole and proconfig=array['search_path=\"\"'] from pg_proc where oid=%s::regprocedure",('public.'+sig,))
 check('T9');check('T10')
 for i,disp in [(13,'PASS'),(14,'PASS_WITH_NOTES'),(15,'NEEDS_REVIEW'),(16,'FAIL')]:check('T'+str(i),bool(submit(payload(disposition=disp))))
 check('fail_has_no_side_effect',facts()==before_facts)
 def invalid(label,change):
  x=payload();change(x);deny(label,lambda:submit(x))
 invalid('T17',lambda x:x.update(overall_disposition='OTHER'))
 invalid('T18',lambda x:x.update(rubric_version='v2'))
 invalid('T19',lambda x:x.update(rubric_result=[]))
 invalid('T20',lambda x:x['rubric_result'].pop('diagnosis'))
 invalid('T21',lambda x:x['rubric_result'].update(extra='OK'))
 invalid('T22',lambda x:x['rubric_result'].update(sentence_feedback='OK'))
 invalid('T23',lambda x:x['rubric_result'].update(diagnosis='FAIL'))
 check('T24',bool(submit(payload())))
 invalid('T25',lambda x:x.update(summary_note='x'*2001))
 def finding(kind='OVERALL',ref=None):return dict(issue_category='OTHER',severity='MINOR',target_kind=kind,target_ref=ref,note='Synthetic internal observation')
 def fp(e=zero,f=None):
  x=payload(e,'NEEDS_REVIEW');x['findings']=[f or finding()];return x
 f=finding();f['note']='x'*1001;deny('T26',lambda:submit(fp(f=f)))
 f=finding();f['issue_category']='BAD';deny('T27',lambda:submit(fp(f=f)))
 f=finding('BAD');deny('T28',lambda:submit(fp(f=f)))
 progress=previous['polish'];deny('T29',lambda:submit(fp(f=finding('PROGRESS',{'progress_id':progress}))))
 deny('T30',lambda:submit(fp(f=finding('SENTENCE',{'index':0}))))
 x=payload();root=submit(x)['judgment_id'];check('T31')
 independent=submit(payload(),OP2)['judgment_id'];check('T32',scalar('select supersedes_judgment_id is null from public.human_quality_judgments where id=%s',(independent,)))
 before=scalar('select to_jsonb(j) from public.human_quality_judgments j where id=%s',(root,))
 x=payload();x['supersedes_judgment_id']=root;correction=submit(x)['judgment_id'];check('T33',correction!=root)
 x2=payload();x2['supersedes_judgment_id']=correction;third=submit(x2,OP2)['judgment_id'];check('T34',str(scalar('select reviewer_user_id from public.human_quality_judgments where id=%s',(third,)))==OP2)
 y=payload(first);y['supersedes_judgment_id']=third;deny('T35',lambda:submit(y))
 # self-ID cannot be supplied; direct DB self-FK/check constraint also rejects.
 y=payload();y['id']=new();deny('T36',lambda:submit(y))
 deny('T37',lambda:c.execute('update public.human_quality_judgments set supersedes_judgment_id=%s where id=%s',(third,root)))
 y=payload();y['supersedes_judgment_id']=root;deny('T38',lambda:submit(y))
 check('T39',scalar('select to_jsonb(j) from public.human_quality_judgments j where id=%s',(root,))==before)
 active={a['id']:a['is_active'] for a in history(limit=100)['judgments']};check('T40',not active[root] and not active[correction] and active[third]);check('T41',active[independent])
 x=payload();one=submit(x);check('T42');two=submit(x);check('T43',one['judgment_id']==two['judgment_id'] and two['replayed'])
 y=copy.deepcopy(x);y['summary_note']='different';deny('T44',lambda:submit(y))
 y=copy.deepcopy(x);y['evaluation_id']=first;deny('T45',lambda:submit(y))
 c.execute('delete from public.quality_operators where user_id=%s',(OP,));deny('T46',lambda:submit(x));c.execute('insert into public.quality_operators values(%s,now())',(OP,))
 def concurrent_submit(p):
  with psycopg.connect(host=str(sock),user='postgres',dbname='postgres',autocommit=True) as other:
   with other.transaction():
    other.execute('set local role authenticated');other.execute("select set_config('request.jwt.claim.sub',%s,true),set_config('request.jwt.claims',%s,true)",(OP,json.dumps({'sub':OP,'role':'authenticated','exp':int(time.time())+600})))
    return other.execute('select public.ql_submit_human_judgment(%s)',(Jsonb(p),)).fetchone()[0]
 x=payload()
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:out=list(pool.map(concurrent_submit,[x,x]))
 check('T47',out[0]['judgment_id']==out[1]['judgment_id'] and sum(not a['replayed'] for a in out)==1)
 check('T48',submit(x2,OP2)['judgment_id']==third)
 subjects=[]
 for i,disp,want in [(50,'PASS','REVIEWED_ACCEPTABLE'),(51,'PASS_WITH_NOTES','REVIEWED_ACCEPTABLE'),(52,'NEEDS_REVIEW','REVIEWED_WITH_CONCERNS'),(53,'FAIL','REVIEWED_FAILED')]:
  e=clone();subjects.append(e);check('T49' if i==50 else 'empty_'+str(i),state(e)['human_review_state']=='UNREVIEWED');submit(payload(e,disp));check('T'+str(i),state(e)['human_review_state']==want)
 e=subjects[0];root=history(e)['judgments'][0]['id'];y=payload(e,'FAIL');y['supersedes_judgment_id']=root;submit(y);check('T54',state(e)['human_review_state']=='REVIEWED_FAILED')
 e=clone();submit(payload(e));submit(payload(e),OP2);check('T55',state(e)['human_review_state']=='MULTIPLE_REVIEWS')
 submit(payload(e,'FAIL'));check('T56',state(e)['human_review_state']=='DISAGREEMENT')
 projected=scalar('select essay_private.hq_projection(%s)',(Jsonb([{'rubric_version':'hq-rubric-v1','overall_disposition':'PASS'},{'rubric_version':'future-fixture-only','overall_disposition':'PASS'}]),));check('T57',projected['comparison_status']=='NOT_COMPARABLE')
 check('T58',state(subjects[0])['active_count']==1)
 read=history();check('T59',bool(read['judgments']))
 deny('T60',lambda:history(uid=B));deny('T61',lambda:rpc('ql_list_human_judgments',[zero],uid=None,role='anon'))
 check('T62',any(a['supersedes_judgment_id'] is None for a in read['judgments']));check('T63',any(a['supersedes_judgment_id'] for a in read['judgments']))
 rows=history(limit=100)['judgments'];check('T64',[(a['created_at'],a['id']) for a in rows]==sorted([(a['created_at'],a['id']) for a in rows],reverse=True))
 # All seven positive targets use actual finalize-generated identifiers.
 detail=rpc('ql_case_detail',[first],uid=OP);link=detail['evaluation_evidence_links'][0]
 targets=[finding(),finding('DIMENSION',{'dimension_id':detail['dimensions'][0]['dimension_id']}),finding('PROGRESS',{'progress_id':progress}),finding('ISSUE_KEY',{'issue_key':'polish'}),finding('SENTENCE',{'progress_id':progress,'observation_key':'s1'}),finding('EVIDENCE_LINK',link)]
 x=fp(first);x['findings']=targets;x['summary_note']='Internal synthetic note';review=submit(x,OP2)['judgment_id']
 check('positive_six_targets')
 deny('finding_immutable',lambda:c.execute('update public.human_quality_findings set note=null where judgment_id=%s',(review,)))
 deny('reviewer_cannot_be_cleared_manually',lambda:c.execute('update public.human_quality_judgments set reviewer_user_id=null where id=%s',(review,)))
 check('E2-A',str(scalar('select reviewer_user_id from public.human_quality_judgments where id=%s',(review,)))==OP2)
 c.execute('delete from auth.users where id=%s',(OP2,))
 rr=next(a for a in history(first)['judgments'] if a['id']==review)
 check('E2-B',rr['id']==review);check('E2-C',rr['reviewer_user_id'] is None);check('E2-D',len(rr['findings'])==6);check('E2-E',not set(rr).intersection({'email','name','reviewer_email','reviewer_name'}));check('E2-F',rr['reviewer_state']=='DELETED_OR_UNAVAILABLE');check('T65',rr['reviewer_user_id'] is None)
 check('T66',not any(k in json.dumps(rr) for k in ['reviewer_email','reviewer_name']));check('T67',not set(rr).intersection({'student_user_id','email','phone'}));check('T68',rr['summary_note']=='Internal synthetic note')
 seen=[];cursor=None
 while True:
  pg=history(limit=2,cursor=cursor);seen.extend(a['id'] for a in pg['judgments']);cursor=pg['next_cursor']
  if cursor is None:break
 check('T69',len(seen)==len(set(seen))==scalar('select count(*) from public.human_quality_judgments where evaluation_id=%s',(zero,)))
 # Genuine concurrent corrections: exactly one winner for a single predecessor.
 root=submit(payload())['judgment_id'];p1=payload();p2=payload();p1['supersedes_judgment_id']=p2['supersedes_judgment_id']=root
 def race(p):
  try:return concurrent_submit(p)['judgment_id']
  except psycopg.Error as ex:assert ex.sqlstate in ['23514','23505'];return None
 with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:out=list(pool.map(race,[p1,p2]))
 check('concurrent_correction',sum(x is not None for x in out)==1)
 # Rewrite appears after review: original NA and exact retry stay bound to original observation.
 e=clone();early=payload(e);submit(early)
 rw=new();c.execute("insert into public.essay_generated_rewrites(id,evaluation_id,generation_version,contract_version,status,body,input_sha256,output_sha256,completed_at) values(%s,%s,'fixture','1.3','completed','Synthetic rewrite',repeat('a',64),repeat('b',64),now())",(rw,e))
 check('late_rewrite_retry',submit(early)['replayed'])
 y=fp(e,finding('GENERATED_REWRITE'));late=submit(y)['judgment_id'];check('positive_generated_target',str(scalar('select reviewed_generated_rewrite_id from public.human_quality_judgments where id=%s',(late,)))==rw)
 c.execute('delete from public.essay_generated_rewrites where id=%s',(rw,));check('rewrite_erase_exception',scalar('select reviewed_generated_rewrite_id is null from public.human_quality_judgments where id=%s',(late,)))
 # E1: lifecycle != privacy erase; separate subject avoids cascading fixture dependencies.
 e=clone();p=fp(e);rj=submit(p)['judgment_id'];y=payload(e,'FAIL');y['supersedes_judgment_id']=rj;submit(y)
 c.execute("update public.essay_evaluations set invalidated_at=clock_timestamp(),invalidation_reason='Synthetic' where id=%s",(e,));check('E1-A',scalar('select count(*) from public.human_quality_judgments where evaluation_id=%s',(e,))==2)
 ee=new();c.execute("insert into public.essay_evaluations select (jsonb_populate_record(null::public.essay_evaluations,to_jsonb(e)||jsonb_build_object('id',%s::text,'idempotency_key',%s::text,'supersedes_evaluation_id',%s::text,'correction_reason','Synthetic'))).* from public.essay_evaluations e where id=%s",(ee,new(),e,e));check('E1-B',scalar('select count(*) from public.human_quality_judgments where evaluation_id=%s',(e,))==2)
 c.execute('delete from public.essay_evaluations where id=%s',(e,));check('E1-C',scalar('select count(*) from public.human_quality_judgments where evaluation_id=%s',(e,))==0);check('E1-D',scalar('select count(*) from public.human_quality_findings where judgment_id=%s',(rj,))==0);check('E1-E',not scalar("select exists(select 1 from public.human_quality_judgments j where to_jsonb(j)::text like %s)",('%'+e+'%',)))
 # Extra bounds/stale/unknown conditions.
 deny('batch_bound',lambda:rpc('ql_review_state',[[zero]*101],uid=OP));deny('batch_unauthorized',lambda:rpc('ql_review_state',[[zero]],uid=B));check('batch_empty',rpc('ql_review_state',[[]],uid=OP)['cases']==[])
 invalid('unknown_verdict',lambda x:x['rubric_result'].update(diagnosis='UNKNOWN'))
 invalid('source_not_confirmed',lambda x:x.update(official_source_reviewed=False))
 invalid('stale_hash',lambda x:x.update(expected_output_sha256='0'*64))
 y=fp();y['findings']=[finding()]*21;deny('finding_bound',lambda:submit(y))
 check('catalog_after_writes',catalog()==baseline)
 metadata={'indexes':c.execute("select indexname,indexdef from pg_indexes where schemaname='public' and tablename like 'human_quality_%' order by indexname").fetchall(),'tables':c.execute("select relname,relowner::regrole::text,relrowsecurity,relacl::text from pg_class where relname in ('human_quality_judgments','human_quality_findings') order by relname").fetchall()}
 # owner erase and auth cascade use actual canonical schema, no production records.
 rpc('essay_erase',[session],uid=A);check('session_erasure',scalar('select count(*) from public.human_quality_judgments where evaluation_id in (%s,%s)',(first,second))==0)
 c.execute('delete from auth.users where id=%s',(A,));check('account_erasure',scalar('select count(*) from public.human_quality_judgments')==0 and scalar('select count(*) from public.human_quality_findings')==0)
 rpc('essay_open_session',[new(),str(scalar('select id from public.essay_questions limit 1'))],uid=B)
 rollback_facts=facts()
 c.execute('create view public.hqp_dependency_fixture as select * from public.human_quality_judgments')
 try:c.execute((V/'rollback.sql').read_text())
 except psycopg.errors.DependentObjectsStillExist:c.execute('rollback')
 else:raise AssertionError('unbounded rollback')
 check('rollback_dependency_refusal',scalar("select to_regclass('public.human_quality_judgments')") is not None)
 c.execute('drop view public.hqp_dependency_fixture');c.execute((V/'rollback.sql').read_text());check('rollback',catalog()==baseline and scalar("select to_regclass('public.human_quality_judgments')") is None)
 check('rollback_preserves_remaining_domain_data',facts()==rollback_facts)
 result={'scope':'isolated PG17 Unix socket; auth role/claims shim, not real JWT gateway','migration_sha256':hashlib.sha256(H.read_bytes()).hexdigest(),'catalog':metadata,'checks':passed,'check_count':len(passed),'existing_catalog_unchanged':True,'rollback':'PASS','production_writes':0,'provider_calls':0}
 (V/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
 print('HQP3_CHECK_COUNT',len(passed))

if __name__=='__main__':main()
