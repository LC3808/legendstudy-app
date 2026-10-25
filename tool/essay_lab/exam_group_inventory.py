"""Compare canonical whole-exam coverage without granting runtime approval."""
from collections import Counter


def summarize(snapshot, prior_questions):
    prior = {q['question_id']: q for q in prior_questions}
    materials = {m['exam_id']: m for m in snapshot['materials']}
    result = []
    for exam in snapshot['exams']:
        questions = [q for q in snapshot['questions'] if q['exam_id'] == exam['exam_id']]
        ids = {q['question_id'] for q in questions}
        if len(ids) != len(questions) or len(ids) != exam['registered_questions']:
            raise ValueError('CANONICAL_QUESTION_SET_MISMATCH')
        approved = set(exam.get('approved_question_ids') or [])
        if not approved <= ids:
            raise ValueError('APPROVAL_OUTSIDE_CANONICAL_EXAM')
        old = [prior.get(qid, {}) for qid in ids]
        reasons = []
        if not ids:
            reasons.append('NO_REGISTERED_QUESTIONS')
        if exam['exam_id'] not in materials:
            reasons.append('RUNTIME_SOURCE_MAPPING_NOT_CONNECTED')
        if ids and not all(q.get('profile_mapped') for q in old):
            reasons.append('PROFILE_MAPPING_INCOMPLETE')
        # Old passes are reuse candidates, never a claim of current input validity.
        if ids and not all(q.get('input_pass') for q in old):
            reasons.append('WHOLE_EXAM_INPUT_NOT_VALIDATED')
        if approved != ids or not exam['runtime_policy'] or not ids:
            reasons.append('WHOLE_EXAM_RUNTIME_NOT_APPROVED')
        result.append(dict(**exam, question_ids=sorted(ids),
            existing_approved_questions=len(approved),
            prior_input_pass=sum(bool(q.get('input_pass')) for q in old),
            whole_exam_approval=bool(ids and ids == approved and exam['runtime_policy']),
            current_input_pass=None, public_whole_exam_verified=False,
            blockers=reasons, activation_granted=False))
    summary = {}
    for university in sorted({e['slug'] for e in result}):
        exams = [e for e in result if e['slug'] == university]
        summary[university] = dict(registered_exams=len(exams),
            nonempty_exams=sum(bool(e['question_ids']) for e in exams),
            questions=sum(len(e['question_ids']) for e in exams),
            whole_exam_approvals=sum(e['whole_exam_approval'] for e in exams),
            approved_questions=sum(e['existing_approved_questions'] for e in exams),
            blockers=dict(Counter(b for e in exams for b in e['blockers'])))
    return dict(exams=result, by_university=summary, production_writes=0,
                provider_calls=0, activation_granted=False)
