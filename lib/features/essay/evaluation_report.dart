import 'dart:convert';

/// growth-display-v1: read-only presentation of canonical stored evaluations.
/// Qualitative Math grades are never converted to invented numerical stars.
Map<String, dynamic> evaluationObject(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : {};
List<dynamic> evaluationList(dynamic v) => v is List ? v : [];
String evaluationText(dynamic v) => v is String ? v : '';
int? evaluationRating(dynamic v) =>
    v is num && v.isFinite && v == v.round() && v >= 1 && v <= 5
    ? v.toInt()
    : null;

const evaluationGradeLabels = {
  'STRONG': '충실',
  'ADEQUATE': '대체로 충실',
  'NEEDS_IMPROVEMENT': '보완 필요',
  'INSUFFICIENT': '부족',
  'NOT_APPLICABLE': '해당 없음',
  'NOT_ASSESSABLE': '판단 어려움',
  'satisfied': '충족',
  'partially_satisfied': '일부 충족',
  'not_satisfied': '미충족',
  'not_determinable': '판단 어려움',
};
const evaluationDimensionLabels = {
  'logical_development': '논리적 전개',
  'computation_accuracy': '계산의 정확성',
  'final_conclusion': '최종 결론',
  'problem_understanding': '문제 이해',
  'concept_selection': '개념 선택',
  'solution_strategy': '풀이 전략',
  'justification_completeness': '근거의 충실성',
  'mathematical_writing': '수학적 표현',
  'case_analysis': '경우 분석',
  'graph_interpretation': '그래프 해석',
};
const evaluationOverallLabels = {
  'ANSWER_CORRECT_AND_REASONING_SUFFICIENT': '답을 정확하게 구했고, 풀이 근거도 충분히 설명했어요.',
  'ANSWER_CORRECT_REASONING_INCOMPLETE': '답은 맞았어요. 다만 풀이 근거를 더 설명해야 해요.',
  'ANSWER_INCORRECT_APPROACH_MOSTLY_VALID': '접근 방법은 대체로 타당하지만, 답은 맞지 않았어요.',
  'FUNDAMENTAL_APPROACH_ERROR': '문제에 접근하는 방법부터 다시 살펴볼 필요가 있어요.',
  'NOT_DETERMINABLE': '현재 답안만으로는 정확한 판단이 어려워요.',
};

class EvaluationCriterion {
  const EvaluationCriterion(
    this.id,
    this.name,
    this.value,
    this.rating,
    this.feedback,
  );
  final String id, name, value, feedback;
  final int? rating;
  String get display => rating == null
      ? (evaluationGradeLabels[value] ?? (value.isEmpty ? '판단 어려움' : value))
      : '${'★' * rating!}${'☆' * (5 - rating!)}';
}

class EvaluationFeedback {
  const EvaluationFeedback(
    this.title,
    this.explanation,
    this.evidence,
    this.action,
  );
  final String title, explanation, evidence, action;
}

class EvaluationReport {
  const EvaluationReport({
    required this.id,
    required this.answer,
    required this.question,
    required this.summary,
    required this.rubric,
    required this.strengths,
    required this.weaknesses,
    required this.actions,
    required this.nextSteps,
    required this.pins,
    this.priorId,
  });
  final String id, answer, question, summary;
  final String? priorId;
  final List<String> pins, actions, nextSteps;
  final List<EvaluationCriterion> rubric;
  final List<EvaluationFeedback> strengths, weaknesses;
}

EvaluationReport mathEvaluationReport(dynamic value) {
  final v = evaluationObject(value), out = evaluationObject(v['output']);
  final profile = evaluationObject(v['profile']),
      prov = evaluationObject(out['provenance']);
  final o = evaluationObject(out['overall']);
  final steps = evaluationList(out['steps']).map(evaluationObject).toList();
  final core = evaluationList(out['core']).map(evaluationObject).toList();
  String evidence(dynamic stepId) {
    for (final s in steps) {
      if (s['id'] == stepId) return evaluationText(s['representation']);
    }
    return '';
  }

  final weaknesses = [
    for (final c in core)
      EvaluationFeedback(
        evaluationText(c['title']),
        [
          evaluationText(c['diagnosis']),
          evaluationText(c['why']),
        ].where((s) => s.isNotEmpty).join('\n'),
        evidence(c['step_id']),
        evaluationText(c['next_action']),
      ),
    for (final e in evaluationList(out['errors']).map(evaluationObject))
      if (!core.any((c) => c['error_id'] == e['id']))
        EvaluationFeedback(
          '확인할 부분',
          evaluationText(e['explanation']),
          evidence(e['step_id']),
          '',
        ),
  ];
  return EvaluationReport(
    id: evaluationText(v['evaluation_id']),
    answer: evaluationText(v['typed_answer']),
    question: evaluationText(evaluationObject(v['problem'])['statement']),
    summary:
        evaluationOverallLabels[evaluationText(o['explanation'])] ??
        evaluationText(o['explanation']),
    rubric: [
      for (final c in evaluationList(out['criteria']).map(evaluationObject))
        EvaluationCriterion(
          'criterion:${evaluationText(c['criterion_id'])}',
          _mathCriterionName(v, c['criterion_id']),
          evaluationText(c['verdict']),
          null,
          evaluationText(c['explanation']),
        ),
      for (final e in evaluationObject(out['rubric']).entries)
        EvaluationCriterion(
          e.key,
          evaluationDimensionLabels[e.key] ?? e.key,
          evaluationText(e.value),
          null,
          '',
        ),
    ],
    strengths: [
      for (final s in steps)
        if (s['status'] == 'VALID')
          EvaluationFeedback(
            '풀이 ${s['position'] ?? ''}',
            evaluationText(s['explanation']),
            evaluationText(s['representation']),
            '',
          ),
    ],
    weaknesses: weaknesses,
    actions: core
        .map((c) => evaluationText(c['next_action']))
        .where((s) => s.isNotEmpty)
        .toList(),
    nextSteps: [],
    pins: [
      evaluationText(v['leaf_id']),
      evaluationText(v['profile_id']),
      evaluationText(profile['rubric_version']),
      evaluationText(out['contract_version']),
      evaluationText(prov['provider']),
      evaluationText(prov['model_version']),
      evaluationText(prov['prompt_version']),
      v['kind'] == 'STEP_RETRY' ? '' : 'full-answer',
    ],
    priorId: evaluationText(v['prior_evaluation_id']).isEmpty
        ? null
        : evaluationText(v['prior_evaluation_id']),
  );
}

EvaluationReport humanEvaluationReport(dynamic value, {String? priorId}) {
  final v = evaluationObject(value),
      progress = evaluationList(v['essay_improvement_progress'])
          .map(evaluationObject)
          .toList();
  final attempt = evaluationObject(v['attempt']),
      snapshot = evaluationObject(v['input_snapshot']);
  final criteria =
      evaluationList(snapshot['criteria']).map(evaluationObject).toList()..sort(
        (a, b) => evaluationText(a['id']).compareTo(evaluationText(b['id'])),
      );
  final dimensions =
      evaluationList(v['essay_evaluation_dimensions'])
          .map(evaluationObject)
          .toList()
        ..sort(
          (a, b) =>
              (a['display_order'] as num).compareTo(b['display_order'] as num),
        );
  return EvaluationReport(
    id: evaluationText(v['id']),
    answer: evaluationText(evaluationObject(v['attempt'])['body']),
    question: evaluationText(
      evaluationObject(
        evaluationObject(v['session'])['essay_questions'],
      )['label'],
    ),
    summary: evaluationText(v['overall_summary']),
    rubric: [
      for (final d in dimensions)
        EvaluationCriterion(
          evaluationText(d['criterion_id']),
          evaluationText(
                evaluationObject(d['essay_evaluation_criteria'])['label'],
              ).isEmpty
              ? '평가 항목 ${d['display_order'] ?? ''}'
              : evaluationText(
                  evaluationObject(d['essay_evaluation_criteria'])['label'],
                ),
          '',
          evaluationRating(d['level_1_to_5']),
          evaluationText(d['explanation']),
        ),
    ],
    strengths: [
      for (final s in evaluationList(v['strengths']))
        if (evaluationText(s).isNotEmpty)
          EvaluationFeedback('잘한 점', evaluationText(s), '', ''),
    ],
    weaknesses: [
      for (final p in progress)
        if (p['status'] != 'resolved')
          EvaluationFeedback(
            evaluationText(p['title']),
            evaluationText(p['explanation']),
            '',
            evaluationText(p['next_action']),
          ),
    ],
    actions: progress
        .map((p) => evaluationText(p['next_action']))
        .where((s) => s.isNotEmpty)
        .toList(),
    nextSteps: evaluationList(v['rewrite_checklist'])
        .map(evaluationText)
        .where((s) => s.isNotEmpty)
        .toList(),
    priorId: priorId,
    pins:
        v['evidence_completeness'] == 'complete' &&
            criteria.isNotEmpty &&
            criteria.every(
              (c) =>
                  evaluationText(c['id']).isNotEmpty &&
                  evaluationText(c['version']).isNotEmpty,
            ) &&
            evaluationObject(attempt['conditions_snapshot']).isNotEmpty
        ? [
            evaluationText(v['session_id']),
            evaluationText(v['question_id']),
            evaluationText(v['regime_key']),
            evaluationText(v['contract_version']),
            evaluationText(attempt['mode']),
            evaluationText(attempt['question_metadata_version']),
            _stable(attempt['conditions_snapshot']),
            _stable(
              criteria
                  .map((c) => {'id': c['id'], 'version': c['version']})
                  .toList(),
            ),
          ]
        : [],
  );
}

class EvaluationChange {
  const EvaluationChange(this.before, this.after, this.direction);
  final EvaluationCriterion before, after;
  final String direction;
}

List<EvaluationChange>? compareEvaluationReports(
  EvaluationReport before,
  EvaluationReport after,
) {
  if (before.id.isEmpty ||
      after.priorId != before.id ||
      before.pins.isEmpty ||
      before.pins.length != after.pins.length) {
    return null;
  }
  for (var i = 0; i < before.pins.length; i++) {
    if (before.pins[i].isEmpty || before.pins[i] != after.pins[i]) return null;
  }
  if (before.rubric.isEmpty ||
      before.rubric.length != after.rubric.length ||
      before.rubric.map((c) => c.id).toSet().length != before.rubric.length ||
      after.rubric.map((c) => c.id).toSet().length != after.rubric.length) {
    return null;
  }
  const ranks = {
    'STRONG': 4,
    'ADEQUATE': 3,
    'NEEDS_IMPROVEMENT': 2,
    'INSUFFICIENT': 1,
    'satisfied': 3,
    'partially_satisfied': 2,
    'not_satisfied': 1,
  };
  final changes = <EvaluationChange>[];
  for (final a in after.rubric) {
    final found = before.rubric.where((b) => b.id == a.id);
    if (found.isEmpty) return null;
    final b = found.first,
        x = b.rating ?? ranks[b.value],
        y = a.rating ?? ranks[a.value];
    changes.add(
      EvaluationChange(
        b,
        a,
        x == null || y == null
            ? 'UNAVAILABLE'
            : y > x
            ? 'IMPROVED'
            : y < x
            ? 'DECLINED'
            : 'UNCHANGED',
      ),
    );
  }
  return changes;
}

String _stable(dynamic v) {
  if (v is List) return '[${v.map(_stable).join(',')}]';
  if (v is Map) {
    final entries = evaluationObject(v).entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '{${entries.map((e) => '${jsonEncode(e.key)}:${_stable(e.value)}').join(',')}}';
  }
  return jsonEncode(v);
}

String _mathCriterionName(Map<String, dynamic> v, dynamic id) {
  for (final x in evaluationList(v['criteria']).map(evaluationObject)) {
    final c = evaluationObject(x['criterion']);
    if (c['id'] == id && evaluationText(c['description']).isNotEmpty) {
      return evaluationText(c['description']);
    }
  }
  return '대학 평가 기준';
}
