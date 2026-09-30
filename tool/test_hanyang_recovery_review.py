import unittest
from tool.essay_lab.hanyang_recovery_review import finding_rows,TARGETS
from tool.test_essay_live_worker import fixture

class FindingReview(unittest.TestCase):
    def test_exact_quote_diagnosis_action_and_source_locator(self):
        _,_,o=fixture();e=[dict(id='3',semantic_role='scoring_criterion',source_id='pdf',page=2,locator='p2')]
        text='\n'.join(finding_rows(o,e))
        for value in [o['sentence_feedback'][0]['quote'],o['improvements'][0]['explanation'],o['improvements'][0]['action'],'p2','[Owner 확인]']:self.assertIn(value,text)
    def test_no_fake_quote_for_unlocalized_core(self):
        _,_,o=fixture();o['sentence_feedback']=[]
        text='\n'.join(finding_rows(o,[dict(id='3',semantic_role='scoring_criterion',source_id='pdf',page=2,locator='p2')]))
        self.assertIn('별도 sentence quote 없음',text)
    def test_full_hanyang_targets_and_no_automatic_quality_verdict(self):
        self.assertEqual(len(TARGETS),15);self.assertIn('불필요한 X국 삽입 없음',TARGETS)

if __name__=='__main__':unittest.main()
