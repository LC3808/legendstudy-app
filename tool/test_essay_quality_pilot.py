"""Offline safety/scope tests. Optional private PDF integration is explicit."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from tool.essay_lab import quality_pilot_2025 as q
from tool.essay_lab import pilot_2025 as previous

class QualityPilotTest(unittest.TestCase):
    def setUp(self):self.plan=q.load_plan()
    def test_scope_identity(self):
        self.assertEqual(len(self.plan['exams']),2)
        self.assertEqual({e['admission_year'] for e in self.plan['exams']},{2025})
        self.assertEqual({e['exam_key'] for e in self.plan['exams']},{'mock-humanities'})
    def test_previous_validator_stays_bounded(self):
        with self.assertRaises(AssertionError):previous.validate(self.plan)
        previous.validate(previous.load_plan())
    def test_controlled_path_explicit_validator(self):
        for slug,count in [('sookmyung',7),('hanyang',6)]:
            rows=previous.scope(self.plan,slug,validate_plan=q.validate)
            self.assertEqual(len(rows['essay_exam_resources']),count)
    def test_duplicate_rejected(self):
        self.plan['mappings'].append(copy.deepcopy(self.plan['mappings'][0]))
        with self.assertRaises(AssertionError):q.validate(self.plan)
    def test_cross_university_rejected(self):
        self.plan['mappings'][0]['resource_id']=self.plan['documents'][-1]['resource_id']
        with self.assertRaises(AssertionError):q.validate(self.plan)
    def test_unknown_year_rejected(self):
        self.plan['exams'][0]['admission_year']=2026
        with self.assertRaises(AssertionError):q.validate(self.plan)
    def test_false_high_scoring_rejected(self):
        self.plan['mappings'][-1]['role']='high_scoring_answer'
        with self.assertRaises(AssertionError):q.validate(self.plan)
    def test_official_and_verified_required(self):
        for field,value in [('provenance','ai_generated'),('verification_status','pending'),('official_source_url','https://example.com'),('source_locator','')]:
            p=copy.deepcopy(self.plan);p['mappings'][0][field]=value
            with self.assertRaises(AssertionError):q.validate(p)
    def test_blind_allowlist_no_reference_answers(self):
        p=q.blind_payload('question','passages','intent','criteria','abc',[])
        s=json.dumps(p)
        for forbidden in ['high_scoring','ground_truth','example_answer','model_answer','university','official_source_url','resource_id']:
            self.assertNotIn(forbidden,s)
        self.assertEqual(set(p['official_evidence']),{'exam_intent','scoring_criteria'})
    def test_blind_deterministic(self):
        self.assertEqual(q.encoded(q.blind_payload('q','p','i','c','a',[])),q.encoded(q.blind_payload('q','p','i','c','a',[])))
    def test_roles_and_absence(self):
        for slug,missing in [('sookmyung',{'model_answer'}),('hanyang',{'model_answer','high_scoring_answer'})]:
            ms=previous.scope(self.plan,slug,validate_plan=q.validate)['essay_exam_resources']
            self.assertTrue(missing.isdisjoint({m['role'] for m in ms}))
    def test_missing_source_fails_closed(self):
        with tempfile.TemporaryDirectory() as p:
            with self.assertRaises(FileNotFoundError):q.verify_sources(self.plan,Path(p))

if __name__=='__main__':unittest.main()
