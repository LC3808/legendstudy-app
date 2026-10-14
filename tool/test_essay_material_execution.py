"""Reviewed material -> existing Worker -> durable exam. Fake transport, no E2E claim."""
import tempfile
import unittest
from copy import deepcopy
from tool import test_essay_reviewed_runtime as runtime_fixture
from tool.essay_lab.material_runtime import load_reviewed_material, execute_reviewed_material_exam
from tool.essay_lab.durable_journal import DurableJournal
from tool.essay_lab.live_worker import Invalid


class MaterialExecutionTests(unittest.TestCase):
    def fixture(self, root, mode='ok'):
        worker, _, requests, _, claim, out = runtime_fixture.RuntimeTests().fixture(mode)
        exam = dict(examId='exam', universityId='university', year=2024,
            kind='admission', track='humanities', session='afternoon2', campus=None,
            name='Synthetic exam', sourceHashes=['a'*64],
            questions=[dict(id='question', sourceKey='source:question')])
        material = dict(schema='essay-material-package-v1', verification_status='VERIFIED_MANIFEST',
            package_digest='f'*64, package_version=16, exam_id='exam', university_id='university',
            exam_identity=dict(academic_year=2024, exam_type='admission', track='humanities', title='Synthetic exam'),
            rights_status={'a'*64: {'providerTransmission':'APPROVED'}},
            questions=[dict(question_id='question', source_key='source:question',
                source_page_references=[dict(questionId='question', sourceHash='a'*64,
                    role=role, startPage=1, endPage=1, evidenceText='Synthetic '+role,
                    verification='VERIFIED') for role in ('question','shared_passage','intent','criteria')])])
        policy = dict(pinned_digest='f'*64, binding=worker.permit.binding,
            regime='essay-v1.3/policy/'+'b'*64, evaluation_type='humanities')
        hosted, _ = load_reviewed_material(material, {'exams':[exam]},
            **policy, activation_approved=True)
        cache = hosted['question'].frozen_cache
        claim['input']['evidence'] = [e['binding'] for e in cache['evidence']]
        claim['input']['criteria'] = [c['binding'] for c in cache['criteria']]
        criterion = cache['criteria'][0]['binding']['id']
        evidence = cache['evidence'][-1]['binding']['id']
        out['dimensions'][0].update(criterion_id=criterion, evidence_ids=[evidence])
        out['improvements'][0]['evidence_ids'] = [evidence]
        version = 'material-16-'+'f'*64
        selected = dict(questionId='question', rubricVersion=version, evidenceVersion=version,
            evaluationId='evaluation', claim=claim)
        settlements = []
        args = dict(package=material, registry={'exams':[exam]}, **policy,
            activation_approved=True, frozen_run=dict(run_id='run', subject_id='owner',
                exam_id='exam', questions=[selected]), journal=DurableJournal(root),
            authorize=lambda _:True, provider=worker.provider, reviewer=worker.reviewer,
            review_source=worker.review_source, receipt_sink=worker.receipt_sink,
            finalize=lambda record: settlements.append(record) or 'completed', clock=lambda:100)
        return args, requests, settlements

    def test_material_reaches_provider_and_existing_result_without_second_dispatch(self):
        with tempfile.TemporaryDirectory() as root:
            args, requests, settlements = self.fixture(root)
            for _ in range(2):
                self.assertEqual(execute_reviewed_material_exam(**args), 'completed')
            self.assertEqual(len(requests), 1)
            self.assertIn('Synthetic question', requests[0]['input'])
            import json
            identity=json.loads(requests[0]['input'])['exam_identity']
            self.assertEqual(identity['exam_id'], 'exam')
            self.assertEqual(identity['question_id'], 'question')
            self.assertEqual(identity['academic_year'], 2024)
            self.assertEqual(settlements[0], settlements[1])
            result = settlements[0]['result']
            self.assertEqual(result['summary'], result['questions'][0]['evaluation']['summary'])
            self.assertEqual(result['questions'][0]['evaluation']['contract_version'], '1.3')

    def test_bad_package_or_permissions_block_before_provider(self):
        mutations = [
            lambda a:a.update(activation_approved=False),
            lambda a:a['package'].update(rights_status={}),
            lambda a:a['frozen_run'].update(exam_id='another-exam'),
            lambda a:a['frozen_run']['questions'][0].update(evidenceVersion='old'),
            lambda a:a['frozen_run']['questions'][0]['claim']['input'].update(criteria=[]),
            lambda a:a.update(reviewer=None),
        ]
        for change in mutations:
            with self.subTest(change=change), tempfile.TemporaryDirectory() as root:
                args, requests, settlements = self.fixture(root)
                change(args)
                with self.assertRaises(Invalid): execute_reviewed_material_exam(**args)
                self.assertEqual(requests+settlements, [])

    def test_invalid_later_question_blocks_whole_batch_before_dispatch(self):
        with tempfile.TemporaryDirectory() as root:
            args, requests, settlements = self.fixture(root)
            other = deepcopy(args['frozen_run']['questions'][0])
            other.update(questionId='foreign', evaluationId='second')
            args['frozen_run']['questions'].append(other)
            args['summarize'] = lambda _: 'Must not execute'
            with self.assertRaisesRegex(Invalid, 'QUESTION_NOT_IN_EXAM'):
                execute_reviewed_material_exam(**args)
            self.assertEqual(requests+settlements, [])

    def test_provider_timeout_stays_reconciling_without_settlement_or_retry(self):
        with tempfile.TemporaryDirectory() as root:
            args, requests, settlements = self.fixture(root, 'timeout')
            for _ in range(2):
                self.assertEqual(execute_reviewed_material_exam(**args), 'reconciling')
            self.assertEqual(len(requests), 1)
            self.assertEqual(settlements, [])

    def test_account_access_is_rechecked_before_cached_result(self):
        with tempfile.TemporaryDirectory() as root:
            args, requests, settlements = self.fixture(root)
            execute_reviewed_material_exam(**args)
            args['authorize'] = lambda _:False
            with self.assertRaisesRegex(Invalid, 'EXAM_ACCESS_DENIED'):
                execute_reviewed_material_exam(**args)
            self.assertEqual(len(requests), 1)
            self.assertEqual(len(settlements), 1)


if __name__ == '__main__': unittest.main()
