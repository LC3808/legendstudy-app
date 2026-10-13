import unittest
from copy import deepcopy
from essay_lab.material_runtime import reviewed_material_question
from essay_lab.live_worker import Invalid

class MaterialRuntimeTests(unittest.TestCase):
 def setUp(self):
  self.exam=dict(examId='e',universityId='u',year=2024,kind='admission',track='인문',session='오후2',campus=None,name='Hanyang 2024 afternoon2',sourceHashes=['a'*64],questions=[dict(id='q',sourceKey='source:q')])
  self.package=dict(schema='essay-material-package-v1',verification_status='VERIFIED_MANIFEST',package_digest='f'*64,package_version=2,exam_id='e',university_id='u',exam_identity=dict(academic_year=2024,exam_type='admission',track='인문',title='Hanyang 2024 afternoon2'),rights_status={'a'*64:{'providerTransmission':'APPROVED'}},questions=[dict(question_id='q',source_key='source:q',source_page_references=[dict(questionId='q',sourceHash='a'*64,role=r,startPage=1,endPage=1,evidenceText='official '+r,verification='VERIFIED') for r in ['question','shared_passage','intent','criteria','scoring']])])
 def bind(self,p=None,approved=False):return reviewed_material_question(p or self.package,{'exams':[self.exam]},'q',pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities',approved_processing=approved)
 def test_binds_existing_runtime_without_activation(self):
  q,report=self.bind();self.assertFalse(q.approved_processing);self.assertTrue(q.reviewed_cache);self.assertEqual(q.frozen_cache['criteria'][0]['label'],'official criteria');self.assertFalse(report['activation_granted'])
 def test_wrong_exam_unreviewed_or_rights_block(self):
  for mutate in [lambda p:p['exam_identity'].update(academic_year=2025),lambda p:p.update(package_digest='e'*64),lambda p:p['questions'][0]['source_page_references'][0].update(verification='NEEDS_REVIEW'),lambda p:p.update(rights_status={})]:
   p=deepcopy(self.package);mutate(p)
   with self.assertRaises(Invalid):self.bind(p,True)
 def test_model_answer_is_not_misrepresented_as_criteria(self):
  self.package['questions'][0]['source_page_references'].append(dict(questionId='q',sourceHash='a'*64,role='model_answer',startPage=2,endPage=2,evidenceText='answer',verification='VERIFIED'))
  q,r=self.bind();self.assertEqual(r['not_forwarded_roles'],['model_answer']);self.assertEqual(len(q.frozen_cache['criteria']),1)
if __name__=='__main__':unittest.main()
