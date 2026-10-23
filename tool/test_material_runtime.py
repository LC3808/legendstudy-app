import unittest
from copy import deepcopy
from essay_lab.material_runtime import reviewed_material_question,material_readiness,load_reviewed_material,fetch_reviewed_material
from essay_lab.live_worker import Invalid

class MaterialRuntimeTests(unittest.TestCase):
 def setUp(self):
  self.exam=dict(examId='e',universityId='u',year=2024,kind='admission',track='인문',session='오후2',campus=None,name='Hanyang 2024 afternoon2',sourceHashes=['a'*64],questions=[dict(id='q',sourceKey='source:q')])
  self.package=dict(schema='essay-material-package-v1',verification_status='VERIFIED_MANIFEST',package_digest='f'*64,package_version=2,exam_id='e',university_id='u',exam_identity=dict(academic_year=2024,exam_type='admission',track='인문',title='Hanyang 2024 afternoon2'),rights_status={'a'*64:{'providerTransmission':'APPROVED'}},questions=[dict(question_id='q',source_key='source:q',source_page_references=[dict(questionId='q',sourceHash='a'*64,role=r,startPage=1,endPage=1,evidenceText='official '+r,verification='VERIFIED') for r in ['question','shared_passage','intent','criteria','scoring']])])
 def bind(self,p=None,approved=False):return reviewed_material_question(p or self.package,{'exams':[self.exam]},'q',pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities',approved_processing=approved)
 def test_binds_existing_runtime_without_activation(self):
  q,report=self.bind();self.assertFalse(q.approved_processing);self.assertTrue(q.reviewed_cache);self.assertEqual(q.frozen_cache['criteria'][0]['label'],'official criteria');self.assertFalse(report['activation_granted'])
 def test_official_range_surfaces_without_inventing_counting_or_penalty(self):
  self.package['questions'][0]['source_page_references'][0]['evidenceText']='분석하시오. (801~1,000자)'
  q,_=self.bind();length=q.frozen_cache['length_requirement']
  self.assertEqual(length['official_question_ranges'][0]['quote'],'801~1,000자')
  self.assertIsNone(length['counting_convention']);self.assertIsNone(length['deduction_rule'])
 def test_passage_range_is_not_question_requirement(self):
  self.package['questions'][0]['source_page_references'][1]['evidenceText']='인용: 100~200자'
  q,_=self.bind();self.assertIsNone(q.frozen_cache['length_requirement'])
 def test_plus_minus_question_range_surfaces_without_assumed_penalty(self):
  self.package['questions'][0]['source_page_references'][0]['evidenceText']='오류를 설명하시오. (300±30자)'
  q,_=self.bind();length=q.frozen_cache['length_requirement']
  self.assertEqual(length['official_question_ranges'][0]['quote'],'300±30자')
  self.assertIsNone(length['counting_convention']);self.assertIsNone(length['deduction_rule'])
 def test_wrong_exam_unreviewed_or_rights_block(self):
  for mutate in [lambda p:p['exam_identity'].update(academic_year=2025),lambda p:p.update(package_digest='e'*64),lambda p:p['questions'][0]['source_page_references'][0].update(verification='NEEDS_REVIEW'),lambda p:p.update(rights_status={})]:
   p=deepcopy(self.package);mutate(p)
   with self.assertRaises(Invalid):self.bind(p,True)
 def test_review_status_does_not_hide_empty_question_or_missing_rights(self):
  p=deepcopy(self.package)
  p['questions'][0]['source_page_references'][0]['evidenceText']=''
  p['rights_status']={}
  codes={i['code'] for i in material_readiness(p,{'exams':[self.exam]})}
  self.assertTrue({'MISSING_EVIDENCE','EMPTY_MAPPING','PROVIDER_RIGHTS_REQUIRED'}<=codes)
 def test_complete_content_has_no_readiness_blockers(self):
  self.assertEqual(material_readiness(self.package,{'exams':[self.exam]}),[])
 def test_host_loader_requires_content_and_keeps_activation_separate(self):
  q,r=load_reviewed_material(self.package,{'exams':[self.exam]},pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities')
  self.assertTrue(r['ready']);self.assertFalse(q['q'].approved_processing)
  self.package['questions'][0]['source_page_references'][0]['evidenceText']=''
  q,r=load_reviewed_material(self.package,{'exams':[self.exam]},pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities')
  self.assertEqual(q,{});self.assertFalse(r['ready'])
 def test_fetch_uses_pinned_worker_rpc_without_activation(self):
  calls=[]
  def rpc(name,args):calls.append((name,args));return self.package
  q,r=fetch_reviewed_material(rpc,{'exams':[self.exam]},exam_id='e',pinned_digest='f'*64,binding={},regime='held',evaluation_type='humanities')
  self.assertEqual(calls,[('essay_material_runtime_package',{'p_exam':'e','p_digest':'f'*64})])
  self.assertFalse(q['q'].approved_processing)
 def image(self):
  import base64,hashlib
  raw=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Zl1EAAAAASUVORK5CYII=')
  return dict(sha256=hashlib.sha256(raw).hexdigest(),data=base64.b64encode(raw).decode(),sourceHash='a'*64,startPage=1,endPage=1)
 def test_official_images_follow_pinned_question_evidence(self):
  self.package['questions'][0]['official_images']=[self.image()]
  q,_=self.bind();images=q.frozen_cache['official_images']
  self.assertEqual(len(images),1)
  self.assertEqual(set(images[0]['evidence_ids']),{e['binding']['id'] for e in q.frozen_cache['evidence'] if e['binding']['role'] in ('question','passage')})
  self.assertFalse(q.approved_processing)
 def test_foreign_page_source_or_changed_image_fails_closed(self):
  for change in [dict(sourceHash='b'*64),dict(startPage=2,endPage=2),dict(sha256='0'*64)]:
   self.package['questions'][0]['official_images']=[dict(self.image(),**change)]
   with self.assertRaises(Invalid):self.bind()
 def test_official_images_cannot_point_only_to_rubric(self):
  for m in self.package['questions'][0]['source_page_references']:
   if m['role']=='criteria':m.update(startPage=2,endPage=2)
  self.package['questions'][0]['official_images']=[dict(self.image(),startPage=2,endPage=2)]
  with self.assertRaisesRegex(Invalid,'FOREIGN_OFFICIAL_IMAGE'):self.bind()
 def test_model_answer_is_not_misrepresented_as_criteria(self):
  self.package['questions'][0]['source_page_references'].append(dict(questionId='q',sourceHash='a'*64,role='model_answer',startPage=2,endPage=2,evidenceText='answer',verification='VERIFIED'))
  q,r=self.bind();self.assertEqual(r['not_forwarded_roles'],['model_answer']);self.assertEqual(len(q.frozen_cache['criteria']),1)
if __name__=='__main__':unittest.main()
