"""Review-only tests. No PostgreSQL, AI, private data or production connections."""
import copy
import hashlib
import unittest
from scaffolding_contract_check import ROOT, contract, validate_fragment


def fixture():
    answer = '🙂 근거와 결론을 연결한다. 다음 문장도 확인한다.'
    context = {'answer':answer, 'answer_hash':hashlib.sha256(answer.encode()).hexdigest(),
               'evidence_ids':['official-1'], 'previous':{}}
    item = {'issue_key':'link','claim_scope':'official_criterion','evidence_ids':['official-1'],'status':'open'}
    sentence = {'observation_key':'s1','linked_issue_key':'link','category':'logic','priority':'contradiction',
                'start':2,'end':15,'quote':answer[2:15],'diagnosis':'연결의 근거를 확인해 보세요.',
                'direction':'앞 문장의 근거와 마지막 판단을 연결해 보세요.'}
    output = {'version':'1.3-review.1','improvements':[item], 'core_improvement_keys':['link'],
              'sentence_feedback':[sentence],'previous_improvement_reviews':[]}
    return output,context


class ReviewContractTest(unittest.TestCase):
    def test_frozen_v12_and_prior_proposal(self):
        c=contract()
        self.assertEqual(hashlib.sha256((ROOT/'tool/essay_lab/evidence'/c['base_file']).read_bytes()).hexdigest(),c['base_sha256'])
        self.assertEqual(hashlib.sha256((ROOT/'tool/essay_lab/evidence/sentence_feedback_v1_2.proposal.json').read_bytes()).hexdigest(),
                         '3bbe172133b11419a3f9f2254d501bd16d4b4a27b8a2640f2d1fbf334bb16a4c')
        self.assertEqual(c['status'],'REVIEW_ONLY_NOT_EXECUTED')
        self.assertEqual(c['storage_proposal']['tables_added'],0)

    def test_valid_unicode_one_item_optional_example_absent(self):
        o,c=fixture(); self.assertTrue(validate_fragment(o,c))

    def test_zero_is_valid(self):
        o,c=fixture()
        for k in ('improvements','core_improvement_keys','sentence_feedback'): o[k]=[]
        self.assertTrue(validate_fragment(o,c))

    def test_same_root_multiple_locations(self):
        o,c=fixture(); s=copy.deepcopy(o['sentence_feedback'][0])
        s.update(observation_key='s2',start=16,end=len(c['answer']),quote=c['answer'][16:])
        o['sentence_feedback'].append(s)
        self.assertTrue(validate_fragment(o,c))

    def test_invalid_sentence_fragments(self):
        patches=[{'quote':'없는 문장'}, {'start':-1},{'start':True},{'start':3},
                 {'end':1000},{'diagnosis':' '},{'direction':''},{'category':'made_up'},
                 {'priority':'high'},{'linked_issue_key':'other'},{'example':''},{'extra':'unknown'}]
        for patch in patches:
            with self.subTest(patch=patch):
                o,c=fixture();o['sentence_feedback'][0].update(patch)
                with self.assertRaises(ValueError): validate_fragment(o,c)

    def test_count_links_and_duplicate_rejection(self):
        for kind in ('six','span','root','focus','foreign_focus'):
            with self.subTest(kind=kind):
                o,c=fixture()
                if kind=='six': o['sentence_feedback']*=6
                if kind=='span': o['sentence_feedback']*=2
                if kind=='root': o['improvements']*=2
                if kind=='focus': o['core_improvement_keys']*=4
                if kind=='foreign_focus': o['core_improvement_keys']=['unknown']
                with self.assertRaises(ValueError): validate_fragment(o,c)

    def test_exact_binding_no_normalization(self):
        for changed in ('draft text','다른 학생 문장', '🙂 근거와 결론을 연결한다. 다음 문장도 확인한다. '):
            o,c=fixture();c['answer']=changed
            with self.assertRaises(ValueError): validate_fragment(o,c)
        o,c=fixture();o['sentence_feedback'][0]['quote']=o['sentence_feedback'][0]['quote'].replace(' ','')
        with self.assertRaises(ValueError): validate_fragment(o,c)

    def test_local_grammar_no_fabricated_official_reference(self):
        o,c=fixture();o['improvements'][0].update(claim_scope='local_sentence',evidence_ids=[])
        o['sentence_feedback'][0].update(category='grammar',priority='grammar_agreement')
        c['approved_local_issue_keys']=['link']
        self.assertTrue(validate_fragment(o,c))

    def test_provenance_rejections(self):
        for kind in ('missing_official','foreign_official','unapproved_local','unanchored_local'):
            with self.subTest(kind=kind):
                o,c=fixture(); i=o['improvements'][0]
                if kind=='missing_official':i['evidence_ids']=[]
                if kind=='foreign_official':i['evidence_ids']=['other-question']
                if kind=='unapproved_local':i.update(claim_scope='local_sentence',evidence_ids=[])
                if kind=='unanchored_local':i.update(claim_scope='local_sentence',evidence_ids=[]);o['sentence_feedback']=[]
                with self.assertRaises(ValueError):validate_fragment(o,c)

    def test_resolved_local_does_not_invent_error_sentence(self):
        o,c=fixture();c['approved_local_issue_keys']=['link']
        c['previous']={'p1':{'issue_key':'link','core':True,'status':'open','verified_local_quote':True}}
        o['core_improvement_keys']=[];o['sentence_feedback']=[]
        o['improvements'][0].update(claim_scope='local_sentence',evidence_ids=[],status='resolved',previous_progress_id='p1')
        o['previous_improvement_reviews']=[{'previous_progress_id':'p1','outcome':'resolved','reason':'현재 답안에서 해당 문장 문제가 해결됐는지 확인했어요.'}]
        self.assertTrue(validate_fragment(o,c))

    def test_local_internal_contradiction_requires_trusted_classification(self):
        o,c=fixture();o['improvements'][0].update(claim_scope='local_sentence',evidence_ids=[])
        with self.assertRaises(ValueError):validate_fragment(o,c)
        c['approved_local_issue_keys']=['link']
        self.assertTrue(validate_fragment(o,c))

    def test_previous_core_cannot_be_silently_skipped(self):
        o,c=fixture();c['previous']={'p1':{'issue_key':'link','core':True,'status':'open'}}
        with self.assertRaises(ValueError):validate_fragment(o,c)

    def test_unknown_is_not_resolved(self):
        o,c=fixture();c['previous']={'p1':{'issue_key':'old','core':True,'status':'open'}}
        o['previous_improvement_reviews']=[{'previous_progress_id':'p1','outcome':'not_assessable','reason':'비교 근거가 부족해요.'}]
        o['uncertainty_note']='이전 과제는 비교 근거가 부족해 판단하기 어려워요.'
        self.assertTrue(validate_fragment(o,c))
        o['improvements'][0]['previous_progress_id']='p1'
        with self.assertRaises(ValueError):validate_fragment(o,c)

    def test_history_fixture_keeps_each_stage(self):
        history=[]; previous=None
        for index,state in enumerate(('open','improved','resolved','recurred')):
            o,c=fixture();o['improvements'][0]['status']=state
            if state=='resolved':o['core_improvement_keys']=[];o['sentence_feedback']=[]
            if previous:
                c['previous']={previous['id']:{'issue_key':'link','core':previous['status']!='resolved','status':previous['status']}}
                o['improvements'][0]['previous_progress_id']=previous['id']
                o['previous_improvement_reviews']=[{'previous_progress_id':previous['id'],'outcome':state,'reason':'이번 작성본과 이전 과제를 비교했어요.'}]
            self.assertTrue(validate_fragment(o,c))
            previous={'id':f'p{index}', 'status':state};history.append(copy.deepcopy(previous))
        self.assertEqual([p['status'] for p in history],['open','improved','resolved','recurred'])
        # Fixture oracle only; actual append-only SQL enforcement is a next-phase runtime gate.

    def test_unfounded_recurrence_rejected(self):
        o,c=fixture();c['previous']={'p1':{'issue_key':'link','core':True,'status':'open'}}
        o['improvements'][0].update(status='recurred',previous_progress_id='p1')
        o['previous_improvement_reviews']=[{'previous_progress_id':'p1','outcome':'recurred','reason':'다시 나타났어요.'}]
        with self.assertRaises(ValueError):validate_fragment(o,c)

    def test_three_core_and_five_sentences_valid(self):
        o,c=fixture(); answer='가나다라마'
        c['answer']=answer;c['answer_hash']=hashlib.sha256(answer.encode()).hexdigest()
        o['improvements']=[dict(o['improvements'][0],issue_key=f'root{i}') for i in range(3)]
        o['core_improvement_keys']=[i['issue_key'] for i in o['improvements']]
        source=o['sentence_feedback'][0]
        o['sentence_feedback']=[dict(source,observation_key=f's{i}',linked_issue_key=f'root{i%3}',start=i,end=i+1,quote=answer[i]) for i in range(5)]
        self.assertTrue(validate_fragment(o,c))

    def test_resolved_is_not_active_core(self):
        o,c=fixture();o['improvements'][0]['status']='resolved'
        with self.assertRaises(ValueError):validate_fragment(o,c)

    def test_wrong_previous_root_or_unknown_id_rejected(self):
        for kind in ('root','id'):
            with self.subTest(kind=kind):
                o,c=fixture();c['previous']={'p1':{'issue_key':'old','core':True,'status':'open'}}
                o['previous_improvement_reviews']=[{'previous_progress_id':'p1' if kind=='root' else 'other','outcome':'improved','reason':'관측 이유'}]
                o['improvements'][0].update(previous_progress_id='p1',status='improved')
                with self.assertRaises(ValueError):validate_fragment(o,c)

    def test_no_global_weakness_or_execution_claim(self):
        c=contract()
        self.assertIn('permanent',c['progression_rules'][-1])
        self.assertIn('Separate approval for Scaffolding AI Pilot',c['activation_gates'])
        self.assertIn('official criterion priority',c['inherit'].lower())
        self.assertEqual(c['storage_proposal']['type'],'jsonb NULL')


if __name__ == '__main__': unittest.main()
