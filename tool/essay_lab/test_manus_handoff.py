import json,os,shutil,tempfile,unittest
from pathlib import Path
from essay_lab.manus_handoff import verify,refs,validate_evidence_candidate
PACKAGE=Path(os.environ.get('MANUS_PACKAGE_DIR','/nonexistent'))
class Contract(unittest.TestCase):
 def test_source_list_forms(self):
  self.assertEqual(refs("['LSL27-1','LSL27-2']"),['LSL27-1','LSL27-2']);self.assertEqual(refs('LSL27-1 | LSL27-2'),['LSL27-1','LSL27-2'])
 def test_literal_is_not_executed(self):
  with self.assertRaises(ValueError):refs('[__import__("os").system("false")]')
 def test_missing_evidence_is_not_importable(self):
  result=validate_evidence_candidate({'rights':'REVIEW_REQUIRED'});self.assertFalse(result['importReady']);self.assertIn('RIGHTS_REVIEW',result['missing'])
 def complete_candidate(self):
  return dict(questionId='synthetic',academicYear=2025,examKind='mock',sourceLocator='PDF p1',pdfSha256='a'*64,rights='APPROVED',examId='synthetic-exam',visibleResourceIds=['synthetic-resource'],resourceMappings=[dict(essay_exam_id='synthetic-exam',resource_id='synthetic-resource',role=r,is_active=True,verification_status='verified',provenance='official',official_source_url='https://example.edu/synthetic',source_locator='PDF p1',source_sha256='a'*64) for r in ['question','scoring_criteria']])
 def test_complete_evidence_never_enables_evaluator(self):
  result=validate_evidence_candidate(self.complete_candidate());self.assertTrue(result['importReady']);self.assertFalse(result['evaluationAllowed']);self.assertFalse(result['publicationAllowed'])
 def test_unverified_role_remains_blocked(self):
  c=self.complete_candidate();c['resourceMappings'][1]['verification_status']='review';self.assertFalse(validate_evidence_candidate(c)['importReady'])
 def test_role_source_hash_required(self):
  c=self.complete_candidate();c['resourceMappings'][1]['source_sha256']='';self.assertIn('MAPPING_SOURCE_HASH',validate_evidence_candidate(c)['missing'])
@unittest.skipUnless(PACKAGE.exists(),'Requires Owner-provided local V2 ZIP extraction; no download')
class Handoff(unittest.TestCase):
 def test_actual_integrity_relationships_and_states(self):
  a,c,e=verify(PACKAGE);self.assertFalse([x for x in a['issues'] if x['severity']=='error']);self.assertEqual(sum(f['manifest_match'] for f in a['files']),12);self.assertEqual(a['counts']['tracks'],101);self.assertEqual(len(e),10);self.assertTrue(all(o['questionSets']==[] and o['evaluationState']=='NOT_CONNECTED' for o in c['offerings']))
 def test_future_date_quarantined_without_rewrite(self):
  a,c,e=verify(PACKAGE);r=[o for o in c['offerings'] if 'LSL27-052' in o['sourceIds']][0];self.assertEqual(r['metadataState'],'QUARANTINED');self.assertIn('2027-08-27',json.dumps(r,ensure_ascii=False))
 def test_tampering_and_orphan_detected(self):
  with tempfile.TemporaryDirectory() as t:
   p=Path(t)/'source';shutil.copytree(PACKAGE,p);f=p/'data/essay-tracks-2027.csv';s=f.read_text(encoding='utf-8-sig');s=s.replace('ajou-essay-2027-b27ebd06,','missing-offering,',1);f.write_text(s,encoding='utf-8-sig');a,_,_=verify(p);codes={x['code'] for x in a['issues']};self.assertIn('SOURCE_HASH_MISMATCH',codes);self.assertIn('MISSING_OFFERING',codes)
 def test_reproducible_no_current_time_identity(self):self.assertEqual(verify(PACKAGE),verify(PACKAGE))
if __name__=='__main__':unittest.main()
