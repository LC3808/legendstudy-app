import copy
import json
from pathlib import Path
import random
import unittest
from audit_exam_canonical import audit

ROOT=Path(__file__).resolve().parent
class CanonicalAuditTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((ROOT/'ingestion/samples/exam-canonical-audit-2026-09-27.json').read_text())
    def test_inventory_and_no_publication_authority(self):
        result=audit(self.data)
        self.assertEqual(len(result['rows']),185)
        self.assertEqual(result['state_counts']['WRITER_READY'],{'FULL_SET_CANONICAL':30,'AMBIGUOUS':27})
        self.assertEqual(result['state_counts']['ACTIVE'],{'FULL_SET_CANONICAL':15,'AMBIGUOUS':16,'PARTIAL_DUPLICATE':2})
        self.assertFalse(result['publication_authorized'])
        self.assertTrue(all(not r['automatic_publication_allowed'] for r in result['rows']))
        self.assertTrue(all(not r['canonical_review_eligible'] for r in result['rows'] if r['classification']!='FULL_SET_CANONICAL' or r['state']!='WRITER_READY'))
    def test_same_input_and_shuffled_order_are_deterministic(self):
        data=copy.deepcopy(self.data);rng=random.Random(13)
        rng.shuffle(data['rows'])
        for row in data['rows']:rng.shuffle(row['resources'])
        self.assertEqual(audit(self.data),audit(data))
    def test_source_march_identity_kept_separate_from_parser_drift(self):
        rows={r['external_post_id']:r for r in audit(self.data)['rows']}
        self.assertEqual(rows['1474']['broader_source_ids'],['1431'])
        self.assertEqual(rows['1474']['classification'],'PARTIAL_DUPLICATE')
        self.assertEqual(rows['1431']['existing_identity'][1],4)
        self.assertEqual(rows['1431']['normalized_exam_identity'][1],3)
        self.assertEqual(rows['1431']['state'],'IDENTITY_REVIEW_52')
        self.assertFalse(rows['1431']['canonical_review_eligible'])
        self.assertEqual(rows['1447']['broader_source_ids'],['1404'])
    def test_missing_paper_and_extra_count_cannot_make_full_set(self):
        data=copy.deepcopy(self.data)
        row=next(r for r in data['rows'] if r['external_post_id']=='1481')
        row['resources']=[r for r in row['resources'] if r['subject']!='한국사']
        for i in range(30):row['resources'].append({**row['resources'][0],'key':f'extra{i}'})
        got=next(r for r in audit(data)['rows'] if r['external_post_id']=='1481')
        self.assertEqual(got['classification'],'AMBIGUOUS')
        self.assertIn('한국사',got['missing_subjects'])
    def test_protected_holds_and_additional_domains_fail_closed(self):
        rows=audit(self.data)['rows']
        self.assertEqual(sum(r['state']=='IDENTITY_REVIEW_52' for r in rows),52)
        self.assertTrue(all(not r['canonical_review_eligible'] for r in rows if r['external_post_id'] in self.data['identity_review_ids'] or r['external_post_id']=='1710'))
        kice=[r for r in rows if r['exam_type'] in ['csat','evaluation_mock']]
        self.assertTrue(all(r['classification']!='FULL_SET_CANONICAL' for r in kice))
    def test_coverage_evidence_and_raw_labels_are_retained(self):
        result=audit(self.data)
        for r in result['rows']:
            if r['classification']=='FULL_SET_CANONICAL':
                self.assertTrue(r['expected_subjects'])
                self.assertFalse(r['missing_subjects'])
                self.assertFalse(r['review_reasons'])
                self.assertTrue(r['source_url'].startswith('https://legendstudy.com/'))
        row=next(r for r in result['rows'] if r['external_post_id']=='1496')
        self.assertIn('생화과윤리',row['raw_occurrence_split'])
        self.assertEqual(row['classification'],'AMBIGUOUS')

if __name__=='__main__':unittest.main()
