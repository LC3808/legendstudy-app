"""Forward migration static security floor; actual behavior tested in provider_runtime."""
import re,unittest
from pathlib import Path
from pglast import parse_sql
ROOT=Path(__file__).resolve().parents[3]
SQL=(ROOT/'supabase/migrations/20260929000500_essay_provider_provenance_telemetry.sql').read_text()
class ProviderBoundary(unittest.TestCase):
 def test_parse_and_no_new_master_or_history_rewrite(self):
  self.assertGreater(len(parse_sql(SQL)),10)
  self.assertNotRegex(SQL.lower(),r'create\s+table|drop\s+|truncate\s+|delete\s+from')
  self.assertEqual(len(re.findall(r'add column',SQL)),1)
  self.assertIn('total_tokens bigint check(total_tokens>=0)',SQL)
 def test_empty_policy_and_no_selected_provider(self):
  registry=SQL.split('create function essay_private.provider_policy',1)[1].split('$$;',1)[0]
  self.assertIn('select null::jsonb',registry)
  self.assertNotIn('values',registry)
 def test_narrow_exposure_and_fixed_path(self):
  self.assertNotRegex(SQL,r'(?i)grant execute.*to (authenticated|anon|service_role)')
  self.assertIn('to essay_worker;',SQL)
  self.assertEqual(SQL.count('security definer'),5)
  self.assertEqual(SQL.count("security definer set search_path=''"),5)
  self.assertIn('from public,anon,authenticated,service_role,essay_worker,essay_finance',SQL)
 def test_fence_precedes_idempotency(self):
  operation=SQL.split('create function public.essay_record_provider_telemetry',1)[1]
  self.assertLess(operation.index('essay_private.fence'),operation.index('if r.latency_ms is not null'))
  params=operation.split(') returns uuid',1)[0]
  self.assertNotIn('json',params);self.assertNotIn('p_model',params);self.assertNotIn('p_provider',params)
if __name__=='__main__':unittest.main()
