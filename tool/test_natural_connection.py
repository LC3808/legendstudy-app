"""Connection metadata and official-content preservation, no Provider."""
import copy
import unittest
from essay_lab.natural_connection import connect
from essay_lab.natural_expansion import build_review_package, ReviewError
from test_natural_expansion import PLAN

class ConnectionTest(unittest.TestCase):
    def setUp(self):
        self.exam=PLAN['exams'][0];self.question=self.exam['questions'][0]
        self.package=build_review_package(self.exam,self.question,['original \ue123 formula/rubric']*self.exam['source']['pages'])

    def test_worker_physical_pages_and_source_roles(self):
        new=connect(self.package,self.exam,self.question)
        for row in new['existing_schema_rows']['math_source_artifacts']:
            self.assertRegex(row['locator'],r' PDF [0-9,]+쪽$')
            self.assertEqual(row['content_sha256'],self.exam['source']['sha256'])
        self.assertEqual(new['essay_question_id'],self.question['question_id'])
        self.assertNotEqual(new['ids']['leaf'],self.package['ids']['leaf'])
        self.assertEqual(new,connect(self.package,self.exam,self.question))
        self.assertFalse(new['publication_allowed']);self.assertFalse(new['provider_allowed'])

    def test_official_text_points_and_page_order_unchanged(self):
        old=copy.deepcopy(self.package)
        new=connect(self.package,self.exam,self.question)['existing_schema_rows']
        for table, fields in {'math_problems':['statement','display_order'], 'math_scoring_criteria':['description','official_points','rubric_dimensions'], 'math_canonical_solutions':['body','origin'], 'math_canonical_solution_steps':['body','position']}.items():
            for a,b in zip(old['existing_schema_rows'][table],new[table]):
                for field in fields:self.assertEqual(a[field],b[field])
        self.assertEqual(self.package,old)

    def test_identity_publication_and_hash_drift_rejected(self):
        for change,error in [({'exam_id':'wrong'},'IDENTITY_DRIFT'),({'publication_allowed':True},'NOT_PRIVATE_DRAFT')]:
            p=copy.deepcopy(self.package);p.update(change)
            with self.assertRaisesRegex(ReviewError,error):connect(p,self.exam,self.question)
        p=copy.deepcopy(self.package);p['existing_schema_rows']['math_source_artifacts'][0]['content_sha256']='0'*64
        with self.assertRaisesRegex(ReviewError,'SOURCE_HASH_DRIFT'):connect(p,self.exam,self.question)

if __name__=='__main__':unittest.main()
