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
        self.assertEqual(c.check(self.sql), dict(statements=68, tables=9, rls_tables=9,
                         policies=15, indexes=9, triggers=7, functions=2))
        c.check_contract()

    def test_format_and_boolean_reordering(self):
        sql = self.sql.replace('e.id = exam_id and e.is_active', 'e.is_active AND e.id = exam_id')
        sql = sql.replace('using (is_active)', 'USING ( ( is_active ) )')
        c.check(sql)

    def test_unsafe_mutations(self):
        cases = [
            ('negative activity', 'using (is_active)', 'using (not is_active)'),
            ('true disjunction', 'using (is_active)', 'using (true or is_active)'),
            ('parent bypass', 'e.id = exam_id and e.is_active', 'e.id = exam_id or e.is_active'),
            ('missing parent', 'and exists (select 1 from public.exams e where e.id = exam_id and e.is_active)', ''),
            ('owner bypass', '((select auth.uid()) = id)', '(true)'),
            ('timestamp grant', 'grant update (user_id, exam_id)', 'grant update (user_id, exam_id, viewed_at)'),
            ('id grant', 'grant update (user_id, exam_id)', 'grant update (id, user_id, exam_id)'),
            ('profile missing id', 'grant update (id, display_name, grade_level)', 'grant update (display_name, grade_level)'),
            ('public diagnostics', 'grant select (id, slug, title', 'grant select (normalization_note, id, slug, title'),
            ('broad content select', 'on public.exams to anon, authenticated;', 'on public.exams to anon, authenticated; grant select on public.exams to anon;'),
            ('quarantine exposure', 'commit;', 'grant select on public.ingestion_quarantine to authenticated; commit;'),
            ('update cascade', 'on delete restrict', 'on delete restrict on update cascade'),
            ('delete cascade', 'on delete restrict', 'on delete cascade'),
            ('mapping partial', 'match full', 'match simple'),
            ('nullable identity', 'external_post_id text not null', 'external_post_id text'),
            ('merge self', 'merged_into_exam_id <> id and not is_active', 'not is_active'),
            ('mapping confidence', 'and mapping_confidence is not null and verified_at is null', 'and verified_at is null'),
            ('URL scheme case', "url ~* '^https?", "url ~ '^https?"),
            ('sort proxy', 'pg_catalog.make_date(year, 1, 1)', 'pg_catalog.make_date(year, 12, 1)'),
            ('index columns', '(sort_date desc nulls last, id desc)', '(year desc nulls last, id desc)'),
            ('index order', '(sort_date desc nulls last, id desc)', '(sort_date asc nulls last, id desc)'),
            ('index predicate', 'where is_active;', 'where not is_active;'),
            ('trigger removed', 'create trigger profiles_updated_at before update on public.profiles\n    for each row execute function public.set_updated_at();', ''),
            ('trigger timing', 'recent_views_viewed_at before insert or update', 'recent_views_viewed_at after insert or update'),
            ('definer', 'security invoker', 'security definer'),
            ('search path', "set search_path = ''", "set search_path = 'public'"),
            ('execute revoke removed', 'revoke all on function public.set_viewed_at() from public, anon, authenticated;', ''),
            ('execute regranted', 'commit;', 'grant execute on function public.set_viewed_at() to anon; commit;'),
            ('RLS disable', 'alter table public.resources enable row level security;', 'alter table public.resources disable row level security;'),
            ('seed DML', 'commit;', "insert into public.subjects (code) values ('math'); commit;"),
            ('extension', 'commit;', 'create extension pg_trgm; commit;'),
        ]
        for label, old, new in cases:
            with self.subTest(label=label):
                self.assertIn(old, self.sql)
                with self.assertRaises(ValueError):
                    c.check(self.sql.replace(old, new, 1))

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
        self.assertEqual(c.check_inspection((c.ROOT/'supabase/review/initial_content_schema_checks.sql').read_text()), 14)
        for sql in ('delete from public.exams', 'select * into x from public.exams',
                    'with x as (delete from public.exams returning *) select * from x'):
            with self.subTest(sql=sql), self.assertRaises(ValueError):
                c.check_inspection(sql)


if __name__ == '__main__':
    unittest.main()
