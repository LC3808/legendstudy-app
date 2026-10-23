import unittest
from tool.essay_lab.batch_remediation import causes, build_manifest
class RootCausesTests(unittest.TestCase):
 def row(self,route=None,mapped=False):return dict(question_id='q',exam_id='e',university='u',route=route,profile_mapped=mapped,draft_sha256='pinned',evaluation_scope='NEEDS_REVIEW',reasons=['PHYSICAL_MATH_OR_SPECIAL_BINDING_REQUIRED','MISSING_CLEAN_QUESTION'])
 def test_missing_profile_is_not_math(self):self.assertEqual(causes(self.row()),['PROFILE_SCOPE'])
 def test_special_and_math_remain_distinct(self):
  self.assertEqual(causes(self.row('special',True)),['SPECIAL_TYPE_ROUTING']);self.assertEqual(causes(self.row('math',True)),['MATH_INPUT_ADAPTER'])
 def test_groups_preserve_ids_and_do_not_promote(self):
  row=self.row();a={'questions':[row], 'registry':{'exams':[dict(examId='e',year=2026,kind='admission',track='T')]}}
  result=build_manifest(a,{'unmapped':[dict(question_id='q',exam_id='e',university='u',year=2026,track='T',reason='PROFILE_MISSING')]})
  self.assertEqual(result['needs_review'],1);self.assertEqual(result['repair_groups'][0]['question_ids'],['q']);self.assertFalse(result['activation_granted']);self.assertEqual(row['evaluation_scope'],'NEEDS_REVIEW');self.assertIsNone(result['by_university']['u']['public_questions']);self.assertFalse(result['by_university']['u']['complete'])
if __name__=='__main__':unittest.main()
