"""Offline migration/adapter checks; runtime reports are separate."""
import copy,hashlib,re,sys,unittest
from pathlib import Path
from pglast import parse_sql,parse_plpgsql
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tool/essay_lab'))
from scaffolding_adapter import finalize_payload
SQL=(ROOT/'supabase/migrations/20260929000100_essay_scaffolding_persistence.sql').read_text()
OLD=(ROOT/'supabase/migrations/20260928000300_essay_server_operations.sql').read_text()

class PersistenceStatic(unittest.TestCase):
 def test_sql_and_functions_parse(self):
  self.assertTrue(parse_sql(SQL));self.assertTrue(parse_plpgsql(SQL))
 def test_only_one_column_no_seed_or_table(self):
  nodes=parse_sql(SQL); alters=[n.stmt for n in nodes if type(n.stmt).__name__=='AlterTableStmt']
  self.assertEqual(len(alters),1);self.assertEqual(alters[0].relation.relname,'essay_improvement_progress')
  self.assertEqual(len(alters[0].cmds),1);self.assertEqual(alters[0].cmds[0].def_.colname,'scaffolding_observation')
  for n in nodes:self.assertNotIn(type(n.stmt).__name__,['CreateStmt','DropStmt','InsertStmt','UpdateStmt','DeleteStmt','TruncateStmt'])
 def test_v12_function_bodies_exact(self):
  for name in ['essay_request_evaluation','essay_claim','essay_finalize_success']:
   old=re.search(r'create function public\.'+name+r'\(.*?end\$\$;',OLD,re.S).group()
   expected=old.replace('create function public.'+name,'create function essay_private.scaffold_legacy_'+name,1)
   self.assertIn(expected,SQL)
 def test_explicit_version_routing_and_no_default_upgrade(self):
  self.assertIn("default 'essay-v1.2'",SQL)
  self.assertIn("p_regime in ('essay-v1.3','essay-v1.3-next-model')",SQL)
  self.assertIn("e.regime_key,'scaffolding-1.3-v1'",SQL)
 def test_all_new_functions_have_fixed_path_and_explicit_acl(self):
  funcs=re.findall(r'create (?:or replace )?function .*?end\$\$;',SQL,re.S)
  self.assertEqual(len(funcs),12)
  self.assertTrue(all("set search_path=''" in f for f in funcs))
  self.assertIn('from public,anon,authenticated,service_role,essay_worker,essay_finance',SQL)
  self.assertIn('revoke create on schema public,essay_private from essay_executor',SQL)
 def test_v12_adapter_pass_through_no_mutation(self):
  old={'contract_version':'1.2','legacy':{'a':1}}
  self.assertEqual(finalize_payload(old,contract_version='1.2'),old)
  result=finalize_payload(old,contract_version='1.2');result['legacy']['a']=2
  self.assertEqual(old['legacy']['a'],1)
 def test_provider_cannot_self_approve(self):
  with self.assertRaises(ValueError):finalize_payload({'contract_version':'1.3','local_reviews':[]},contract_version='1.3')
 def test_local_review_exact_binding_and_required(self):
  item={'issue_key':'local','claim_scope':'local_sentence','explanation':'합성 진단'}
  sentence={'linked_issue_key':'local','quote':'합성 원문'}
  output={'contract_version':'1.3','improvements':[item],'sentence_feedback':[sentence]}
  with self.assertRaises(ValueError):finalize_payload(output,contract_version='1.3')
  approval={'issue':copy.deepcopy(item),'sentences':[copy.deepcopy(sentence)],'reviewer':'synthetic-trusted-review','decision':'local_only'}
  result=finalize_payload(output,contract_version='1.3',local_reviews=[approval]);self.assertNotIn('local_reviews',output)
  self.assertEqual(result['local_reviews'],[approval])
  for change in ['issue','sentences','reviewer','decision']:
   bad=copy.deepcopy(approval);bad[change]=None
   with self.assertRaises(ValueError):finalize_payload(output,contract_version='1.3',local_reviews=[bad])
 def test_official_requires_no_local_approval(self):
  output={'contract_version':'1.3','improvements':[{'claim_scope':'official_criterion'}],'sentence_feedback':[]}
  self.assertEqual(finalize_payload(output,contract_version='1.3')['local_reviews'],[])
 def test_review_and_v12_contracts_frozen(self):
  self.assertEqual(hashlib.sha256((ROOT/'tool/essay_lab/evidence/evaluation_contract_v1_2.json').read_bytes()).hexdigest(),'84d19d3474ffdf1a1dc6cf7ec8a1de108cac0de221b148c87f6574931c3af021')
 def test_no_provider_call_or_secrets_in_adapter(self):
  s=(ROOT/'tool/essay_lab/scaffolding_adapter.py').read_text()
  for pattern in ['import requests','import openai','SERVICE_ROLE_KEY','urlopen','psycopg.connect']:self.assertNotIn(pattern,s)
if __name__=='__main__':unittest.main()
