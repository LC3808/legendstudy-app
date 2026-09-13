import unittest
from check_study_storage import check, MIGRATION

class StudyStorageGateTests(unittest.TestCase):
    def test_final_package(self):
        check(MIGRATION.read_text())

    def test_contract_regressions_are_rejected(self):
        sql = MIGRATION.read_text()
        mutations = [
            ('duration_seconds >= 1', 'duration_seconds >= 0'),
            ('jsonb_array_length(p_segments) > 256', 'jsonb_array_length(p_segments) > 257'),
            ('start_ms < previous_end', 'start_ms < 0'),
            ('end_ms > p_span_ms', 'end_ms > 999999999'),
            ('planned_duration_seconds between 60 and 43200', 'planned_duration_seconds between 0 and 86400'),
            ('security invoker', 'security definer'),
            ('grant select, delete on table public.study_sessions to authenticated', 'grant select, update, delete on table public.study_sessions to authenticated'),
            ('using ((select auth.uid()) = user_id)', 'using (true)'),
            ('  mode text not null,', '  mode text not null,\n  status text,'),
            ('on delete cascade', 'on delete restrict'),
        ]
        for old, new in mutations:
            with self.subTest(change=old):
                self.assertIn(old, sql)
                with self.assertRaises(AssertionError):
                    check(sql.replace(old, new))
        with self.assertRaises(AssertionError):
            check(sql + '\nalter table public.profiles add column unexpected text;')

if __name__ == '__main__':
    unittest.main()
