#!/usr/bin/env python3
"""Offline PostgreSQL AST checks, not runtime RLS/transaction/concurrency verification."""
from pathlib import Path
import hashlib
import json
import re
import pglast
from pglast import parse_sql
from pglast.parser import parse_plpgsql_json
from pglast.stream import RawStream

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
FILES = ('001_student_essay_product.draft.sql', '002_entitlements.draft.sql')
CANONICAL = {'essay_questions', 'essay_question_evidence', 'essay_evaluation_criteria'}
DIRECT_WRITE = {'essay_drafts', 'student_target_universities'}
EXPECTED = CANONICAL | DIRECT_WRITE | set('essay_practice_sessions essay_attempts essay_evaluations essay_evaluation_dimensions essay_improvement_items essay_improvement_progress essay_evaluation_evidence essay_generated_rewrites essay_learning_events essay_ai_processing_runs credit_accounts credit_grants essay_billing_decisions credit_transactions'.split())

def require(value, message):
    if not value:
        raise ValueError(message)

def names(nodes):
    return tuple(n['sval'] for n in (nodes or ()))

def validate(sql=None):
    sql = sql or '\n'.join((HERE / f).read_text() for f in FILES)
    nodes = parse_sql(sql)
    tables, policies, enabled, grants, functions = {}, [], set(), [], set()
    for raw in nodes:
        node = raw.stmt()
        kind = node['@']
        require(kind not in ('DropStmt', 'TruncateStmt', 'DeleteStmt', 'UpdateStmt', 'InsertStmt'), 'destructive/data mutation SQL')
        if kind == 'CreateStmt':
            table = node['relation']['relname']
            require(table not in tables, 'duplicate table')
            cols, keys, fks = {}, set(), []
            for e in node['tableElts']:
                col = e.get('colname')
                if col:
                    cols[col] = names(e['typeName']['names'])
                    cs = e.get('constraints') or ()
                else:
                    cs = [e]
                for c in cs:
                    ct = c['contype']['name']
                    if ct in ('CONSTR_PRIMARY', 'CONSTR_UNIQUE'):
                        keys.add((col,) if col else names(c['keys']))
                    if ct == 'CONSTR_FOREIGN':
                        fks.append(((col,) if col else names(c['fk_attrs']), c['pktable']['relname'], names(c['pk_attrs'])))
            require(any(e.get('colname') and any(c['contype']['name'] == 'CONSTR_PRIMARY' for c in (e.get('constraints') or ())) for e in node['tableElts']), f'{table}: primary key required')
            require(any(c.endswith('_at') for c in cols), f'{table}: timestamp required')
            tables[table] = (cols, keys, fks)
        elif kind == 'AlterTableStmt':
            require(all(c['subtype']['name'] == 'AT_EnableRowSecurity' for c in node['cmds']), 'only RLS-enable ALTER permitted')
            enabled.add(node['relation']['relname'])
        elif kind == 'CreatePolicyStmt':
            policies.append(node)
        elif kind == 'GrantStmt':
            grants.append(node)
        elif kind == 'CreateFunctionStmt':
            require(not node.get('replace'), 'cannot replace existing function')
            parse_plpgsql_json(RawStream()(raw))
            functions.add(names(node['funcname'])[-1])
    require(set(tables) == EXPECTED, 'unexpected table set')
    require(enabled == EXPECTED, 'RLS required on every new table')
    inventory = json.loads((HERE/'current_schema_inventory.json').read_text())['inventory']
    live = {t['name'] for t in inventory['tables']}
    require(not (live & EXPECTED), 'live schema table collision')
    require(not (functions & {f['name'] for f in inventory['functions']}), 'live function collision')
    external = {t: ({c['column']: None for c in inventory['columns'] if c['table'] == t}, set(), []) for t in ('profiles','universities','essay_exams','essay_exam_resources')}
    for t in ('profiles','universities','essay_exams'):
        external[t][1].add(('id',))
    for c in inventory['constraints']:
        if c['definition'].startswith(('PRIMARY KEY','UNIQUE')):
            k = tuple(v.strip() for v in re.search(r'\(([^)]+)\)', c['definition']).group(1).split(','))
            if c['table'] in external:
                external[c['table']][1].add(k)
    graph = {**external, **tables}
    fk_count = 0
    for t, (cols, keys, fks) in tables.items():
        for local, target, remote in fks:
            fk_count += 1
            require(target in graph, f'{t}: unknown FK table {target}')
            tcols,tkeys,_ = graph[target]
            require(len(local) == len(remote), f'{t}: FK arity')
            require(all(c in cols for c in local), f'{t}: missing local column')
            require(all(c in tcols for c in remote), f'{t}: missing referenced column')
            require(remote in tkeys, f'{t}: referenced key not UNIQUE: {target}{remote}')
            for a,b in zip(local,remote):
                if tcols[b] is not None:
                    require(cols[a] == tcols[b], f'{t}: FK type mismatch')
    read_tables=set()
    for p in policies:
        t = p['table']['relname']; cmd = p['cmd_name']
        roles = {x['rolename'] for x in p['roles']}
        if cmd == 'select':
            read_tables.add(t)
            require(('anon' in roles) == (t in CANONICAL), f'{t}: public exposure')
        else:
            require(t in DIRECT_WRITE and roles == {'authenticated'}, f'{t}: direct write policy forbidden')
    require(read_tables == EXPECTED - {'essay_ai_processing_runs'}, 'missing/unsafe read policies')
    for g in grants:
        if not g['is_grant'] or g['objtype']['name'] != 'OBJECT_TABLE':
            continue
        roles={x.get('rolename') for x in g['grantees']}
        for obj in g['objects']:
            t=obj['relname']
            privs={x['priv_name'] for x in (g.get('privileges') or [])}
            require(bool(privs), 'unbounded ALL grant')
            require('anon' not in roles or t in CANONICAL, 'private anon grant')
            if roles & {'authenticated','anon'} and privs - {'select'}:
                require(t in DIRECT_WRITE and 'anon' not in roles, f'{t}: unsafe client grant')
            if t == 'credit_transactions':
                require(not privs & {'update','delete'}, 'ledger mutable grant')
    require('level_1_to_5 between 1 and 5' in sql, 'level bound')
    require('official_weight_percent' in sql, 'official weight separate')
    require(not re.search(r'attempt_no\s*(=|>=)\s*[23]', sql), 'billing attempt rule hardcoded')
    require('unique(session_id,attempt_no)' in sql, 'attempt identity')
    require('input_sha256' in sql and 'regime_key' in sql, 'versioning lost')
    require('payload' not in tables['essay_learning_events'][0], 'event body payload forbidden')
    require("origin = 'ai_generated'" in sql, 'rewrite provenance')
    require('foreign key(evidence_id,question_id)' in sql and 'foreign key(criterion_id,question_id)' in sql, 'cross-question guards')
    require('foreign key(included_by_decision_id,account_id)' in sql, 'cross-account included decision guard')
    # Verify accepted v1.1 has not changed; new contract is exactly two additive rules.
    base_path=ROOT/'tool/essay_lab/evidence/evaluation_contract_v1_1.json'
    old=json.loads(base_path.read_text()); new=json.loads((base_path.parent/'evaluation_contract_v1_2.json').read_text())
    require(hashlib.sha256(base_path.read_bytes()).hexdigest() == '92a84addc22045a62be66009a3d637f6f94344214f8cccd737384a0c69bb08cf', 'accepted v1.1 changed')
    require(new['base_sha256'] == hashlib.sha256(base_path.read_bytes()).hexdigest(), 'base hash')
    require(new['rules'][:-2] == old['rules'] and new['output_keys_preserved'] == old['output_keys_preserved'], 'v1.2 not additive')
    return {'tables':len(tables),'foreign_keys':fk_count,'policies':len(policies),'plpgsql_functions':len(functions),'parser_version':pglast.__version__,'static':'PASS','runtime':'NOT_RUN'}

if __name__ == '__main__':
    print(json.dumps(validate(),indent=2))
