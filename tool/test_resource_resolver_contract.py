"""Offline parser parity and quota migration permission/atomicity contract."""
import json
from pathlib import Path
import unittest
from ingestion.parser import parse_html
ROOT = Path(__file__).resolve().parents[1]
class ResolverContract(unittest.TestCase):
    def test_shared_python_deno_fixture(self):
        f = json.loads((ROOT / 'supabase/functions/resource-resolver/fixtures/kakao.json').read_text())
        for html in [f['html'], f['html'].replace('signature=xyz%3D', 'signature=rotated')]:
            attachments = parse_html('1705', html).attachments
            kakao = [a for a in attachments if a.provider == 'kakaocdn']
            self.assertEqual(len(kakao), 1)
            self.assertEqual(kakao[0].resource_key, f['expected_key'])
            self.assertEqual(kakao[0].provider, f['expected_provider'])
    def test_quota_sql_permissions_and_bounded_shared_atomic_contract(self):
        sql = (ROOT / 'supabase/migrations/20260925000100_resource_resolver_quota.sql').read_text().lower()
        for fragment in ['enable row level security', 'security definer set search_path =', 'pg_advisory_xact_lock', "'lock_timeout', '500ms'", 'limit 128', 'v_global >= v_global_limit', 'v_resource >= v_resource_limit', 'window_start <> v_window', 'to service_role', 'from public, anon, authenticated', 'constant integer := 600', 'constant integer := 12']:
            self.assertIn(fragment, sql)
        self.assertLess(sql.index('pg_advisory_xact_lock'),sql.index('select used into v_global'))
        self.assertNotIn('create policy',sql)
        for forbidden in ['alter table public.resources', 'update public.resources', 'insert into public.resources', 'cron.schedule']:
            self.assertNotIn(forbidden,sql)
        # This is static contract coverage, NOT a runtime Postgres concurrency claim.
if __name__ == '__main__': unittest.main()
