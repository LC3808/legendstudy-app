"""Offline shape/security regression checks; actual operation tests live in runtime/."""
from pathlib import Path
import unittest
from pglast import parse_sql,parse_plpgsql
HERE=Path(__file__).parent
SQL=(HERE/'003_server_operations.draft.sql').read_text()

class ServerDraftTests(unittest.TestCase):
 def test_real_postgres_syntax(self):
  self.assertGreater(len(parse_sql(SQL)),30)
  self.assertGreater(len(parse_plpgsql(SQL)),15)
 def test_only_additive_existing_table_changes(self):
  nodes=parse_sql(SQL)
  self.assertFalse(any(n.stmt.__class__.__name__ in ('CreateStmt','DropStmt','TruncateStmt') for n in nodes))
  tables=[n.stmt for n in nodes if n.stmt.__class__.__name__=='AlterTableStmt']
  self.assertEqual({n.relation.relname for n in tables},{'essay_attempts','essay_evaluations','essay_ai_processing_runs'})
 def test_public_operations_are_definer_fixed_path(self):
  funcs=[n.stmt for n in parse_sql(SQL) if n.stmt.__class__.__name__=='CreateFunctionStmt']
  public=[f for f in funcs if f.funcname[0].sval=='public']
  self.assertEqual(len(public),12)
  for f in public:
   self.assertTrue(any(o.defname=='security' and o.arg.boolval for o in f.options))
   self.assertTrue(any(o.defname=='set' and o.arg.name=='search_path' for o in f.options))
 def test_no_client_owner_parameter(self):
  for n in parse_sql(SQL):
   f=n.stmt
   if f.__class__.__name__=='CreateFunctionStmt' and f.funcname[0].sval=='public':
    self.assertFalse(any(p.name in ('user_id','p_user_id','owner_id') for p in f.parameters or ()))
 def test_no_test_switch_or_provider_in_sql(self):
  self.assertNotIn('essay_test.',SQL)
  self.assertNotIn('p_fail',SQL)
  self.assertNotIn('http_post',SQL)
  self.assertNotIn('grant essay_executor to essay_worker',SQL)
 def test_uid_bridge_narrow(self):
  self.assertIn("as $$select auth.uid()$$",SQL)
  self.assertIn("f.proname='uid'",SQL)
  self.assertIn('revoke essay_executor from current_user',SQL)

if __name__=='__main__':unittest.main()
