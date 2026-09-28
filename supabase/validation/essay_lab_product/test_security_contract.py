import copy, unittest
from security_contract import memberships_valid
class MembershipTests(unittest.TestCase):
    def setUp(self):
        self.rows=[dict(granted_role=r,member_role='postgres',grantor_role='supabase_admin',admin_option=True,inherit_option=False,set_option=False,effective_inherit=False,effective_set=False) for r in ['essay_executor','essay_worker','essay_finance']]
    def test_exact_managed_allowance(self): self.assertTrue(memberships_valid(self.rows))
    def test_runtime_access_denied(self):
        for key in ['inherit_option','set_option','effective_inherit','effective_set']:
            rows=copy.deepcopy(self.rows); rows[0][key]=True; self.assertFalse(memberships_valid(rows))
    def test_wrong_identity_or_extra_membership(self):
        for key in ['member_role','grantor_role','granted_role']:
            rows=copy.deepcopy(self.rows);rows[0][key]='authenticated';self.assertFalse(memberships_valid(rows))
        self.assertFalse(memberships_valid(self.rows+self.rows[:1]))
    def test_missing_membership_not_silently_accepted(self): self.assertFalse(memberships_valid(self.rows[:2]))
    def test_disposable_superuser_scope(self):
        self.assertTrue(memberships_valid([],managed=False)); self.assertFalse(memberships_valid([],managed=True))
class CorrectionTests(unittest.TestCase):
    def test_exact_nine_revokes_only(self):
        from pathlib import Path
        from pglast import parse_sql
        from pglast.stream import RawStream
        from security_contract import HELPERS
        path=Path(__file__).resolve().parents[2]/'migrations/20260928000400_essay_helper_execute_boundary.sql'
        actual=parse_sql(path.read_text())
        self.assertEqual(len(actual),11)
        self.assertEqual({RawStream()(x.stmt) for x in actual[1:-1]},
            {RawStream()(parse_sql('revoke execute on function public.'+n+'() from service_role;')[0].stmt) for n in HELPERS})
        self.assertEqual(type(actual[0].stmt).__name__,'TransactionStmt')
        self.assertEqual(type(actual[-1].stmt).__name__,'TransactionStmt')
if __name__=='__main__':unittest.main()
