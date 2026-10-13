"""Real reviewed worker + disk journal; synthetic Provider, no operating Credit."""
import tempfile
import unittest
import concurrent.futures
import multiprocessing
from dataclasses import replace
from copy import deepcopy
from tool.test_essay_reviewed_runtime import RuntimeTests
from tool.essay_lab.durable_exam import DurableExamRunner
from tool.essay_lab.durable_journal import DurableJournal
from tool.essay_lab.live_worker import Invalid, Unknown, digest


def competing_exam(root):
    run, _, requests, summaries, _ = DurableExamTests().fixture(root)
    return run(), sum(len(r) for r in requests), len(summaries)


class DurableExamTests(unittest.TestCase):
    def test_competing_processes_dispatch_each_child_and_synthesis_once(self):
        with tempfile.TemporaryDirectory() as root:
            with concurrent.futures.ProcessPoolExecutor(
                    4, mp_context=multiprocessing.get_context('spawn')) as pool:
                results = list(pool.map(competing_exam, [root] * 8))
            self.assertEqual([r[0] for r in results], ['completed'] * 8)
            self.assertEqual(sum(r[1] for r in results), 2)
            self.assertEqual(sum(r[2] for r in results), 1)

    def fixture(self, root, modes=('ok', 'ok')):
        questions, workers, requests = [], {}, []
        for index, mode in enumerate(modes):
            worker, _, req, _, claim, _ = RuntimeTests().fixture(mode)
            evaluation = f'evaluation-{index}'
            worker.permit = replace(worker.permit, evaluation_id=evaluation)
            workers[evaluation] = worker
            requests.append(req)
            questions.append(dict(questionId=str(index), rubricVersion='r1', evidenceVersion='e1',
                                  evaluationId=evaluation, claim=claim))
        summaries, settled = [], []

        def build(channel, checkpoint):
            worker = workers[channel.evaluation_id]
            worker.rpc = channel
            worker.checkpoint = checkpoint
            return worker

        def summarize(results):
            summaries.append(results)
            return 'Synthetic reviewed summary'

        def finalize(record):
            settled.append(record)
            return 'failed' if record['failed'] else 'completed'

        def run(**overrides):
            args = dict(run_id='run', subject_id='owner', exam_id='exam', questions=questions,
                        authorize=lambda _: True, build_worker=build, summarize=summarize, finalize=finalize)
            args.update(overrides)
            return DurableExamRunner(DurableJournal(root)).execute(**args)
        return run, questions, requests, summaries, settled

    def test_completed_restart_reuses_children_summary_and_final_record(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, settled = self.fixture(root)
            self.assertEqual(run(), 'completed')
            self.assertEqual(run(), 'completed')
            self.assertEqual([len(r) for r in requests], [1, 1])
            self.assertEqual(len(summaries), 1)
            self.assertEqual(settled[0], settled[1])  # DB finalize must be idempotent.

    def test_lost_finalize_response_only_replays_exact_record(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, _ = self.fixture(root)
            def lost(_): raise Unknown()
            with self.assertRaises(Unknown): run(finalize=lost)
            self.assertEqual(run(), 'completed')
            self.assertEqual([len(r) for r in requests], [1, 1])
            self.assertEqual(len(summaries), 1)

    def test_unknown_provider_never_reruns_or_refunds(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, settled = self.fixture(root, ('timeout', 'ok'))
            self.assertEqual(run(), 'reconciling')
            self.assertEqual(run(), 'reconciling')
            self.assertEqual([len(r) for r in requests], [1, 0])
            self.assertEqual(summaries + settled, [])

    def test_partial_failure_has_one_failed_record_and_no_later_dispatch(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, settled = self.fixture(root, ('ok', 'invalid', 'ok'))
            self.assertEqual(run(), 'failed')
            self.assertEqual(run(), 'failed')
            self.assertEqual([len(r) for r in requests], [1, 1, 0])
            self.assertEqual(summaries, [])
            self.assertEqual(settled[0], {'examId': 'exam', 'result': None, 'failed': True})

    def test_snapshot_owner_and_lifecycle_rechecked_on_resume(self):
        with tempfile.TemporaryDirectory() as root:
            run, questions, _, _, settled = self.fixture(root)
            run()
            for override in ({'subject_id': 'other'}, {'exam_id': 'foreign'}, {'authorize': lambda _: False}):
                with self.assertRaises(Invalid): run(**override)
            changed = deepcopy(questions)
            changed[0]['rubricVersion'] = 'r2'
            with self.assertRaises(Invalid): run(questions=changed)
            self.assertEqual(len(settled), 1)

    def test_interrupted_synthesis_does_not_repeat_provider_or_synthesis(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, settled = self.fixture(root)
            def lost(_): raise Unknown()
            with self.assertRaises(Unknown): run(summarize=lost)
            with self.assertRaisesRegex(Invalid, 'SYNTHESIS_RECONCILIATION'): run()
            self.assertEqual([len(r) for r in requests], [1, 1])
            self.assertEqual(summaries + settled, [])

    def test_crash_after_review_checkpoint_recovers_child(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, _ = self.fixture(root)
            from unittest.mock import patch
            original = DurableJournal.write
            def fail_child(j, key, value):
                if key.endswith('-q0'): raise OSError('disk unavailable')
                return original(j, key, value)
            with patch.object(DurableJournal, 'write', fail_child):
                with self.assertRaises(OSError): run()
            self.assertEqual(run(), 'completed')
            self.assertEqual([len(r) for r in requests], [1, 1])
            self.assertEqual(len(summaries), 1)

    def test_claim_marker_survives_process_loss_without_dispatch(self):
        with tempfile.TemporaryDirectory() as root:
            run, _, requests, summaries, settled = self.fixture(root)
            j = DurableJournal(root)
            key = 'exam-' + digest('run') + '-q0'
            with j.lock(key): j.begin(key)
            self.assertEqual(run(), 'reconciling')
            self.assertEqual([len(r) for r in requests], [0, 0])
            self.assertEqual(summaries + settled, [])


if __name__ == '__main__': unittest.main()
