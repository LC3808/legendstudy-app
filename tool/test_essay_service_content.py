"""Actual frozen content + canonical PG17 import/draft/submit/rewrite. No real provider."""
import copy,json,os,hashlib
import psycopg
from pathlib import Path
import test_human_quality as harness
from essay_lab.service_content import prepare,import_isolated,cache_for_claim,EXAM_ID,RESOURCE_ID
R=Path(__file__).resolve().parents[1]

def verify(c,rpc,new,scalar,first,second,zero,A,B,OP,session,previous,args,sock):
 root=Path(os.environ['ESSAY_PRIVATE_PACKAGE'])
 package=json.loads((root/'package.json').read_text())
 manifest=json.loads((R/'tool/essay_lab/evidence/skku_2025_humanities1_manifest.json').read_text())
 figure=(root/'q2-data-1.png').read_bytes()
 plan=prepare(package,manifest,figure);checks=[]
 def ok(name,condition=True):assert condition,name;checks.append(name);print(name,'PASS',flush=True)
 def reject(name,fn):
  try:fn()
  except (ValueError, psycopg.Error):
   checks.append(name);print(name,'PASS',flush=True);return
  raise AssertionError(name)
 ok('existing_package_three_real_questions_nine_official_dimensions',len(plan['questions'])==3 and len(plan['criteria'])==9)
 ok('no_grade_bands_as_dimensions',all(x['criterion_key'][-1] in '①②③' for x in plan['criteria']))
 ok('no_official_example_in_provider_projection',all(e['role'] not in ('example_answer','model_answer','high_scoring_answer') for q in plan['private_content'] for e in q['evaluator_evidence']))
 reject('changed_figure_denied',lambda:prepare(package,manifest,b'changed'))
 altered=copy.deepcopy(package);altered['evidence'][0]['text']+='changed'
 reject('changed_source_denied',lambda:prepare(altered,manifest,figure))
 # Existing schema only; exact source metadata imported into this disposable fixture.
 source=json.loads((R/'tool/essay_lab/evidence/skku_2025_humanities1_source.json').read_text())
 u=source['university'];c.execute('insert into public.universities(id,slug,name,is_active) values(%s,%s,%s,true)',(u['id'],u['slug'],u['name']))
 sp,ci=new(),new()
 c.execute("insert into public.source_posts(id,source,external_post_id,url,title) values(%s,'isolated-source','1689','https://legendstudy.com/1689','Private source fixture')",(sp,))
 c.execute("insert into public.content_items(id,source_post_id,source_content_key,slug,content_type,title,source_url,is_active) values(%s,%s,'source','private-source','university_essay','Private source fixture','https://legendstudy.com/1689',true)",(ci,sp))
 c.execute("insert into public.resources(id,content_item_id,source_post_id,source_resource_key,title,source_url,is_active) values(%s,%s,%s,'source','Private source fixture','https://example.edu/isolated-source',true)",(RESOURCE_ID,ci,sp))
 c.execute("insert into public.essay_exams(id,university_id,admission_year,exam_key,exam_name,exam_kind,provenance,verification_status,verified_at,official_source_url,evidence_note,is_active) values(%s,%s,2025,'regular-humanities-1','Private source fixture','admission','official','verified',now(),'https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290','Isolated source fixture',true)",(EXAM_ID,u['id']))
 for m in source['mappings']:
  c.execute("insert into public.essay_exam_resources(essay_exam_id,resource_id,role,source_locator,provenance,verification_status,verified_at,official_source_url,evidence_note,is_active) values(%s,%s,%s,%s,'official','verified',now(),'https://admission.skku.edu/admission/html/ipsi/noticeView.html?idx=59290','Isolated source fixture',true)",(EXAM_ID,RESOURCE_ID,m['role'],m['source_locator']))
 class Rollback(Exception):pass
 try:
  with c.transaction():
   import_isolated(c,plan)
   raise Rollback()
 except Rollback:pass
 ok('rollback_removes_entire_import',scalar('select count(*) from public.essay_questions where essay_exam_id=%s',(EXAM_ID,))==0)
 counts=import_isolated(c,plan);ok('actual_existing_schema_import',counts==dict(questions=3,evidence=34,criteria=9,published=0))
 before=scalar('select count(*) from public.essay_question_evidence')
 import_isolated(c,plan);ok('exact_replay_no_duplicate',scalar('select count(*) from public.essay_question_evidence')==before)
 altered=copy.deepcopy(plan);altered['questions'][0]['label']='changed'
 reject('conflicting_import_no_overwrite',lambda:import_isolated(c,altered))
 qid=plan['questions'][0]['id']
 with c.transaction():
  c.execute('set local role anon')
  ok('unpublished_questions_hidden',scalar('select count(*) from public.essay_questions where id=%s',(qid,))==0)
 # Publication only in isolated fixture to exercise canonical student RPC; never in importer.
 c.execute('update public.essay_questions set is_published=true where id=%s',(qid,))
 se=str(rpc('essay_open_session',[new(),qid]));draft=scalar('select revision from public.essay_drafts where session_id=%s',(se,))
 body='독립 테스트용 학생 답안입니다. 실제 Provider에 전송하지 않습니다.'
 rev=rpc('essay_save_draft',[se,draft,body,'web_desktop','practice',0]);key=new();digest=hashlib.sha256(body.encode()).hexdigest()
 attempt=str(rpc('essay_submit_attempt',[se,rev,key,digest]));ok('canonical_submit_replay',str(rpc('essay_submit_attempt',[se,rev,key,digest]))==attempt)
 reject('foreign_draft_save_denied',lambda:rpc('essay_save_draft',[se,rev,'foreign','web_desktop','practice',0],uid=B))
 reject('stale_draft_revision_denied',lambda:rpc('essay_save_draft',[se,draft,'stale','web_desktop','practice',0]))
 evaluation=str(rpc('essay_request_evaluation',[attempt,new(),'essay-v1.3']))
 claim=rpc('essay_claim',[evaluation],role='essay_worker')
 ok('official_criteria_reach_frozen_claim',len(claim['input']['criteria'])==3 and len(claim['input']['evidence'])>=4)
 cache=cache_for_claim(plan,qid,claim)
 ok('real_evidence_connected_to_existing_worker',len(cache['criteria'])==3 and all(e['text'] for e in cache['evidence']))
 changed=copy.deepcopy(claim);changed['input']['evidence'][0]['hash']='0'*64
 reject('wrong_snapshot_evidence_denied',lambda:cache_for_claim(plan,qid,changed))
 reject('missing_graph_never_text_dispatch',lambda:cache_for_claim(plan,plan['questions'][1]['id'],claim))

 rpc('essay_finalize_failure',[evaluation,claim['run_id'],claim['lease_token']],role='essay_worker')
 status=rpc('essay_evaluation_status',[evaluation]);ok('failure_releases_credit',status['state']=='failed' and status['no_credit_consumed'])
 rev2=rpc('essay_save_draft',[se,rev,body+' 직접 재작성.','web_desktop','practice',0]);a2=rpc('essay_submit_attempt',[se,rev2,new(),hashlib.sha256((body+' 직접 재작성.').encode()).hexdigest()])
 ok('immutable_original_and_rewrite_same_session',str(a2)!=attempt and scalar('select count(*) from public.essay_attempts where session_id=%s',(se,))==2)
 out=R/'supabase/verification/essay_service';out.mkdir(parents=True,exist_ok=True)
 (out/'content-validation.json').write_text(json.dumps({'environment':'isolated PG17','real_provider_calls':0,'production_writes':0,'package_version':plan['package_version'],'checks':checks,'count':len(checks)},indent=2)+'\n')

harness.verify_hqp=verify
if __name__=='__main__':harness.main()
