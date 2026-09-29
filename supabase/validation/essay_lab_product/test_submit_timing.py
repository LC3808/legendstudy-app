"""The forward migration changes exactly one expression in the original RPC."""
import re, unittest
from pathlib import Path
from pglast import parse_sql, parse_plpgsql
ROOT=Path(__file__).resolve().parents[3]
OLD=(ROOT/'supabase/migrations/20260928000300_essay_server_operations.sql').read_text()
NEW=(ROOT/'supabase/migrations/20260929000200_essay_submit_timing_correction.sql').read_text()
OLD_EXPR='least(d.active_writing_seconds,greatest(0,extract(epoch from now()-d.started_at)::int))'
NEW_EXPR='case when d.active_writing_seconds is null then null else least(d.active_writing_seconds,greatest(0,floor(extract(epoch from now()-d.started_at))::int)) end'
class TimingCorrection(unittest.TestCase):
 def test_exact_single_expression_change(self):
  prior=re.search(r'create function public\.essay_submit_attempt\(.*?end\$\$;',OLD,re.S).group()
  new=re.search(r'create or replace function public\.essay_submit_attempt\(.*?end\$\$;',NEW,re.S).group()
  self.assertEqual(new,prior.replace('create function','create or replace function',1).replace(OLD_EXPR,NEW_EXPR))
 def test_real_sql_parse(self):
  self.assertTrue(parse_sql(NEW));self.assertTrue(parse_plpgsql(NEW))
 def test_no_data_schema_or_check_changes(self):
  types=[type(n.stmt).__name__ for n in parse_sql(NEW)]
  self.assertEqual(types,['TransactionStmt','GrantRoleStmt','CreateFunctionStmt','GrantRoleStmt','TransactionStmt'])
 def test_membership_is_temporary_no_acl_changes(self):
  self.assertIn('grant essay_executor to current_user;',NEW)
  self.assertIn('revoke essay_executor from current_user;',NEW)
  self.assertNotIn('grant execute',NEW.lower());self.assertNotIn('alter function',NEW.lower())
 def test_no_existing_migration_updated(self):
  self.assertIn(OLD_EXPR,OLD);self.assertNotIn(NEW_EXPR,OLD)
if __name__=='__main__':unittest.main()
