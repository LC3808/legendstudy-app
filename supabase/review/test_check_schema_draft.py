"""Mutation tests for the offline checker; no database or SQL execution."""
import json
import tempfile
import unittest
from pathlib import Path
import check_schema_draft as c


class OfflineCheckerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sql = c.MIGRATION.read_text()

    def test_baseline(self):
        self.assertEqual(c.check(self.sql), dict(statements=74, tables=10, rls_tables=10,
                         policies=16, indexes=10, triggers=8, functions=2))
        c.check_contract()

    def test_format_and_boolean_reordering(self):
        sql = self.sql.replace('c.id = exams.content_item_id and c.is_active', 'c.is_active AND c.id = exams.content_item_id')
        sql = sql.replace('using (is_active)', 'USING ( ( is_active ) )')
        c.check(sql)

    def test_unsafe_mutations(self):
        cases = [
            ('negative activity', 'using (is_active)', 'using (not is_active)'),
            ('true disjunction', 'using (is_active)', 'using (true or is_active)'),
            ('parent bypass', 'c.id = exams.content_item_id and c.is_active', 'c.id = exams.content_item_id or c.is_active'),
            ('missing parent', 'and exists (select 1 from public.content_items c where c.id = exam_subjects.content_item_id and c.is_active)', ''),
            ('owner bypass', '((select auth.uid()) = id)', '(true)'),
            ('timestamp grant', 'grant update (user_id, content_item_id)', 'grant update (user_id, content_item_id, viewed_at)'),
            ('id grant', 'grant update (user_id, content_item_id)', 'grant update (id, user_id, content_item_id)'),
            ('profile missing id', 'grant update (id, display_name, grade_level)', 'grant update (display_name, grade_level)'),
            ('public diagnostics', 'grant select (content_item_id, content_type, year', 'grant select (normalization_note, content_item_id, content_type, year'),
            ('broad content select', 'on public.exams to anon, authenticated;', 'on public.exams to anon, authenticated; grant select on public.exams to anon;'),
            ('quarantine exposure', 'commit;', 'grant select on public.ingestion_quarantine to authenticated; commit;'),
            ('update cascade', 'on delete restrict', 'on delete restrict on update cascade'),
            ('delete cascade', 'on delete restrict', 'on delete cascade'),
            ('mapping partial', 'match full', 'match simple'),
            ('nullable identity', 'external_post_id text not null', 'external_post_id text'),
            ('merge self', 'merged_into_content_item_id <> id and not is_active', 'not is_active'),
            ('mapping confidence', 'and mapping_confidence is not null and verified_at is null', 'and verified_at is null'),
            ('URL scheme case', "url ~* '^https?", "url ~ '^https?"),
            ('sort proxy', 'pg_catalog.make_date(year, 1, 1)', 'pg_catalog.make_date(year, 12, 1)'),
            ('index columns', '(sort_date desc nulls last, content_item_id desc)', '(year desc nulls last, content_item_id desc)'),
            ('index order', '(sort_date desc nulls last, content_item_id desc)', '(sort_date asc nulls last, content_item_id desc)'),
            ('index predicate', 'where is_active;', 'where not is_active;'),
            ('trigger removed', 'create trigger profiles_updated_at before update on public.profiles\n    for each row execute function public.set_updated_at();', ''),
            ('trigger timing', 'recent_views_viewed_at before insert or update', 'recent_views_viewed_at after insert or update'),
            ('definer', 'security invoker', 'security definer'),
            ('search path', "set search_path = ''", "set search_path = 'public'"),
            ('execute revoke removed', 'revoke all on function public.set_viewed_at() from public, anon, authenticated;', ''),
            ('execute regranted', 'commit;', 'grant execute on function public.set_viewed_at() to anon; commit;'),
            ('RLS disable', 'alter table public.resources enable row level security;', 'alter table public.resources disable row level security;'),
            ('seed DML', 'commit;', "insert into public.subjects (code) values ('math'); commit;"),
            ('stale trigger key', 'new.content_item_id is distinct from old.content_item_id', 'new.exam_id is distinct from old.exam_id'),
            ('trigger clock removed', 'new.viewed_at = pg_catalog.now();', ''),
            ('extension', 'commit;', 'create extension pg_trgm; commit;'),
            ('content key drift', "source_content_key ~ '^[a-z0-9]+(-[a-z0-9]+)*$'", "source_content_key <> ''"),
            ('content type bypass', "'admissions_info', 'other'", "'admissions_info', 'other', 'arbitrary'"),
            ('exam discriminator', "content_type text generated always as ('exam'::text) stored", "content_type text default 'exam'"),
            ('missing exam uniqueness', 'content_item_id uuid primary key', 'content_item_id uuid not null'),
            ('type FK bypass', 'foreign key (content_item_id, content_type)\n        references public.content_items(id, content_type)', 'foreign key (content_item_id) references public.content_items(id)'),
            ('scope FK bypass', 'foreign key (exam_subject_id, content_item_id)\n        references public.exam_subjects(id, content_item_id)', 'foreign key (exam_subject_id) references public.exam_subjects(id)'),
            ('occurrence permits non-exam', 'references public.exams(content_item_id)', 'references public.content_items(id)'),
            ('resource requires exam', 'content_item_id uuid not null references public.content_items(id)', 'content_item_id uuid not null references public.exams(content_item_id)'),
            ('home wrong clock', 'greatest(published_at, source_updated_at)', 'greatest(published_at, updated_at)'),
            ('home wrong index', '(feed_updated_at desc nulls last, id desc)', '(published_at desc nulls last, id desc)'),
            ('parent hidden leak', 'exists (select 1 from public.content_items c where c.id = resources.content_item_id and c.is_active)', 'true'),
            ('taxonomy visibility coupling', 'c.id = exam_subjects.content_item_id and c.is_active', 'c.id = exam_subjects.content_item_id and c.is_active and exists (select 1 from public.subjects s where s.id = subject_id and s.is_active)'),

        ]
        for label, old, new in cases:
            with self.subTest(label=label):
                self.assertIn(old, self.sql)
                with self.assertRaises(ValueError):
                    c.check(self.sql.replace(old, new, 1))

    def test_all_content_personal_targets(self):
        for table in ('bookmarks', 'recent_views'):
            with self.subTest(table=table):
                start = self.sql.index('create table public.' + table)
                end = self.sql.index(');', start) + 2
                block = self.sql[start:end].replace('references public.content_items(id)',
                                                    'references public.exams(content_item_id)')
                with self.assertRaises(ValueError):
                    c.check(self.sql[:start] + block + self.sql[end:])
                with self.assertRaises(ValueError):
                    c.check(self.sql.replace(f'c.id = {table}.content_item_id and c.is_active',
                                            f'c.id = {table}.content_item_id or c.is_active', 1))

    def mutate_column(self, table, column, mutate):
        """Edit only in-memory ASTs; never touch or execute the migration file."""
        parsed = c.pglast.parse_sql(self.sql)
        relation = next(r.stmt for r in parsed if isinstance(r.stmt, c.ast.CreateStmt)
                        and r.stmt.relation.relname == table)
        definition = next(x for x in relation.tableElts if isinstance(x, c.ast.ColumnDef)
                          and x.colname == column)
        mutate(definition, relation)
        return '-- DRAFT ONLY: in-memory mutation fixture\n' + c.RawStream()(parsed)

    def remove_constraint(self, table, column, kind):
        def mutate(definition, relation):
            original = definition.constraints
            definition.constraints = tuple(x for x in original if x.contype != kind)
            self.assertLess(len(definition.constraints), len(original))
        return self.mutate_column(table, column, mutate)

    def replace_check(self, table, column, expr):
        def mutate(definition, relation):
            checks = [x for x in definition.constraints if x.contype == c.enums.ConstrType.CONSTR_CHECK]
            self.assertEqual(len(checks), 1)
            checks[0].raw_expr = c.expression(expr)
        return self.mutate_column(table, column, mutate)

    def test_slug_invariants_independently(self):
        for label, sql in (
            ('NOT NULL removal', self.remove_constraint('content_items', 'slug', c.enums.ConstrType.CONSTR_NOTNULL)),
            ('UNIQUE removal', self.remove_constraint('content_items', 'slug', c.enums.ConstrType.CONSTR_UNIQUE)),
            ('regex weakening', self.replace_check('content_items', 'slug', "btrim(slug) <> ''")),
        ):
            with self.subTest(label=label), self.assertRaisesRegex(ValueError, 'content_items.slug'):
                c.check(sql)

    def test_source_url_collision_guard(self):
        for label, sql in (
            ('NOT NULL removal', self.remove_constraint('source_posts', 'url', c.enums.ConstrType.CONSTR_NOTNULL)),
            ('UNIQUE removal', self.remove_constraint('source_posts', 'url', c.enums.ConstrType.CONSTR_UNIQUE)),
            ('shape weakening', self.replace_check('source_posts', 'url', "btrim(url) <> ''")),
        ):
            with self.subTest(label=label), self.assertRaisesRegex(ValueError, 'source_posts.url'):
                c.check(sql)

    def test_publication_defaults_each_layer(self):
        for table in ('content_items', 'subjects', 'exam_subjects', 'resources'):
            def make_public(definition, relation):
                default = next(x for x in definition.constraints if x.contype == c.enums.ConstrType.CONSTR_DEFAULT)
                default.raw_expr = c.expression('true')
            cases = (
                ('true default', self.mutate_column(table, 'is_active', make_public)),
                ('missing default', self.remove_constraint(table, 'is_active', c.enums.ConstrType.CONSTR_DEFAULT)),
                ('nullable', self.remove_constraint(table, 'is_active', c.enums.ConstrType.CONSTR_NOTNULL)),
            )
            for label, sql in cases:
                with self.subTest(table=table, label=label), self.assertRaisesRegex(ValueError, table + '.is_active'):
                    c.check(sql)

    def test_generated_input_and_numeric_ranges(self):
        for table, column, weakened in (
            ('exams', 'year', 'year between 0 and 2200'),
            ('exams', 'academic_year', 'academic_year between 0 and 2200'),
            ('exams', 'exam_month', 'exam_month between 0 and 12'),
            ('exams', 'grade_level', 'grade_level in (0, 1, 2, 3)'),
            ('exam_subjects', 'mapping_confidence', 'mapping_confidence between -1 and 1'),
        ):
            for label, sql in (
                ('weakened', self.replace_check(table, column, weakened)),
                ('removed', self.remove_constraint(table, column, c.enums.ConstrType.CONSTR_CHECK)),
            ):
                with self.subTest(table=table, column=column, label=label), self.assertRaisesRegex(ValueError, table + '.' + column):
                    c.check(sql)

    def test_domain_checks_reject_widening_and_removal(self):
        # Independent inventory of critical enum columns, not generated from checker constants.
        for table, column in (
            ('source_posts', 'source_status'), ('content_items', 'content_type'),
            ('exams', 'exam_type'), ('exam_subjects', 'mapping_status'),
            ('resources', 'resource_type'), ('resources', 'link_kind'),
            ('resources', 'link_status'), ('ingestion_quarantine', 'status'),
        ):
            def widen(definition, relation):
                rule = next(x for x in definition.constraints if x.contype == c.enums.ConstrType.CONSTR_CHECK)
                self.assertEqual(rule.raw_expr.kind, c.enums.A_Expr_Kind.AEXPR_IN)
                rule.raw_expr.rexpr += (c.ast.A_Const(val=c.ast.String(sval='unreviewed_value')),)
            for label, sql in (
                ('extra enum value', self.mutate_column(table, column, widen)),
                ('removed', self.remove_constraint(table, column, c.enums.ConstrType.CONSTR_CHECK)),
            ):
                with self.subTest(table=table, column=column, label=label), self.assertRaisesRegex(ValueError, table + '.' + column):
                    c.check(sql)

    def test_display_orders_nonnegative(self):
        for table, column in (('subjects', 'sort_order'), ('exam_subjects', 'display_order'), ('resources', 'display_order')):
            for label, sql in (
                ('negative allowed', self.replace_check(table, column, column + ' >= -1')),
                ('removed', self.remove_constraint(table, column, c.enums.ConstrType.CONSTR_CHECK)),
            ):
                with self.subTest(table=table, column=column, label=label), self.assertRaisesRegex(ValueError, table + '.' + column):
                    c.check(sql)

    def test_global_uniqueness_not_composite(self):
        for table, column, extra in (('content_items', 'slug', 'source_post_id'), ('source_posts', 'url', 'source')):
            def move_unique(definition, relation):
                definition.constraints = tuple(x for x in definition.constraints if x.contype != c.enums.ConstrType.CONSTR_UNIQUE)
                relation.tableElts += (c.statement(f'create table x (constraint unique_fixture unique ({column}))').tableElts[0],)
            c.check(self.mutate_column(table, column, move_unique))
            def make_composite(definition, relation):
                move_unique(definition, relation)
                relation.tableElts[-1].keys += (c.ast.String(sval=extra),)
            with self.subTest(table=table), self.assertRaisesRegex(ValueError, 'Global UNIQUE'):
                c.check(self.mutate_column(table, column, make_composite))

    def test_scalar_formatting_and_comments(self):
        sql = self.sql.replace('not null unique check', 'NOT /* harmless */ NULL\n UNIQUE CHECK')
        sql = sql.replace('default false', 'DEFAULT /* reviewed */ ( false )')
        sql = sql.replace('year between 1900 and 2200', 'year BETWEEN /* bound */ 1900 AND 2200')
        sql = sql.replace('display_order >= 0', '( display_order >= 0 )')
        c.check(sql)

    def test_contract_mutations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'supabase/review').mkdir(parents=True)
            (root / 'wiki').mkdir()
            contract = root / 'supabase/review/ingestion_contract.json'
            wiki = root / 'wiki/ingestion.md'
            contract.write_text(json.dumps(c.CONTRACT))
            wiki.write_text(c.VERIFIED_RULE)
            c.check_contract(root)
            contract.write_text(json.dumps({**c.CONTRACT, 'automated_update_excluded_mapping_statuses': []}))
            with self.assertRaises(ValueError):
                c.check_contract(root)
            contract.write_text(json.dumps(c.CONTRACT))
            wiki.write_text('No protection rule.')
            with self.assertRaises(ValueError):
                c.check_contract(root)

    def test_inspection(self):
        self.assertEqual(c.check_inspection((c.ROOT/'supabase/review/initial_content_schema_checks.sql').read_text()), 16)
        inspection = c.pglast.parse_sql((c.ROOT/'supabase/review/initial_content_schema_checks.sql').read_text())
        expected_orphans = c.statement("""select c.id, c.slug from public.content_items c
            where c.is_active and c.content_type = 'exam'
            and not exists (select 1 from public.exams e where e.content_item_id = c.id)""")
        self.assertEqual(c.norm(inspection[-1].stmt), c.norm(expected_orphans))
        for sql in ('delete from public.exams', 'select * into x from public.exams',
                    'with x as (delete from public.exams returning *) select * from x'):
            with self.subTest(sql=sql), self.assertRaises(ValueError):
                c.check_inspection(sql)


if __name__ == '__main__':
    unittest.main()
