#!/usr/bin/env python3
"""Offline grammar/structure assertions only; never executes SQL or contacts a DB.

Expected contracts are independent of the migration. AST comparison ignores source
locations and AND/OR operand order, but deliberately requires reviewed identifiers.
It is not a general SQL equivalence prover or a catalog/permissions test.
"""
import json
from pathlib import Path
import pglast
from pglast import ast, enums
from pglast.parser import parse_plpgsql_json
from pglast.stream import RawStream

ROOT = Path(__file__).resolve().parents[2]
MIGRATION = ROOT / 'supabase/migrations/20260912000100_initial_content_schema.sql'
CONTENT = {'exams', 'subjects', 'exam_subjects', 'resources'}
PRIVATE = {'profiles', 'bookmarks', 'recent_views'}
TABLES = CONTENT | PRIVATE | {'source_posts', 'ingestion_quarantine'}
PUBLIC_COLUMNS = {
    'exams': 'id slug title year academic_year exam_month exam_date sort_date grade_level exam_type exam_round curriculum_version published_at is_active',
    'subjects': 'id code name category taxonomy_version curriculum_version parent_id sort_order is_active',
    'exam_subjects': 'id exam_id subject_id raw_subject_label taxonomy_version mapping_status display_order is_active',
    'resources': 'id exam_id exam_subject_id resource_type title source_label source_url link_kind file_url mime_type file_extension file_size display_order is_active',
}
INDEXES = {
    'exams_active_feed': 'exams (sort_date desc nulls last, id desc) where is_active',
    'subjects_parent': 'subjects (parent_id, taxonomy_version)',
    'exam_subjects_mapping': 'exam_subjects (subject_id, taxonomy_version)',
    'resources_subject_exam': 'resources (exam_subject_id, exam_id)',
    'resources_source_post': 'resources (source_post_id)',
    'bookmarks_owner_recency': 'bookmarks (user_id, created_at desc, id desc)',
    'bookmarks_exam': 'bookmarks (exam_id)',
    'recent_views_owner_recency': 'recent_views (user_id, viewed_at desc, id desc)',
    'recent_views_exam': 'recent_views (exam_id)',
}
CONTRACT = {
    'source_conflict_target': ['source', 'external_post_id'],
    'slug_template': 'legendstudy-{external_post_id}-{source_exam_key}',
    'slug_mutable_after_assignment': False,
    'automated_update_excluded_mapping_statuses': ['verified'],
    'duplicate_exam_normalized_url_action': 'ingestion_quarantine',
    'verified_update_workflow_required_before_ingestion': True,
}
VERIFIED_RULE = 'Automated ingestion MUST NOT update any existing exam_subjects row whose mapping_status is verified.'


def require(ok, message):
    if not ok:
        raise ValueError(message)


def norm(value):
    if isinstance(value, ast.Node):
        value = value()
    if isinstance(value, dict):
        result = {k: norm(v) for k, v in value.items()
                  if k not in {'location', 'stmt_location', 'stmt_len', 'rexpr_list_start', 'rexpr_list_end'}}
        if result.get('@') == 'BoolExpr' and result['boolop']['name'] in {'AND_EXPR', 'OR_EXPR'}:
            result['args'] = sorted(result['args'], key=lambda x: json.dumps(x, sort_keys=True))
        return result
    if isinstance(value, (tuple, list)):
        return [norm(v) for v in value]
    return value


def statement(sql):
    return pglast.parse_sql(sql)[0].stmt


def expression(sql):
    return statement('select 1 where ' + sql).whereClause if sql else None


def constraints(table):
    for element in table.tableElts:
        if isinstance(element, ast.Constraint):
            yield element
        elif isinstance(element, ast.ColumnDef):
            yield from element.constraints or ()


def check_contract(root=ROOT):
    data = json.loads((root / 'supabase/review/ingestion_contract.json').read_text())
    require(data == CONTRACT, 'Ingestion contract drift')
    require(VERIFIED_RULE in (root / 'wiki/ingestion.md').read_text(), 'Verified mapping rule missing')


def check(sql):
    require(sql.startswith('-- DRAFT ONLY:'), 'Missing draft warning')
    nodes = [r.stmt for r in pglast.parse_sql(sql)]
    allowed = (ast.TransactionStmt, ast.CreateStmt, ast.CreateFunctionStmt,
               ast.CreateTrigStmt, ast.IndexStmt, ast.AlterTableStmt, ast.GrantStmt, ast.CreatePolicyStmt)
    require(all(isinstance(n, allowed) for n in nodes), 'Unexpected SQL statement (no DML/extensions/DO)')
    require(norm(nodes[0]) == norm(statement('begin')) and
            norm(nodes[-1]) == norm(statement('commit')), 'Transaction boundary changed')
    require(sum(isinstance(n, ast.TransactionStmt) for n in nodes) == 2, 'Extra transaction boundary')
    tables_list = [n for n in nodes if isinstance(n, ast.CreateStmt)]
    tables = {n.relation.relname: n for n in tables_list}
    require(set(tables) == TABLES and len(tables_list) == len(TABLES), 'Unexpected table inventory')
    require(all(n.relation.schemaname == 'public' for n in tables.values()), 'Unexpected schema')
    alterations = [n for n in nodes if isinstance(n, ast.AlterTableStmt)]
    require(len(alterations) == len(TABLES), 'RLS statement inventory')
    require({n.relation.relname for n in alterations} == TABLES, 'Missing RLS table')
    for n in alterations:
        require(norm(n) == norm(statement(f'alter table public.{n.relation.relname} enable row level security')),
                'Unexpected table alteration / RLS disabled')

    parent = 'exists (select 1 from public.exams e where e.id = exam_id and e.is_active)'
    public = {
        'exams': 'is_active', 'subjects': 'is_active',
        'exam_subjects': f'is_active and {parent}',
        'resources': f'''is_active and {parent} and (exam_subject_id is null or exists (
            select 1 from public.exam_subjects es where es.id = exam_subject_id
            and es.exam_id = resources.exam_id and es.is_active))''',
    }
    expected_policies = {}
    for table, expr in public.items():
        expected_policies[f'{table}_public_active_select'] = (table, 'select', expr, None)
    for table in sorted(PRIVATE):
        owner = '(select auth.uid()) = ' + ('id' if table == 'profiles' else 'user_id')
        new = owner if table == 'profiles' else f'{owner} and {parent}'
        for cmd in ('select', 'insert', 'update', 'delete'):
            if table == 'bookmarks' and cmd == 'update':
                continue
            expected_policies[f'{table}_owner_{cmd}'] = (
                table, cmd, None if cmd == 'insert' else owner,
                new if cmd in {'insert', 'update'} else None)
    policies = [n for n in nodes if isinstance(n, ast.CreatePolicyStmt)]
    require(len(policies) == len(expected_policies) and
            {p.policy_name for p in policies} == set(expected_policies), 'Policy inventory')
    for p in policies:
        table, cmd, qual, new = expected_policies[p.policy_name]
        roles = 'anon, authenticated' if table in CONTENT else 'authenticated'
        expected = f'create policy {p.policy_name} on public.{table} for {cmd} to {roles}'
        if qual:
            expected += f' using ({qual})'
        if new:
            expected += f' with check ({new})'
        require(norm(p) == norm(statement(expected)), f'Policy AST mismatch: {p.policy_name}')

    # Exact role/table/privilege/column surface, not just presence of SELECT.
    expected_grants = {}
    for table, columns in PUBLIC_COLUMNS.items():
        for role in ('anon', 'authenticated'):
            expected_grants[role, table, 'select'] = set(columns.split())
    for table in PRIVATE:
        for privilege in ('select', 'delete'):
            expected_grants['authenticated', table, privilege] = None
        columns = {'id', 'display_name', 'grade_level'} if table == 'profiles' else {'user_id', 'exam_id'}
        expected_grants['authenticated', table, 'insert'] = columns
        if table != 'bookmarks':
            expected_grants['authenticated', table, 'update'] = columns
    for table in TABLES:
        for privilege in ('select', 'insert', 'update', 'delete'):
            expected_grants['service_role', table, privilege] = None
    grants, revoked, function_revokes, schema_grants = {}, set(), set(), 0
    for g in (n for n in nodes if isinstance(n, ast.GrantStmt)):
        require(not g.grant_option and g.grantor is None, 'Delegable grant forbidden')
        roles = {r.rolename or 'PUBLIC' for r in g.grantees}
        if g.objtype == enums.ObjectType.OBJECT_FUNCTION:
            require(not g.is_grant and g.privileges is None and roles == {'PUBLIC', 'anon', 'authenticated'},
                    'Function EXECUTE must be revoked')
            for obj in g.objects:
                require(not obj.objargs and not obj.args_unspecified, 'Unexpected function overload')
                function_revokes.add(tuple(x.sval for x in obj.objname))
            continue
        if g.objtype == enums.ObjectType.OBJECT_SCHEMA:
            require(norm(g) == norm(statement('grant usage on schema public to anon, authenticated, service_role')),
                    'Unexpected schema grant')
            schema_grants += 1
            continue
        require(g.objtype == enums.ObjectType.OBJECT_TABLE, 'Unexpected privilege object')
        for obj in g.objects:
            require(obj.schemaname == 'public' and obj.relname in TABLES, 'Unknown grant relation')
            if not g.is_grant:
                require(g.privileges is None and roles == {'PUBLIC', 'anon', 'authenticated'}, 'Incomplete revoke')
                revoked.add(obj.relname)
                require(not any(k[1] == obj.relname for k in grants), 'Revoke must precede grants')
                continue
            require(obj.relname in revoked and g.privileges, 'Missing prior explicit revoke')
            for role in roles:
                for privilege in g.privileges:
                    key = (role, obj.relname, privilege.priv_name.lower())
                    require(key not in grants, 'Duplicate privilege assignment')
                    grants[key] = {c.sval for c in privilege.cols} if privilege.cols else None
    require(revoked == TABLES and grants == expected_grants and schema_grants == 1, 'Grant surface mismatch')
    require(function_revokes == {('public', 'set_updated_at'), ('public', 'set_viewed_at')},
            'Missing function EXECUTE revoke')

    named = {c.conname: c for t in tables.values() for c in constraints(t) if c.conname}
    for t in tables.values():
        for c in constraints(t):
            if c.contype == enums.ConstrType.CONSTR_FOREIGN:
                require(c.fk_del_action == ('c' if c.pktable.schemaname == 'auth' else 'r'), 'FK delete action')
                require(c.fk_upd_action in {'a', 'r'}, 'FK ON UPDATE cascade forbidden')
    for name, keys in {
        'source_posts_external_identity': 'source external_post_id',
        'exams_source_identity': 'source_post_id source_exam_key',
        'exam_subjects_source_identity': 'exam_id source_subject_key',
        'resources_source_identity': 'exam_id source_post_id source_resource_key',
        'subjects_versioned_code': 'taxonomy_version code', 'subjects_id_version': 'id taxonomy_version',
        'exam_subjects_id_exam': 'id exam_id', 'bookmarks_user_exam': 'user_id exam_id',
        'recent_views_user_exam': 'user_id exam_id',
    }.items():
        require(name in named and named[name].contype == enums.ConstrType.CONSTR_UNIQUE and
                [k.sval for k in named[name].keys] == keys.split(), f'Identity constraint: {name}')
    for name, cols, target, ref, match in (
        ('subjects_parent_same_version', 'parent_id taxonomy_version', 'subjects', 'id taxonomy_version', 's'),
        ('exam_subjects_versioned_mapping', 'subject_id taxonomy_version', 'subjects', 'id taxonomy_version', 'f'),
        ('resources_subject_same_exam', 'exam_subject_id exam_id', 'exam_subjects', 'id exam_id', 's'),
    ):
        c = named[name]
        require(c.contype == enums.ConstrType.CONSTR_FOREIGN and c.pktable.schemaname == 'public'
                and c.pktable.relname == target and [x.sval for x in c.fk_attrs] == cols.split()
                and [x.sval for x in c.pk_attrs] == ref.split() and c.fk_matchtype == match, f'Composite FK: {name}')
    columns = {t: {c.colname: c for c in n.tableElts if isinstance(c, ast.ColumnDef)} for t, n in tables.items()}
    require(any(c.contype == enums.ConstrType.CONSTR_NOTNULL for c in columns['source_posts']['external_post_id'].constraints),
            'external_post_id must be NOT NULL')
    # Exact inline FK inventory catches omitted or redirected ownership/provenance FKs.
    expected_inline = {
        ('exams', 'source_post_id'): ('public', 'source_posts'),
        ('exams', 'merged_into_exam_id'): ('public', 'exams'),
        ('exam_subjects', 'exam_id'): ('public', 'exams'),
        ('resources', 'exam_id'): ('public', 'exams'),
        ('resources', 'source_post_id'): ('public', 'source_posts'),
        ('profiles', 'id'): ('auth', 'users'),
        ('bookmarks', 'user_id'): ('auth', 'users'),
        ('bookmarks', 'exam_id'): ('public', 'exams'),
        ('recent_views', 'user_id'): ('auth', 'users'),
        ('recent_views', 'exam_id'): ('public', 'exams'),
        ('ingestion_quarantine', 'source_post_id'): ('public', 'source_posts'),
    }
    inline = {}
    for table, cols in columns.items():
        for column, definition in cols.items():
            for constraint in definition.constraints or ():
                if constraint.contype == enums.ConstrType.CONSTR_FOREIGN:
                    key = table, column
                    require(key not in inline and [x.sval for x in constraint.pk_attrs] == ['id'], 'Inline FK keys')
                    inline[key] = constraint.pktable.schemaname, constraint.pktable.relname
    require(inline == expected_inline, 'Inline FK inventory')
    require(sum(c.contype == enums.ConstrType.CONSTR_FOREIGN for t in tables.values()
                for c in constraints(t)) == len(expected_inline) + 3, 'FK inventory')
    merge = columns['exams']['merged_into_exam_id']
    require(any(c.contype == enums.ConstrType.CONSTR_FOREIGN and c.pktable.schemaname == 'public'
                and c.pktable.relname == 'exams' and [x.sval for x in c.pk_attrs] == ['id'] for c in merge.constraints), 'Merge FK')
    checks = {
        'exams_merge_state': 'merged_into_exam_id is null or (merged_into_exam_id <> id and not is_active)',
        'exam_subjects_mapping_state': '''
            (mapping_status in ('unmapped', 'unmappable') and subject_id is null and taxonomy_version is null
             and mapping_confidence is null and verified_at is null)
            or (mapping_status = 'provisional' and subject_id is not null and taxonomy_version is not null
                and mapping_confidence is not null and verified_at is null)
            or (mapping_status = 'verified' and subject_id is not null and taxonomy_version is not null and verified_at is not null)''',
        'ingestion_quarantine_resolution': "(status = 'open' and resolved_at is null) or (status in ('resolved', 'ignored') and resolved_at is not null)",
    }
    for name, expr in checks.items():
        require(norm(named[name].raw_expr) == norm(expression(expr)), f'CHECK changed: {name}')
    for table, column, expr in (
        ('exams', 'source_exam_key', "source_exam_key ~ '^[a-z0-9]+(-[a-z0-9]+)*$'"),
        ('source_posts', 'url', "url ~* '^https?://[^/[:space:]]+'"),
        ('resources', 'source_url', "source_url ~* '^https?://[^/[:space:]]+'"),
        ('resources', 'file_url', "file_url is null or file_url ~* '^https?://[^/[:space:]]+'"),
    ):
        require(any(c.contype == enums.ConstrType.CONSTR_CHECK and norm(c.raw_expr) == norm(expression(expr))
                    for c in columns[table][column].constraints), f'Column CHECK: {table}.{column}')
    generated = statement('''create table public.example (sort_date date generated always as (
        case when exam_date is not null then exam_date
        when year is not null and exam_month is not null then pg_catalog.make_date(year, exam_month, 1)
        when year is not null then pg_catalog.make_date(year, 1, 1) else null end) stored)''').tableElts[0]
    require(norm(columns['exams']['sort_date']) == norm(generated), 'Generated sort_date changed')

    functions = [n for n in nodes if isinstance(n, ast.CreateFunctionStmt)]
    require(len(functions) == 2 and {tuple(x.sval for x in f.funcname) for f in functions} == function_revokes,
            'Function inventory')
    expected_set = statement("set search_path = ''")
    for f in functions:
        opts = {o.defname: o.arg for o in f.options}
        require(len(opts) == len(f.options) == 4 and set(opts) == {'security', 'set', 'language', 'as'}, 'Function options')
        require(isinstance(opts['security'], ast.Boolean) and not opts['security'].boolval, 'Function must be invoker')
        require(norm(opts['set']) == norm(expected_set), 'Function search_path must be empty')
        require(opts['language'].sval == 'plpgsql' and not f.parameters and not f.is_procedure
                and [x.sval for x in f.returnType.names] == ['trigger'], 'Function signature')
        # Native parser validates grammar without decoding pglast 8.4 NEW/OLD JSON.
        require(bool(parse_plpgsql_json(RawStream()(f))), 'PL/pgSQL parse failed')
    triggers = [n for n in nodes if isinstance(n, ast.CreateTrigStmt)]
    expected_triggers = {}
    for t in ('source_posts', 'exams', 'subjects', 'exam_subjects', 'resources', 'profiles'):
        expected_triggers[t + '_updated_at'] = statement(f'create trigger {t}_updated_at before update on public.{t} for each row execute function public.set_updated_at()')
    expected_triggers['recent_views_viewed_at'] = statement('create trigger recent_views_viewed_at before insert or update on public.recent_views for each row execute function public.set_viewed_at()')
    require(len(triggers) == len(expected_triggers) and {t.trigname for t in triggers} == set(expected_triggers), 'Trigger inventory')
    for t in triggers:
        require(norm(t) == norm(expected_triggers[t.trigname]), f'Trigger shape: {t.trigname}')
    indexes = [n for n in nodes if isinstance(n, ast.IndexStmt)]
    require(len(indexes) == len(INDEXES) and {n.idxname for n in indexes} == set(INDEXES), 'Index inventory')
    for n in indexes:
        require(norm(n) == norm(statement(f'create index {n.idxname} on public.{INDEXES[n.idxname]}')),
                f'Index structure: {n.idxname}')
    return dict(statements=len(nodes), tables=len(tables), rls_tables=len(alterations),
                policies=len(policies), indexes=len(indexes), triggers=len(triggers), functions=len(functions))


def check_inspection(sql):
    nodes = [r.stmt for r in pglast.parse_sql(sql)]
    def visit(value):
        if isinstance(value, dict):
            require(value.get('@') not in {'InsertStmt', 'UpdateStmt', 'DeleteStmt', 'MergeStmt', 'IntoClause'}, 'Inspection mutation')
            for v in value.values():
                visit(v)
        elif isinstance(value, list):
            for v in value:
                visit(v)
    require(nodes and all(isinstance(q, ast.SelectStmt) for q in nodes), 'Inspection must be SELECT-only')
    visit(norm(nodes))
    return len(nodes)


if __name__ == '__main__':
    print(f'pglast {pglast.__version__}; PostgreSQL parser {pglast.get_postgresql_version()}')
    check_contract()
    print('Migration checks:', check(MIGRATION.read_text()))
    count = check_inspection((ROOT / 'supabase/review/initial_content_schema_checks.sql').read_text())
    print(f'Future inspection SQL: {count} SELECT statements parsed, NOT executed')
    print('PASS: offline syntax/structure only; no SQL executed or DB contacted.')
    print('NOT verified: catalog, RLS runtime, PostgREST, Supabase grants, trigger runtime, performance.')
