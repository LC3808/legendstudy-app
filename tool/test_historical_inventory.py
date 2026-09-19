"""Offline historical report contracts; no DB, network or production mutation."""
import csv
from collections import Counter
from dataclasses import asdict
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from ingestion.crawler import SampleSource
from ingestion.pipeline import run
from ingestion.apply import resolve, assert_write_shape, assert_no_signing_material
from ingestion.writer import assert_no_collisions

ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT / 'reports/historical-exam'

class HistoricalInventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = SampleSource(ROOT / 'tool/ingestion/samples/day9b_exam_posts.jsonl').posts()
        cls.result = run(cls.raw, '2026-09-20T00:00:00Z', map_subjects=True)

    def rows(self, name):
        with (REPORTS / name).open(encoding='utf-8', newline='') as stream:
            return list(csv.DictReader(stream))

    def test_semantic_projection_ignores_observation_clock(self):
        later = run(self.raw, '2030-01-01T00:00:00Z', map_subjects=True)
        for before, after in zip(self.result.plans, later.plans):
            a, b = asdict(resolve(before)), asdict(resolve(after))
            self.assertNotEqual(a['source_post'].pop('last_crawled_at'),
                                b['source_post'].pop('last_crawled_at'))
            self.assertEqual(a, b)

    def test_identity_visibility_and_locator_gates(self):
        self.assertFalse(self.result.parse_errors)
        self.assertFalse(self.result.merge_candidates)
        assert_no_collisions(self.result.plans)
        rows = [resolve(p) for p in self.result.plans]
        assert_write_shape(rows)
        assert_no_signing_material(rows)
        self.assertEqual(len({p.source_post['url'] for p in self.result.plans}), 38)
        for p in self.result.plans:
            self.assertEqual(len({r['source_url'] for r in p.resources}), len(p.resources))
            for o in p.occurrences:
                self.assertEqual(o['raw_subject_label'], o['source_subject_key'])
            for r in p.resources:
                self.assertNotIn('?', r['source_url'])

    def test_box_delta_matches_current_source(self):
        observed = {(p.external_post_id, r['source_resource_key'], r['source_url'])
                    for p in self.result.plans for r in p.resources if r['provider'] == 'box'}
        report = self.rows('2024-resource-drift.csv')
        self.assertEqual(observed, {(r['external_post_id'], r['source_resource_key'], r['source_url']) for r in report})
        self.assertEqual(len(report), 23)
        self.assertEqual(len({r['source_resource_key'] for r in report}), 23)
        self.assertEqual(Counter(r['year'] for r in report), {'2025': 15, '2026': 8})

    def test_2024_csv_scope_and_resource_pairing(self):
        plans = [p for p in self.result.plans if p.exam['year'] == 2024]
        batch = [p for p in plans if p.exam['grade_level'] == 3]
        self.assertEqual(Counter(p.exam['grade_level'] for p in plans), {1: 4, 2: 4, 3: 7})
        report = self.rows('2024-candidate-reconciliation.csv')
        self.assertEqual({r['external_post_id'] for r in report}, {p.external_post_id for p in plans})
        self.assertEqual(sum(int(r['subject_count']) for r in report), 246)
        self.assertEqual(sum(int(r['resource_count']) for r in report), 489)
        resources = self.rows('2024-grade3-batch.csv')
        self.assertEqual(len(resources), 299)
        self.assertEqual({(r['external_post_id'], r['source_resource_key']) for r in resources},
                         {(p.external_post_id, r['source_resource_key']) for p in batch for r in p.resources})
        self.assertTrue(all(r['is_active'] == 'False' and r['feed_updated_at'].startswith('2024-') for r in resources))
        pairs = self.rows('2024-grade3-subject-pairing.csv')
        self.assertEqual(len(pairs), 151)
        for row in pairs:
            actual = Counter(r['resource_type'] for r in resources
                             if r['external_post_id'] == row['external_post_id']
                             and r['source_subject_key'] == row['source_subject_key'])
            for kind in ('question', 'answer', 'explanation', 'answer_explanation', 'listening_script', 'listening_audio'):
                self.assertEqual(actual[kind], int(row[kind]))
        keys = self.rows('2024-candidate-keys.csv')
        self.assertEqual(Counter(k['table'] for k in keys), {'source_posts': 15, 'content_items': 15, 'exams': 15, 'exam_subjects': 246, 'resources': 489})
        self.assertEqual(len(keys), len({(k['table'], k['natural_key']) for k in keys}))
        self.assertTrue(all(k['production_key_status'] == 'UNVERIFIED' for k in keys))

if __name__ == '__main__':
    unittest.main()
