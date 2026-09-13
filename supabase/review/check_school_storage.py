#!/usr/bin/env python3
"""Offline grammar/scope gate only. Never connects to or executes against a DB."""
import hashlib
import re
from pathlib import Path
from pglast import parse_sql, ast, enums
from pglast.stream import RawStream

ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / 'supabase/migrations/20260913000100_profile_school_selection.sql'
COLUMNS = {'neis_office_code', 'neis_school_code'}
EXPECTED_CHECK = r"""
(neis_office_code is null) = (neis_school_code is null)
and (neis_office_code is null or (
  neis_office_code = btrim(neis_office_code, E' \t\n\r\f\013')
  and char_length(neis_office_code) between 1 and 32))
and (neis_school_code is null or (
  neis_school_code = btrim(neis_school_code, E' \t\n\r\f\013')
  and char_length(neis_school_code) between 1 and 32))
"""

def check(sql):
    nodes = [raw.stmt for raw in parse_sql(sql)]
    assert [type(n) for n in nodes] == [ast.TransactionStmt, ast.AlterTableStmt,
        ast.GrantStmt, ast.NotifyStmt, ast.TransactionStmt]
    assert nodes[0].kind == enums.TransactionStmtKind.TRANS_STMT_BEGIN
    assert nodes[-1].kind == enums.TransactionStmtKind.TRANS_STMT_COMMIT
    alter, grant, notify = nodes[1:4]
    assert (alter.relation.schemaname, alter.relation.relname) == ('public', 'profiles')
    assert len(alter.cmds) == 3 and not alter.missing_ok
    added = []
    for cmd in alter.cmds[:2]:
        assert cmd.subtype == enums.AlterTableType.AT_AddColumn and not cmd.missing_ok
        col = cmd.def_
        assert [x.sval for x in col.typeName.names] == ['text']
        assert not col.is_not_null and not col.constraints and col.raw_default is None
        added.append(col.colname)
    assert set(added) == COLUMNS
    cmd = alter.cmds[2]
    assert cmd.subtype == enums.AlterTableType.AT_AddConstraint
    con = cmd.def_
    assert con.contype == enums.ConstrType.CONSTR_CHECK
    assert con.conname == 'profiles_neis_school_pair'
    assert con.initially_valid and not con.skip_validation
    expected = parse_sql('select ' + EXPECTED_CHECK)[0].stmt.targetList[0].val
    assert RawStream()(con.raw_expr) == RawStream()(expected)
    assert grant.is_grant and not grant.grant_option
    assert [(x.schemaname, x.relname) for x in grant.objects] == [('public', 'profiles')]
    assert [r.rolename for r in grant.grantees] == ['authenticated']
    assert {p.priv_name: {c.sval for c in p.cols} for p in grant.privileges} == {
        'insert': COLUMNS, 'update': COLUMNS}
    assert (notify.conditionname, notify.payload) == ('pgrst', 'reload schema')

if __name__ == '__main__':
    sql = MIGRATION.read_text()
    check(sql)
    initial = ROOT / 'supabase/migrations/20260912000100_initial_content_schema.sql'
    assert hashlib.sha256(initial.read_bytes()).hexdigest() == '2a2c55cfc542e961fe2356e211141b3a3df0d0c47044efac3f8360dd1f360a2b'
    doc = (ROOT / 'wiki/day-7-school-storage-proposal.md').read_text()
    assert sql in re.findall(r'```sql\n(.*?)```', doc, re.S)
    for name in ['profile_school_before.sql', 'profile_school_after.sql']:
        nodes = parse_sql((ROOT / 'supabase/review' / name).read_text())
        assert nodes and all(isinstance(n.stmt, ast.SelectStmt) for n in nodes)
    mutations = [
        sql.replace('to authenticated', 'to anon'),
        sql.replace('between 1 and 32', 'between 0 and 32'),
        sql.replace('(neis_office_code is null) = (neis_school_code is null)', 'true'),
        sql.replace('add column neis_school_code text', 'add column neis_school_code text not null'),
        sql.replace('commit;', 'update public.profiles set grade_level = null;\ncommit;'),
    ]
    for changed in mutations:
        try:
            check(changed)
        except AssertionError:
            pass
        else:
            raise AssertionError('Unsafe mutation accepted')
    print('PASS: SQL grammar/scope, nullable pair/value CHECK, column grants, read-only validation,')
    print('immutable initial migration, identical owner SQL; 5 unsafe mutations rejected.')
    print('Static only: no PostgreSQL execution, deployment, JWT/RLS or client runtime claim.')
