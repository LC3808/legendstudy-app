"""Offline registered-content acceptance through the existing reviewed Essay worker.
Private official text is read from --package, never committed or sent to a provider.
This checks dispatch bindings and replay, NOT educational quality or Production E2E.
"""
import argparse, json, socket
from copy import deepcopy
from dataclasses import replace
from hashlib import sha256
from pathlib import Path
from unittest.mock import patch
from tool.essay_lab.package_registry import bind_registered_package
from tool.essay_lab.live_worker import digest, package
from tool.test_essay_reviewed_runtime import RuntimeTests

def verify(path):
    data=json.loads(Path(path).read_text())
    assert data['publication_allowed'] is False and data['provider_allowed'] is False
    assert sha256(Path(data['source']).read_bytes()).hexdigest()==data['source_sha256']
    cache=data['cache']; a=data['assignment']; history=[]; calls=0
    bound=bind_registered_package(data['registry'],a,cache,binding={},regime='unconfigured')
    assert not bound.approved_processing and not bound.reviewed_cache
    assert a['questionId']=='1f980d57-683e-5d49-b2ed-4bbb554b967b'
    assert len(cache['criteria'])==5
    for revision in [1,2]:
        w,events,requests,saved,claim,out=RuntimeTests().fixture()
        answer=('합성 테스트 답안: 환대와 책임의 실천 및 상호 소통을 논한다.' if revision==1 else
                '합성 수정 답안: 부부의 환대와 아주머니의 응답을 연결하고 그 관계의 근거를 설명한다.')
        claim['answer']=answer; claim['input']['answer_hash']=sha256(answer.encode()).hexdigest()
        claim['input']['attempt_id']=f'konkuk-q2-synthetic-{revision}'
        claim['input']['evidence']=[deepcopy(e['binding']) for e in cache['evidence']]
        claim['input']['criteria']=[deepcopy(c['binding']) for c in cache['criteria']]
        scoring=next(e['binding']['id'] for e in cache['evidence'] if e['binding']['role']=='scoring_criteria')
        out.update(attempt_id=claim['input']['attempt_id'],answer_hash=claim['input']['answer_hash'],sentence_feedback=[])
        out['dimensions']=[dict(criterion_id=c['binding']['id'],level=3,explanation='합성 결과 — 평가 품질 판정 아님',evidence_ids=[scoring]) for c in cache['criteria']]
        out['improvements'][0]['evidence_ids']=[scoring]
        if revision==2:
            claim['input']['scaffolding_context']={'items':[{'progress_id':'prior-mock-progress','issue_key':'root','status':'open'}],'previous_core_progress_ids':['prior-mock-progress']}
            out['improvements'][0].update(previous_progress_id='prior-mock-progress',status='improved')
            out['previous_improvement_reviews']=[dict(previous_progress_id='prior-mock-progress',outcome='improved',reason='합성 재작성 연결 확인')]
        w.cache=deepcopy(cache)
        w.permit=replace(w.permit,snapshot_sha256=digest(claim['input']),cache_sha256=digest(cache))
        projected=package(claim,cache)
        assert len(projected['criteria'])==5
        assert all(e['reference']['role']!='model_answer' for e in projected['evidence'])
        assert w.execute('evaluation')=='completed'
        assert len(saved)==1 and len(requests)==1
        w.resume_finalization(saved[0]); assert len(requests)==1
        history.append({'revision':revision,'question_id':a['questionId'],'output':saved[0]['p_output']})
        calls+=len(requests)
    assert len(history)==2 and history[0]['question_id']==history[1]['question_id']
    return dict(status='PASS',scope='offline official-input worker contract + synthetic rewrite/checkpoint replay',question_id=a['questionId'],criteria=5,mock_requests=calls,actual_provider_calls=0,production_writes=0,credit_transactions=0,production_history_verified=False,full_user_e2e=False)

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--package',required=True);parser.add_argument('--report',required=True);args=parser.parse_args()
    with patch.object(socket,'create_connection',side_effect=AssertionError('NETWORK_FORBIDDEN')):
        result=verify(args.package)
    Path(args.report).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
