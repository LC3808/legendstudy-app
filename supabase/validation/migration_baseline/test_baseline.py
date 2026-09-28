"""Offline assertions; no Production network, migration execution, or personal fixtures."""
import hashlib,json,re,runpy,unittest
from pathlib import Path
from pglast import parse_sql,parser
H=Path(__file__).resolve().parent
M=json.loads((H/'manifest.json').read_text())
class BaselineTests(unittest.TestCase):
 def test_inventory_frozen_complete(self):
  actual=sorted((H.parents[2]/'supabase/migrations').glob('*.sql'))
  self.assertEqual(len(actual),16)
  self.assertEqual([p.name for p in actual],[x['filename'] for x in M['migrations']])
  for p,x in zip(actual,M['migrations']):self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),x['sha256'])
 def test_catalog_compare(self):
  namespace=runpy.run_path(str(H/'compare.py'));rows=namespace['results']
  self.assertEqual(sum(len(v) for v in rows.values()),1569)
  self.assertTrue(all(x['match'] for v in rows.values() for x in v))
 def test_normalizer_preserves_material_change(self):
  n=runpy.run_path(str(H/'compare.py'));e=n['exp']
  self.assertNotEqual(e("level between 1 and 5"),e("level between 1 and 6"))
  self.assertNotEqual(e("role in ('question','passage')"),e("role in ('question','answer')"))
  self.assertNotEqual(e('auth.uid() = user_id'),e('true'))
  self.assertEqual(e("state in ('open','resolved')"),e("state = ANY(ARRAY['open'::text,'resolved'::text])"))
 def test_no_write_inference(self):
  self.assertFalse(M['history_present']);self.assertFalse(M['baseline_ready'])
  self.assertEqual(M['confirmed_applied'],[]);self.assertEqual(M['approved_history_write_versions'],[])
  self.assertEqual(len(M['state_equivalent_execution_unproven']),10)
  self.assertEqual(len(M['unknown']),13);self.assertEqual(len(M['unknown_data_effects']),3)
  for v in M['unknown_data_effects']:self.assertEqual(next(x for x in M['migrations'] if x['version']==v)['state_equivalent'],'UNKNOWN')
 def test_pending_never_baselined(self):
  self.assertEqual(M['confirmed_not_applied'],M['after_baseline_expected_pending'])
  self.assertEqual(len(M['confirmed_not_applied']),3)
 def test_canonical_preserved(self):self.assertEqual(M['canonical_before'],M['canonical_after'])
 def test_readonly_query(self):
  for name,h in json.loads((H/'query_hashes.json').read_text()).items():
   text=(H/name).read_text();self.assertEqual(hashlib.sha256(text.encode()).hexdigest(),h)
   self.assertIn('begin read only;',text);self.assertTrue(text.rstrip().endswith('rollback;'))
   for n in parse_sql(text):self.assertIn(type(n.stmt).__name__,['SelectStmt','TransactionStmt','VariableSetStmt'])
   tree=json.loads(parser.parse_sql_json(text))
   def walk(x):
    if isinstance(x,dict):
     self.assertFalse(set(x)&{'InsertStmt','UpdateStmt','DeleteStmt','MergeStmt','IntoClause','LockingClause'})
     for v in x.values():walk(v)
    elif isinstance(x,list):
     for v in x:walk(v)
   walk(tree)
 def test_no_private_identifiers(self):
  for name in ['manifest.json','catalog.json','catalog_followup.json','inventory.json']:
   text=(H/name).read_text()
   self.assertNotRegex(text,r'postgres(?:ql)?://|eyJ[A-Za-z0-9_-]{20,}|sbp_[A-Za-z0-9]{20,}')
   self.assertNotRegex(text,r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b')
if __name__=='__main__':unittest.main()
