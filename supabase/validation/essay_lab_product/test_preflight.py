"""Offline checks only: no database connection or credential handling."""
import hashlib,json,unittest
from pathlib import Path
from pglast import parse_sql,parser
HERE=Path(__file__).resolve().parent
class PreflightTests(unittest.TestCase):
 def setUp(self): self.r=json.loads((HERE/'production_preflight_result.json').read_text())
 def test_guarded_sql_frozen(self):
  for name,h in self.r['sql_sha256'].items():
   text=(HERE/name).read_text()
   self.assertEqual(hashlib.sha256(text.encode()).hexdigest(),h)
   self.assertIn('begin read only;',text.lower());self.assertTrue(text.rstrip().endswith('rollback;'))
   for stmt in parse_sql(text):
    self.assertIn(type(stmt.stmt).__name__,['SelectStmt','TransactionStmt','VariableSetStmt'])
    if type(stmt.stmt).__name__=='VariableSetStmt':
     self.assertTrue(stmt.stmt.is_local);self.assertIn(stmt.stmt.name,['search_path','timezone'])
   # Also reject modifying CTEs, SELECT INTO and row-locking clauses anywhere in AST.
   def visit(x):
    if isinstance(x,dict):
     self.assertFalse(set(x)&{'InsertStmt','UpdateStmt','DeleteStmt','MergeStmt','IntoClause','LockingClause'})
     for v in x.values():visit(v)
    elif isinstance(x,list):
     for v in x:visit(v)
   visit(json.loads(parser.parse_sql_json(text)))
 def test_history_blocks_apply(self):
  self.assertFalse(self.r['catalog']['check_11'][0]['history_available'])
  self.assertEqual(self.r['checks']['MIGRATION_HISTORY'],'FAIL')
  self.assertFalse(self.r['ready_for_production_apply']);self.assertFalse(self.r['production_apply'])
 def test_canonical_preserved(self):
  self.assertEqual(self.r['canonical_before'],self.r['canonical_after'])
  for k in ['orphan_exams','orphan_exam_resource_exam','orphan_exam_resource_resource']:self.assertEqual(self.r['supplement'][k],0)
 def test_no_target_collisions(self):
  self.assertEqual(len(self.r['catalog']['check_04']),19)
  self.assertTrue(all(x['name_available'] for x in self.r['catalog']['check_04']))
  self.assertEqual(len(self.r['catalog']['check_06']),28)
  self.assertTrue(all(x['function_name_available'] for x in self.r['catalog']['check_06']))
if __name__=='__main__':unittest.main()
