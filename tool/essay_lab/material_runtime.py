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
    cache={'contract_version':'1.3','evidence':evidence,'criteria':criteria,'length_requirement':length_requirement}
    sources={e['binding']['hash'] for e in evidence if e['binding']['role']=='question'}
    require(len(sources)==1,'QUESTION_DOCUMENT_MISMATCH')
    assignment={k:exam[k] for k in ('examId','universityId','year','kind','track','session','campus')}
    assignment.update(evaluationType=evaluation_type,questionId=question_id,sourceKey=entry['source_key'],
                      questionSourceHash=next(iter(sources)),cacheSha256=digest(cache))
    hosted=bind_registered_package(registry,assignment,cache,binding=binding,regime=regime,
                                   approved_processing=approved_processing,reviewed_cache=True)
    return hosted,{'package_digest':pinned_digest,'package_version':package['package_version'],
                   'not_forwarded_roles':sorted(set(unsupported)),'activation_granted':False}
