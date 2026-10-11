import unittest
from copy import deepcopy
from tool.essay_lab.public_catalog import build

class PublicCatalogTests(unittest.TestCase):
 def fixture(self):
  row=dict(id='source-1',universityId='source-university',name='자료 대학',campus='서울',region='서울',year=2027,admissionNames=['논술'],sourceIds=['row-1'],checkedAt='2026-10-10',sourceStatus='OFFICIAL_CONFIRMED',metadataState='VERIFIED',rawMaster=[dict(evidence_status='OFFICIAL_CONFIRMED',essay_type='자연: 수학 논술; 과학(40%)',official_source_url='https://admission.example.edu/source.pdf')])
  return {'version':'essay-research-preview-v1','asOf':'2026-10-10','offerings':[row]}, {'verifiedAt':'2026-10-11','universities':[]}
 def test_nullable_identity_and_literal_type_not_department(self):
  c,i=self.fixture();u=build(c,i)['universities'][0]
  self.assertIsNone(u['universityId']);self.assertEqual(u['sourceUniversityId'],'source-university');self.assertEqual(u['offerings'][0]['types'],['수리','과학'])
  c['offerings'][0]['rawMaster'][0]['essay_type']='NOT PUBLISHED';self.assertEqual(build(c,i)['universities'][0]['offerings'][0]['types'],[])
 def test_campuses_retained_quarantined_offer_excluded(self):
  c,i=self.fixture();other=deepcopy(c['offerings'][0]);other.update(id='source-2',campus='세종',region='세종');c['offerings'].append(other)
  self.assertEqual(len(build(c,i)['universities'][0]['offerings']),2)
  other['metadataState']='QUARANTINED';self.assertEqual(len(build(c,i)['universities'][0]['offerings']),1)
 def test_no_duplicate_or_unverified_university(self):
  c,i=self.fixture();c['offerings'].append(deepcopy(c['offerings'][0]))
  with self.assertRaisesRegex(ValueError,'DUPLICATE_OFFERING'):build(c,i)
  c,i=self.fixture();c['offerings'][0]['rawMaster'][0]['evidence_status']='UNVERIFIED'
  with self.assertRaisesRegex(ValueError,'UNVERIFIED_UNIVERSITY'):build(c,i)
 def test_admission_projection_omits_unknowns_and_preserves_source_scope(self):
  c,i=self.fixture();r=c['offerings'][0]['rawMaster'][0]
  r.update(inventory_id='row-1',recruitment_track='지역인재',intake_count='21명',exam_date='NOT PUBLISHED',answer_length='노트형 답안지; individual limit NOT PUBLISHED',question_count='Campus subtotal NOT PUBLISHED',essay_weight='80%',notes='시행계획 값',private_answer='must not be public')
  d=build(c,i)['universities'][0]['offerings'][0]['admissionDetails'][0]
  self.assertEqual(d['facts'],dict(intake_count='21명',essay_weight='80%'))
  self.assertEqual(d['name'],'지역인재');self.assertEqual(d['documentBasis'],'시행계획 포함')
  self.assertIsNone(d['applicants']);self.assertIsNone(d['competitionRatio']);self.assertNotIn('private_answer',str(d))
 def test_development_group_never_generates_short_answer_type(self):
  c,i=self.fixture();c['offerings'][0]['rawMaster'][0]['essay_type']='인문·사회 통합 논술 및 수학 논술'
  self.assertNotIn('단답·약술형',build(c,i)['universities'][0]['offerings'][0]['types'])
  c['offerings'][0]['rawMaster'][0]['essay_type']='국어·수학 약술형 논술'
  self.assertIn('단답·약술형',build(c,i)['universities'][0]['offerings'][0]['types'])
if __name__=='__main__':unittest.main()
