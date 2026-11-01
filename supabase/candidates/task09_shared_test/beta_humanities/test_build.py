"""Offline candidate checks. Does not connect to any database."""
import hashlib
import json
from pathlib import Path
import subprocess
import unittest

P = Path(__file__).parent

class HumanitiesBootstrapTests(unittest.TestCase):
    def test_reproducible(self):
        before = (P / 'install.sql').read_bytes()
        subprocess.run(['python3', str(P / 'build.py')], check=True, capture_output=True)
        self.assertEqual(before, (P / 'install.sql').read_bytes())

    def test_absent_math_session_not_installed(self):
        sql = (P / 'install.sql').read_text()
        self.assertNotIn('CREATE OR REPLACE FUNCTION public.math_session_submit(', sql)
        self.assertIn('UNEXPECTED_MATH_SESSION_REVIEW_REQUIRED', sql)
        self.assertIn('BASELINE', sql)

    def test_existing_math_allocator_only_adds_beta_fence(self):
        sql = (P / 'install.sql').read_text()
        before = (P / 'math-before.sql').read_text()
        anchor = 'from public.credit_grants g where g.account_id=account'
        after = before.replace(anchor, anchor + ' and not essay_beta_private.is_beta(g.id)')
        self.assertIn(after, sql)
        m = json.loads((P / 'manifest.json').read_text())
        self.assertEqual(hashlib.md5(before.encode()).hexdigest(), m['math_allocator_before_md5'])
        self.assertEqual(hashlib.md5(after.encode()).hexdigest(), m['math_allocator_after_md5'])

    def test_no_activation_or_finish_replacement(self):
        sql = (P / 'install.sql').read_text().lower()
        self.assertNotIn('create or replace function essay_exam_private.finish(', sql)
        self.assertNotIn('insert into essay_beta_private.campaigns', sql)
        self.assertIn('revoke essay_executor from postgres', sql)

if __name__ == '__main__':
    unittest.main()
