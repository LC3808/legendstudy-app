"""Offline fixtures + PostgreSQL AST review. Never connects/applies SQL.

Run with supabase/review/requirements.txt installed. SQL execution, RLS runtime
and idempotent runtime replay are separate NOT_RUN approval-gated checks.
"""
import json
from pathlib import Path
import unittest
from pglast import ast, enums, parse_sql
from pglast.stream import RawStream
from essay_lab.evidence_preview import ROLES, evidence_manifest

ROOT = Path(__file__).resolve().parents[1]
DRAFT = ROOT / 'supabase/review/essay_lab/001_foundation.draft.sql'
FIXTURE = json.loads((ROOT / 'tool/essay_lab/pilot_2025_inspection.json').read_text())
NEW_TABLES = {'universities', 'essay_exams', 'essay_exam_resources'}


class DraftReview(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.stmts = [x.stmt for x in parse_sql(DRAFT.read_text())]
        cls.tables = {s.relation.relname: s for s in cls.stmts if isinstance(s, ast.CreateStmt)}

    def constraints(self, table):
        result = []
        for e in self.tables[table].tableElts:
            result.extend(e.constraints or () if isinstance(e, ast.ColumnDef) else (e,))
        return result

    def test_only_three_new_tables_and_no_existing_alter(self):
        self.assertEqual(set(self.tables), NEW_TABLES)
        for s in self.stmts:
            if isinstance(s, ast.AlterTableStmt):
                self.assertIn(s.relation.relname, NEW_TABLES)
                self.assertEqual([c.subtype for c in s.cmds], [enums.AlterTableType.AT_EnableRowSecurity])
        self.assertFalse(any(isinstance(s, (ast.InsertStmt, ast.UpdateStmt, ast.DeleteStmt, ast.TruncateStmt)) for s in self.stmts))
        self.assertEqual([s.kind for s in self.stmts if isinstance(s, ast.TransactionStmt)],
                         [enums.TransactionStmtKind.TRANS_STMT_BEGIN, enums.TransactionStmtKind.TRANS_STMT_COMMIT])

    def test_no_live_name_collision(self):
        self.assertFalse(NEW_TABLES & {r['table'] for r in FIXTURE['existing_public_tables']})
        for p in (ROOT / 'supabase/migrations').glob('*.sql'):
            self.assertNotIn('create table public.essay_exams', p.read_text().lower())

    def test_replay_static_guards(self):
        for s in self.stmts:
            if isinstance(s, (ast.CreateStmt, ast.IndexStmt)):
                self.assertTrue(s.if_not_exists)
            if isinstance(s, ast.DropStmt):
                self.assertEqual(s.removeType, enums.ObjectType.OBJECT_POLICY)
                self.assertTrue(s.missing_ok)
                self.assertIn(s.objects[0][1].sval, NEW_TABLES)
            if isinstance(s, ast.CreateTrigStmt):
                self.assertTrue(s.replace)
                self.assertEqual([x.sval for x in s.funcname], ['public', 'set_updated_at'])

    def test_fk_targets_and_restrict(self):
        targets = []
        for table in NEW_TABLES:
            for c in self.constraints(table):
                if c.contype == enums.ConstrType.CONSTR_FOREIGN:
                    targets.append(c.pktable.relname)
                    self.assertEqual(c.fk_del_action, 'r')
        self.assertCountEqual(targets, ['universities', 'resources', 'essay_exams', 'resources'])

    def test_multi_role_identity(self):
        pk = [c for c in self.constraints('essay_exam_resources') if c.contype == enums.ConstrType.CONSTR_PRIMARY]
        self.assertEqual([x.sval for x in pk[0].keys], ['essay_exam_id', 'resource_id', 'role'])
        unique = [c for c in self.constraints('essay_exams') if c.contype == enums.ConstrType.CONSTR_UNIQUE]
        self.assertEqual([x.sval for x in unique[0].keys], ['university_id', 'admission_year', 'exam_key'])
        index = next(s for s in self.stmts if isinstance(s, ast.IndexStmt) and s.idxname == 'essay_exams_verified_context')
        self.assertTrue(index.unique and index.nulls_not_distinct)
        self.assertEqual(RawStream()(index.whereClause), "verification_status = 'verified'")
        self.assertIn('session_label', [p.name for p in index.indexParams])
        self.assertIn('exam_kind', [p.name for p in index.indexParams])

    def test_verification_is_fail_closed(self):
        for table in ['essay_exams', 'essay_exam_resources']:
            checks = {c.conname: RawStream()(c.raw_expr) for c in self.constraints(table) if c.contype == enums.ConstrType.CONSTR_CHECK}
            check = checks[table + '_verification']
            for term in ["verification_status = 'review'", 'NOT is_active', 'verified_at IS NULL',
                         "verification_status = 'verified'", 'provenance IS NOT NULL', 'verified_at IS NOT NULL']:
                self.assertIn(term, check)
            self.assertIn('official_source_url IS NOT NULL', checks[table + '_official_evidence'])

    def test_role_and_origin_checks(self):
        checks = ' '.join(RawStream()(c.raw_expr) for c in self.constraints('essay_exam_resources') if c.contype == enums.ConstrType.CONSTR_CHECK)
        for role in ROLES:
            self.assertIn("'" + role + "'", checks)
        for origin in ['official', 'legendstudy_derived', 'ai_generated']:
            self.assertIn("'" + origin + "'", checks)
        self.assertNotIn("'answer'", checks)

    def test_public_read_only_and_rls_parent_chain(self):
        policies = [s for s in self.stmts if isinstance(s, ast.CreatePolicyStmt)]
        self.assertEqual(len(policies), 3)
        for p in policies:
            self.assertEqual(p.cmd_name, 'select')
            self.assertEqual({r.rolename for r in p.roles}, {'anon', 'authenticated'})
            self.assertIn('is_active', RawStream()(p.qual))
        resource_policy = next(p for p in policies if p.table.relname == 'essay_exam_resources')
        self.assertIn('public.resources', RawStream()(resource_policy.qual))
        self.assertIn('public.essay_exams', RawStream()(resource_policy.qual))
        grants = [s for s in self.stmts if isinstance(s, ast.GrantStmt) and s.is_grant]
        for g in grants:
            roles = {r.rolename for r in g.grantees}
            if roles & {'anon', 'authenticated'}:
                self.assertEqual([p.priv_name for p in g.privileges], ['select'])
            else:
                self.assertEqual(roles, {'service_role'})

    def test_lookup_is_select_with_official_and_parent_guards(self):
        statements = parse_sql((DRAFT.parent / 'evidence_lookup.sql').read_text())
        self.assertEqual(len(statements), 1)
        self.assertIsInstance(statements[0].stmt, ast.SelectStmt)
        sql = RawStream()(statements[0].stmt)
        for term in ["m.provenance = 'official'", "m.verification_status = 'verified'", 'r.is_active',
                     'c.is_active', 'e.is_active', 'u.is_active', 'public.exam_subjects', '$1', 'ORDER BY']:
            self.assertIn(term, sql)


class RealPilotInspection(unittest.TestCase):
    def test_exact_six_and_2025_boundary(self):
        self.assertEqual({u['slug_candidate'] for u in FIXTURE['universities']}, {'yonsei', 'skku', 'cau', 'khu', 'pnu', 'knu'})
        all_r = [r for u in FIXTURE['universities'] for p in u['posts'] for r in p['resources']]
        self.assertEqual(len(all_r), 55)
        self.assertEqual(sum(r['pilot_scope'] == 'exam_candidate' for r in all_r), 44)
        self.assertEqual(sum(r['pilot_scope'] == 'admission_guide_only' for r in all_r), 3)
        self.assertEqual(len({r['id'] for r in all_r}), len(all_r))
        for r in all_r:
            self.assertIsNone(r['provenance'])
            self.assertEqual(r['verification_status'], 'review')
            if r['pilot_scope'] == 'exam_candidate': self.assertIn(2025, r['admission_year_candidates'])

    def test_missing_pusan_chungang_not_invented(self):
        by_slug = {u['slug_candidate']: u for u in FIXTURE['universities']}
        self.assertEqual(by_slug['cau']['posts'], [])
        pusan = by_slug['pnu']['posts'][0]
        self.assertEqual(pusan['post_id'], '1658')
        self.assertEqual(sum(r['pilot_scope'] == 'exam_candidate' for r in pusan['resources']), 0)
        self.assertEqual(sum(r['pilot_scope'] == 'admission_guide_only' for r in pusan['resources']), 1)

    def test_actual_patterns_and_no_answer_subtype_inference(self):
        rows = [r for u in FIXTURE['universities'] for p in u['posts'] for r in p['resources']]
        for term in ['자연(추가)', '인문1', '자연3', '문제,답안', '출제의도', '의약학_화학']:
            self.assertTrue(any(term in r['title'] for r in rows), term)
        for r in rows:
            if '답안' in r['title']:
                self.assertEqual(r['answer_subtype'], 'unknown')
                self.assertNotIn('model_answer', r['candidate_roles'])

    def test_year_is_not_publication_year(self):
        p = next(p for u in FIXTURE['universities'] for p in u['posts'] if p['post_id'] == '1633')
        self.assertTrue(p['published_at'].startswith('2024'))
        self.assertTrue(all(r['admission_year_candidates'] == [2025] for r in p['resources']))
        for u in FIXTURE['universities']:
            for p in u['posts']: self.assertEqual(p['guest_resources_verified'], len(p['resources']))


class EvidenceContract(unittest.TestCase):
    # SYNTHETIC mapping only. No claim that these official roles exist in Pilot.
    def row(self, **overrides):
        return dict(dict(essay_exam_id='exam-2025', resource_id='r1', role='question',
                         provenance='official', verification_status='verified', is_active=True,
                         official_source_url='https://example.edu/exam', source_locator='PDF pp. 1–2'), **overrides)

    def test_multi_role_multi_file_order_and_year_isolation(self):
        rows = [self.row(), self.row(role='passage'), self.row(role='scoring_criteria'),
                self.row(resource_id='r2'), self.row(essay_exam_id='exam-2024', role='guidebook')]
        got = evidence_manifest('exam-2025', rows, ['r1', 'r2'])
        self.assertEqual(got, evidence_manifest('exam-2025', list(reversed(rows)), ['r2', 'r1']))
        self.assertEqual(got['resources_by_role']['question'], ['r1', 'r2'])
        self.assertEqual(got['resources_by_role']['scoring_criteria'], ['r1'])
        self.assertIn('guidebook', got['missing_roles'])
        self.assertEqual(evidence_manifest('exam-2024', rows, ['r1'])['resources_by_role']['guidebook'], ['r1'])

    def test_unverified_generated_hidden_and_unlocated_not_official(self):
        variants = [dict(provenance='ai_generated'), dict(provenance='legendstudy_derived'),
                    dict(provenance=None), dict(verification_status='review'), dict(is_active=False),
                    dict(official_source_url=None), dict(source_locator=None)]
        for override in variants:
            with self.subTest(override=override):
                self.assertEqual(evidence_manifest('exam-2025', [self.row(**override)], ['r1'])['resources_by_role']['question'], [])
        self.assertEqual(evidence_manifest('exam-2025', [self.row()], [])['resources_by_role']['question'], [])

    def test_duplicate_rejected(self):
        with self.assertRaises(ValueError): evidence_manifest('exam-2025', [self.row(), self.row()], ['r1'])

    def test_missing_official_document_is_not_fabricated(self):
        got = evidence_manifest('exam-2025', [], [])
        self.assertEqual(set(got['missing_roles']), set(ROLES))
        with self.assertRaises(ValueError): evidence_manifest('exam-2025', [self.row(role='answer')], ['r1'])


if __name__ == '__main__':
    unittest.main()
