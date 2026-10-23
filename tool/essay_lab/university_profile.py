"""Private, deterministic profile composition. No network, activation or DB writes.
Inputs must come from reviewed server manifests, never from student requests.
"""
from copy import deepcopy
from .live_worker import digest, require

VERSION = 'university-profile-resolver-v1'


def profile_digest(profile):
    return digest({k: v for k, v in profile.items() if k != 'content_sha256'})


def _validate_inheritance_scope(scope):
    require(scope.get('review_status') == 'REVIEWED' and scope.get('source_refs'),
            'INHERITANCE_SCOPE_REVIEW_REQUIRED')
    require(type(scope.get('years')) is list and bool(scope['years'])
            and all(type(y) is int for y in scope['years']), 'INHERITANCE_YEARS')
    require(type(scope.get('kinds')) is list and bool(scope['kinds'])
            and set(scope['kinds']) <= {'admission', 'mock'}, 'INHERITANCE_KINDS')
    require(type(scope.get('tracks')) is list and bool(scope['tracks'])
            and all(type(t) is str and t.strip() for t in scope['tracks']), 'INHERITANCE_TRACKS')


def _inherits(profile, exam):
    return profile.get('profile_readiness') == 'PROFILE_READY' and any(
        exam['year'] in s['years'] and exam['kind'] in s['kinds']
        and exam['track'] in s['tracks']
        for s in profile.get('inheritance_scopes', []))


def validate(profile):
    require(profile.get('schema') == 'university-evaluation-profile-v1', 'PROFILE_SCHEMA')
    require(type(profile.get('version')) is int and profile['version'] > 0, 'PROFILE_VERSION')
    require(profile.get('content_sha256') == profile_digest(profile), 'PROFILE_PIN_DRIFT')
    require(profile.get('review_status') in ('DRAFT', 'REVIEWED', 'ACTIVE'), 'PROFILE_REVIEW')
    require(profile.get('engine_route') in ('humanities', 'business', 'math', 'special'), 'PROFILE_ROUTE')
    require(bool(profile.get('profile_id')) and bool(profile.get('university_id')), 'PROFILE_ID')
    scopes = profile.get('scopes')
    require(type(scopes) is list, 'PROFILE_SCOPE')
    for s in scopes:
        require(type(s.get('year')) is int and s.get('kind') in ('admission', 'mock')
                and s.get('exam_id') and s.get('question_ids'), 'PROFILE_SCOPE')
    for scope in profile.get('inheritance_scopes', []):
        _validate_inheritance_scope(scope)
    if profile.get('profile_readiness') == 'PROFILE_READY':
        require(profile['review_status'] in ('REVIEWED', 'ACTIVE')
                and (profile.get('inheritance_scopes') or profile.get('scopes'))
                and profile.get('common_evidence'), 'BASE_PROFILE_EVIDENCE_REQUIRED')
        for common in profile['common_evidence']:
            require(common.get('scope') == 'COMMON' and common.get('verification') == 'VERIFIED'
                    and common.get('provenance') == 'OFFICIAL' and common.get('evidenceText', '').strip()
                    and len(common.get('sourceHash', '')) == 64
                    and common.get('applies_to_profile') is True
                    and type(common.get('startPage')) is int and type(common.get('endPage')) is int
                    and 1 <= common['startPage'] <= common['endPage'], 'BASE_PROFILE_EVIDENCE_REQUIRED')
    for rule in profile.get('rules', []):
        require(rule.get('key') and rule.get('provenance') in ('OFFICIAL', 'INTERNAL_GUIDANCE'), 'PROFILE_RULE')
        if rule['provenance'] == 'OFFICIAL':
            require(bool(rule.get('source_refs')), 'PROFILE_RULE_SOURCE')
    return profile


def select(profiles, exam, question_id, *, pinned=None):
    require(any(q['id'] == question_id for q in exam['questions']), 'QUESTION_NOT_IN_EXAM')
    matches = []
    for profile in profiles:
        validate(profile)
        if profile['review_status'] not in ('REVIEWED', 'ACTIVE'):
            continue
        if pinned is not None and (profile['profile_id'], profile['version'], profile['content_sha256']) != tuple(pinned):
            continue
        if profile['university_id'] != exam['universityId']:
            continue
        if any(s['exam_id'] == exam['examId'] and s['year'] == exam['year']
               and s['kind'] == exam['kind'] and s.get('track') == exam['track']
               and question_id in s['question_ids'] for s in profile['scopes']) or _inherits(profile, exam):
            matches.append(profile)
    require(len(matches) == 1, 'PROFILE_MISSING' if not matches else 'PROFILE_AMBIGUOUS')
    return matches[0]


def map_profile(profiles, exam, question_id, *, pinned=None):
    """Base inheritance is independent of question evidence and execution admission.
    This sidecar never claims Worker readiness, correctness grading or activation.
    """
    profile = select(profiles, exam, question_id, pinned=pinned)
    inherited = _inherits(profile, exam)
    return dict(profile_id=profile['profile_id'], profile_version=profile['version'],
                profile_digest=profile['content_sha256'], question_id=question_id,
                exam_id=exam['examId'], mapping_mode='INHERITED' if inherited else 'LEGACY_QUESTION_PIN',
                PROFILE_READY=profile.get('profile_readiness') == 'PROFILE_READY',
                PROFILE_MAPPED=True, QUESTION_EVIDENCE_READY=None,
                EVALUATION_READY=None, E2E_PASS=None, activation_granted=False,
                diagnostic_capabilities=deepcopy(profile.get('diagnostic_capabilities', [])),
                correctness_requires_question_evidence=True)


def resolve_rules(profile_rules, year_rules=(), question_rules=()):
    """Higher official scopes win; same-level conflict is never silently merged."""
    resolved = {}; trace = []
    for level, rules in [('profile', profile_rules), ('year', year_rules), ('question', question_rules)]:
        local = {}
        for rule in rules:
            key = rule['key']
            require(key not in local or local[key] == rule, 'PROFILE_RULE_CONFLICT')
            require(rule.get('provenance') == 'OFFICIAL' and rule.get('source_refs'), 'OFFICIAL_RULE_REQUIRED')
            local[key] = deepcopy(rule)
        for key, rule in sorted(local.items()):
            if rule.get('value') is None:
                continue  # Unknown is not zero and cannot erase a known official rule.
            trace.append({'key': key, 'scope': level, 'supersedes': key in resolved})
            resolved[key] = rule
    return resolved, trace


def compose_material(package, registry, question_id, profiles, *, pinned_profile=None):
    """Return a one-question projection and an immutable sidecar; siblings untouched.
    Profile fallback is allowed only for reviewed official criteria mappings. A
    question's existing official criteria replace the whole lower-level criteria
    group, avoiding accidental extra deductions from duplicate lower-level rules.
    """
    exams = [e for e in registry['exams'] if e['examId'] == package['exam_id']]
    require(len(exams) == 1, 'EXAM_NOT_REGISTERED')
    exam = exams[0]
    require(package['university_id'] == exam['universityId'], 'PACKAGE_EXAM_MISMATCH')
    entries = [q for q in package['questions'] if q['question_id'] == question_id]
    require(len(entries) == 1, 'QUESTION_NOT_IN_EXAM')
    profile = select(profiles, exam, question_id, pinned=pinned_profile)
    require(profile['engine_route'] in ('humanities', 'business'), 'USE_EXISTING_MATH_RUNTIME')
    entry = deepcopy(entries[0]); mappings = entry['source_page_references']
    require(all(m.get('questionId') == question_id for m in mappings), 'QUESTION_SOURCE_MISMATCH')
    official = [m for m in mappings if m['role'] == 'criteria']
    require(all(m.get('verification') == 'VERIFIED' and m.get('evidenceText', '').strip()
                for m in official), 'QUESTION_CRITERIA_REVIEW_REQUIRED')
    exceptions = [x for x in profile.get('year_exceptions', [])
                  if x.get('exam_id') == exam['examId'] and x.get('year') == exam['year']
                  and x.get('kind') == exam['kind'] and x.get('track') == exam['track']
                  and question_id in x.get('question_ids', [])]
    require(len(exceptions) <= 1, 'YEAR_EXCEPTION_AMBIGUOUS')
    if exceptions:
        require(exceptions[0].get('review_status') == 'REVIEWED', 'YEAR_EXCEPTION_REVIEW_REQUIRED')
    fallback = exceptions[0]['criteria_mappings'] if exceptions else profile.get('criteria_mappings', [])
    if not official:
        require(fallback, 'OFFICIAL_CRITERIA_REQUIRED')
        for m in fallback:
            require(m.get('role') == 'criteria' and m.get('verification') == 'VERIFIED'
                    and m.get('evidenceText', '').strip() and m.get('sourceHash'), 'PROFILE_CRITERIA_INVALID')
            mappings.append(dict(deepcopy(m), questionId=question_id))
    # Common guidance is evidence, never an additional scored criterion. Only
    # reviewed common clauses and their reviewed framework summary travel here;
    # question answers and point bands stay in question mappings. Content review is
    # still required by bind_material when this changes the package.
    framework_attached = False
    common_entries = profile.get('common_evidence', [])
    applicable_refs = [ref for scope in profile.get('inheritance_scopes', [])
                       if exam['year'] in scope.get('years', [])
                       and exam['kind'] in scope.get('kinds', [])
                       and exam['track'] in scope.get('tracks', [])
                       for ref in scope.get('source_refs', []) if isinstance(ref, dict)]
    if applicable_refs:
        locators = {(r['sourceHash'], r['startPage'], r['endPage']) for r in applicable_refs}
        common_entries = [c for c in common_entries
                          if (c.get('sourceHash'),c.get('startPage'),c.get('endPage')) in locators]
        require(common_entries, 'COMMON_SCOPE_EVIDENCE_MISSING')
    for common in common_entries:
        require(common.get('scope') == 'COMMON' and common.get('verification') == 'VERIFIED'
                and common.get('provenance') == 'OFFICIAL'
                and common.get('evidenceText', '').strip(), 'COMMON_EVIDENCE_REVIEW_REQUIRED')
        require(len(common.get('sourceHash', '')) == 64
                and type(common.get('startPage')) is int
                and type(common.get('endPage')) is int
                and 1 <= common['startPage'] <= common['endPage'], 'COMMON_EVIDENCE_SOURCE')
        if common.get('applies_to_profile') is True:
            require(profile.get('profile_readiness') == 'PROFILE_READY', 'COMMON_INHERITANCE_SCOPE')
        else:
            require(type(common.get('question_ids')) is list and common['question_ids'], 'COMMON_EVIDENCE_SCOPE')
            if question_id not in common['question_ids']:
                continue
        text = ('대학 공통 평가 방향(별도 배점·감점 항목 아님). '
                '이 문항의 공식 채점기준과 충돌하면 문항 기준을 우선한다.\n'
                + common['evidenceText'])
        # A reviewed base framework is an interpretation of the cited common
        # evidence, not question-specific truth or a new numeric scoring rubric.
        if common.get('applies_to_profile') is True and not framework_attached:
            framework_attached = True
            framework = profile.get('base_framework', {})
            for key in ('core_competencies', 'scoring_method', 'partial_credit_principle',
                        'deduction_principle', 'answer_structure'):
                value = framework.get(key)
                if value:
                    provenance = profile.get('base_framework_provenance', {}).get(key)
                    labels = {'OFFICIAL_DERIVED': '공식 자료에서 도출한 진단 방향',
                              'INTERNAL_GUIDANCE': '내부 진단 가이드(공식 채점·감점 기준 아님)'}
                    require(provenance is None or provenance in labels,
                            'FRAMEWORK_PROVENANCE_INVALID')
                    label = labels.get(provenance, '검수된 기본체계 요약')
                    text += '\n' + label + ' ' + key + ': ' + (
                        ' / '.join(value) if isinstance(value, list) else str(value))

        mapping = dict(questionId=question_id, role='scoring', verification='VERIFIED',
                       sourceHash=common['sourceHash'], startPage=common['startPage'],
                       endPage=common['endPage'], evidenceText=text)
        if mapping not in mappings:
            mappings.append(mapping)
    out = deepcopy(package); out['questions'] = [entry]
    # Preserve the legacy pin for identical projected content; do not invent a
    # Postgres jsonb digest or modify a Production package from this compiler.
    manifest = dict(schema=VERSION, exam_id=exam['examId'], question_id=question_id,
                    profile_id=profile['profile_id'], profile_version=profile['version'],
                    profile_digest=profile['content_sha256'],
                    source_package_digest=package.get('package_digest'),
                    criteria_source='question' if official else 'year' if exceptions else 'profile',
                    package_content_sha256=digest(out), activation_granted=False)
    manifest['resolution_sha256'] = digest(manifest)
    return out, manifest


def bind_material(package, registry, question_id, profiles, **runtime_args):
    """Existing Worker host adapter. Does not replace runtime admission/policy."""
    from .material_runtime import reviewed_material_question
    out, manifest = compose_material(package, registry, question_id, profiles)
    selected = next(p for p in profiles if p['content_sha256'] == manifest['profile_digest'])
    require(selected['engine_route'] == runtime_args.get('evaluation_type'), 'PROFILE_ENGINE_MISMATCH')
    require(out == {**package, 'questions': [next(q for q in package['questions']
                    if q['question_id'] == question_id)]}, 'COMPILED_PACKAGE_REVIEW_REQUIRED')
    hosted, report = reviewed_material_question(out, registry, question_id, **runtime_args)
    return hosted, dict(report, profile_resolution=manifest)


def bind_math(context, exam, question_id, profiles, *, pinned_profile=None):
    """Use the existing physical Math profile and official leaf pins unchanged.
    Logical profiles are not a new database scope or numeric-scoring engine.
    """
    profile = select(profiles, exam, question_id, pinned=pinned_profile)
    require(profile['engine_route'] == 'math', 'USE_EXISTING_ESSAY_RUNTIME')
    expected = profile.get('math_binding', {})
    require(expected and context['profile']['id'] == expected.get('profile_id')
            and context['leaf']['id'] == expected.get('leaf_id')
            and context['problem']['id'] == expected.get('problem_id'), 'MATH_PROFILE_PIN_MISMATCH')
    require(digest(context['profile']) == expected.get('profile_sha256'), 'MATH_PROFILE_CONTENT_DRIFT')
    require(context['profile']['rubric_version'] == 'math-rubric-v1', 'MATH_RUBRIC_VERSION')
    manifest = dict(schema=VERSION, profile_id=profile['profile_id'],
                    profile_version=profile['version'], profile_digest=profile['content_sha256'],
                    exam_id=exam['examId'], question_id=question_id,
                    math_profile_id=expected['profile_id'], leaf_id=expected['leaf_id'],
                    context_sha256=digest(context), activation_granted=False)
    manifest['resolution_sha256'] = digest(manifest)
    return deepcopy(context), manifest
