"""No-Provider Ewha adapter and isolated PostgreSQL apply/rollback checks."""
from __future__ import annotations
import argparse, base64, copy, hashlib, importlib.util, json, os, re, subprocess, sys, tempfile
from pathlib import Path
APP=Path(__file__).resolve().parents[1]

def run(app, snapshot, pg):
    root=app/'.local/ewha-public-20261112'; candidate=app/'supabase/candidates/ewha_public_20261112'
    read=lambda p:json.loads(p.read_text())
    packages=read(root/'essay-packages.private.json'); registry=read(root/'essay-registry.private.json')
    functions=read(root/'essay-baseline-functions.private.json')
    sys.path.insert(0,str(snapshot))
    from essay_lab.live_worker import package as worker_package, validate_output, Invalid
    from essay_lab.material_runtime import reviewed_material_question as old_adapter
    from essay_lab.exam_runtime import ExamQuestionChannel
    spec=importlib.util.spec_from_file_location('essay_lab.ewha_candidate_material_runtime',root/'essay-material-runtime.proposed.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    bind=lambda p,q,fn:fn(p,registry,q,pinned_digest=p['package_digest'],binding={},regime='essay-v1.3/policy/'+'a'*64,evaluation_type='humanities',approved_processing=True)[0]
    canonical_spec=importlib.util.spec_from_file_location('essay_lab.ewha_canonical_material_runtime',app/'tool/essay_lab/material_runtime.py')
    canonical_module=importlib.util.module_from_spec(canonical_spec);canonical_spec.loader.exec_module(canonical_module)
    old_failures=0; positive=0; output_count=0; images_count=0; role_guard_count=0
    for eid,p in packages.items():
        for q in p['questions']:
            try:bind(p,q['question_id'],old_adapter)
            except Invalid as error:
                assert str(error)=='FOREIGN_OFFICIAL_IMAGE';old_failures+=1
            else:raise AssertionError('EXPECTED_DEPLOYED_ADAPTER_INCOMPATIBILITY')
            hosted=bind(p,q['question_id'],module.reviewed_material_question);cache=hosted.frozen_cache
            assert bind(p,q['question_id'],canonical_module.reviewed_material_question).frozen_cache==cache
            assert hosted.approved_processing and hosted.reviewed_cache
            assert len(cache['official_images'])==len(q['official_images'])
            # All prior question/passage associations and exact text remain identical.
            legacy=copy.deepcopy(p)
            for lq in legacy['questions']:
                question_hash=next(m['sourceHash'] for m in lq['source_page_references'] if m['role']=='question')
                lq['official_images']=[i for i in lq['official_images'] if i['sourceHash']==question_hash]
            oldcache=bind(legacy,q['question_id'],old_adapter).frozen_cache
            assert {k:v for k,v in oldcache.items() if k!='official_images'}=={k:v for k,v in cache.items() if k!='official_images'}
            old_images={i['sha256']:i for i in oldcache['official_images']}
            assert all(i==old_images[i['sha256']] for i in cache['official_images'] if i['sha256'] in old_images)
            roles={e['binding']['id']:e['binding']['role'] for e in cache['evidence']}
            for image in cache['official_images']:
                matching=next(i for i in q['official_images'] if i['sha256']==image['sha256'])
                source_roles={module.ROLE[m['role']] for m in q['source_page_references'] if m['sourceHash']==matching['sourceHash'] and m['startPage']<=matching['startPage']<=matching['endPage']<=m['endPage']}
                assert {roles[x] for x in image['evidence_ids']}<=source_roles
                images_count+=1
            for cycle in range(2):
                answer='기술 계약 검증용 입력입니다.'+str(cycle)
                claim=dict(answer=answer,run_id='synthetic-run',lease_token='synthetic-token',input=dict(contract_version='1.3',attempt_id=f'synthetic-{q["question_id"]}-{cycle}',answer_hash=hashlib.sha256(answer.encode()).hexdigest(),evidence=[e['binding'] for e in cache['evidence']],criteria=[c['binding'] for c in cache['criteria']],scaffolding_context=dict(items=[],previous_core_progress_ids=[])))
                request=worker_package(claim,cache);assert request['exam_identity']['question_id']==q['question_id']
                result=dict(contract_version='1.3',attempt_id=claim['input']['attempt_id'],answer_hash=claim['input']['answer_hash'],summary='기술 계약 검증용 모의 출력. 실제 첨삭 아님.',strengths=[],checklist=[],dimensions=[dict(criterion_id=c['binding']['id'],level=3,explanation='모의 형식 검증',evidence_ids=[cache['evidence'][-1]['binding']['id']]) for c in cache['criteria']],improvements=[],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[])
                validate_output(result,claim)
                events=[];channel=ExamQuestionChannel(q['question_id'],claim,lambda kind,args:events.append(kind))
                channel('essay_claim',dict(p_evaluation=q['question_id']))
                assert channel('essay_finalize_success',dict(p_evaluation=q['question_id'],p_run='synthetic-run',p_token='synthetic-token',p_output=result))=='completed'
                resumed=ExamQuestionChannel(q['question_id'],claim,lambda *_:None);resumed.restore(channel.snapshot());assert resumed.output==result
                assert events==['claim','question_success'];output_count+=1
            positive+=1
    p=copy.deepcopy(next(iter(packages.values())));qid=p['questions'][0]['question_id']
    mutations=[lambda x:x['questions'][0]['official_images'][0].update(sourceHash='0'*64),lambda x:x['questions'][0]['official_images'][0].update(startPage=999,endPage=999),lambda x:x['questions'][0]['official_images'][0].update(sha256='0'*64),lambda x:x['questions'][0]['source_page_references'][2].update(role='example_answer')]
    for mutate in mutations:
        bad=copy.deepcopy(p);mutate(bad)
        try:bind(bad,qid,module.reviewed_material_question)
        except (Invalid,ValueError):role_guard_count+=1
        else:raise AssertionError('TAMPER_NOT_REJECTED')
    runtime=dict(status='PASS',original_live_adapter_rejections=old_failures,proposed_adapter_questions=positive,
      official_images_preserved=images_count,request_mock_result_rewrite_cycles=output_count,tamper_rejections=role_guard_count,
      prior_question_image_bindings_unchanged=True,provider_calls=0,actual_quality='NOT TESTED',browser='NOT TESTED',device='NOT TESTED')
    dump=lambda path,value:path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n')
    dump(candidate/'essay-runtime-validation.json',runtime)
    env={k:v for k,v in os.environ.items() if not k.startswith('PG')};env['LC_ALL']='C'
    command=lambda args,**kw:subprocess.run([str(a) for a in args],env=env,text=True,capture_output=True,**kw)
    lit=lambda s:"'"+str(s).replace("'","''")+"'"
    with tempfile.TemporaryDirectory(prefix='ewha-essay-') as directory:
        t=Path(directory);sock=t/'socket';sock.mkdir();data=t/'db'
        for args in [[pg/'initdb','-D',data,'-U','local_admin','--auth=trust','--no-locale','--encoding=UTF8'],[pg/'pg_ctl','-D',data,'-l',t/'postgres.log','-o',f"-k {sock} -p 5432 -c listen_addresses=''",'-w','start']]:
            r=command(args);assert not r.returncode,r.stderr
        try:
            def sql(query, failure=None):
                r=command([pg/'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-h',sock,'-U','local_admin','-d','postgres'],input=query)
                if failure:assert r.returncode and failure in r.stderr,r.stderr;return
                assert not r.returncode,r.stderr;return r.stdout.strip()
            sql("create schema essay_exam_private;create schema essay_material_private;create schema storage;create role authenticated;create table storage.buckets(id text primary key,public bool);insert into storage.buckets values('essay-material-originals',false);create table storage.objects(id int);create policy untouched on storage.objects for select to authenticated using(false);create table public.essay_exams(id uuid primary key,is_active bool);create table public.essay_questions(id uuid primary key,essay_exam_id uuid,question_key text,is_published bool);create table essay_material_private.documents(sha256 text primary key,resource_id uuid,title text,page_count int,object_key text,created_at timestamptz default now());create table essay_material_private.reviews(exam_id uuid primary key,revision int,state text,body jsonb,updated_at timestamptz default now(),reviewer uuid,approval_requested bool);create table essay_material_private.revisions(exam_id uuid,revision int,state text,body jsonb,reviewer uuid,created_at timestamptz default now(),primary key(exam_id,revision));create table essay_exam_private.runs(id uuid primary key,exam_id uuid,state text,result jsonb)")
            for name in ('runtime_policy','essay_material_runtime_package'):
                f=next(f for f in functions if f['proname']==name);sql(f['definition'])
            for exam in registry['exams']:
                sql(f"insert into public.essay_exams values({lit(exam['examId'])},false)")
                for q in exam['questions']:sql(f"insert into public.essay_questions values({lit(q['id'])},{lit(exam['examId'])},{lit(q['sourceKey'])},false)")
            oldid='00000000-0000-4000-8000-000000000003'
            sql(f"insert into public.essay_exams values({lit(oldid)},true);insert into public.essay_questions values({lit(oldid)},{lit(oldid)},'preserved',true);insert into essay_exam_private.runs values({lit(oldid)},{lit(oldid)},'completed','{{\"preserve\":true}}')")
            policy=next(f for f in functions if f['proname']=='runtime_policy');oldids=sorted(set(re.findall(r"p_exam='([a-f0-9-]{36})'",policy['definition'])))
            read_policies=lambda:sql("select jsonb_object_agg(e,essay_exam_private.runtime_policy(e::uuid)) from unnest(array["+','.join(lit(x) for x in oldids)+"]) e")
            before=read_policies()
            def checks(name):
                q=(candidate/name).read_text().strip().rstrip(';');v=json.loads(sql('select row_to_json(r) from ('+q+') r'));assert all(x is True for x in v.values()),v;return len(v)
            pre=checks('essay-precheck.sql')
            first=next(iter(packages));sql(f"insert into essay_exam_private.runs values('00000000-0000-4000-8000-000000000004',{lit(first)},'running',null)")
            sql((root/'essay-apply.private.sql').read_text(),'EWHA_ESSAY_BASELINE_CHANGED')
            sql("delete from essay_exam_private.runs where id='00000000-0000-4000-8000-000000000004'")
            sql((root/'essay-apply.private.sql').read_text());post=checks('essay-postcheck.sql')
            sql((root/'essay-apply.private.sql').read_text(),'EWHA_ESSAY_BASELINE_CHANGED')
            assert before==read_policies()
            assert sql('select count(*) from public.essay_questions where is_published')=='1'
            for eid,p in packages.items():
                actual=sql(f"select body->'package'->>'package_digest' from essay_material_private.reviews where exam_id={lit(eid)}");assert actual==p['package_digest']
            sql((candidate/'essay-rollback.sql').read_text());sql((candidate/'essay-rollback.sql').read_text())
            assert before==read_policies()
            assert sql('select count(*) from public.essay_questions where is_published')=='1'
            assert sql('select count(*) from essay_material_private.revisions')=='12'
            assert sql("select result->>'preserve' from essay_exam_private.runs")=='true'
            assert sql("select count(*) from pg_policies where policyname='untouched'")=='1'
            assert sql('select count(*) from essay_material_private.documents')=='24'
            outcome=dict(status='PASS',environment='isolated PostgreSQL17 Unix socket',prechecks=pre,postchecks=post,
              inserted_documents=24,inserted_reviews=12,inserted_revisions=12,runtime_connected_questions=36,legacy_registry_flags_preserved=True,
              old_runtime_entries_preserved=len(oldids),all_12_jsonb_digests_verified=True,reapply_blocked=True,
              existing_runs_block_apply=True,rollback_idempotent=True,rollback_keeps_all_materials_and_histories=True,
              existing_question_publication_unchanged=True,existing_RLS_unchanged=True,production_writes=0)
            dump(candidate/'essay-sql-validation.json',outcome)
        finally:command([pg/'pg_ctl','-D',data,'-m','immediate','-w','stop'])
    return dict(runtime=runtime,sql=outcome)

def verify_actual_packages(app, snapshot, source):
    """Read only a privately saved SELECT response; never fetch or evaluate a Provider."""
    import ast
    sys.path.insert(0,str(snapshot))
    from essay_lab.material_runtime import load_reviewed_material
    from prepare_ewha_essay_public import digest
    tree=ast.parse((snapshot/'registry_asset.py').read_text())
    registry=ast.literal_eval(next(n.value for n in tree.body if isinstance(n,ast.Assign)))
    expected=json.loads((app/'.local/ewha-public-20261112/essay-packages.private.json').read_text())
    rows=json.loads(source.read_text())
    if isinstance(rows,dict):rows=rows.get('rows',rows.get('result',rows))
    if isinstance(rows,list) and len(rows)==1 and 'packages' in rows[0]:rows=rows[0]['packages']
    assert isinstance(rows,list) and len(rows)==12
    checks=[]
    for row in rows:
        eid=row['exam_id'];package=row['package'];policy=row['policy']
        assert package==expected[eid]
        assert digest({k:v for k,v in package.items() if k!='package_digest'})==package['package_digest']==policy['package_digest']
        hosted,report=load_reviewed_material(package,registry,pinned_digest=policy['package_digest'],binding={},regime=policy['regime'],evaluation_type=policy['evaluation_type'],activation_approved=True)
        assert report['ready'] and set(hosted)=={q['question_id'] for q in package['questions']}
        checks.append(dict(exam_id=eid,questions=len(hosted),digest=policy['package_digest'],ready=True))
    result=dict(status='PASS',source='Actual operating read-only essay_material_runtime_package SELECT response',exams=len(checks),questions=sum(x['questions'] for x in checks),checks=checks,provider_calls=0,production_writes=0,quality='NOT TESTED',browser='NOT TESTED',device='NOT TESTED')
    (app/'supabase/candidates/ewha_public_20261112/essay-production-package-validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--app',type=Path,default=APP);p.add_argument('--worker-snapshot',type=Path,required=True);p.add_argument('--pg',type=Path,default=Path('/opt/homebrew/opt/postgresql@17/bin'));p.add_argument('--production-packages',type=Path);a=p.parse_args()
    print(json.dumps(verify_actual_packages(a.app,a.worker_snapshot,a.production_packages) if a.production_packages else run(a.app,a.worker_snapshot,a.pg)))
