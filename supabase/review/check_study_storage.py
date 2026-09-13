#!/usr/bin/env python3
"""Offline migration grammar/scope gate; never connects to any database."""
from pathlib import Path
import hashlib
import re
from pglast import ast, enums, parse_sql, parse_plpgsql
from pglast.stream import RawStream

ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / 'supabase/migrations/20260914000100_study_sessions.sql'
COLUMNS = {'id','user_id','mode','title','subject','planned_duration_seconds',
           'started_at','ended_at','active_segments','duration_seconds','created_at'}

def check(sql):
    nodes = [n.stmt for n in parse_sql(sql)]
    expected = [ast.TransactionStmt, ast.CreateFunctionStmt, ast.CreateStmt,
                ast.IndexStmt, ast.AlterTableStmt] + [ast.GrantStmt]*6 + [ast.CreatePolicyStmt]*3 + [ast.NotifyStmt, ast.TransactionStmt]
    assert [type(n) for n in nodes] == expected, 'unexpected statement scope'
    assert nodes[0].kind == enums.TransactionStmtKind.TRANS_STMT_BEGIN
    assert nodes[-1].kind == enums.TransactionStmtKind.TRANS_STMT_COMMIT
    function, table = nodes[1:3]
    parse_plpgsql(RawStream()(function))
    assert [s.sval for s in function.funcname] == ['public','study_active_milliseconds']
    assert not function.replace
    assert (table.relation.schemaname, table.relation.relname) == ('public','study_sessions')
    cols = [c for c in table.tableElts if isinstance(c,ast.ColumnDef)]
    assert {c.colname for c in cols} == COLUMNS and len(cols) == 11
    checks = [c for c in table.tableElts if isinstance(c,ast.Constraint)]
    assert len(checks) == 6 and all(c.contype == enums.ConstrType.CONSTR_CHECK for c in checks)
    assert nodes[3].relation.relname == nodes[4].relation.relname == 'study_sessions'
    assert nodes[4].cmds[0].subtype == enums.AlterTableType.AT_EnableRowSecurity
    policies = nodes[11:14]
    assert {p.cmd_name for p in policies} == {'select','insert','delete'}
    for p in policies:
        assert p.table.relname == 'study_sessions'
        assert [r.rolename for r in p.roles] == ['authenticated']
        expr = p.with_check if p.cmd_name == 'insert' else p.qual
        assert RawStream()(expr) == '(SELECT auth.uid()) = user_id'
    normalized = [RawStream()(n).lower().replace(' (', '(') for n in nodes[5:11]]
    assert normalized == [
      'revoke all privileges on table public.study_sessions from public, anon, authenticated',
      'revoke all privileges on function public.study_active_milliseconds(jsonb, numeric) from public, anon, authenticated',
      'grant execute on function public.study_active_milliseconds(jsonb, numeric) to authenticated, service_role',
      'grant select, delete on table public.study_sessions to authenticated',
      'grant insert(id, mode, title, subject, planned_duration_seconds, started_at, ended_at, active_segments) on table public.study_sessions to authenticated',
      'grant select, insert, update, delete on table public.study_sessions to service_role',
    ], normalized

    required = [
      'language plpgsql immutable security invoker', "set search_path = ''",
      'p_span_ms between 0 and 86400000', 'jsonb_array_length(p_segments) > 256',
      'jsonb_array_length(segment) <> 2', "jsonb_typeof(segment -> 0) <> 'number'",
      "jsonb_typeof(segment -> 1) <> 'number'", 'start_ms <> trunc(start_ms)',
      'end_ms <> trunc(end_ms)', 'start_ms < previous_end', 'end_ms <= start_ms',
      'end_ms > p_span_ms', 'previous_end := end_ms',
      'total_ms := total_ms + (end_ms - start_ms)::bigint',
      'default auth.uid() references auth.users(id) on delete cascade',
      'duration_seconds integer generated always as (',
      'active_segments, extract(epoch from (ended_at - started_at)) * 1000',
      ') / 1000)::integer', ') stored not null', 'duration_seconds >= 1',
      'isfinite(started_at) and isfinite(ended_at)', 'ended_at >= started_at',
      "ended_at - started_at <= interval '24 hours'",
      "mode in ('study', 'mock_exam')", 'planned_duration_seconds between 60 and 43200',
      ') <= planned_duration_seconds::bigint * 1000',
    ]
    compact = re.sub(r'\s+', ' ', sql.lower())
    assert all(t in compact for t in required), 'duration/validation contract drift'
    assert 'security definer' not in compact

if __name__ == '__main__':
    check(MIGRATION.read_text())
    assert MIGRATION.read_bytes() == (ROOT/'supabase/proposals/study_sessions.sql').read_bytes()
    for p in sorted((ROOT/'supabase/verification').glob('study_sessions_*.sql')):
        parsed = parse_sql(p.read_text())
        if p.stem.endswith(('preflight', 'catalog')):
            assert all(isinstance(n.stmt, (ast.SelectStmt, ast.TransactionStmt, ast.VariableSetStmt)) for n in parsed)
    historical_hashes = {'20260912000100_initial_content_schema.sql': '2a2c55cfc542e961fe2356e211141b3a3df0d0c47044efac3f8360dd1f360a2b', '20260913000100_profile_school_selection.sql': '7d151a18ff2aab721eb40c9e1ccef54b1c8e186d0e50619aa9ed05e45970e7cb', '20260913000200_profile_day_target.sql': 'c060ced1166740c272f34320953b74f46d629ef51034616fe3f1a64a4c977b53'}
    for name, expected in historical_hashes.items():
        assert hashlib.sha256((ROOT/'supabase/migrations'/name).read_bytes()).hexdigest() == expected
    print('Study migration grammar/scope, read-only catalog SQL and applied migration hashes PASS (offline only)')
