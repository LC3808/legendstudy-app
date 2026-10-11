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
if __name__=='__main__':unittest.main()
