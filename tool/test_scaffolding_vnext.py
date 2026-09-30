"""Offline L2-B4 acceptance: no provider, credentials, DB, or private artifacts.
Quality goldens are human-review examples, NOT an automated Korean classifier.
"""
import copy
import json
from pathlib import Path
import unittest
from unittest.mock import patch
from tool.test_essay_live_worker import fixture
from tool.essay_lab.live_worker import Invalid, validate_output, parse_provider, output_schema, sha256
from tool.essay_lab.scaffolding_adapter import finalize_payload
from tool.essay_lab import scaffolding_vnext as v
from tool.essay_lab.evidence_vnext import VERSION, validate_sidecar


def case(university='sookmyung'):
    c, _, o = fixture()
    # Synthetic excerpts only; not a copied benchmark answer or provider result.
    body = '🙂 가가 평균이 낮아졌다. 기존에 없었던 표본이다. 답안이 부정적이다. '
    c['answer'] = body
    c['input']['answer_hash'] = sha256(body.encode()).hexdigest()
    o['answer_hash'] = c['input']['answer_hash']
    base = copy.deepcopy(o['improvements'][0])
    if university == 'sookmyung':
        names = ['complete_error_contrast', 'local_redundancy', 'local_sample_wording']
        cores = names[:1]
        explanation = '평균 하락의 해석은 있으나 책임 주체와 실제 응시 집단 변화 사이의 원인이 생략되어 보고서의 오류를 대비하지 못해요.'
        action = '보고서가 책임을 누구에게 돌렸는지 밝히고, 접근 기회 확대에서 응시 집단 변화와 평균 하락까지 원인을 연결하세요.'
        spans = ['🙂 가가', '기존에 없었던 표본이다.']
    else:
        names = ['utilitarian_total_welfare_application', 'utilitarian_critique_policy_connection', 'social_contract_condition2_direction', 'local_wording_negative_answer']
        cores = names[:2]
        explanation = '효용의 개념 설명과 판단 사이에서 누구의 이익과 고통을 비교하는지 빠져 적용 근거가 드러나지 않아요.'
        action = '현재·미래 집단 각각의 이익과 고통을 비교한 뒤 그 비교가 자신의 판단을 어떻게 지지하는지 연결하세요.'
        spans = ['답안이 부정적이다.']
    o['improvements'] = []
    for i, name in enumerate(names):
        local = name.startswith('local_')
        o['improvements'].append(dict(base, issue_key=name, priority=i+1,
            category='expression' if local else 'reasoning',
            title='표현의 대상 확인' if local else '빠진 논리 관계 연결',
            explanation='이 표현의 대상이 불분명하므로 실제 가리키는 대상을 밝혀요.' if local else explanation,
            action='대상이 드러나는 말로 최소 수정하세요.' if local else action,
            claim_scope='local_sentence' if local else 'official_criterion', evidence_ids=[] if local else ['3']))
    o['core_improvement_keys'] = cores
    o['sentence_feedback'] = []
    local_names = [n for n in names if n.startswith('local_')]
    for i, (name, quote) in enumerate(zip(local_names, spans)):
        a = body.index(quote)
        o['sentence_feedback'].append(dict(observation_key=f'observation_{i}', linked_issue_key=name,
            category='expression', priority='wording', start=a, end=a+len(quote), quote=quote,
            diagnosis='표현이 가리키는 대상을 확인해요.', direction='대상을 명시하는 범위에서만 고쳐 보세요.'))
    o['checklist'] = ['판단과 근거 사이에 빠진 관계를 연결했나요?']
    return c, o


def local_reviews(o):
    # Explicit synthetic operator fixture; no deployed signature or authorization.
    return [dict(issue=r, sentences=[s for s in o['sentence_feedback'] if s['linked_issue_key']==r['issue_key']],
                 reviewer='synthetic-offline', decision='local_only')
            for r in o['improvements'] if r['claim_scope']=='local_sentence']


class OptionA(unittest.TestCase):
    def test_T1_core_root(self):
        c, _, o = fixture(); self.assertEqual(validate_output(o,c),o)

    def test_T2_T4_noncore_real_root(self):
        c,o=case(); validate_output(o,c)
        self.assertTrue(all(s['linked_issue_key'] not in o['core_improvement_keys'] for s in o['sentence_feedback']))
        with self.assertRaisesRegex(ValueError,'LOCAL_REVIEW_REQUIRED'):
            finalize_payload(o,contract_version='1.3')
        p=finalize_payload(o,contract_version='1.3',local_reviews=local_reviews(o))
        self.assertEqual(p['improvements'],o['improvements'])
        self.assertEqual(p['sentence_feedback'],o['sentence_feedback'])

    def test_T3_original_GPT_missing_roots_rejected(self):
        for name, missing in [('sookmyung',2),('hanyang',1)]:
            c,o=case(name); self.assertEqual(len(o['sentence_feedback']),missing)
            o['improvements']=[r for r in o['improvements'] if not r['issue_key'].startswith('local_')]
            with self.subTest(name=name), self.assertRaisesRegex(Invalid,'SENTENCE_ROOT'):
                validate_output(o,c)

    def test_GPT_S_and_H_valid_option_A(self):
        for name in ('sookmyung','hanyang'):
            c,o=case(name); original=copy.deepcopy(o)
            self.assertEqual(parse_provider(json.dumps(o),c),original)
            self.assertEqual(o,original)  # No repair, drops, nulls or fabricated links.

    def test_null_link_rejected(self):
        c,o=case();o['sentence_feedback'][0]['linked_issue_key']=None
        with self.assertRaises(Invalid):parse_provider(json.dumps(o),c)

    def test_T5_T6_T7_core_limits(self):
        c,o=case('hanyang')
        for count in (1,2,3):
            o['core_improvement_keys']=[r['issue_key'] for r in o['improvements'][:count]]
            # Three independent mandatory relations are justified only in this synthetic fixture.
            for i,r in enumerate(o['improvements'][:count]):
                r['explanation']=f'합성 기준 {i+1}의 독립적인 관계가 빠졌어요. 다른 두 관계를 고쳐도 이 관계는 남아 별도 행동이 필요해요.'
            with self.subTest(count=count): validate_output(o,c)
        o['core_improvement_keys']=[r['issue_key'] for r in o['improvements']]
        with self.assertRaises(Invalid):validate_output(o,c)

    def test_T9_T10_quote_exactness(self):
        c,o=case();validate_output(o,c)
        for quote in ('🙂 가가', '🙂 가가 ', '없는 원문', 'draft only'):
            bad=copy.deepcopy(o);bad['sentence_feedback'][0]['quote']=quote
            with self.subTest(quote=quote), self.assertRaisesRegex(Invalid,'EXACT_QUOTE'):validate_output(bad,c)

    def test_T11_grounding(self):
        c,o=case();validate_output(o,c)
        for ids in ([],['not-allowed']):
            bad=copy.deepcopy(o);bad['improvements'][0]['evidence_ids']=ids
            with self.assertRaises(Invalid):validate_output(bad,c)
        bad=copy.deepcopy(o);bad['improvements'][-1]['evidence_ids']=['3']
        with self.assertRaisesRegex(Invalid,'LOCAL_OFFICIAL_MIX'):validate_output(bad,c)

    def test_T14_previous_progress_chain(self):
        c,o=case();o['sentence_feedback']=[];o['improvements']=o['improvements'][:1]
        frozen=[]
        for i,(state,previous) in enumerate([('open',None),('improved','open'),('resolved','improved'),('recurred','resolved')]):
            o=copy.deepcopy(o);c=copy.deepcopy(c)
            o['improvements'][0].update(status=state,previous_progress_id=None if previous is None else f'p{i-1}')
            o['core_improvement_keys']=[] if state=='resolved' else [o['improvements'][0]['issue_key']]
            if previous:
                c['input']['scaffolding_context']={'items':[dict(progress_id=f'p{i-1}',issue_key=o['improvements'][0]['issue_key'],status=previous)],'previous_core_progress_ids':[f'p{i-1}']}
                o['previous_improvement_reviews']=[dict(previous_progress_id=f'p{i-1}',outcome=state,reason='현재 답안에서 책임 주체가 추가되었는지와 원인 연결이 남았는지를 비교한 합성 근거.')]
            frozen.append(validate_output(o,c))
        self.assertEqual([x['improvements'][0]['status'] for x in frozen],['open','improved','resolved','recurred'])
        self.assertIsNone(frozen[0]['improvements'][0]['previous_progress_id'])

    def test_noncore_history_review(self):
        c,o=case();r=o['improvements'][-1];r.update(status='improved',previous_progress_id='minor-prior')
        c['input']['scaffolding_context']['items']=[dict(progress_id='minor-prior',issue_key=r['issue_key'],status='open')]
        o['previous_improvement_reviews']=[dict(previous_progress_id='minor-prior',outcome='improved',reason='대상을 추가했지만 범위 표현은 남아 있어요.')]
        self.assertEqual(validate_output(o,c)['improvements'][-1]['status'],'improved')
        self.assertNotIn(r['issue_key'],o['core_improvement_keys'])

    def test_T15_not_assessable(self):
        c,_,o=fixture();c['input']['scaffolding_context']={'items':[dict(progress_id='prior',issue_key='root',status='open')],'previous_core_progress_ids':['prior']}
        o.update(improvements=[],sentence_feedback=[],core_improvement_keys=[],previous_improvement_reviews=[dict(previous_progress_id='prior',outcome='not_assessable',reason='이번 답안에서 해당 관계를 판단할 근거가 없어요.')])
        self.assertEqual(validate_output(o,c)['previous_improvement_reviews'][0]['outcome'],'not_assessable')
        o['previous_improvement_reviews'][0]['outcome']='resolved'
        with self.assertRaisesRegex(Invalid,'REVIEW_LINK'):validate_output(o,c)

    def test_Q7_zero_sentence_and_zero_core(self):
        c,_,o=fixture();o.update(improvements=[],sentence_feedback=[],core_improvement_keys=[])
        self.assertEqual(validate_output(o,c)['sentence_feedback'],[])

    def test_T8_structurally_valid_minor_core_overload_is_not_quality_pass(self):
        c,o=case()
        o['core_improvement_keys']=[r['issue_key'] for r in o['improvements']]
        validate_output(o,c)
        rows=json.loads((Path(__file__).parent/'essay_lab/fixtures/scaffolding_vnext_quality.json').read_text())
        self.assertEqual(next(r for r in rows if r['id']=='T8')['expected_human_verdict'],'REJECT')

    def test_Q8_one_root_multiple_spans_no_fake_tasks(self):
        c,_,o=fixture()
        body=c['answer'];o['sentence_feedback'][0].update(start=0,end=1,quote=body[:1])
        o['sentence_feedback'].append(dict(o['sentence_feedback'][0],observation_key='other_span',start=2,end=len(body),quote=body[2:]))
        validate_output(o,c)
        self.assertEqual(len(o['core_improvement_keys']),1)
        self.assertEqual({s['linked_issue_key'] for s in o['sentence_feedback']},{'root'})

    def test_legacy_and_wire_unchanged(self):
        old={'summary':'legacy','legacy_field':True}
        self.assertEqual(finalize_payload(old,contract_version='1.2'),old)
        with patch('socket.socket',side_effect=AssertionError('offline only')):
            p=v.prompt_contract()
        self.assertEqual(p['schema'],output_schema());self.assertEqual(p['contract_version'],'1.3')
        self.assertEqual(p['prompt_version'],'scaffolding-1.3-v2')
        self.assertNotIn('GPT',p['prompt']);self.assertNotIn('Claude',p['prompt'])
        self.assertEqual(p['prompt_sha256'],sha256(p['prompt'].encode()).hexdigest())
        p['schema'].clear();self.assertEqual(v.prompt_contract()['schema'],output_schema())


class EvidencePreparation(unittest.TestCase):
    def setUp(self):
        self.refs=[dict(id='question',role='question',hash='a'*64),dict(id='rubric',role='scoring_criteria',hash='b'*64),dict(id='scan',role='answer_image',hash='c'*64)]
        self.value=dict(version=VERSION,facets=[],transcriptions=[])
        for kind,source,body in [('question_displayed_length','question','문제지 명목 1,200자'),('scoring_length_rule','rubric','합성 fixture: 별도 검증된 원고지 산정 규칙. 실제 감점 threshold는 이 fixture에 없음.'),('explicit_non_criterion','rubric','서론-본론-결론 형식 여부를 평가하지 않는다.')]:
            self.value['facets'].append(dict(id=kind,kind=kind,source_id=source,source_hash=self.refs[0 if source=='question' else 1]['hash'],locator='synthetic/page1',text=body,usage='rule_context'))

    def test_T13_length_distinct_no_inferred_deduction(self):
        got=validate_sidecar(self.value,self.refs)
        self.assertNotEqual(got['facets'][0]['source_id'],got['facets'][1]['source_id'])
        bad=copy.deepcopy(self.value);bad['facets'][1].update(source_id='question',source_hash='a'*64)
        with self.assertRaisesRegex(Invalid,'FACET_BINDING'):validate_sidecar(bad,self.refs)
        got['facets'].clear();self.assertEqual(len(self.value['facets']),3)

    def test_multiple_examples_calibration_only(self):
        for i in range(2):
            source=f'example{i}';self.refs.append(dict(id=source,role='accepted_student_example',hash='d'*64))
            self.value['facets'].append(dict(id=source,kind='accepted_example_answer',source_id=source,source_hash='d'*64,locator=f'synthetic/page{i+2}',text='합성 대안 논증',usage='calibration_only'))
        validate_sidecar(self.value,self.refs)
        self.value['facets'][-1]['usage']='rule_context'
        with self.assertRaisesRegex(Invalid,'EXAMPLE_NOT_RUBRIC'):validate_sidecar(self.value,self.refs)

    def test_hanyang_transcription_correction_lineage(self):
        # Short Owner-supplied regression fragment, not a private answer body.
        old='오로지 최대행복 최소고통만을 [판독 어려움]하는 공리주의는'
        corrected='오로지 최대 행복, 최소 고통만을 주장하는 공리주의는'
        for i,body in enumerate([old,corrected]):
            self.value['transcriptions'].append(dict(version=f'v{i}',text=body,text_hash=sha256(body.encode()).hexdigest(),source_id='scan',source_hash='c'*64,prior_version=None if i==0 else 'v0',reason=None if i==0 else 'Owner verified readable source',reviewer=None if i==0 else 'synthetic-owner-review',reviewed_at=None if i==0 else '2026-09-30'))
        before=copy.deepcopy(self.value);got=validate_sidecar(self.value,self.refs)
        self.assertEqual(got['transcriptions'][0]['text'],old);self.assertEqual(before,self.value)
        self.assertEqual(got['transcriptions'][1]['text'],corrected)
        for key,value in [('prior_version','missing'),('reason',''),('text_hash','0'*64)]:
            bad=copy.deepcopy(self.value);bad['transcriptions'][1][key]=value
            with self.assertRaises(Invalid):validate_sidecar(bad,self.refs)

    def test_duplicate_unknown_and_source_mutation(self):
        for mutate in (lambda x:x.update(unknown=True),lambda x:x['facets'].append(x['facets'][0]),lambda x:x['facets'][0].update(source_hash='0'*64)):
            bad=copy.deepcopy(self.value);mutate(bad)
            with self.assertRaises(Invalid):validate_sidecar(bad,self.refs)


class QualityExamples(unittest.TestCase):
    def test_curated_examples_are_not_automatic_quality_classifier(self):
        rows=json.loads((Path(__file__).parent/'essay_lab'/'fixtures'/'scaffolding_vnext_quality.json').read_text())
        ids={r['id'] for r in rows}
        self.assertTrue({'T8','T12','T16',*[f'Q{i}' for i in range(1,9)],'X_COUNTRY','LOGICAL_DIRECTION'}<=ids)
        for r in rows:
            with self.subTest(id=r['id']):
                self.assertIn(r['expected_human_verdict'],('ACCEPT','REJECT'))
                self.assertTrue(r['context'] and r['feedback'] and r['rationale'])
                self.assertEqual(r['gate'],'HUMAN_SEMANTIC_REVIEW')
        self.assertEqual(v.ABSTRACT_FEEDBACK_GATE,'PROMPT_AND_FIXTURE')
        # Structural acceptance intentionally does not imply the curated semantic verdict.
        c,_,o=fixture();o['improvements'][0].update(explanation='논리가 부족합니다.',action='논리를 강화하세요.')
        validate_output(o,c)
        self.assertEqual(next(r for r in rows if r['id']=='Q1')['expected_human_verdict'],'REJECT')


if __name__=='__main__': unittest.main()
