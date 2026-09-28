"""Disposable PG17 regression + ADMIN-only semantics. Never connects to Production.
Uses the existing numeric-loopback/empty-db/explicit-consent guard in run.py.
"""
import contextlib, io, json, os, sys
from pathlib import Path
import psycopg
from psycopg import sql
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / 'supabase/review/essay_lab_product/runtime'))
import run_server

class SQLText:
    def __init__(self, text): self.text = text
    def read_text(self): return self.text

def main():
    original = run_server.baseline.main
    migrations = ROOT / 'supabase/migrations'
    correction = migrations / '20260928000400_essay_helper_execute_boundary.sql'
    def corrected(**kwargs):
        # Reproduce the observed service_role default ACL before helper creation.
        first = SQLText('alter default privileges in schema public grant execute on functions to service_role;\n' + (migrations / '20260928000100_student_essay_product.sql').read_text())
        last = SQLText((migrations / '20260928000300_essay_server_operations.sql').read_text() + '\n' + correction.read_text())
        return original(schema_paths=[first, migrations / '20260928000200_essay_entitlements.sql'], additional_draft=last)
    run_server.baseline.main = corrected
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        result = run_server.main()
    if result: raise SystemExit(result)
    regression = json.loads(buf.getvalue())
    c = psycopg.connect(os.environ['ESSAY_REVIEW_TEST_DSN'], autocommit=True)
    # Connection is already constrained and bootstrapped by the existing guard above.
    checks = []
    def check(value, name):
        assert value, name
        checks.append(name)
    helpers = ['essay_product_reject_update','essay_product_terminal_guard','essay_product_child_guard','essay_question_identity_guard','essay_product_progress_guard','essay_product_processing_guard','essay_product_draft_guard','essay_credit_account_guard','essay_billing_history_guard']
    for name in helpers:
        check(not c.execute("select has_function_privilege('service_role',%s,'execute')", ('public.'+name+'()',)).fetchone()[0], 'B1_revoke_'+name)
    c.execute('create role security_migrator login createrole nosuperuser')
    c.execute('create schema security_probe; create table security_probe.secret(value integer); insert into security_probe.secret values(1)')
    # Genuine non-superuser session: SET ROLE from a superuser session is insufficient evidence.
    options = c.info.get_parameters(); options['user'] = 'security_migrator'
    m = psycopg.connect(**options, autocommit=True)
    m.execute('create role security_created nologin')
    row = c.execute("select a.admin_option,a.inherit_option,a.set_option,pg_get_userbyid(a.grantor) from pg_auth_members a where a.roleid='security_created'::regrole and a.member='security_migrator'::regrole").fetchone()
    check(row[:3] == (True, False, False) and row[3] == c.info.user, 'B2_auto_admin_bootstrap_grant')
    c.execute('grant usage on schema security_probe to security_created; grant select on security_probe.secret to security_created')
    def denied(stmt, label):
        try: m.execute(stmt)
        except psycopg.errors.InsufficientPrivilege: checks.append(label)
        else: raise AssertionError(label)
    denied('select * from security_probe.secret', 'B2_no_inherited_table_privilege')
    denied('set role security_created', 'B2_set_role_denied')
    m.execute('alter role security_created connection limit 2')
    check(c.execute("select rolconnlimit from pg_roles where rolname='security_created'").fetchone()[0] == 2, 'B2_admin_allows_management')
    # Ordinary self-revoke cannot remove bootstrap-superuser-granted ADMIN membership.
    m.execute('revoke security_created from security_migrator')
    check(c.execute("select count(*) from pg_auth_members where roleid='security_created'::regrole and member='security_migrator'::regrole").fetchone()[0] == 1, 'B2_self_revoke_does_not_remove_bootstrap_grant')
    # Explicitly prove ADMIN is powerful, not an anti-escalation sandbox.
    m.execute('grant security_created to security_migrator with inherit true, set true')
    check(m.execute('select value from security_probe.secret').fetchone()[0] == 1, 'B2_admin_can_explicitly_self_grant_runtime_access')
    m.execute('set role security_created'); m.execute('reset role')
    m.execute('revoke security_created from security_migrator')
    denied('set role security_created', 'B2_temporary_runtime_grant_revoked')
    c.execute('revoke security_created from security_migrator')
    denied('alter role security_created connection limit 3', 'B2_superuser_revoke_removes_management_authority')
    m.close(); c.close()
    print(json.dumps({'runtime': 'PASS', 'regression': regression, 'security_checks': checks, 'security_check_count': len(checks), 'b2_decision': 'CONTRACT_REVISION', 'admin_is_trusted_management_not_security_sandbox': True}, indent=2))

if __name__ == '__main__': main()
