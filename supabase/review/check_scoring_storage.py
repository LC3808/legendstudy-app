#!/usr/bin/env python3
"""Offline SQL grammar/scope gate; never accepts a database URL or credentials."""
from pathlib import Path
import hashlib
import re
from pglast import ast, enums, parse_sql

ROOT=Path(__file__).resolve().parents[2]
MIGRATION=ROOT/'supabase/migrations/20260914000200_mock_exam_scoring.sql'
TABLES={'answer_key_versions','exam_questions','grade_cutoff_versions','mock_exam_attempts','mock_exam_answers'}
# Filled from the pre-task committed baseline; protects all already-applied migrations.
BASELINE={'20260912000100_initial_content_schema.sql': '2a2c55cfc542e961fe2356e211141b3a3df0d0c47044efac3f8360dd1f360a2b', '20260913000100_profile_school_selection.sql': '7d151a18ff2aab721eb40c9e1ccef54b1c8e186d0e50619aa9ed05e45970e7cb', '20260913000200_profile_day_target.sql': 'c060ced1166740c272f34320953b74f46d629ef51034616fe3f1a64a4c977b53', '20260914000100_study_sessions.sql': 'a832d5e4704d868461d1dd24e0253c1b06e5feb0fa2546b0ebceb115d4d6eb51'}

def check(sql):
    nodes=[n.stmt for n in parse_sql(sql)]
    assert isinstance(nodes[0],ast.TransactionStmt) and nodes[0].kind==enums.TransactionStmtKind.TRANS_STMT_BEGIN
    assert isinstance(nodes[-1],ast.TransactionStmt) and nodes[-1].kind==enums.TransactionStmtKind.TRANS_STMT_COMMIT
    tables=[n for n in nodes if isinstance(n,ast.CreateStmt)]
    assert {n.relation.relname for n in tables}==TABLES and len(tables)==5
    assert all(n.relation.schemaname=='public' for n in tables)
    assert not any(isinstance(n,(ast.InsertStmt,ast.UpdateStmt,ast.DeleteStmt,ast.DropStmt)) for n in nodes)
    funcs=[n for n in nodes if isinstance(n,ast.CreateFunctionStmt)]
    assert len(funcs)==12 and all(not n.replace for n in funcs)
    assert len([n for n in nodes if isinstance(n,ast.CreatePolicyStmt)])==6
    assert len([n for n in nodes if isinstance(n,ast.CreateTrigStmt)])==7
    for n in nodes:
        if isinstance(n,ast.AlterTableStmt):
            assert n.relation.schemaname=='public' and n.relation.relname in TABLES|{'study_sessions'}
    for body in re.findall(r'create function .*?\$\$;',sql,re.S):
        assert "set search_path = ''" in body
        assert re.search(r'language (?:sql|plpgsql) (?:immutable|stable|volatile) security (?:invoker|definer)',body)
        assert not re.search(r'\bexecute\s+(?:format|\w+\s*;)',body,re.I), 'dynamic SQL forbidden'
    assert 'on delete set null (study_session_id)' in sql
    assert 'security_invoker=true' in sql
    assert "'unavailable','estimated','confirmed'" in sql
    assert 'auth.uid()' in sql and 'pg_advisory_xact_lock' in sql
    assert 'for share' in sql and 'draft_revision=draft_revision+1' in sql
    assert 'grant execute on function public.submit_mock_attempt(uuid,uuid,uuid,uuid,text,jsonb) to authenticated;' in sql
    for name in ['scoring_question_guard','scoring_publication_guard','scoring_attempt_guard','scoring_answer_guard','scoring_attempt_consistency']:
        assert f'revoke all on function public.{name}() from public,anon,authenticated,service_role;' in sql
    return len(nodes)

def main():
    sql=MIGRATION.read_text()
    count=check(sql)
    for filename,digest in BASELINE.items():
        assert hashlib.sha256((ROOT/'supabase/migrations'/filename).read_bytes()).hexdigest()==digest,filename
    for name in ['preflight','postflight','rollback']:
        text=(ROOT/f'supabase/verification/mock_exam_scoring_{name}.sql').read_text()
        nodes=parse_sql(text)
        if name != 'rollback':
            assert all(isinstance(n.stmt,(ast.SelectStmt,ast.TransactionStmt,ast.VariableSetStmt)) for n in nodes)
            assert 'begin transaction read only;' in text
    package=(ROOT/'wiki/day-8-scoring-migration-package.md').read_text()
    assert '\n```sql\n'+sql+'```' in package,'migration copy differs'
    for name in ['preflight','postflight','rollback']:
        text=(ROOT/f'supabase/verification/mock_exam_scoring_{name}.sql').read_text()
        assert '\n```sql\n'+text+'```' in package,f'{name} copy differs'
    # Value signatures only; documentation words/role identifiers are not credentials.
    files=[MIGRATION,*[ROOT/f'supabase/verification/mock_exam_scoring_{n}.sql' for n in ['preflight','postflight','rollback']],
        ROOT/'wiki/day-8-scoring-migration-package.md',ROOT/'wiki/day-8-scoring-storage-proposal.md',
        ROOT/'tool/test_scoring_storage.mjs',ROOT/'supabase/review/mock_scoring_vectors.json']
    patterns=[r'sb_(?:secret|publishable)_[A-Za-z0-9_-]{16,}',r'eyJ[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',r'-----BEGIN (?:RSA |EC )?PRIVATE KEY-----']
    for f in files:
        assert not any(re.search(p,f.read_text()) for p in patterns),f'credential signature: {f.name}'
    print(f'SCORING_STATIC PASS grammar ({count} statements), scope, baseline hashes, read-only checks, package parity, credential signatures')
if __name__=='__main__': main()
