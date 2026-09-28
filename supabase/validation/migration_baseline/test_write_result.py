"""Offline verification of the authorized baseline write; no database connections."""
from pathlib import Path
import json,hashlib,unittest
H=Path(__file__).resolve().parent
class WriteResultTests(unittest.TestCase):
 def setUp(self):self.r=json.loads((H/'write_result.json').read_text());self.a=json.loads((H/'adoption_result.json').read_text())
 def test_exact_allowlist(self):
  self.assertEqual(self.r['remote_baseline_versions'],self.a['baseline_versions'])
  self.assertEqual(len(self.r['remote_baseline_versions']),13);self.assertEqual(self.r['unexpected_remote_versions'],[])
  self.assertEqual(self.r['repair_count'],1);self.assertFalse(self.r['repair_all'])
 def test_metadata_pinned(self):
  for m in self.r['metadata_checks']:
   files=list((H.parents[2]/'supabase/migrations').glob(m['version']+'_*.sql'));self.assertEqual(len(files),1)
   self.assertEqual(hashlib.sha256(files[0].read_bytes()).hexdigest(),m['pinned_file_sha256'])
   self.assertEqual(m['name'],files[0].name[15:-4]);self.assertTrue(m['statements_ast_match'])
 def test_dry_run_only(self):
  self.assertEqual(self.r['actual_pending'],self.a['expected_pending_after_baseline'])
  d=self.r['dry_run_output'];self.assertTrue(d['dryRun']);self.assertEqual(d['seeds'],[]);self.assertEqual(d['roles'],[])
  self.assertEqual([x.split('_')[0] for x in d['migrations']],self.r['actual_pending'])
  self.assertIn('--skip-vault',self.r['dry_run_command']);self.assertFalse(self.r['product_migration_apply'])
 def test_application_preserved(self):
  self.assertEqual(self.r['canonical_before'],self.r['canonical_after'])
  self.assertEqual(self.r['application_catalog_sha256_before'],self.r['application_catalog_sha256_after'])
  self.assertEqual(self.r['final_product_table_collision_count'],0);self.assertEqual(self.r['final_product_function_collision_count'],0)
  for key in ['old_sql_replayed','application_schema_mutation','application_data_mutation','student_data_created','ai_called']:self.assertFalse(self.r[key])
if __name__=='__main__':unittest.main()
