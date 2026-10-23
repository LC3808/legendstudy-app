"""Read-only full inventory; inherited profiles never imply evaluation readiness."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

from .material_runtime import load_reviewed_material
from .university_profile import map_profile, validate


# Preserved operating evidence, not a fresh Math runtime check. See
# wiki/phase3-service-20261022.md and university-profile-production-e2e-20261023.md.
PRESERVED_MATH_E2E = {'cea40cf3-dc05-507a-a6eb-fd5e1e1847bb'}


def classify(identity, input_result, preserved_math=False):
    if identity and ((input_result or {}).get('passed') or preserved_math):
        return 'FULL_EVALUATION'
    return 'NEEDS_REVIEW'


def inventory(root, evidence):
    rows = json.loads((root / 'question-readiness-512.json').read_text())
    inheritance = json.loads((root / 'reference-recovery-20261023/base-inheritance-512.json').read_text())
    mapped = {x['question_id']: x for x in inheritance['mapped']}
    actual = {x['question_id']: x for x in json.loads((evidence / 'batch-production-identity.private.json').read_text())}
    registry = json.loads((evidence / 'worker-registry-swu-v15.json').read_text())
    runtime = json.loads((evidence / 'batch-runtime-packages.private.json').read_text())
    assert len(rows) == len({x['question_id'] for x in rows}) == 512
    assert len(mapped) == 423
    assembled = {}
    for item in runtime:
        package, policy = item['package'], item['policy']
        try:
            hosted, report = load_reviewed_material(package, registry,
                pinned_digest=policy['package_digest'], binding=item['binding'],
                regime=policy['regime'], evaluation_type=policy['evaluation_type'],
                activation_approved=True)
            for qid in hosted:
                assembled[qid] = {'passed': bool(report['ready']),
                    'package_digest': policy['package_digest'], 'issues': report['issues']}
        except Exception as error:
            for question in package.get('questions', []):
                assembled[question['question_id']] = {'passed': False, 'reason': str(error)}
    hashes = {}
    profiles = {}
    result = []
    for row in rows:
        qid = row['question_id']
        live = actual.get(qid)
        identity = bool(live and all(live.get(k) == row.get(k)
            for k in ('exam_id', 'admission_year', 'exam_kind', 'field_or_division')))
        reasons = [] if identity else ['CANONICAL_IDENTITY_MISMATCH']
        mapping = mapped.get(qid)
        profile_valid = False
        if mapping:
            key = (mapping['profile_id'], mapping['profile_version'])
            try:
                if key not in profiles:
                    path = root / 'profiles' / key[0].removeprefix('uep/') / f'v{key[1]}.json'
                    profile = json.loads(path.read_text())
                    validate(profile)
                    profiles[key] = profile
                profile = profiles[key]
                exam = dict(examId=row['exam_id'], universityId=live['university_id'],
                    year=row['admission_year'], kind=row['exam_kind'],
                    track=row['field_or_division'], questions=[{'id': qid}])
                resolved = map_profile([profile], exam, qid)
                profile_valid = resolved['profile_digest'] == mapping['profile_digest']
                if not profile_valid:
                    reasons.append('PROFILE_DIGEST_DRIFT')
            except Exception as error:
                reasons.append('PROFILE_RECHECK:' + str(error))
        else:
            reasons.append('PROFILE_NOT_INHERITED')
        source_refs = row.get('evidence', [])
        checked = []
        for ref in source_refs:
            path = Path(ref['source_path']) if ref.get('source_path') else None
            if path and path.is_file():
                if str(path) not in hashes:
                    hashes[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
                matched = hashes[str(path)] == ref.get('source_hash')
            else:
                matched = False
            checked.append({'role': ref['role'], 'hash_matches': matched,
                'pages': ref.get('pages'), 'pua_count': ref.get('pua_count')})
        input_result = assembled.get(qid)
        preserved_math = qid in PRESERVED_MATH_E2E
        scope = classify(identity, input_result, preserved_math)
        full = scope == 'FULL_EVALUATION'
        if not full:
            reasons.append('FULL_INPUT_ASSEMBLY_NOT_VERIFIED')
        # No diagnostic execution contract/presentation is yet verified. A mapped
        # profile is a diagnostic candidate, not a ready or paid diagnostic service.
        # Preserved Math success does not increment fresh input verification.
        result.append(dict(university=row['university'], exam_id=row['exam_id'], question_id=qid,
            year=row['admission_year'], exam_kind=row['exam_kind'], track=row['field_or_division'],
            identity_verified=identity, profile_mapped=bool(mapping), profile_rechecked=profile_valid,
            profile_id=mapping.get('profile_id') if mapping else None,
            profile_version=mapping.get('profile_version') if mapping else None,
            local_question_pdf_hash_verified=any(x['role']=='question' and x['hash_matches'] for x in checked),
            official_mapping_present=any(x['role'] in {'criteria','scoring','explanation'} for x in checked),
            source_checks=checked, input_validation=input_result or {'passed':False,'reason':'NOT_ASSEMBLED'},
            evaluation_scope=scope, scope_basis=('PRESERVED_MATH_E2E' if preserved_math else 'CURRENT_ESSAY_INPUT_CHECK'), diagnostic_candidate=bool(profile_valid and not full),
            diagnostic_execution_verified=False, activation_candidate=False,
            reasons=reasons, individual_e2e=('PRESERVED_SUCCESS' if preserved_math else 'NOT_RECOUNTED'), public_availability='SEPARATE_RUNTIME_CHECK'))
    summary = {}
    for university in sorted({x['university'] for x in result}):
        group = [x for x in result if x['university']==university]
        summary[university] = dict(exams=len({x['exam_id'] for x in group}), questions=len(group),
            identity_verified=sum(x['identity_verified'] for x in group),
            profile_mapped=sum(x['profile_mapped'] for x in group),
            profile_rechecked=sum(x['profile_rechecked'] for x in group),
            official_mapping_present=sum(x['official_mapping_present'] for x in group),
            input_verified=sum(x['input_validation']['passed'] for x in group),
            scopes=dict(Counter(x['evaluation_scope'] for x in group)))
    return {'status':'PARTIAL_INVENTORY_NOT_SERVICE_COMPLETION', 'questions':result,
        'by_university':summary, 'total':len(result), 'provider_calls':0,'production_writes':0,
        'limitations':['Original inventory page mappings are not newly reviewed official evidence.',
            'Local PDF hashes are not authenticated WEB/APP PDF delivery.',
            'One prior Math E2E scope is preserved; Math runtime input is not freshly verified.',
            'DIAGNOSTIC service contract/presentation not verified; no automatic promotion.',
            'Unassembled questions remain NEEDS_REVIEW; this is not a complete compilation pass.']}


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--profiles-root',type=Path,required=True)
    parser.add_argument('--evidence-root',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    output=inventory(args.profiles_root,args.evidence_root)
    args.output.write_text(json.dumps(output,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(output['by_university'],ensure_ascii=False,indent=2))
