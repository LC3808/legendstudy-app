"""Connect a server-generated, reviewed material package to the existing Runtime.
No evaluation engine, automatic approval, Provider call or database write.
The host supplies a trusted stored package + its pinned digest and approved policy.
"""
from hashlib import sha256
from uuid import UUID, uuid5
from .live_worker import require,digest
from .package_registry import bind_registered_package
NS=UUID('bfbc9384-f407-440d-aa9e-45e2f485a849')
ROLE={'question':'question','shared_passage':'passage','intent':'exam_intent',
      'criteria':'scoring_criteria','scoring':'scoring_criteria'}

def material_readiness(package, registry):
    """Content-only blockers, without exposing source text or granting approval."""
    issues=[]
    exams=[e for e in registry['exams'] if e['examId']==package.get('exam_id')]
    if len(exams)!=1:return [{'code':'EXAM_NOT_REGISTERED'}]
    exam=exams[0]
    for q in package.get('questions',[]):
        qid=q.get('question_id'); mappings=q.get('source_page_references',[])
        def issue(code,**extra):issues.append(dict(code=code,question_id=qid,**extra))
        registered=next((r for r in exam['questions'] if r['id']==qid),None)
        if not registered or registered['sourceKey']!=q.get('source_key'):issue('QUESTION_SOURCE_MISMATCH')
        for role in ('question','shared_passage','intent','criteria'):
            if not any(m.get('role')==role and str(m.get('evidenceText','')).strip() for m in mappings):issue('MISSING_EVIDENCE',role=role)
        for i,m in enumerate(mappings):
            if m.get('role') in ROLE and not str(m.get('evidenceText','')).strip():issue('EMPTY_MAPPING',index=i,role=m.get('role'))
            if m.get('verification')!='VERIFIED':issue('MAPPING_REVIEW_REQUIRED',index=i)
            if m.get('role')=='question' and m.get('sourceHash') not in exam['sourceHashes']:issue('QUESTION_DOCUMENT_MISMATCH',index=i)
        for source in sorted({m.get('sourceHash','') for m in mappings}):
            if package.get('rights_status',{}).get(source,{}).get('providerTransmission')!='APPROVED':issue('PROVIDER_RIGHTS_REQUIRED',source_hash=source)
    if not package.get('questions'):issues.append({'code':'QUESTIONS_REQUIRED'})
    return issues

def reviewed_material_question(package,registry,question_id,*,pinned_digest,binding,regime,evaluation_type,
                              approved_processing=False,length_requirement=None):
    require(evaluation_type in ('humanities','business'),'USE_EXISTING_MATH_OR_SCIENCE_RUNTIME')
    require(type(package) is dict and package.get('schema')=='essay-material-package-v1', 'MATERIAL_PACKAGE_REQUIRED')
    require(package.get('verification_status')=='VERIFIED_MANIFEST' and
            package.get('package_digest')==pinned_digest and
            isinstance(pinned_digest,str) and len(pinned_digest)==64, 'REVIEWED_PACKAGE_PIN_REQUIRED')
    require(type(package.get('package_version')) is int and package['package_version']>0,'PACKAGE_VERSION_REQUIRED')
    exams=[e for e in registry['exams'] if e['examId']==package['exam_id']]
    require(len(exams)==1,'EXAM_NOT_REGISTERED');exam=exams[0];identity=package['exam_identity']
    require(package['university_id']==exam['universityId'] and identity['academic_year']==exam['year'] and
            identity['exam_type']==exam['kind'] and identity['track']==exam['track'] and identity.get('title')==exam['name'], 'PACKAGE_EXAM_MISMATCH')
    registered=[q for q in exam['questions'] if q['id']==question_id]
    entries=[q for q in package['questions'] if q['question_id']==question_id]
    require(len(registered)==1 and len(entries)==1,'QUESTION_NOT_IN_EXAM');entry=entries[0]
    require(entry['source_key']==registered[0]['sourceKey'],'QUESTION_SOURCE_MISMATCH')
    mappings=entry['source_page_references'];require(mappings,'EVIDENCE_REQUIRED')
    version=f"material-{package['package_version']}-{pinned_digest}"
    evidence=[];criteria=[];unsupported=[]
    for index,m in enumerate(mappings):
        require(m.get('questionId')==question_id and m.get('verification')=='VERIFIED', 'MAPPING_REVIEW_REQUIRED')
        require(type(m.get('startPage')) is int and type(m.get('endPage')) is int and 1<=m['startPage']<=m['endPage'],'INVALID_PAGE_RANGE')
        source=m['sourceHash'];require(isinstance(source,str) and len(source)==64,'SOURCE_HASH_REQUIRED')
        if approved_processing:
            require(package.get('rights_status',{}).get(source,{}).get('providerTransmission')=='APPROVED','PROVIDER_RIGHTS_REQUIRED')
        if m['role'] not in ROLE:
            unsupported.append(m['role']);continue # Never relabel example answers as official criteria.
        text=m.get('evidenceText');require(isinstance(text,str) and text.strip(),'OFFICIAL_TEXT_REQUIRED')
        eid=str(uuid5(NS,f'{version}/{question_id}/evidence/{index}'))
        evidence.append({'binding':dict(id=eid,role=ROLE[m['role']],hash=source,version=version,
                          locator=f"PDF {m['startPage']}-{m['endPage']}"),
                         'text':text,'text_sha256':sha256(text.encode()).hexdigest()})
        if m['role']=='criteria':
            criteria.append({'binding':dict(id=str(uuid5(NS,f'{version}/{question_id}/criterion/{index}')),version=version),'label':text})
    require({e['binding']['role'] for e in evidence}=={'question','passage','exam_intent','scoring_criteria'},'EVIDENCE_COVERAGE')
    require(criteria,'OFFICIAL_CRITERIA_REQUIRED')
    cache={'contract_version':'1.3','evidence':evidence,'criteria':criteria,'length_requirement':length_requirement,
           'exam_identity':dict(university_id=exam['universityId'], exam_id=exam['examId'],
               question_id=question_id, academic_year=exam['year'], exam_type=exam['kind'],
               track=exam['track'], session=exam['session'], campus=exam['campus'])}
    sources={e['binding']['hash'] for e in evidence if e['binding']['role']=='question'}
    require(len(sources)==1,'QUESTION_DOCUMENT_MISMATCH')
    assignment={k:exam[k] for k in ('examId','universityId','year','kind','track','session','campus')}
    assignment.update(evaluationType=evaluation_type,questionId=question_id,sourceKey=entry['source_key'],
                      questionSourceHash=next(iter(sources)),cacheSha256=digest(cache))
    hosted=bind_registered_package(registry,assignment,cache,binding=binding,regime=regime,
                                   approved_processing=approved_processing,reviewed_cache=True)
    return hosted,{'package_digest':pinned_digest,'package_version':package['package_version'],
                   'not_forwarded_roles':sorted(set(unsupported)),'activation_granted':False}


def load_reviewed_material(package, registry, *, pinned_digest, binding, regime,
                           evaluation_type, activation_approved=False,
                           length_requirement=None):
    """Host startup hook: all question bindings from one trusted package or none.

    A review request is not activation authority. The deployment passes a separately
    approved activation flag and policy; student requests cannot supply these inputs.
    """
    issues=material_readiness(package,registry)
    require(package.get('package_digest')==pinned_digest,'REVIEWED_PACKAGE_PIN_REQUIRED')
    if issues:return {},{'ready':False,'issues':issues,'activation_granted':False}
    questions={};reports=[]
    for entry in package['questions']:
        q,report=reviewed_material_question(package,registry,entry['question_id'],
            pinned_digest=pinned_digest,binding=binding,regime=regime,
            evaluation_type=evaluation_type,approved_processing=activation_approved,
            length_requirement=length_requirement)
        questions[q.question_id]=q;reports.append(report)
    return questions,{'ready':True,'issues':[],'activation_granted':activation_approved,
                      'questions':reports}



def fetch_reviewed_material(worker_rpc, registry, *, exam_id, pinned_digest,
                            binding, regime, evaluation_type,
                            activation_approved=False, length_requirement=None):
    """Deployment hook using only the narrow worker RPC, never a service-role key."""
    package=worker_rpc('essay_material_runtime_package',
                       {'p_exam':exam_id,'p_digest':pinned_digest})
    require(type(package) is dict and package.get('exam_id')==exam_id,'PACKAGE_EXAM_MISMATCH')
    return load_reviewed_material(package,registry,pinned_digest=pinned_digest,
        binding=binding,regime=regime,evaluation_type=evaluation_type,
        activation_approved=activation_approved,length_requirement=length_requirement)


def execute_reviewed_material_exam(*, package, registry, pinned_digest, binding,
        regime, evaluation_type, activation_approved, frozen_run, journal,
        authorize, provider, reviewer, review_source, receipt_sink, finalize,
        summarize=None, length_requirement=None, clock=None):
    """Connect stored material to the existing durable exam runner.

    All arguments are trusted server inputs, never request JSON. frozen_run comes
    from an owned, reserved, immutable exam run. authorize/finalize must enforce
    the current account, allowlist and reservation lease. This is not an HTTP API
    and does not reserve Credit or grant activation. Unknown dispatch is never
    retried. A single submitted question uses its reviewed summary unchanged;
    multiple questions require the existing reviewed exam synthesis callback.
    """
    import time
    import re
    from copy import deepcopy
    from .durable_exam import DurableExamRunner
    from .live_worker import package as provider_package, provider_binding
    from .reviewed_runtime import ReviewedRuntimeWorker, RuntimePermit
    clock = clock or time.time
    run = deepcopy(frozen_run)
    require(type(run) is dict and set(run) == {
        'run_id', 'subject_id', 'exam_id', 'questions'
    }, 'INVALID_EXAM_RUN')
    require(run['exam_id'] == package.get('exam_id'), 'PACKAGE_EXAM_MISMATCH')
    require(activation_approved is True, 'CONTENT_HELD')
    require(isinstance(regime, str) and re.fullmatch(r'essay-v1\.3/policy/[a-f0-9]{64}', regime),
            'POLICY_REQUIRED')
    hosted, readiness = load_reviewed_material(package, registry,
        pinned_digest=pinned_digest, binding=binding, regime=regime,
        evaluation_type=evaluation_type, activation_approved=True,
        length_requirement=length_requirement)
    require(readiness['ready'] and hosted, 'MATERIAL_NOT_READY')
    questions = run['questions']
    require(type(questions) is list and bool(questions), 'QUESTIONS_REQUIRED')
    require(len(questions) == 1 or callable(summarize), 'EXAM_SYNTHESIS_REQUIRED')
    prepared = {}
    # Validate ALL selected questions before any journal intent or Provider call.
    # Exact list equality prevents quietly dropping a required official criterion.
    for q in questions:
        require(type(q) is dict and set(q) == {
            'questionId', 'rubricVersion', 'evidenceVersion', 'evaluationId', 'claim'
        }, 'INVALID_EXAM_QUESTION_SET')
        content = hosted.get(q['questionId'])
        require(content is not None, 'QUESTION_NOT_IN_EXAM')
        version = f"material-{package['package_version']}-{pinned_digest}"
        require(q['rubricVersion'] == version and q['evidenceVersion'] == version,
                'REVIEWED_PACKAGE_PIN_REQUIRED')
        cache = deepcopy(content.frozen_cache)
        claim = q['claim']
        require(claim['input']['evidence'] == [e['binding'] for e in cache['evidence']]
                and claim['input']['criteria'] == [c['binding'] for c in cache['criteria']],
                'FROZEN_PACKAGE_MISMATCH')
        provider_package(claim, cache)
        require(provider_binding(claim, provider) == content.binding,
                'PERMIT_BINDING_MISMATCH')
        require(q['evaluationId'] not in prepared, 'DUPLICATE_EXAM_CHANNEL')
        prepared[q['evaluationId']] = (cache, content.binding)

    def build(channel, checkpoint):
        cache, policy = prepared[channel.evaluation_id]
        permit = RuntimePermit(channel.evaluation_id, digest(channel.claim['input']),
            digest(cache), policy, int(clock() + 90), True)
        return ReviewedRuntimeWorker(channel, provider, cache, reviewer, review_source,
            receipt_sink, checkpoint, permit=permit, clock=clock)

    # Configuration must fail before the first dispatch, including missing reviewer.
    from .exam_runtime import ExamQuestionChannel
    for q in questions:
        probe = ExamQuestionChannel(q['evaluationId'], q['claim'], lambda *_: None)
        build(probe, lambda _: None).authorize(q['evaluationId'])

    def synthesis(results):
        if len(results) == 1:
            return results[0]['evaluation']['summary']
        return summarize(results)

    return DurableExamRunner(journal).execute(**run, authorize=authorize,
        build_worker=build, summarize=synthesis, finalize=finalize)


class ReservedExamRuntime:
    """Private HTTP host composition for the existing DB lease + reviewed runtime.

    subject(token) must verify Auth online and the existing allowlist. worker_rpc
    uses only essay_worker. Construction does not enable public submission.
    """
    def __init__(self, *, subject, worker_rpc, registry, journal, provider, reviewer,
                 review_source, receipt_sink, summarize=None, clock=None):
        import time
        self.subject=subject;self.rpc=worker_rpc;self.registry=registry
        self.journal=journal;self.provider=provider;self.reviewer=reviewer
        self.review_source=review_source;self.receipt_sink=receipt_sink
        self.summarize=summarize;self.clock=clock or time.time

    def handle(self, path, token, payload):
        from copy import deepcopy
        from .live_worker import package as provider_package
        require(type(payload) is dict, 'INVALID_REQUEST')
        subject=self.subject(token);require(isinstance(subject,str) and subject,'ACCESS_DENIED')
        if path=='/exam-admission':
            require(set(payload)=={'exam_id'},'INVALID_REQUEST')
            policy=self.rpc('essay_exam_preflight',{'p_subject':subject,'p_exam':payload['exam_id']})
            hosted, report=fetch_reviewed_material(self.rpc,self.registry,
                exam_id=payload['exam_id'],pinned_digest=policy['package_digest'],
                binding=policy['binding'],regime=policy['regime'],evaluation_type=policy['evaluation_type'],
                activation_approved=True)
            from .reviewed_runtime import ReviewedRuntimeWorker,RuntimePermit
            for q in hosted.values():
                probe=ReviewedRuntimeWorker(self.rpc,self.provider,q.frozen_cache,self.reviewer,
                    self.review_source,self.receipt_sink,lambda _:None,
                    permit=RuntimePermit('preflight','unused',digest(q.frozen_cache),q.binding,int(self.clock()+90),True),clock=self.clock)
                probe.authorize('preflight')
            require(report['ready'] and hosted and self.journal.ready,'RUNTIME_UNAVAILABLE')
            return {'ready':True,'exam_id':payload['exam_id']}
        require(path=='/exam-evaluate' and set(payload)=={'run_id'},'INVALID_REQUEST')
        run_id=str(UUID(payload['run_id']))
        dispatch=str(uuid5(NS,'dispatch/'+subject+'/'+run_id))
        claimed=self.rpc('essay_exam_claim',{'p_subject':subject,'p_run':run_id,'p_dispatch':dispatch})
        if claimed['state'] in ('completed','failed'):return {'run_id':run_id,'state':claimed['state']}
        if claimed.get('dispatch_allowed') is not True:
            key='exam-'+digest(run_id)+'-final'
            with self.journal.lock(key):
                if self.journal.read(key) is None:return {'run_id':run_id,'state':'reconciling'}
        snap=claimed['snapshot'];policy=snap['runtime'];exam_id=claimed['exam_id']
        pkg=self.rpc('essay_material_runtime_package',{'p_exam':exam_id,'p_digest':policy['package_digest']})
        hosted, report=load_reviewed_material(pkg,self.registry,pinned_digest=policy['package_digest'],
            binding=policy['binding'],regime=policy['regime'],evaluation_type=policy['evaluation_type'],activation_approved=True)
        require(report['ready'] and claimed['subject_id']==subject and snap['ownerId']==subject,'EXAM_ACCESS_DENIED')
        questions=[];caches={}
        parent=claimed.get('parent_result')
        for answer in snap['answers']:
            qid=answer['questionId'];cache=hosted[qid].frozen_cache;caches[qid]=cache
            evaluation=str(uuid5(NS,'evaluation/'+run_id+'/'+qid))
            context={'items':[],'previous_core_progress_ids':[]}
            if claimed.get('parent_id'):
                previous=[q for q in parent['questions'] if q['questionId']==qid]
                require(len(previous)==1,'PRIOR_RESULT_REQUIRED')
                out=previous[0]['evaluation'];core=set(out['core_improvement_keys'])
                for item in out['improvements']:
                    progress=str(uuid5(NS,'progress/'+claimed['parent_id']+'/'+qid+'/'+item['issue_key']))
                    context['items'].append(dict(item,progress_id=progress))
                    if item['issue_key'] in core:context['previous_core_progress_ids'].append(progress)
            frozen=dict(contract_version='1.3',attempt_id=evaluation,
                answer_hash=sha256(answer['body'].encode()).hexdigest(),
                criteria=[c['binding'] for c in cache['criteria']],evidence=[e['binding'] for e in cache['evidence']],
                scaffolding_context=context,provider_binding=policy['binding'])
            claim=dict(run_id=run_id,lease_token=claimed['lease_token'],answer=answer['body'],
                input=frozen,provider_binding=policy['binding'])
            provider_package(claim,cache)
            questions.append(dict(questionId=qid,rubricVersion=answer['rubricVersion'],
                evidenceVersion=answer['evidenceVersion'],evaluationId=evaluation,claim=claim))

        def authorize(_):
            # Recheck Auth/lifecycle/lease on cached replay too; no guessed ownership.
            require(self.subject(token)==subject,'EXAM_ACCESS_DENIED')
            latest=self.rpc('essay_exam_claim',{'p_subject':subject,'p_run':run_id,'p_dispatch':dispatch})
            return latest.get('lease_token')==claimed['lease_token'] or latest.get('state') in ('completed','failed')

        def finish(record):
            result=deepcopy(record['result'])
            if result is not None:
                for index,q in enumerate(result['questions']):
                    q['criteria']=deepcopy(caches[q['questionId']]['criteria'])
                    usage_key='exam-'+digest(run_id)+'-q'+str(index)+'-usage'
                    with self.journal.lock(usage_key):usage=self.journal.read(usage_key)
                    require(type(usage) is dict,'PROVIDER_TELEMETRY_REQUIRED')
                    q['telemetry']={k:usage.get('p_'+k) for k in ('input_tokens','output_tokens','total_tokens','latency_ms','image_count','cost_amount','currency')}
            return self.rpc('essay_exam_finish',dict(p_subject=subject,p_run=run_id,
                p_token=claimed['lease_token'],p_result=result,p_failed=record['failed']))
        state=execute_reviewed_material_exam(package=pkg,registry=self.registry,
            pinned_digest=policy['package_digest'],binding=policy['binding'],regime=policy['regime'],
            evaluation_type=policy['evaluation_type'],activation_approved=True,
            frozen_run=dict(run_id=run_id,subject_id=subject,exam_id=exam_id,questions=questions),
            journal=self.journal,authorize=authorize,provider=self.provider,reviewer=self.reviewer,
            review_source=self.review_source,receipt_sink=self.receipt_sink,finalize=finish,
            summarize=self.summarize,clock=self.clock)
        return {'run_id':run_id,'state':state}
