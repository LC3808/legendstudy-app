"""Local API surface integration atop real canonical Ledger schema.
Lifecycle/Package lookups use explicit synthetic fixtures, not production evidence.
"""
import json,uuid,tempfile,time,re,os,asyncio
from .material_runtime import NS, ReservedExamRuntime
from .durable_journal import DurableJournal
from .reviewed_runtime import reviewed_openai
from .positive_learning import PROMPT_VERSION
from .live_worker import SignedReview,Unknown
from tool.test_essay_live_worker import receipt

def cases(sql, root, user, account, exam, question):
    def literal(v):return "'"+json.dumps(v,ensure_ascii=False).replace("'","''")+"'::jsonb"
    sql((root/'supabase/candidates/essay_exam_unit/provider-policy.sql').read_text())
    # Use the real deployed lifecycle bodies, including subject advisory locking.
    # The deletion table below is a local fixture; no deletion worker is run.
    sql("create schema math_private;create schema account_private;create table public.account_deletion_requests(subject_id uuid,state text);")
    lifecycle=(root/'supabase/migrations/20261001000300_account_deletion_lifecycle.sql').read_text()
    math=(root/'supabase/migrations/20261002000100_math_essay_persistence.sql').read_text()
    for name, source in [('account_private.lock_subject',lifecycle),('account_private.allowed',lifecycle),('math_private.require_active',math)]:
        match=re.search(r'create (?:or replace )?function '+re.escape(name)+r'\(.*?\$(?:math_fn)?\$;',source,re.S|re.I)
        assert match, name
        sql(match.group(0))
    # Match the verified production deployer: NOSUPERUSER+BYPASSRLS; it cannot
    # execute essay_executor's private hash helper. Do not mask ownership failures.
    sql("grant select,insert,update,delete,references,trigger on all tables in schema public to postgres;alter role postgres nosuperuser bypassrls;")
    assert sql("select has_function_privilege('postgres','essay_private.hash(text)','EXECUTE')")=='f'

    pkg=dict(university_id=sql(f"select university_id from public.essay_exams where id='{exam}'"),package_version=16,package_digest='f'*64,exam_identity={'track':'humanities'},questions=[{'question_id':question}])
    pkg.update(schema='essay-material-package-v1',verification_status='VERIFIED_MANIFEST',exam_id=exam,rights_status={'a'*64:{'providerTransmission':'APPROVED'}},exam_identity=dict(academic_year=2025,exam_type='mock',track='humanities',title='Fixture'))
    pkg['questions'][0].update(source_key='source:fixture',source_page_references=[dict(questionId=question,sourceHash='a'*64,role=role,startPage=1,endPage=1,evidenceText='Synthetic '+role,verification='VERIFIED') for role in ('question','shared_passage','intent','criteria')])
    sql(f"create function public.essay_material_runtime_package(p_exam uuid,p_digest text) returns jsonb language sql as $$select {literal(pkg)}$$;")
    sql((root/'supabase/candidates/essay_exam_unit/api.sql').read_text())
    binding=dict(policy_version='fixture-v1',provider='openai',model='fixture',model_version='fixture',prompt_version=PROMPT_VERSION,contract_version='1.3')
    regime='essay-v1.3/policy/'+sql(f"select encode(sha256(convert_to(({literal(binding)})::text,'UTF8')),'hex')")
    sql(f"create or replace function essay_private.provider_policy(p_regime text) returns jsonb language sql immutable as $$select {literal(binding)}$$;")
    policy=dict(evaluation_type='humanities',regime=regime,package_digest='f'*64)
    answer=[dict(questionId=question,body='Synthetic answer',revision=1)]
    key=str(uuid.uuid4());dispatch=None;other=str(uuid.uuid4())
    def submit(a=answer,k=key,parent=None,subject=user,role='essay_worker',extra=''):
        return f"{extra}set role {role};select public.essay_exam_submit('{subject}','{exam}','{k}',{literal(a)},{'null' if parent is None else chr(39)+parent+chr(39)})"
    sql(submit(), 'EXAM_NOT_ACTIVATED')
    sql(f"create or replace function essay_exam_private.runtime_policy(p_exam uuid) returns jsonb language sql stable as $$select {literal(policy)}$$;")
    for role in ('authenticated','anon','service_role'):
        sql(submit(role=role),'permission denied')
    sql(f"insert into public.account_deletion_requests values('{user}','DELETION_PENDING')")
    sql(submit(),'ACCOUNT_RESTRICTED')
    sql(f"delete from public.account_deletion_requests where subject_id='{user}'")
    initial=sql(submit());assert sql(submit())==initial
    dispatch=str(uuid.uuid5(NS,'dispatch/'+user+'/'+initial))
    assert sql(f"select sum(reserved_delta) from public.credit_transactions where account_id='{account}'")=='1'
    def claim(run=initial,d=dispatch,subject=user):return f"set role essay_worker;select public.essay_exam_claim('{subject}','{run}','{d}')"
    c=json.loads(sql(claim()));assert c['lease_token']==json.loads(sql(claim()))['lease_token']
    sql(claim(d=str(uuid.uuid4())),'RECONCILIATION_REQUIRED')
    sql(f"insert into auth.users(id) values('{other}');insert into public.profiles(id) values('{other}');")
    sql(claim(subject=other),'PT403')
    version='material-16-'+'f'*64
    result=dict(summary='Synthetic summary',questions=[dict(questionId=question,rubricVersion=version,evidenceVersion=version,evaluation={'summary':'fixture','local_reviews':[{'private':'receipt'}]})])
    def finish(run=initial,token=c['lease_token'],r=result):return f"set role essay_worker;select public.essay_exam_finish('{user}','{run}','{token}',{literal(r)},false)"
    sql(finish(token=str(uuid.uuid4())),'PT403')
    # Execute the actual Package -> ReviewedRuntimeWorker -> Ledger RPC path.
    requests=[]
    class Response:
        def __init__(self,body):self.body=body
        def __enter__(self):return self
        def __exit__(self,*_):pass
        def read(self,_):return json.dumps(self.body).encode()
    def transport(req,timeout):
        value=json.loads(json.loads(req.data)['input']);requests.append(value)
        output=dict(contract_version='1.3',attempt_id=value['attempt_id'],answer_hash=value['answer_hash'],
            summary='Synthetic summary',strengths=['Synthetic strength'],checklist=['Synthetic checklist'],
            dimensions=[dict(criterion_id=c['reference']['id'],level=3,explanation='Synthetic explanation',evidence_ids=[value['evidence'][-1]['reference']['id']]) for c in value['criteria']],
            improvements=[],core_improvement_keys=[],previous_improvement_reviews=[],sentence_feedback=[])
        return Response(dict(status='completed',model='fixture',usage=dict(input_tokens=1,output_tokens=2,total_tokens=3),output=[dict(type='message',content=[dict(type='output_text',text=json.dumps(output))])]))
    def rpc(name,args):
        def arg(v):
            if isinstance(v,(dict,list)):return literal(v)
            if v is None:return 'null'
            if isinstance(v,bool):return str(v).lower()
            return "'"+str(v).replace("'","''")+"'"
        data=sql('set role essay_worker;select public.'+name+'('+','.join(k+'=>'+arg(v) for k,v in args.items())+')')
        try:return json.loads(data)
        except json.JSONDecodeError:return data
    registry={'exams':[dict(examId=exam,universityId=pkg['university_id'],year=2025,kind='mock',track='humanities',session=None,campus=None,name='Fixture',sourceHashes=['a'*64],questions=[dict(id=question,sourceKey='source:fixture')])]}
    async_mode=os.environ.get('ESSAY_ASYNC_TEST')=='1'
    if async_mode:
        from .cloudflare_runtime import CloudflareExamRuntime
        sql((root/'supabase/candidates/essay_cloudflare_execution/install.sql').read_text())
        writer=str(uuid.uuid4())
        def cp(action,key='probe',writer_id=writer,payload='null',subject=user):
            return f"set role essay_worker;select public.essay_exam_checkpoint('{subject}','{initial}','{c['lease_token']}','{key}','{action}','{writer_id}',{payload})"
        import concurrent.futures
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            attempts=list(pool.map(lambda _:json.loads(sql(cp('begin'))),range(4)))
        assert sum(v['started'] for v in attempts)==1
        sql(cp('write',writer_id=str(uuid.uuid4()),payload="'{}'::jsonb"),'PT409')
        sql(cp('write',payload="'{}'::jsonb"))
        sql(cp('write',payload="'{\"different\":true}'::jsonb"),'CHECKPOINT_IMMUTABLE')
        sql(cp('read',subject=other),'PT403')
        sql(cp('read').replace('set role essay_worker','set role authenticated'),'permission denied')
        provider=reviewed_openai('fixture-only',binding,transport=transport)
        provider.evaluate=provider.evaluate_async
        finish_attempts=[]
        async def async_rpc(name,args):
            if name=='essay_exam_finish':
                finish_attempts.append(args)
                if len(finish_attempts)==1:raise Unknown('LOCAL_LOST_FINALIZE')
            return rpc(name,args)
        async def async_review(*args):
            return receipt(*args)
        runtime=CloudflareExamRuntime(rpc=async_rpc,registry=registry,provider=provider,
            reviewer=SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),
            review_source=async_review,receipt_sink=lambda _:None,allowed_subjects=[user],enabled=True)
        async def execute():
            try:await runtime.consume({'subject_id':user,'run_id':initial})
            except Unknown:pass
            else:raise AssertionError('missing simulated interruption')
            assert await runtime.consume({'subject_id':user,'run_id':initial})=='completed'
            assert await runtime.consume({'subject_id':user,'run_id':initial})=='completed'
        asyncio.run(execute())
        assert len(requests)==1
        sql((root/'supabase/candidates/essay_cloudflare_execution/rollback.sql').read_text(),'NONEMPTY_CHECKPOINT_ROLLBACK_DENIED')
    else:
        with tempfile.TemporaryDirectory(prefix='exam-surface-journal-',dir='/private/tmp') as directory:
            runtime=ReservedExamRuntime(subject=lambda _:user,worker_rpc=rpc,registry=registry,journal=DurableJournal(directory),
                provider=reviewed_openai('fixture-only',binding,transport=transport),reviewer=SignedReview({'independent-test':b'test-only-not-deployed'},clock=lambda:100),
                review_source=receipt,receipt_sink=lambda _:None,clock=lambda:100)
            assert runtime.handle('/exam-admission','fixture',{'exam_id':exam})['ready']
            assert runtime.handle('/exam-evaluate','fixture',{'run_id':initial})['state']=='completed'
            assert runtime.handle('/exam-evaluate','fixture',{'run_id':initial})['state']=='completed'
            assert len(requests)==1 and requests[0]['answer']=='Synthetic answer'
    result=json.loads(sql(f"select result from essay_exam_private.runs where id='{initial}'"))

    assert result['questions'][0]['telemetry']['total_tokens']==3
    assert sql(f"select sum(balance_delta)||','||sum(reserved_delta) from public.credit_transactions where account_id='{account}'")=='2,0'
    def history(subject=user,run=initial):return json.loads(sql(f"set request.jwt.claim.sub='{subject}';set role authenticated;select public.essay_exam_history('{run}')"))
    h=history()['runs'][0];assert h['free_rewrite_available'];assert 'local_reviews' not in h['result']['questions'][0]['evaluation']
    assert history(other)['runs']==[]
    rewritten=[dict(questionId=question,body='Rewritten answer',revision=0)]
    second=sql(submit(rewritten,str(uuid.uuid4()),initial))
    secondclaim=json.loads(sql(claim(second,str(uuid.uuid4()))))
    assert sql(finish(second,secondclaim['lease_token']))=='completed'
    assert not history()['runs'][0]['free_rewrite_available']
    assert history(run=second)['runs'][0]['parent_id']==initial
    sql(submit(rewritten,str(uuid.uuid4()),initial),'REEVALUATION_ALREADY_USED')
    assert sql(f"select sum(balance_delta)||','||sum(reserved_delta) from public.credit_transactions where account_id='{account}'")=='2,0'
    rollback=(root/'supabase/candidates/essay_exam_unit/api-rollback.sql').read_text()
    sql(rollback,'NONEMPTY_EXAM_ROLLBACK_DENIED')
    if os.environ.get('ESSAY_TEST_CONTINUOUS_CYCLES') == '1':
        from .continuous_cycle_validation import cases as cycle_cases
        cycle_cases(sql,root,user,account,exam,question,initial)
    # Exact legacy Ledger facts survive account anonymization; answer/result runs do not.
    sql(f"update public.credit_accounts set user_id=null where id='{account}'")
    assert sql(f"select count(*) from essay_exam_private.runs where account_id='{account}'")=='0'
    assert sql(f"select sum(balance_delta)||','||sum(reserved_delta) from public.credit_transactions where account_id='{account}'")==('1,0' if os.environ.get('ESSAY_TEST_CONTINUOUS_CYCLES') == '1' else '2,0')
    if os.environ.get('ESSAY_TEST_CONTINUOUS_CYCLES') == '1':
        sql((root/'supabase/candidates/essay_continuous_cycles/rollback.sql').read_text())
    if async_mode:
        assert sql('select count(*) from essay_exam_private.checkpoints')=='0'
        sql((root/'supabase/candidates/essay_cloudflare_execution/rollback.sql').read_text())
    sql(rollback)
    assert sql("select count(*) from public.credit_transactions")!='0'
    formal=(root/'supabase/migrations/20261014023133_essay_exam_operating_api.sql').read_text()
    sql(formal)
    sql(formal,'EXAM_API_ALREADY_INSTALLED_OR_DRIFT')
    assert sql("select count(*) from essay_exam_private.runs")=='0'
    assert sql(f"select essay_exam_private.runtime_policy('{exam}') is null")=='t'
    sql(rollback)
    print('PASS: full local Package -> Provider adapter(fake transport) -> Ledger -> History; worker-only submit/claim/finish, owner-isolated shared History, 1 Credit, included rewrite, exact replay, lease fencing, receipt redaction, erasure preserves Ledger. Synthetic local fixtures only.')
