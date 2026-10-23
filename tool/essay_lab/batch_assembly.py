"""Assemble all Registry questions without changing approval or production state.

Source extraction, draft assembly and trusted runtime compilation are distinct.
Existing approved packages take precedence over old ingestion mappings. Newly
assembled source text remains unreviewed until a content-pinned review is supplied.
"""
import argparse
from collections import Counter
from copy import deepcopy
import json
from pathlib import Path
import re

from .live_worker import digest
from .material_runtime import material_readiness, load_reviewed_material
from .university_profile import map_profile, compose_material, _text_route
from .batch_inventory import PRESERVED_MATH_E2E


def registry_from_rows(rows, source_rows):
    refs = {r['question_id']: r for r in source_rows}
    exams = {}
    seen = set()
    for row in rows:
        qid = row['question_id']
        if qid in seen:
            raise ValueError('DUPLICATE_CANONICAL_QUESTION')
        seen.add(qid)
        eid = row['exam_id']
        exam = exams.setdefault(eid, dict(examId=eid, universityId=row['university_id'],
            year=row['admission_year'], kind=row['exam_kind'], track=row['field_or_division'],
            session=row['session_label'], campus=row['campus'], name=row['exam_name'],
            examKey=row['exam_key'], sourceHashes=[], questions=[]))
        for ref in refs.get(qid, {}).get('source_checks', []):
            if ref['role'] == 'question' and ref.get('source_hash'):
                exam['sourceHashes'].append(ref['source_hash'])
        exam['sourceHashes'] = sorted(set(exam['sourceHashes']))
        exam['questions'].append(dict(id=qid, sourceKey=row['question_key'],
                                     label=row['label'], order=row['display_order']))
    return {'exams': list(exams.values())}


def assemble_entry(row, source):
    """Lossless source mapping draft. Never relabel an example as a criterion."""
    refs = []
    for ref in source.get('source_checks', []):
        if not ref.get('text') or not ref.get('pages') or not ref.get('source_hash'):
            continue
        refs.append(dict(questionId=row['question_id'], sourceHash=ref['source_hash'],
            startPage=ref['pages'][0], endPage=ref['pages'][1], role=ref['role'],
            evidenceText=ref['text'], verification='NEEDS_REVIEW'))
    return dict(question_id=row['question_id'], source_key=row['question_key'],
                source_page_references=refs)


def source_risks(entry):
    risks = []
    for ref in entry['source_page_references']:
        text = ref['evidenceText']
        if ref['role'] in ('criteria', 'scoring') and re.search(r'예시\s*답안|모범\s*답안', text):
            risks.append('CRITERIA_CONTAINS_EXAMPLE_ANSWER')
        if ref['role'] == 'question':
            labels = set(re.findall(r'(?:문제|문항)\s*([1-9][0-9]*(?:[-－][1-9][0-9]*)?)', text))
            if len(labels) > 1:
                risks.append('QUESTION_SCOPE_REQUIRES_SPLIT')
        if re.search(r'[\ue000-\uf8ff\ufffd]', text):
            risks.append('GLYPH_REVIEW_REQUIRED')
    return sorted(set(risks))


def compile_all(rows, audit, profiles, approved, reviews=()):
    sources = {r['question_id']: r for r in audit}
    registry = registry_from_rows(rows, audit)
    exams = {e['examId']: e for e in registry['exams']}
    preserved = {}
    # Validate preserved packages using their canonical registry, never replace
    # their curated passages/images with the older broad ingestion pages.
    for item in approved:
        package = item['package']
        policy = item['policy']
        selected_registry = item.get('registry', registry)
        live_exam = exams.get(package['exam_id'])
        old_exam = next(e for e in selected_registry['exams'] if e['examId'] == package['exam_id'])
        if old_exam['universityId'] not in {e['universityId'] for e in exams.values()}:
            continue  # Preserve other universities; they are outside this input scope.
        if not live_exam or any(live_exam[k] != old_exam[k] for k in
                ('universityId', 'year', 'kind', 'track', 'session', 'campus')):
            raise ValueError('PRESERVED_CANONICAL_IDENTITY_DRIFT')
        live_questions = {q['id']: q['sourceKey'] for q in live_exam['questions']}
        if any(live_questions.get(q['question_id']) != q['source_key'] for q in package['questions']):
            raise ValueError('PRESERVED_CANONICAL_QUESTION_DRIFT')
        hosted, report = load_reviewed_material(package, selected_registry,
            pinned_digest=policy['package_digest'], binding=item['binding'],
            regime=policy['regime'], evaluation_type=policy['evaluation_type'],
            activation_approved=True)
        if not report['ready']:
            raise ValueError('PRESERVED_PACKAGE_VALIDATION_FAILED')
        for qid in hosted:
            preserved[qid] = dict(package_digest=policy['package_digest'],
                                 package_version=package['package_version'])
    review_map = {r['question_id']: r for r in reviews}
    if len(review_map) != len(reviews):
        raise ValueError('DUPLICATE_CONTENT_REVIEW')
    results, drafts, compiled = [], {}, {}
    for row in rows:
        qid = row['question_id']; exam = exams[row['exam_id']]
        source = sources.get(qid, {})
        entry = assemble_entry(row, source)
        reasons = list(source.get('problems', ['SOURCE_AUDIT_MISSING']))
        resolved = None; route = None; profile = None
        try:
            pinned = source.get('profile')
            pin = tuple(pinned[k] for k in ('profile_id', 'profile_version', 'profile_digest')) if pinned else None
            resolved = map_profile(profiles, exam, qid, pinned=pin)
            profile = next(p for p in profiles if p['content_sha256'] == resolved['profile_digest'])
            route = _text_route(profile, exam['examId'], qid)
        except Exception as error:
            reasons.append('PROFILE:' + str(error))
        package = dict(schema='essay-material-package-v1', exam_id=exam['examId'],
            university_id=exam['universityId'], package_version=1,
            verification_status='DRAFT', questions=[entry], rights_status={},
            exam_identity=dict(academic_year=exam['year'], exam_type=exam['kind'],
                               track=exam['track'], title=exam['name']))
        risks = source_risks(entry)
        draft = dict(package=package, profile_resolution=resolved, source_risks=risks,
                     source_audit_sha256=digest(source), registry_identity_sha256=digest(row))
        draft['content_sha256'] = digest(draft)
        drafts[qid] = draft
        passed = qid in preserved
        # Historical Math receipt is keyed by the canonical live question ID.
        # Essay-only package registries need not contain this Math question.
        # Preserve that evidence without counting a fresh Math input check.
        math_preserved = qid in PRESERVED_MATH_E2E
        review = review_map.get(qid)
        if review and not passed:
            try:
                if review['draft_sha256'] != draft['content_sha256']:
                    raise ValueError('CONTENT_REVIEW_DRIFT')
                if review.get('status') != 'REVIEWED' or not review.get('review_evidence'):
                    raise ValueError('CONTENT_REVIEW_REQUIRED')
                candidate = deepcopy(review['package'])
                if candidate['exam_id'] != exam['examId'] or [q['question_id'] for q in candidate['questions']] != [qid]:
                    raise ValueError('CONTENT_REVIEW_IDENTITY_MISMATCH')
                candidate, resolution = compose_material(candidate, registry, qid, [profile])
                # Local compilation digest only. Production uses Postgres jsonb::text.
                candidate.pop('package_digest', None)
                candidate['package_digest'] = digest(candidate)
                hosted, report = load_reviewed_material(candidate, registry,
                    pinned_digest=candidate['package_digest'], binding={}, regime='held',
                    evaluation_type=route, university_profiles=[profile])
                passed = report['ready'] and qid in hosted
                if passed:
                    compiled[qid] = dict(package=candidate, profile_resolution=resolution,
                                         review_evidence=review['review_evidence'])
                else:
                    reasons.extend(x['code'] for x in report['issues'])
            except Exception as error:
                reasons.append('COMPILATION:' + str(error))
        if not passed:
            reasons.extend(risks)
            reasons.extend(x['code'] + (':' + x['role'] if 'role' in x else '')
                           for x in material_readiness(package, registry))
            if route not in ('humanities', 'business'):
                reasons.append('PHYSICAL_MATH_OR_SPECIAL_BINDING_REQUIRED')
        scope = 2022 <= exam['year'] <= 2026 or (exam['year'] == 2027 and exam['kind'] == 'mock')
        results.append(dict(university=row['slug'], exam_id=exam['examId'], question_id=qid,
            in_requested_year_scope=scope, profile_mapped=resolved is not None, route=route,
            source_mapping_count=len(entry['source_page_references']),
            official_mapping_present=any(m['role'] in ('criteria','scoring','explanation') for m in source.get('source_checks', [])),
            official_text_assembled=any(m['role'] in ('criteria','scoring','explanation') for m in entry['source_page_references']),
            draft_sha256=draft['content_sha256'], input_pass=passed,
            preserved_runtime=preserved.get(qid),
            preserved_math_e2e=math_preserved,
            evaluation_scope='FULL_EVALUATION' if passed or math_preserved else 'NEEDS_REVIEW',
            activation_candidate=bool(qid in compiled and scope and review.get('representative_contract_pass') is True),
            individual_e2e='NOT_RECOUNTED', public_availability='SEPARATE_RUNTIME_CHECK',
            reasons=[] if passed else sorted(set(reasons))))
    groups = {}
    for row in results:
        draft = drafts[row['question_id']]
        p = draft['profile_resolution'] or {}
        e = exams[row['exam_id']]
        key = (row['university'], row['route'], e['year'], e['kind'], e['track'],
               p.get('profile_id'), p.get('profile_version'), p.get('profile_digest'))
        groups.setdefault(key, []).append(row['question_id'])
    summary = {}
    for university in sorted({r['university'] for r in results}):
        group = [r for r in results if r['university'] == university]
        summary[university] = dict(exams=len({r['exam_id'] for r in group}), questions=len(group),
            profiles=sum(r['profile_mapped'] for r in group),
            official_mappings=sum(r['official_mapping_present'] for r in group),
            official_text_assembled=sum(r['official_text_assembled'] for r in group),
            input_pass=sum(r['input_pass'] for r in group),
            candidates=sum(r['activation_candidate'] for r in group),
            scopes=dict(Counter(r['evaluation_scope'] for r in group)))
    return dict(registry=registry, questions=results, drafts=drafts, compiled=compiled,
        groups=[dict(university=k[0], route=k[1], year=k[2], kind=k[3], track=k[4],
            profile_id=k[5], profile_version=k[6], profile_digest=k[7], question_ids=v)
            for k,v in groups.items()], by_university=summary,
        provider_calls=0, production_writes=0, activation_granted=False)


def main():
    parser = argparse.ArgumentParser()
    for flag in ('registry-rows', 'source-audit', 'profiles-root', 'approved', 'output'):
        parser.add_argument('--' + flag, type=Path, required=True)
    parser.add_argument('--reviews', type=Path)
    args = parser.parse_args()
    read = lambda p: json.loads(p.read_text())
    audit = read(args.source_audit)['questions']
    pins = { (r['profile']['profile_id'], r['profile']['profile_version'])
             for r in audit if r.get('profile') }
    profiles = [read(args.profiles_root / pid.removeprefix('uep/') / f'v{v}.json') for pid,v in sorted(pins)]
    result = compile_all(read(args.registry_rows), audit, profiles, read(args.approved),
                         read(args.reviews) if args.reviews else [])
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'by_university':result['by_university'], 'groups':len(result['groups']),
                      'compiled':len(result['compiled'])}, ensure_ascii=False))


if __name__ == '__main__':
    main()
