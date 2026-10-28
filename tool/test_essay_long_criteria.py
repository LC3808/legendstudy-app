"""Long official input regression. Synthetic text/transport only; no network."""
import tempfile
import unittest
from copy import deepcopy
from dataclasses import replace
from unittest.mock import patch

from tool.test_essay_live_worker import fixture
from tool.test_essay_material_execution import MaterialExecutionTests
from tool.essay_lab.live_worker import Invalid, package, text
from tool.essay_lab.material_runtime import prepare_claimed_material, execute_reviewed_material_exam
from tool import test_essay_session_retry as session_fixture
from tool import test_essay_reviewed_runtime as worker_fixture
from tool.essay_lab.live_worker import digest


class LongCriteriaTests(unittest.TestCase):
    def test_official_input_preserved_at_incident_length_and_existing_evidence_limit(self):
        for length in (4000, 4001, 4576, 100000):
            with self.subTest(length=length):
                claim, cache, _ = fixture()
                label = '공' * length
                cache['criteria'][0]['label'] = label
                original = deepcopy(cache)
                self.assertEqual(package(claim, cache)['criteria'][0]['label'], label)
                self.assertEqual(cache, original)

    def test_invalid_input_and_general_text_limit_stay_closed(self):
        for label in ('공' * 100001, '', '  ', None, 42):
            claim, cache, _ = fixture()
            cache['criteria'][0]['label'] = label
            with self.assertRaisesRegex(Invalid, 'TEXT'):
                package(claim, cache)
        with self.assertRaisesRegex(Invalid, 'TEXT'):
            text('공' * 4001)
        claim, cache, _ = fixture()
        cache['criteria'][0]['binding'] = {'id': 'foreign', 'version': 1}
        with self.assertRaisesRegex(Invalid, 'CRITERION_VERSION'):
            package(claim, cache)

    def material(self, args):
        mapping = args['package']['questions'][0]['source_page_references'][-1]
        mapping['evidenceText'] = '공' * 4576

    def test_two_question_claim_preparation_keeps_full_frozen_criteria(self):
        with tempfile.TemporaryDirectory() as root:
            args, requests, settled = MaterialExecutionTests().fixture(root)
            self.material(args)
            second = deepcopy(args['package']['questions'][0])
            second.update(question_id='question-2', source_key='source:question-2')
            for mapping in second['source_page_references']:
                mapping['questionId'] = 'question-2'
            args['package']['questions'].append(second)
            args['registry']['exams'][0]['questions'].append(
                {'id': 'question-2', 'sourceKey': 'source:question-2'})
            version = 'material-16-' + 'f' * 64
            claim = dict(run_id='synthetic-run', subject_id='owner', lease_token='lease',
                snapshot=dict(ownerId='owner', runtime=dict(package_digest='f'*64,
                    binding=args['binding'], regime=args['regime'], evaluation_type='humanities'),
                    answers=[dict(questionId=q, body='합성 답안', rubricVersion=version,
                        evidenceVersion=version) for q in ('question', 'question-2')]))
            questions, caches = prepare_claimed_material(claim, args['package'], args['registry'])
            self.assertEqual(len(questions), 2)
            self.assertTrue(all(c['criteria'][0]['label'] == '공'*4576 for c in caches.values()))
            self.assertEqual(requests + settled, [])

    def test_long_material_completes_with_mock_provider_and_replay_does_not_redispatch(self):
        with tempfile.TemporaryDirectory() as root:
            args, requests, settled = MaterialExecutionTests().fixture(root)
            self.material(args)
            for _ in range(2):
                self.assertEqual(execute_reviewed_material_exam(**args), 'completed')
            self.assertEqual(len(requests), 1)
            self.assertEqual(settled[0], settled[1])
            self.assertFalse(settled[0]['failed'])


class LongCriteriaAsyncTests(unittest.IsolatedAsyncioTestCase):
    async def test_two_long_questions_checkpoint_continue_complete_and_duplicate(self):
        original = worker_fixture.RuntimeTests.fixture

        def long_fixture(test, mode='ok'):
            result = original(test, mode)
            worker = result[0]
            worker.cache['criteria'][0]['label'] = '공' * 4576
            worker.permit = replace(worker.permit, cache_sha256=digest(worker.cache))
            return result

        journal = session_fixture.Journal()
        settled = []
        with patch.object(worker_fixture.RuntimeTests, 'fixture', long_fixture):
            for index, expected in enumerate(('continue', 'completed', 'completed')):
                run, requests = session_fixture.SessionRetryTests().prepare(
                    ['ok', 'ok'], journal, {}, settled, budget=1)
                self.assertEqual(await run(), expected)
                self.assertEqual([len(r) for r in requests],
                                 [1, 0] if index == 0 else [0, 1] if index == 1 else [0, 0])
            self.assertEqual(journal.rows['q0']['payload']['state'], 'completed')
            self.assertEqual(journal.rows['q1']['payload']['state'], 'completed')
            self.assertEqual(journal.rows['final']['state'], 'checkpoint')
            self.assertEqual(settled[0], settled[1])


if __name__ == '__main__':
    unittest.main()
