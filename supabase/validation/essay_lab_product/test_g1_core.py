"""G1 scope/security regression guards. Runtime assertions live in g1_runtime.py."""
import re, unittest
from pathlib import Path
from pglast import parse_sql, parse_plpgsql
from pglast.stream import RawStream
ROOT=Path(__file__).resolve().parents[3]
SQL=(ROOT/'supabase/migrations/20260929000300_essay_credit_commercial_core.sql').read_text()
PRIOR=(ROOT/'supabase/migrations/20260929000100_essay_scaffolding_persistence.sql').read_text()
class G1Static(unittest.TestCase):
 def test_real_parse(self):
  nodes=parse_sql(SQL);self.assertTrue(nodes)
  for node in nodes:
   if type(node.stmt).__name__=='CreateFunctionStmt' and node.stmt.funcname[-1].sval!='credit_profile_signup':
    self.assertTrue(parse_plpgsql(RawStream()(node)))
  # pglast trigger AST JSON serialization limitation; real PG/JWT covers trigger compilation/execution.
 def test_finalize_only_policy_posting_change(self):
  for name in ['scaffold_legacy_essay_finalize_success','scaffold_finalize_v13']:
   pattern=r'create (?:or replace )?function essay_private\.'+name+r'\(.*?end\$\$;'
   prior=re.search(pattern,PRIOR,re.S).group()
   new=re.search(pattern,SQL,re.S).group()
   expected=prior.replace('create function','create or replace function',1).replace("'essay_cycle_v1'","b.policy_key||'_'||b.policy_version")
   self.assertEqual(new,expected)
 def test_no_tables_or_top_level_fact_mutation(self):
  for node in parse_sql(SQL):
   self.assertNotIn(type(node.stmt).__name__,['CreateStmt','DropStmt','InsertStmt','UpdateStmt','DeleteStmt','TruncateStmt','CreatePolicyStmt','AlterPolicyStmt'])
  self.assertEqual(re.findall(r'add column (\w+)',SQL),['billing_policy_version'])
 def test_only_new_public_endpoints(self):
  self.assertEqual(re.findall(r'create function public\.(\w+)',SQL),['essay_claim_signup_credit','essay_admin_grant'])
  self.assertNotIn('create or replace function public.essay_submit_attempt',SQL)
 def test_existing_v1_and_new_v2_pin(self):
  self.assertIn("billing_policy_version text not null default 'v1'",SQL)
  self.assertIn("billing_policy_version set default 'v2'",SQL)
  self.assertNotIn('attempt_no',SQL)
  self.assertIn('scaffold_legacy_essay_request_evaluation(p_attempt,p_key,p_regime)',SQL)
 def test_signup_and_parent_database_uniqueness(self):
  self.assertIn('create unique index credit_signup_once_per_account',SQL)
  self.assertIn('create unique index essay_v2_included_once',SQL)
  self.assertIn("'signup_bonus/'||u::text",SQL)
 def test_security_scope(self):
  funcs=re.findall(r'create (?:or replace )?function .*?(?:end\$\$;|\$fn\$)',SQL,re.S)
  self.assertTrue(all("set search_path=''" in f for f in funcs))
  self.assertIn('to essay_finance;',SQL)
  self.assertIn('from public,anon,authenticated,service_role,essay_worker,essay_finance',SQL)
  self.assertIn('revoke essay_executor from current_user;',SQL)
  self.assertNotIn('grant essay_executor to essay_finance',SQL)
if __name__=='__main__':unittest.main()
