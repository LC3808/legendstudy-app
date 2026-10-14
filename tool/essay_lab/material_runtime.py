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
