"""HQ goldens are reviewed examples, never a Korean classifier or real-model PASS."""
import copy
import json
from pathlib import Path
import unittest
from tool.test_essay_live_worker import fixture
from tool.test_scaffolding_vnext import case
from tool.essay_lab.live_worker import validate_output, parse_provider, output_schema
from tool.essay_lab.positive_learning import prompt_contract
from tool.essay_lab.scaffolding_vnext import prompt_contract as historical

ROWS=json.loads((Path(__file__).parent/'essay_lab/fixtures/positive_learning_quality.json').read_text())

class PositiveLearning(unittest.TestCase):
    def strong(self):
        c,_,o=fixture();o.update(improvements=[],core_improvement_keys=[],sentence_feedback=[])
        return c,o

    def test_HQ1_zero_core(self):
        c,o=self.strong();self.assertEqual(validate_output(o,c)['core_improvement_keys'],[])

    def test_HQ2_zero_core_with_real_minor(self):
        c,o=case();o['improvements']=o['improvements'][-1:];o['sentence_feedback']=o['sentence_feedback'][-1:];o['core_improvement_keys']=[]
        parsed=parse_provider(json.dumps(o),c)
        self.assertEqual(len(parsed['improvements']),1);self.assertEqual(parsed['core_improvement_keys'],[])
        self.assertEqual(parsed['sentence_feedback'][0]['linked_issue_key'],parsed['improvements'][0]['issue_key'])

    def test_HQ3_alternative_reasoning(self):self.assertEqual(ROWS[2]['expected_human_verdict'],'ACCEPT')
    def test_HQ4_alternative_structure(self):self.assertEqual(ROWS[3]['expected_human_verdict'],'ACCEPT')
    def test_HQ5_criterion_strength_wire(self):
        c,o=self.strong();o['strengths']=[ROWS[4]['feedback']];o['dimensions'][0]['explanation']=ROWS[4]['feedback'];validate_output(o,c)
    def test_HQ6_transfer_wire(self):
        c,o=self.strong();o['strengths']=[ROWS[5]['feedback']];o['checklist']=['다른 문제에서도 원인과 결과 사이 작동 과정을 확인했나요?'];validate_output(o,c)
    def test_HQ7_generic_praise_schema_pass_quality_reject(self):
        c,o=self.strong();o['strengths']=[ROWS[6]['feedback']];validate_output(o,c)
        self.assertEqual(ROWS[6]['expected_human_verdict'],'REJECT')
    def test_HQ8_forced_defect_quality_reject(self):self.assertEqual(ROWS[7]['expected_human_verdict'],'REJECT')
    def test_HQ9_polish_not_core(self):self.assertEqual(ROWS[8]['expected_human_verdict'],'REJECT')
    def test_HQ10_zero_sentences(self):
        c,o=self.strong();self.assertEqual(validate_output(o,c)['sentence_feedback'],[])
    def test_curated_complete_no_automatic_quality_claim(self):
        self.assertEqual([r['id'] for r in ROWS],[f'HQ{i}' for i in range(1,11)])
        for r in ROWS:self.assertTrue(r['context'] and r['feedback'] and r['rationale'])
    def test_new_prompt_same_wire_historical_unchanged(self):
        new=prompt_contract();old=historical()
        self.assertEqual(new['schema'],output_schema());self.assertEqual(new['schema'],old['schema'])
        self.assertEqual(old['prompt_sha256'],'b962a46cab2a93ab7ff56eda700cba97c17e3babfbd34c6fa835cecffab01f5b')
        self.assertNotEqual(old['prompt_sha256'],new['prompt_sha256'])
        for meaning in ['STUDENT MOVE','WHY IT WORKS','ANSWER KEY','CORE=0','재사용','RL 훈련이 아닙니다']:
            self.assertIn(meaning,new['prompt'])

if __name__=='__main__':unittest.main()
