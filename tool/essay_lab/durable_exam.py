"""Persistent orchestration for the existing reviewed exam adapter, not an evaluator.

Trusted host inputs only. One persistent host serializes a run across processes.
authorize must recheck owner, lifecycle, reservation and lease on EVERY invocation;
finalize must repeat these checks atomically with existing Ledger settlement.
This adapter does not grant permissions, create reservations or enable a service.
"""
from copy import deepcopy
from .live_worker import digest, require
from .exam_runtime import ExamQuestionChannel, execute_exam, resume_exam


class DurableExamRunner:
    def __init__(self, journal):
        self.journal = journal

    def execute(self, *, run_id, subject_id, exam_id, questions, authorize,
                build_worker, summarize, finalize):
        """questions contain questionId, rubricVersion, evidenceVersion,
        evaluationId and the frozen worker claim. Never accept these from HTTP.
        build_worker(channel, checkpoint) reuses ReviewedRuntimeWorker and must
        persist independent review receipts. summarize retains the reviewed exam
        synthesis contract; an ambiguous synthesis is NOT silently repeated.
        """
        require(all(isinstance(v, str) and v for v in (run_id, subject_id, exam_id)),
                'INVALID_EXAM_IDENTITY')
        questions = deepcopy(questions)
        require(bool(questions) and all(type(q) is dict and set(q) == {
            'questionId', 'rubricVersion', 'evidenceVersion', 'evaluationId', 'claim'
        } for q in questions), 'INVALID_EXAM_QUESTION_SET')
        require(len({q['questionId'] for q in questions}) == len(questions) and
                len({q['evaluationId'] for q in questions}) == len(questions),
                'DUPLICATE_EXAM_CHANNEL')
        binding = dict(runId=run_id, subjectId=subject_id, examId=exam_id, questions=questions)
        binding_hash = digest(binding)
        prefix = 'exam-' + digest(run_id)
        j = self.journal

        def read(suffix):
            with j.lock(prefix + suffix):
                return j.read(prefix + suffix)

        def start(suffix):
            with j.lock(prefix + suffix):
                return j.begin(prefix + suffix)

        def save(suffix, value):
            with j.lock(prefix + suffix):
                j.begin(prefix + suffix)
                j.write(prefix + suffix, deepcopy(value))

        # Authorization precedes journal reads, including cached finalization.
        with j.lock(prefix):
            require(authorize(deepcopy(binding)) is True, 'EXAM_ACCESS_DENIED')
            frozen = read('-binding')
            if frozen is None:
                require(start('-binding'), 'EXAM_RECONCILIATION_REQUIRED')
                save('-binding', {'sha256': binding_hash})
            else:
                require(frozen == {'sha256': binding_hash}, 'EXAM_SNAPSHOT_CHANGED')
            final = read('-final')
            if final is not None:
                return resume_exam(exam_id, final, finalize)

            staged = []
            checkpoint_by_channel = {}
            for index, question in enumerate(questions):
                suffix = '-q' + str(index)
                claim = question['claim']
                evaluation = question['evaluationId']

                def completed(args, claim=claim, evaluation=evaluation):
                    require(type(args) is dict and set(args) == {
                        'p_evaluation', 'p_run', 'p_token', 'p_output'
                    } and args['p_evaluation'] == evaluation and
                        args['p_run'] == claim['run_id'] and
                        args['p_token'] == claim['lease_token'] and
                        type(args['p_output']) is dict, 'FOREIGN_EXAM_CHECKPOINT')
                    return dict(evaluation_id=evaluation, claim_sha256=digest(claim),
                                state='completed', output=deepcopy(args['p_output']))

                def event(name, args, suffix=suffix, claim=claim,
                          evaluation=evaluation, completed=completed):
                    if name == 'claim':
                        require(start(suffix), 'EXAM_RECONCILIATION_REQUIRED')
                    elif name == 'telemetry':
                        save(suffix + '-usage', args)
                    elif name == 'question_success':
                        require(read(suffix + '-reviewed') == args, 'REVIEWED_CHECKPOINT_REQUIRED')
                        save(suffix, completed(args))
                    elif name in ('question_failure', 'question_unknown'):
                        save(suffix, dict(evaluation_id=evaluation, claim_sha256=digest(claim),
                                         state='failed' if name == 'question_failure' else 'reconciling',
                                         output=None))
                    else:
                        raise ValueError('INVALID_EXAM_EVENT')

                channel = ExamQuestionChannel(evaluation, claim, event)
                saved = read(suffix)
                reviewed = read(suffix + '-reviewed')
                if saved is not None:
                    channel.restore(saved)
                elif reviewed is not None:
                    # Crash after independent review checkpoint, before child success.
                    recovered = completed(reviewed)
                    save(suffix, recovered)
                    channel.restore(recovered)
                else:
                    # Distinguish absent from dispatched-but-unknown without creating
                    # a new marker. Pending means Provider may already have run.
                    with j.lock(prefix + suffix):
                        pending = j.exists(prefix + suffix)
                    if pending:
                        channel.restore(dict(evaluation_id=evaluation, claim_sha256=digest(claim),
                                             state='processing', output=None))

                def checkpoint(args, suffix=suffix, completed=completed):
                    completed(args)
                    save(suffix + '-reviewed', args)
                checkpoint_by_channel[channel] = checkpoint
                staged.append({k: question[k] for k in ('questionId', 'rubricVersion', 'evidenceVersion')} |
                              {'channel': channel})

            def factory(channel):
                checkpoint = checkpoint_by_channel[channel]
                worker = build_worker(channel, checkpoint)
                require(worker.checkpoint is checkpoint, 'DURABLE_CHECKPOINT_REQUIRED')
                return worker

            def synthesis(results):
                saved = read('-summary')
                if saved is not None:
                    require(saved.get('input') == digest(results), 'EXAM_SYNTHESIS_CHANGED')
                    return saved['summary']
                require(start('-summary'), 'EXAM_SYNTHESIS_RECONCILIATION_REQUIRED')
                summary = summarize(deepcopy(results))
                require(type(summary) is str and bool(summary.strip()), 'EXAM_SYNTHESIS_REQUIRED')
                save('-summary', {'input': digest(results), 'summary': summary})
                return summary

            return execute_exam(exam_id, staged, factory, synthesis,
                                lambda record: save('-final', record), finalize)
