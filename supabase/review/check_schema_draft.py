#!/usr/bin/env python3
"""Offline PostgreSQL syntax/structure checks. Never connects to or runs a DB.

Install the pinned parser in an isolated venv, then run this file without -O.
This is a review aid, not a substitute for later authorized database/RLS tests.
"""
from pathlib import Path

import pglast
from pglast import ast, enums
from pglast.parser import parse_plpgsql_json
from pglast.stream import RawStream

ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / 'supabase/migrations/20260912000100_initial_content_schema.sql'
CONTENT = {'exams', 'subjects', 'exam_subjects', 'resources'}
PRIVATE = {'profiles', 'bookmarks', 'recent_views'}
TABLES = CONTENT | PRIVATE | {'source_posts'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def text(node):
    return RawStream()(node) if node else ''


def constraints(table):
    for element in table.tableElts:
        if isinstance(element, ast.Constraint):
            yield element
        elif isinstance(element, ast.ColumnDef):
            yield from element.constraints or ()


def check(sql):
    require(sql.startswith('-- DRAFT ONLY:'), 'Missing draft warning')
    nodes = [raw.stmt for raw in pglast.parse_sql(sql)]
    tables = {n.relation.relname: n for n in nodes if isinstance(n, ast.CreateStmt)}
    require(set(tables) == TABLES, 'Unexpected table inventory')
    require(all(n.relation.schemaname == 'public' for n in tables.values()), 'Unexpected schema')
    require(not any(isinstance(n, (ast.InsertStmt, ast.UpdateStmt, ast.DeleteStmt)) for n in nodes),
            'Migration must not contain seed/DML statements')
    enabled = {n.relation.relname for n in nodes if isinstance(n, ast.AlterTableStmt)
               for cmd in n.cmds if cmd.subtype == enums.AlterTableType.AT_EnableRowSecurity}
    require(enabled == TABLES, 'Every table must enable RLS')
    policies = [n for n in nodes if isinstance(n, ast.CreatePolicyStmt)]
    expected = {'exams': {'select'}, 'subjects': {'select'}, 'exam_subjects': {'select'},
                'resources': {'select'}, 'profiles': {'select', 'insert', 'update', 'delete'},
                'bookmarks': {'select', 'insert', 'delete'},
                'recent_views': {'select', 'insert', 'update', 'delete'}}
    require(len(policies) == 15, 'Unexpected policy count')
    for table, commands in expected.items():
        require({p.cmd_name for p in policies if p.table.relname == table} == commands,
                f'Wrong policy commands for {table}')
    for policy in policies:
        table = policy.table.relname
        roles = {role.rolename for role in policy.roles}
        require(table != 'source_posts', 'Raw source metadata cannot have a client policy')
        require(roles == ({'anon', 'authenticated'} if table in CONTENT else {'authenticated'}),
                f'Unexpected policy roles for {table}')
        if table in CONTENT:
            require('is_active' in text(policy.qual), f'Active filter missing: {table}')
        else:
            for expr in ([policy.qual] if policy.cmd_name in {'select', 'delete'} else
                         [policy.with_check] if policy.cmd_name == 'insert' else
                         [policy.qual, policy.with_check]):
                require('auth.uid()' in text(expr), f'Owner check missing: {policy.policy_name}')
    # Verify grant surface, including column grants needed by upserts.
    revoked = set()
    for grant in (n for n in nodes if isinstance(n, ast.GrantStmt)
                  and n.objtype == enums.ObjectType.OBJECT_TABLE):
        names = {obj.relname for obj in grant.objects}
        roles = {role.rolename or 'PUBLIC' for role in grant.grantees}
        if not grant.is_grant:
            if roles >= {'PUBLIC', 'anon', 'authenticated'} and grant.privileges is None:
                revoked |= names
            continue
        privileges = {p.priv_name.lower() for p in grant.privileges or ()}
        if roles & {'PUBLIC', 'anon', 'authenticated'}:
            require('PUBLIC' not in roles, 'No grants to PUBLIC')
            require('source_posts' not in names, 'Raw source grant exposed')
            if names & CONTENT:
                require(privileges == {'select'}, 'Client content write grant')
            if names & PRIVATE:
                require(roles == {'authenticated'}, 'Private grant to non-authenticated role')
            if names == {'profiles'} and 'update' in privileges:
                columns = {c.sval for p in grant.privileges for c in p.cols or ()}
                require(columns == {'display_name', 'grade_level'}, 'Profile update too broad')
    require(revoked == TABLES, 'Default grants not fully revoked')
    fks = [c for table in tables.values() for c in constraints(table)
           if c.contype == enums.ConstrType.CONSTR_FOREIGN]
    for fk in fks:
        require(fk.fk_del_action == ('c' if fk.pktable.schemaname == 'auth' else 'r'),
                'Only auth user references may cascade')
    named = {c.conname: c for table in tables.values() for c in constraints(table) if c.conname}
    resource_fk = named['resources_subject_same_exam']
    require([k.sval for k in resource_fk.fk_attrs] == ['exam_subject_id', 'exam_id'],
            'Missing resource/exam composite FK')
    require(named['exam_subjects_versioned_mapping'].fk_matchtype == 'f', 'Mapping FK needs MATCH FULL')
    for name, keys in {
        'exams_source_identity': ['source_post_id', 'source_exam_key'],
        'exam_subjects_source_identity': ['exam_id', 'source_subject_key'],
        'resources_source_identity': ['exam_id', 'source_post_id', 'source_resource_key'],
        'bookmarks_user_exam': ['user_id', 'exam_id'],
        'recent_views_user_exam': ['user_id', 'exam_id'],
    }.items():
        require([k.sval for k in named[name].keys] == keys, f'Wrong idempotency key: {name}')
    functions = [n for n in nodes if isinstance(n, ast.CreateFunctionStmt)]
    require(len(functions) == 2, 'Unexpected function inventory')
    for function in functions:
        options = {o.defname: o.arg for o in function.options}
        require(not options['security'].boolval, 'Unexpected SECURITY DEFINER')
        require(options['set'].name == 'search_path', 'Function search_path missing')
        # Use native parser output without decoding its trigger-record JSON:
        # pglast 8.4's high-level JSON decoder fails on some NEW/OLD serialization.
        # This call validates grammar only; it does not execute PL/pgSQL.
        require(bool(parse_plpgsql_json(text(function))), 'PL/pgSQL parse failed')
    indexes = sum(isinstance(n, ast.IndexStmt) for n in nodes)
    require(indexes == 11, 'Review index inventory after edits')
    return {'statements': len(nodes), 'tables': len(tables), 'rls_tables': len(enabled),
            'policies': len(policies), 'functions': len(functions), 'indexes': indexes}


if __name__ == '__main__':
    print(f'pglast {pglast.__version__}; PostgreSQL parser {pglast.get_postgresql_version()}')
    print('Migration checks:', check(MIGRATION.read_text()))
    validation = ROOT / 'supabase/review/initial_content_schema_checks.sql'
    queries = [raw.stmt for raw in pglast.parse_sql(validation.read_text())]
    require(all(isinstance(q, ast.SelectStmt) for q in queries), 'Inspection file must be SELECT-only')
    print(f'Future inspection SQL: {len(queries)} SELECT statements parsed, NOT executed')
    print('PASS: offline syntax/structure only. No SQL executed or DB contacted.')
