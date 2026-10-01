#!/usr/bin/env python3
"""LSA-2C T1–T15: fresh Unix-only PG17, actual canonical Essay migrations/RPCs.
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
 ap=argparse.ArgumentParser();ap.add_argument('--pg-bin',type=Path,required=True);ap.add_argument('--live-catalog',type=Path);args=ap.parse_args()
 env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
 def run(cmd,**kw):return subprocess.run(list(map(str,cmd)),check=True,capture_output=True,text=True,env=env,**kw).stdout
 assert ' 17.' in run([args.pg_bin/'postgres','--version'])
 with tempfile.TemporaryDirectory(prefix='lsa2c-',dir='/private/tmp') as temp:
  root=Path(temp);sock=root/'socket';sock.mkdir();data=root/'db';started=False
  run([args.pg_bin/'initdb','-D',data,'-U','postgres','--auth=trust','--no-locale','--encoding=UTF8'])
  try:
   run([args.pg_bin/'pg_ctl','-D',data,'-l',root/'server.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']);started=True
   with psycopg.connect(host=str(sock),port=5432,user='postgres',dbname='postgres',autocommit=True) as c:
    def scalar(q,p=()):return c.execute(q,p).fetchone()[0]
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
    names=['20260912000100','20260913000100','20260927000100','20260927000200','20260928000100','20260928000200','20260928000300','20260928000400','20260929000100','20260929000200','20260929000300','20260929000400']
    for version in names:c.execute(next((R/'supabase/migrations').glob(version+'_*.sql')).read_text())
    if args.live_catalog:
     live=json.loads(args.live_catalog.read_text())['rows'][0]['catalog']
     tables={t['name']:t for t in live['tables']};count=0
     names_used=['universities','resources','essay_questions','essay_exams','essay_attempts','essay_practice_sessions','essay_evaluations','essay_evaluation_dimensions','essay_evaluation_criteria','essay_improvement_items','essay_improvement_progress','essay_question_evidence','essay_evaluation_evidence','essay_generated_rewrites','essay_ai_processing_runs']
     for name in names_used:
      livecols={x['name']:x['type'] for x in tables['public.'+name]['columns']}
      for col,typ in c.execute("select attname,format_type(atttypid,atttypmod) from pg_attribute where attrelid=%s::regclass and attnum>0 and not attisdropped",('public.'+name,)):
       assert livecols.get(col)==typ,(name,col,typ,livecols.get(col));count+=1
     funcs={f['name']:f for f in live['functions']}
     for name in ['essay_private.scaffold_validate','essay_private.scaffold_finalize_v13','essay_private.scaffold_context','public.essay_finalize_success']:
      assert scalar("select md5(btrim(prosrc,chr(32)||chr(9)||chr(10)||chr(13))) from pg_proc where pronamespace=split_part(%s,'.',1)::regnamespace and proname=split_part(%s,'.',2)",(name,name))==funcs[name]['body_md5'],name
     print('LIVE_SCHEMA_COMPATIBILITY PASS',count,'column types; 4 exact canonical function bodies')
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
    policy_sql="select jsonb_agg(to_jsonb(p) order by tablename,policyname) from pg_policies p where schemaname='public'"
    policies=scalar(policy_sql)
    acl_sql="select jsonb_agg(jsonb_build_array(relname,relowner,relacl::text) order by relname) from pg_class where relnamespace='public'::regnamespace and relkind='r' and relname<>'quality_operators'"
    acls=scalar(acl_sql)
    function_acl_sql="select jsonb_agg(jsonb_build_array(oid::text,proacl::text,proconfig) order by oid) from pg_proc where pronamespace in ('public'::regnamespace,'essay_private'::regnamespace) and proname not in ('is_quality_operator','ql_list_cases','ql_case_detail')"
    function_acls=scalar(function_acl_sql)
    essay_tables=[x[0] for x in c.execute("select tablename from pg_tables where schemaname='public' and tablename like 'essay_%'")]
    def essay_fingerprint():
     return {t:scalar(sql.SQL("select md5(coalesce(string_agg(to_jsonb(x)::text,'|' order by to_jsonb(x)::text),'')) from public.{} x").format(sql.Identifier(t))) for t in essay_tables}
    original_essay=essay_fingerprint()
    c.execute(M.read_text())
    c.execute((V/'owner_register.sql').read_text().replace('REPLACE_WITH_CONFIRMED_OPERATOR_UUID',OP).replace('REPLACE_WITH_CONFIRMED_NORMAL_STUDENT_UUID',B))
    for role in ['anon','authenticated']:
     for priv in ['SELECT','INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER','MAINTAIN']:
      assert not scalar('select has_table_privilege(%s,%s,%s)',(role,'public.quality_operators',priv))
    for signature in ['is_quality_operator()','ql_list_cases(integer,timestamptz,uuid)','ql_case_detail(uuid)']:
     for role,want in [('anon',False),('authenticated',True),('service_role',False)]:
      assert scalar('select has_function_privilege(%s,%s,%s)',(role,'public.'+signature,'EXECUTE'))==want
     assert scalar("select prosecdef and array_length(proconfig,1)=1 and proconfig[1]='search_path=\"\"' from pg_proc where oid=%s::regprocedure",('public.'+signature,))
    assert scalar(function_acl_sql)==function_acls
    denied(lambda:rpc('ql_list_cases',uid=None,role='anon'));print('T1 PASS; exact new-object ACL/search_path matrix PASS')
    denied(lambda:rpc('ql_list_cases',uid=A));print('T2 PASS')
    assert rpc('is_quality_operator',uid=OP) is True;print('T3 PASS')
    denied(lambda:rpc('ql_list_cases',[1,None,None,OP],uid=A));denied(lambda:rpc('ql_case_detail',[first],uid=A,extra={'quality_operator':True}));denied(lambda:rpc('ql_list_cases',uid=OP,extra={'sub':A}));print('T4 PASS')
    for uid,exp in [(new(),None),(None,None),('invalid',None),(OP,0)]:denied(lambda:rpc('ql_list_cases',uid=uid,exp=exp))
    print('T5 PASS (expired/malformed request context; gateway signature verification separate)')
    text=M.read_text();assert 'service_role_key' not in text and 'sb_secret_' not in text;print('T6 PASS (artifact values scanned separately)')
    assert len(rpc('ql_list_cases',[1000],uid=OP)['cases'])==100
    assert len(rpc('ql_list_cases',[0],uid=OP)['cases'])==1
    seen=[];cursor=None
    while True:
     page=rpc('ql_list_cases',[7,cursor['requested_at'] if cursor else None,cursor['evaluation_id'] if cursor else None],uid=OP)
     seen += [x['evaluation_id'] for x in page['cases']];cursor=page['next_cursor']
     if cursor is None:break
    assert len(seen)==len(set(seen))==108
    assert body not in json.dumps(page);denied(lambda:rpc('ql_list_cases',[2,'2026-01-01T00:00:00Z',None],uid=OP));print('T7 PASS including timestamp ties')
    d=rpc('ql_case_detail',[first],uid=OP);assert d['student_submission']['answer_full_text']==body
    denied(lambda:rpc('ql_case_detail',[first],uid=A))
    def keys(v):
     if isinstance(v,dict):return set(v).union(*(keys(x) for x in v.values()))
     if isinstance(v,list):return set().union(*(keys(x) for x in v))
     return set()
    assert not keys(d).intersection({'user_id','email','phone','oauth_identity','full_name'})
    assert d['frozen_evidence_bindings'] and d['frozen_criterion_bindings'] and d['evaluation_evidence_links']
    assert d['processing']['cost_amount'] is None and d['generated_rewrite'] is None
    print('T8 PASS full answer, identity minimization, frozen evidence, NULL cost')
    assert scalar(policy_sql)==policies and scalar(acl_sql)==acls
    for u,want in [(A,3),(B,0),(OP,0)]:
     with c.transaction():
      c.execute('set local role authenticated');c.execute("select set_config('request.jwt.claim.sub',%s,true)",(u,));assert scalar('select count(*) from public.essay_attempts')==want
      try:
       with c.transaction():c.execute('insert into public.quality_operators(user_id) values(%s)',(B,))
      except psycopg.errors.InsufficientPrivilege:pass
      else:raise AssertionError('self enrollment')
    print('T9 PASS student RLS + direct operator table denied')
    c.execute("update public.profiles set neis_office_code='B10',neis_school_code='SYNTHETIC',grade_level=3 where id=%s",(B,))
    denied(lambda:rpc('ql_list_cases',uid=B));print('T10 PASS')
    sent=d['sentence_feedback'][0];assert sent['quote']==body[sent['start']:sent['end']]=='가' and sent['linked_issue_key']=='polish' and sent['example']=='Optional';print('T11 PASS Unicode + real root')
    assert d['core_improvement_keys']==['coreA','coreB'];assert {x['issue_key'] for x in d['improvements'] if x['is_core']}=={'coreA','coreB'};print('T12 PASS explicit membership, non-core also priority1; original CORE order')
    z=rpc('ql_case_detail',[zero],uid=OP);assert z['core_improvement_keys']==z['sentence_feedback']==z['improvements']==[];print('T13 PASS')
    assert next(x for x in d['improvements'] if x['issue_key']=='polish')['is_core'] is False
    d2=rpc('ql_case_detail',[second],uid=OP);assert d2['improvements'][0]['previous_progress']['progress_id']==previous['coreB'];assert 'Unavailable comparison' in d2['evaluation']['uncertainty_note'];assert d2['history_context']['selected_previous_evaluation_id']==first;assert len(d2['student_attempts'])==2
    print('T14 PASS non-core + actual finalize progress/uncertainty')
    # Evidence for deferred global-list index candidate; no index added.
    plan=scalar('explain (format json) select e.id from public.essay_evaluations e order by requested_at desc,id desc limit 101')
    print('PLAN',json.dumps(plan))
    # RESTRICT prevents a rollback from silently removing an unexpected dependent object.
    c.execute('create view public.quality_dependency_fixture as select * from public.quality_operators')
    try:c.execute((V/'rollback.sql').read_text())
    except psycopg.errors.DependentObjectsStillExist:c.execute('rollback')
    else:raise AssertionError('rollback bypassed unexpected dependency')
    assert scalar("select to_regprocedure('public.ql_case_detail(uuid)')") is not None
    c.execute('drop view public.quality_dependency_fixture')
    c.execute((V/'rollback.sql').read_text());assert scalar(function_acl_sql)==function_acls
    assert scalar(policy_sql)==policies and scalar(acl_sql)==acls
    assert scalar("select to_regclass('public.quality_operators')") is None
    assert scalar('select count(*) from public.essay_attempts')==3
    assert essay_fingerprint()==original_essay
    print('T15 PASS bounded rollback; all original policies/ACLs/data fingerprints retained')
  finally:
   if started:run([args.pg_bin/'pg_ctl','-D',data,'-m','fast','-w','stop'])
if __name__=='__main__':main()
