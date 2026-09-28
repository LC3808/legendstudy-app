"""Offline promotion equivalence, ordering, and read-only inspection invariants."""
import json,unittest
from pathlib import Path
from pglast import parse_sql,parse_plpgsql
from pglast.stream import RawStream
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
PAIRS=[('001_student_essay_product.draft.sql','20260928000100_student_essay_product.sql'),('002_entitlements.draft.sql','20260928000200_essay_entitlements.sql'),('003_server_operations.draft.sql','20260928000300_essay_server_operations.sql')]
class PromotionTests(unittest.TestCase):
 def test_ast_identical(self):
  for source,target in PAIRS:
   self.assertEqual(RawStream()(parse_sql((ROOT/'supabase/review/essay_lab_product'/source).read_text())),RawStream()(parse_sql((ROOT/'supabase/migrations'/target).read_text())))
 def test_order_unique_and_after_foundation(self):
  files=sorted((ROOT/'supabase/migrations').glob('*.sql'));versions=[p.name.split('_')[0] for p in files]
  self.assertEqual(len(versions),len(set(versions)))
  names=[p.name for p in files];self.assertEqual(names[-4:],['20260927000200_essay_lab_foundation.sql']+[x[1] for x in PAIRS])
 def test_real_sql_and_function_parse(self):
  for _,target in PAIRS:
   text=(ROOT/'supabase/migrations'/target).read_text();self.assertTrue(parse_sql(text))
  # Existing trigger bodies compile in real PostgreSQL; pglast8.4 cannot JSON-decode all legacy trigger ASTs.
  self.assertTrue(parse_plpgsql((ROOT/'supabase/migrations'/PAIRS[-1][1]).read_text()))
 def test_no_top_level_seed_or_destructive_sql(self):
  for _,target in PAIRS:
   for n in parse_sql((ROOT/'supabase/migrations'/target).read_text()):self.assertNotIn(type(n.stmt).__name__,['InsertStmt','UpdateStmt','DeleteStmt','DropStmt','TruncateStmt'])
 def test_inspection_sql_is_readonly(self):
  for name in ['preflight.readonly.sql','post_apply.readonly.sql','catalog_query.readonly.sql']:
   text=(HERE/name).read_text();self.assertIn('begin read only;',text.lower())
   for n in parse_sql(text):
    self.assertIn(type(n.stmt).__name__,['TransactionStmt','SelectStmt','VariableSetStmt'])
    if type(n.stmt).__name__=='VariableSetStmt':
     self.assertTrue(n.stmt.is_local);self.assertIn(n.stmt.name.lower(),['search_path','timezone'])
 def test_expected_catalog_complete(self):
  j=json.loads((HERE/'catalog_contract.json').read_text());self.assertEqual(len(j['tables']),19);self.assertEqual(len(j['objects']),47)
  sql=(ROOT/'supabase/migrations'/PAIRS[-1][1]).read_text()
  self.assertEqual(sql.count('create function public.'),12)
if __name__=='__main__':unittest.main()
