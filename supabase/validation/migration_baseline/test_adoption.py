"""Only the three current data-correction invariants; do not rerun broad comparison."""
import hashlib,json,unittest
from pathlib import Path
from pglast import parse_sql,parser
H=Path(__file__).resolve().parent
class AdoptionTests(unittest.TestCase):
 def setUp(self):self.r=json.loads((H/'adoption_result.json').read_text())
 def test_three_current_invariants(self):
  c=self.r['corrections'];self.assertEqual(set(c),{'20260917000200','20260926000100','20260927000100'})
  for v in c.values():
   self.assertEqual(v['current_violation_count'],0);self.assertEqual(v['current_invariant'],'PASS')
   self.assertEqual(v['baseline_safe'],'YES');self.assertEqual(v['replay_effect'],'NO_OP')
  self.assertEqual(c['20260917000200']['aggregate_evidence']['backfill_replay_matched_rows'],0)
 def test_order_and_pending(self):
  versions=[p.name.split('_')[0] for p in sorted((H.parents[2]/'supabase/migrations').glob('*.sql'))]
  self.assertEqual(self.r['baseline_versions'],versions[:13]);self.assertEqual(self.r['expected_pending_after_baseline'],versions[13:])
  self.assertEqual(self.r['baseline_cutoff'],'20260927000200')
 def test_no_execution_claim_or_write(self):
  self.assertTrue(self.r['structural_match']['reused']);self.assertFalse(self.r['structural_match']['rerun'])
  self.assertFalse(self.r['individual_cli_execution_proven'])
  for k in ['history_write_performed','production_mutation','migration_repair','db_push','db_push_dry_run','product_apply']:self.assertFalse(self.r[k])
 def test_query_guard(self):
  s=(H/'adoption.readonly.sql').read_text();self.assertEqual(hashlib.sha256(s.encode()).hexdigest(),self.r['query_sha256'])
  self.assertIn('begin read only;',s);self.assertTrue(s.rstrip().endswith('rollback;'))
  for n in parse_sql(s):self.assertIn(type(n.stmt).__name__,['TransactionStmt','SelectStmt','VariableSetStmt'])
  def visit(x):
   if isinstance(x,dict):
    self.assertFalse(set(x)&{'InsertStmt','UpdateStmt','DeleteStmt','MergeStmt','IntoClause','LockingClause'})
    if 'FuncCall' in x:self.assertIn('.'.join(v['String']['sval'] for v in x['FuncCall']['funcname']),['count','jsonb_build_object'])
    for v in x.values():visit(v)
   elif isinstance(x,list):
    for v in x:visit(v)
  visit(json.loads(parser.parse_sql_json(s)))
if __name__=='__main__':unittest.main()
