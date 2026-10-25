"""Compare Owner research with a read-only Registry snapshot; never grants approval.

Survey rows may contain multiple sittings. Parent-question counts and answer-unit
counts are deliberately separate. Research is not scoring evidence or an ID source.
"""
import argparse
import json
import re
from collections import Counter
from pathlib import Path

UNIVERSITIES = {
    '중앙대': 'ffad67a6-107f-47b7-a1cb-ab61687ffb9f',
    '성균관대': '4acee829-94d4-5f8a-b440-a72e423d439f',
    '경희대': 'b401cc24-dd17-575e-8ac6-0fd8c9c8405d',
}


def track_key(value):
    if '경영경제' in value:
        return 'business'
    if '의' in value and ('약' in value or '학' in value):
        return 'medical'
    if any(x in value for x in ('인문', '언어', '체육')):
        return 'humanities'
    if '사회' in value:
        return 'social'
    if any(x in value for x in ('수리', '자연')):
        return 'math'
    return value.replace(' ', '')


def session(value):
    found = re.search(r'([123])교시', value)
    return found[1] if found else None


def compare(surveys, snapshot):
    records = []
    summary = {}
    for school, university_id in UNIVERSITIES.items():
        survey = surveys[school]
        registry = [e for e in snapshot['exams']
                    if e['university_id'] == university_id]
        school_rows = []
        for exam in survey['exams']:
            # Actual 2024–26 only. Guidance/2027 mocks never replace actual exams.
            assert exam['year'] in (2024, 2025, 2026)
            for sitting in exam['set_list']:
                candidates = [e for e in registry
                              if e['admission_year'] == exam['year']
                              and e['exam_kind'] == 'admission'
                              and track_key(e['field_or_division'] or '') == track_key(exam['track_key'])]
                if session(sitting):
                    candidates = [e for e in candidates
                                  if session(' '.join(str(e.get(k) or '') for k in ('session_label', 'exam_name'))) == session(sitting)
                                  # Legacy Central humanities/business have one sitting per track.
                                  or (school == '중앙대' and track_key(exam['track_key']) in ('humanities', 'business')
                                      and not session(e['exam_name']))]
                matches = [q for q in survey['questions']
                           if q['exam_id'] == exam['exam_id'] and q['set_name'] == sitting]
                issues = []
                target = candidates[0] if len(candidates) == 1 else None
                canonical_questions = []
                if not candidates:
                    issues.append('A_EXAM_ABSENT')
                elif len(candidates) != 1:
                    issues.append('A_AMBIGUOUS_EXAM')
                else:
                    canonical_questions = [q for q in snapshot['questions'] if q['essay_exam_id'] == target['id']]
                    if not canonical_questions:
                        issues.append('B_NO_REGISTERED_QUESTIONS')
                    elif len(canonical_questions) != exam['main_count']:
                        # E.g. medical subject alternatives are stored as separate parents.
                        issues.append('B_PARENT_COUNT_OR_OPTION_GROUP_REVIEW')
                    if exam['response_count'] != exam['main_count']:
                        issues.append('C_D_SUBQUESTION_ANSWER_UNITS_UNVERIFIED')
                    if target.get('runtime_policy') is None:
                        issues.append('E_RUNTIME_MATERIAL_NOT_APPROVED')
                structural = [i for i in issues if not i.startswith('E_')]
                row = dict(school=school, survey_exam_id=exam['exam_id'], year=exam['year'],
                           kind='admission', sitting=sitting, track=exam['track_key'],
                           registry_exam_id=target['id'] if target else None,
                           candidate_ids=[e['id'] for e in candidates],
                           survey_main_count=exam['main_count'], survey_sub_count=exam['sub_count'],
                           survey_answer_units=exam['response_count'],
                           registry_question_count=len(canonical_questions) if target else None,
                           registry_question_ids=[q['id'] for q in canonical_questions],
                           survey_answer_rows=matches, source_ids=exam['source_ids'],
                           character_limits=exam['character_limits'],
                           count_status='COUNT_MATCH_ONLY' if not structural else 'REVIEW',
                           issues=issues, official_structure_verified=False,
                           publication_approved=False)
                school_rows.append(row)
        counts = Counter(i for row in school_rows for i in row['issues'])
        summary[school] = dict(survey_rows=len(survey['exams']), survey_sittings=len(school_rows),
                               registry_exams=len(registry), registry_questions=sum(e['registered_questions'] for e in registry),
                               matched_identity=sum(bool(r['registry_exam_id']) for r in school_rows),
                               count_match_only=sum(r['count_status'] == 'COUNT_MATCH_ONLY' for r in school_rows),
                               structure_review=sum(r['count_status'] == 'REVIEW' for r in school_rows),
                               missing_exams=counts['A_EXAM_ABSENT'],
                               empty_exams=counts['B_NO_REGISTERED_QUESTIONS'],
                               response_unit_review=counts['C_D_SUBQUESTION_ANSWER_UNITS_UNVERIFIED'],
                               issues=dict(counts))
        records.extend(school_rows)
    return dict(scope='1-A only; survey actual 2024–26 vs Registry 2022+', summary=summary,
                exams=records, guidance_2027={s: v['guidance_2027'] for s, v in surveys.items()},
                production_writes=0, provider_calls=0, public_exam_increment=0)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', type=Path)
    args = parser.parse_args()
    surveys = {s: json.loads((args.root / (s + '.json')).read_text()) for s in UNIVERSITIES}
    result = compare(surveys, json.loads((args.root / 'production-registry.private.json').read_text()))
    (args.root / 'comparison.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(result['summary'], ensure_ascii=False))
