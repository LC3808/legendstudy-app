"""Canonical identity adapter for the existing common Runtime, for any university.
Trusted reviewed package manifests only; never constructed from student HTTP input.
"""
from copy import deepcopy
from .live_worker import require,digest
from .runtime_host import HostedQuestion


def bind_registered_package(registry, assignment, cache, *, binding, regime,
                            approved_processing=False, reviewed_cache=False):
    require(assignment.get('evaluationType') in ('humanities','business'),'USE_EXISTING_MATH_OR_SCIENCE_RUNTIME')
    exams=[e for e in registry['exams'] if e['examId']==assignment['examId']]
    require(len(exams)==1,'EXAM_NOT_REGISTERED')
    exam=exams[0]
    for key in ('universityId','year','kind','track','session','campus'):
        require(key in assignment and assignment[key]==exam[key],'PACKAGE_EXAM_MISMATCH')
    questions=[q for q in exam['questions'] if q['id']==assignment['questionId']]
    require(len(questions)==1,'QUESTION_NOT_IN_EXAM')
    require(assignment['sourceKey']==questions[0]['sourceKey'],'QUESTION_SOURCE_MISMATCH')
    require(assignment['questionSourceHash'] in exam['sourceHashes'],'QUESTION_DOCUMENT_MISMATCH')
    require(assignment['cacheSha256']==digest(cache),'PACKAGE_CACHE_CHANGED')
    require(cache.get('contract_version')=='1.3' and cache.get('evidence') and cache.get('criteria'),'PACKAGE_INCOMPLETE')
    question_refs=[r for r in cache['evidence'] if r['binding']['role']=='question']
    require(question_refs and all(r['binding']['hash']==assignment['questionSourceHash'] for r in question_refs),'QUESTION_EVIDENCE_MISMATCH')
    # The regime comes from the approved DB policy; Python JSON is not jsonb::text.
    return HostedQuestion(assignment['questionId'],'source-registration-v1',regime,
        deepcopy(binding),{},approved_processing,reviewed_cache,deepcopy(cache))
