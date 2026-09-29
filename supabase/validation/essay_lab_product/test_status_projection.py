import json,re,unittest
from pathlib import Path
from pglast import parse_sql,parse_plpgsql
ROOT=Path(__file__).resolve().parents[3]
SQL=(ROOT/'supabase/migrations/20260929000400_essay_owner_evaluation_status.sql').read_text()
class StatusProjection(unittest.TestCase):
 def test_parse(self):self.assertTrue(parse_sql(SQL));self.assertTrue(parse_plpgsql(SQL))
 def test_one_function_no_schema_data_mutation(self):
  nodes=parse_sql(SQL);self.assertEqual(sum(type(n.stmt).__name__=='CreateFunctionStmt' for n in nodes),1)
  for n in nodes:self.assertNotIn(type(n.stmt).__name__,['CreateStmt','AlterTableStmt','CreatePolicyStmt','AlterPolicyStmt','InsertStmt','UpdateStmt','DeleteStmt','DropStmt'])
 def test_stable_owner_only_fixed_path(self):
  self.assertIn("stable security definer set search_path=''",SQL)
  self.assertIn('s.user_id=u',SQL);self.assertIn('a.id=ev.attempt_id and a.session_id=ev.session_id',SQL)
  self.assertIn('to authenticated;',SQL);self.assertNotIn('p_user',SQL)
  body=SQL.split('as $$',1)[1].split('end$$;',1)[0]
  self.assertNotRegex(body,r'\b(?:insert|update|delete)\s+(?:into|from|public\.)')
 def test_output_allowlist(self):
  response=SQL.split('return jsonb_build_object',1)[1].split('end$$;',1)[0]
  for key in ['state','credit_state','credit_mode','release_confirmed','no_credit_consumed']:self.assertIn("'"+key+"'",response)
  for secret in ['lease_token','provider','run_id','error_code','worker']:self.assertNotIn(secret,response)
 def test_release_checks_ledger_and_terminal_state(self):
  self.assertIn("b.status='released'",SQL);self.assertIn('consumed=0',SQL)
  self.assertIn('reserved=released and per_grant_closed',SQL)
  self.assertIn("student_state<>'reconciling'",SQL)
 def test_latest_evaluation_run_only(self):
  self.assertIn('where evaluation_id=e.id',SQL);self.assertIn('order by run_no desc limit 1',SQL)
 def test_deployment_receipt_matches_tested_bytes(self):
  import hashlib
  d=json.loads((ROOT/'supabase/validation/essay_lab_product/status_projection_result.json').read_text())
  self.assertEqual(d['migration_sha256'],hashlib.sha256(SQL.encode()).hexdigest())
  self.assertEqual(d['post_apply'],'PASS');self.assertEqual(d['pending'],[])
  for mode in ['native','jwt']:
   self.assertEqual(d['runtime'][mode]['status_projection_count'],55)
   self.assertEqual(d['runtime'][mode]['status_migration_sha256'],d['migration_sha256'])
  self.assertTrue(d['runtime']['jwt']['real_JWT'])
if __name__=='__main__':unittest.main()
