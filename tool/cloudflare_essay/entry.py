"""Deployment entry. Disabled by default; no Provider/Credit startup calls."""
import json,hmac
from uuid import UUID
from urllib.error import HTTPError
from urllib.parse import urlparse
from workers import WorkerEntrypoint,Response,Request
from essay_lab.live_worker import require,SignedReview,Unknown
from essay_lab.operating_host import TEST_ORIGIN
from essay_lab.cloudflare_http import AsyncOperatingTransport,ORIGIN,provider_transport,fetch_bytes,parse_public_exams
from essay_lab.cloudflare_runtime import CloudflareExamRuntime
from essay_lab.reviewed_runtime import reviewed_openai,ReviewedRuntimeWorker,RuntimePermit,configured_binding
from essay_lab.material_runtime import load_reviewed_material
from essay_lab.semantic_review import openai_review
from essay_lab.live_worker import digest
from essay_lab.evaluation_policy import question_engine, policy_family
from registry_asset import REGISTRY
import time
from essay_lab.admin_run_actions import retry_admin_run,recover_admin_run
from essay_lab.admin_run_recovery import finish_saved_recovery

class Default(WorkerEntrypoint):
    async def math_child(self,payload):
        require(getattr(self.env,'ESSAY_MIXED_SESSION_ENABLED','false')=='true','MATH_CHILD_UNAVAILABLE')
        secret=getattr(self.env,'ESSAY_WORKER_SERVICE_TOKEN','')
        require(len(secret)>=32,'MATH_CHILD_UNAVAILABLE')
        try:
            # global_fetch_strictly_public routes this call to Pages (not the zone origin).
            # Authentication and the parent-lease fence still apply on this route.
            test=getattr(self.env,'ESSAY_TEST_BACKEND_ENABLED','false')=='true'
            url='https://legendstudy-task16b.pages.dev' if test else 'https://lab.legendstudy.com'
            return json.loads(await fetch_bytes(url+'/api/essay/math-session',
                {'Content-Type':'application/json','X-Essay-Service-Token':secret,**({'X-Test-Preview-Access':self.env.TEST_PREVIEW_ACCESS_KEY} if test else {})},json.dumps(payload),timeout=110,limit=1500000))
        except HTTPError as error:
            print('MATH_CHILD_HTTP_STATUS '+str(error.code))
            raise

    def transport(self):
        test=getattr(self.env,'ESSAY_TEST_BACKEND_ENABLED','false')=='true'
        return AsyncOperatingTransport(origin=TEST_ORIGIN if test else ORIGIN,test_backend=test,publishable_key=self.env.SUPABASE_PUBLISHABLE_KEY,
            worker_jwt=self.env.ESSAY_REGISTRY_WORKER_JWT,allowed_subjects=json.loads(self.env.ESSAY_ALLOWED_SUBJECTS),
            public_exams=parse_public_exams(getattr(self.env,'ESSAY_PUBLIC_EXAMS','[]')))

    def configuration(self,transport,binding=None):
        # No synthetic review callback or automatic signing fallback.
        mode=getattr(self.env,'ESSAY_REVIEW_MODE','service')
        require(mode in ('service','independent_model'),'REVIEW_MODE_REQUIRED')
        legacy=json.loads(self.env.ESSAY_PROVIDER_BINDING)
        raw=getattr(self.env,'ESSAY_PROVIDER_BINDINGS',None)
        approved=json.loads(raw) if raw else None
        def provider_for(policy):
            selected=configured_binding(policy,legacy,approved)
            result=reviewed_openai(self.env.ESSAY_PROVIDER_KEY,selected,transport=provider_transport)
            result.evaluate=result.evaluate_async
            return result
        provider=provider_for(legacy if binding is None else binding)
        keys={k:v.encode() for k,v in json.loads(self.env.ESSAY_REVIEW_VERIFY_KEYS).items()}
        require(keys,'REVIEWER_BLOCKED')
        async def review(evaluation,value,output):
            response=await self.env.ESSAY_REVIEWER.fetch(Request('https://essay-review.internal/review',method='POST',
                headers={'Content-Type':'application/json'},body=json.dumps({'evaluation_id':evaluation,'package':value,'output':output})).js_object)
            require(response.status==200,'REVIEW_UNAVAILABLE')
            return json.loads(await response.text())
        if mode=='independent_model':
            policy=json.loads(self.env.ESSAY_REVIEW_BINDING)
            require(set(policy)=={'reviewer_id','model','model_version'} and policy['reviewer_id'] in keys,'REVIEW_POLICY_REQUIRED')
            review=openai_review(key=self.env.ESSAY_PROVIDER_KEY,model=policy['model'],model_version=policy['model_version'],
                reviewer_id=policy['reviewer_id'],signing_key=keys[policy['reviewer_id']],transport=provider_transport)
        else:
            require(getattr(self.env,'ESSAY_REVIEWER',None) is not None,'REVIEW_SERVICE_REQUIRED')
        async def receipt(_):
            # Actual receipt persistence is supplied per-run below, never discard.
            raise Unknown('RECEIPT_PERSISTENCE_REQUIRED')
        quality_factory=None
        if getattr(self.env,'ESSAY_QUALITY_REPAIR_ENABLED','false')=='true':
            require(mode=='independent_model','INDEPENDENT_REVIEW_REQUIRED')
            from essay_lab.quality_repair import patch_schema,PATCH_INSTRUCTIONS
            from essay_lab.live_worker import OpenAIResponses
            def quality_factory(policy):
                selected=configured_binding(policy,legacy,approved)
                return OpenAIResponses(self.env.ESSAY_PROVIDER_KEY,selected['model'],patch_schema(),
                    instructions=PATCH_INSTRUCTIONS,prompt_version='quality-repair-2-1-v1',transport=provider_transport)
        return CloudflareExamRuntime(rpc=transport.rpc,registry=REGISTRY,provider=provider,
            reviewer=SignedReview(keys),review_source=review,receipt_sink=receipt,quality_provider_factory=quality_factory,
            allowed_subjects=transport.allowed,enabled=self.env.ESSAY_EXECUTION_ENABLED=='true',provider_factory=provider_for,public_exams=transport.public_exams,
            math_child=self.math_child if getattr(self.env,'ESSAY_MIXED_SESSION_ENABLED','false')=='true' else None)

    async def admission(self,t,subject,exam):
        require(subject in t.allowed or exam in t.public_exams,'EXAM_ACCESS_DENIED')
        require(await t.rpc('essay_exam_session_ready',{})=='exam-session-v1','EXAM_SESSION_CONTRACT_REQUIRED')
        policy=await t.rpc('essay_exam_preflight',dict(p_subject=subject,p_exam=exam))
        pkg=await t.rpc('essay_material_runtime_package',dict(p_exam=exam,p_digest=policy['package_digest']))
        hosted,report=load_reviewed_material(pkg,REGISTRY,pinned_digest=policy['package_digest'],binding=policy['binding'],regime=policy['regime'],evaluation_type=policy['evaluation_type'],activation_approved=True)
        runtime=self.configuration(t,policy['binding'])
        math_questions={}
        math_status=None
        family=policy_family(policy['evaluation_type'],pkg['exam_identity'])
        for q in hosted.values():
            if question_engine(family,q.frozen_cache.get('evaluation_engine','essay'))=='math':
                if math_status is None:math_status=await self.math_child({'action':'availability'})
                require(math_status.get('ready') is True and math_status.get('contract')=='essay-math-child-v1' and
                    math_status.get('model')==q.frozen_cache['provider_binding']['model'],'MATH_CHILD_UNAVAILABLE')
                math_questions[q.question_id]=q.frozen_cache['leaf']['id']
                continue
            worker=ReviewedRuntimeWorker(t.rpc,runtime.provider,q.frozen_cache,runtime.reviewer,runtime.review_source,runtime.receipt_sink,lambda _:None,
                permit=RuntimePermit('preflight','unused',digest(q.frozen_cache),policy['binding'],int(time.time()+90),True))
            worker.authorize('preflight')
        source=runtime.review_source
        key_bound=bool(getattr(source,'key',None) and runtime.reviewer.keys.get(getattr(source,'reviewer_id',''))==source.key)
        if getattr(self.env,'ESSAY_REVIEW_MODE','service')=='independent_model':require(key_bound,'REVIEW_KEY_BINDING_REQUIRED')
        return {'session_version':'exam-session-v1','ready':bool(report['ready'] and hosted),'package_version':pkg['package_version'],'package_digest':policy['package_digest'],'question_count':len(hosted),'question_ids':sorted(hosted),'math_questions':math_questions,'model':policy['binding']['model'],'review_key_binding':'PASS' if key_bound else 'EXTERNAL_SERVICE','provider_called':False}

    async def fetch(self,request):
        headers={'Cache-Control':'no-store'}
        stage='service_auth'
        try:
            secret=getattr(self.env,'ESSAY_WORKER_SERVICE_TOKEN','')
            require(len(secret)>=32 and hmac.compare_digest(request.headers.get('X-Essay-Service-Token',''),secret),'ACCESS_DENIED')
            require(request.method=='POST' and int(request.headers.get('Content-Length','0'))<=4096,'INVALID_REQUEST')
            raw=await request.text();require(len(raw.encode())<=4096,'INVALID_REQUEST')
            payload=json.loads(raw);path=urlparse(request.url).path
            token=request.headers.get('Authorization','').removeprefix('Bearer ')
            stage='transport_init'
            t=self.transport()
            if path in ('/admin-exam-retry','/admin-exam-recover','/admin-exam-recovery-check'):
                require(self.env.ESSAY_EXECUTION_ENABLED=='true','EVALUATION_EXECUTION_HELD')
                async def admin_rpc(name,args,caller):
                    nonlocal stage
                    stage='admin_read' if name in ('admin_lab_run_capabilities','admin_lab_run_recovery') else 'admin_mutation'
                    # Fixed functions, original JWT: SQL require_admin is authoritative.
                    require(name in ('admin_lab_run_capabilities','admin_lab_manage_run','admin_lab_run_recovery','admin_lab_recover_run'),'ACCESS_DENIED')
                    try:
                        raw=await fetch_bytes(t.origin+'/rest/v1/rpc/'+name,{'apikey':t.key,'Authorization':'Bearer '+caller,'Content-Type':'application/json'},json.dumps(args),error_limit=4096)
                        return json.loads(raw)
                    except HTTPError as error:
                        allowed={'RUN_ARCHIVED','ACTIVE_LEASE','FINALIZED_RUN','RECONCILIATION_REQUIRED','BILLING_NOT_RESERVED','NO_FAILED_QUESTIONS','ACTION_SUPERSEDED','ACTION_KEY_CONFLICT','RUN_NOT_FOUND','ADMIN_REQUIRED','DIAGNOSIS_CHANGED','RECOVERY_NOT_ALLOWED','BILLING_INCONSISTENT','RECOVERY_INTENT_REQUIRED'}
                        try: code=json.loads(error.read(4096)).get('message')
                        except Exception: code=None
                        raise Unknown(code if code in allowed else 'ADMIN_REQUIRED' if error.code in (401,403) else 'ADMIN_RPC_UNAVAILABLE' if stage=='admin_read' else 'RECOVERY_RESPONSE_UNCERTAIN') from None
                async def admission(subject,exam):
                    nonlocal stage
                    stage='runtime_admission'
                    return await self.admission(t,subject,exam)
                async def finish(action):
                    nonlocal stage
                    stage='verify_finish'
                    return await finish_saved_recovery(action,t.rpc,REGISTRY)
                async def enqueue(value):
                    nonlocal stage
                    stage='dispatch'
                    await self.env.ESSAY_QUEUE.send(json.dumps(value))
                if path=='/admin-exam-recovery-check':
                    require(type(payload) is dict and set(payload)=={'run_id'},'INVALID_REQUEST')
                    run=str(UUID(payload['run_id']))
                    diagnosis=await admin_rpc('admin_lab_run_recovery',{'p_run':run},token)
                    require(type(diagnosis) is dict and diagnosis.get('version')=='admin-run-recovery-v1' and diagnosis.get('run_id')==run,'ADMIN_CONTRACT_REQUIRED')
                    await admission(diagnosis['subject_id'],diagnosis['exam_id'])
                    stage='worker_rpc_read'
                    require(await t.rpc('essay_exam_recovery_quality_ready',{})=='quality-repair-2-1-v1','ADMIN_CONTRACT_REQUIRED')
                    return Response.json({'version':'admin-recovery-check-v1','run_id':run,'ready':True,'provider_called':False,'mutation_performed':False},headers=headers)
                if path=='/admin-exam-recover':
                    result=await recover_admin_run(payload,token,admin_rpc,admission,enqueue,finish)
                    return Response.json(result,status=202 if result['state']=='queued' else 409 if result['state']=='blocked' else 200,headers=headers)
                result=await retry_admin_run(payload,token,admin_rpc,admission,enqueue)
                return Response.json(result,status=202,headers=headers)
            subject=await t.subject(token)
            if path=='/connection-check':
                require(self.env.ESSAY_EXECUTION_ENABLED=='false' and set(payload)=={'probe_id'},'INVALID_REQUEST')
                probe=str(UUID(payload['probe_id']))
                result={'service_auth':'PASS','user_auth':'PASS','execution_enabled':False,'probe_id':probe}
                # Fixed read-only RPCs. Never claim/reserve/evaluate, return evidence or log credentials.
                calls=[('registry','essay_registered_questions',{'p_subject':subject}),
                    ('package','essay_material_runtime_package',{'p_exam':'345d3caa-3438-58c3-8f80-62a6242179ec','p_digest':'40ef4e7bbe5295facf146946b7f1924f086ff6e540108a3def8efb22e37ba4ae'}),
                    ('policy','essay_exam_preflight',{'p_subject':subject,'p_exam':'345d3caa-3438-58c3-8f80-62a6242179ec'})]
                for label,name,args in calls:
                    try:
                        raw=await fetch_bytes(ORIGIN+'/rest/v1/rpc/'+name,{'apikey':t.key,'Authorization':'Bearer '+t.worker,'Content-Type':'application/json'},json.dumps(args))
                        value=json.loads(raw)
                        result[label]={'http':200,**({'count':len(value)} if label=='registry' and isinstance(value,list) else {})}
                    except HTTPError as e:result[label]={'http':e.code}
                    except Exception:result[label]={'http':None}
                review_binding='ESSAY_REVIEW_BINDING' if getattr(self.env,'ESSAY_REVIEW_MODE','service')=='independent_model' else 'ESSAY_REVIEWER'
                result['missing_runtime_bindings']=[name for name in (review_binding,'ESSAY_PROVIDER_BINDING','ESSAY_PROVIDER_KEY','ESSAY_REVIEW_VERIFY_KEYS') if not getattr(self.env,name,None)]
                try:
                    result['runtime_admission']=await self.admission(t,subject,'345d3caa-3438-58c3-8f80-62a6242179ec')
                except Exception as error:
                    result['runtime_admission']={'ready':False,'code':type(error).__name__}
                await self.env.ESSAY_QUEUE.send(json.dumps({'kind':'connection_probe','probe_id':probe}))
                result['queue']='ENQUEUED'
                return Response.json(result,headers=headers)
            if path=='/exam-admission':
                require(set(payload)=={'exam_id'},'INVALID_REQUEST')
                return Response.json(await self.admission(t,subject,payload['exam_id']),headers=headers)
            require(path=='/exam-evaluate' and set(payload)=={'run_id'},'INVALID_REQUEST')
            require(self.env.ESSAY_EXECUTION_ENABLED=='true','EVALUATION_EXECUTION_HELD')
            # Read-only owner/lifecycle guard blocks old clients before enqueue.
            # The atomic consumer claim closes any later archive race.
            guard=await t.rpc('essay_exam_dispatch_guard',dict(p_subject=subject,p_run=str(UUID(payload['run_id']))))
            require(guard.get('state')!='archived','RUN_ARCHIVED')
            # Identity-only message. Consumer independently verifies owner/lifecycle/lease.
            # Native binding is a JS proxy: use its positional API. The default
            # structured-clone encoding preserves this JSON string on delivery.
            await self.env.ESSAY_QUEUE.send(json.dumps({'subject_id':subject,'run_id':payload['run_id']}))
            return Response.json({'run_id':payload['run_id'],'state':'queued'},status=202,headers=headers)
        except Exception as error:
            code=str(error)
            safe=code if 0<len(code)<=80 and all(c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789' for c in code) else type(error).__name__
            if locals().get('path') in ('/admin-exam-retry','/admin-exam-recover','/admin-exam-recovery-check'):
                known={'ACTIVE_LEASE','FINALIZED_RUN','RECONCILIATION_REQUIRED','BILLING_NOT_RESERVED','NO_FAILED_QUESTIONS','ACTION_SUPERSEDED','ACTION_KEY_CONFLICT','RUN_NOT_FOUND','ADMIN_REQUIRED','ADMIN_REQUEST_REJECTED','DIAGNOSIS_CHANGED','RECOVERY_NOT_ALLOWED','BILLING_INCONSISTENT','RECOVERY_INTENT_REQUIRED','RUN_ARCHIVED','ADMIN_RPC_UNAVAILABLE','RECOVERY_RESPONSE_UNCERTAIN','INVALID_REQUEST'}
                code=safe if safe in known else ('RECOVERY_RESPONSE_UNCERTAIN' if stage in ('admin_mutation','verify_finish','dispatch') else 'RECOVERY_RUNTIME_INIT_FAILED' if stage in ('transport_init','runtime_admission') else 'ADMIN_RPC_UNAVAILABLE' if stage in ('admin_read','worker_rpc_read') else 'RECOVERY_HANDLER_FAILED')
                # Fixed stage/code only; never exception text, answers, tokens or IDs.
                print('ESSAY_ADMIN_FAILURE '+stage+' '+code)
                return Response.json({'code':code,'stage':stage},status=403 if code in ('ADMIN_REQUIRED','ADMIN_REQUEST_REJECTED') else 422 if code=='INVALID_REQUEST' else 503 if code in ('RECOVERY_RESPONSE_UNCERTAIN','RECOVERY_RUNTIME_INIT_FAILED','ADMIN_RPC_UNAVAILABLE','RECOVERY_HANDLER_FAILED') else 409,headers=headers)
            print('ESSAY_REQUEST_FAILURE '+safe)
            if safe=='RUN_ARCHIVED':return Response.json({'code':safe},status=409,headers=headers)
            admin_codes={'ACTIVE_LEASE','FINALIZED_RUN','RECONCILIATION_REQUIRED','BILLING_NOT_RESERVED','NO_FAILED_QUESTIONS','ACTION_SUPERSEDED','ACTION_KEY_CONFLICT','RUN_NOT_FOUND','ADMIN_REQUIRED','ADMIN_REQUEST_REJECTED','DIAGNOSIS_CHANGED','RECOVERY_NOT_ALLOWED','BILLING_INCONSISTENT','RECOVERY_INTENT_REQUIRED'}
            if locals().get('path') in ('/admin-exam-retry','/admin-exam-recover') and safe in admin_codes:return Response.json({'code':safe},status=403 if safe in ('ADMIN_REQUIRED','ADMIN_REQUEST_REJECTED') else 409,headers=headers)
            return Response.json({'code':'RUNTIME_UNAVAILABLE'},status=503,headers=headers)

    async def queue(self,batch,*_context):
        for message in batch.messages:
            try:
                value=json.loads(message.body)
                if isinstance(value,dict) and value.get('kind')=='connection_probe':
                    require(self.env.ESSAY_EXECUTION_ENABLED=='false' and set(value)=={'kind','probe_id'},'INVALID_PROBE')
                    probe=str(UUID(value['probe_id']))
                    print('ESSAY_CONNECTION_PROBE_ACK '+probe)
                    message.ack()
                    continue
                t=self.transport();runtime=self.configuration(t)
                state=await runtime.consume(json.loads(message.body))
                if state=='continue':
                    # Durable question checkpoints make duplicate delivery safe.
                    # Send before ACK so a lost enqueue never loses the exam.
                    await self.env.ESSAY_QUEUE.send(message.body)
                    message.ack()
                elif state=='reconciling':message.retry()
                else:message.ack()
            except Exception as error:
                # Symbolic class only: messages/tracebacks may contain credentials.
                print('ESSAY_QUEUE_ERROR '+type(error).__name__)
                # An archive racing a checkpoint fence must not become an
                # automatic retry. ACK only an owner-checked archived response;
                # unavailable/denied/other states retain the existing retry.
                try:
                    identity=json.loads(message.body)
                    require(type(identity) is dict and set(identity)=={'subject_id','run_id'},'INVALID_JOB')
                    guard=await self.transport().rpc('essay_exam_dispatch_guard',dict(p_subject=str(UUID(identity['subject_id'])),p_run=str(UUID(identity['run_id']))))
                    if guard.get('state')=='archived':
                        message.ack()
                        continue
                except Exception:
                    pass
                message.retry() # DB intent prevents repeated Provider call.
