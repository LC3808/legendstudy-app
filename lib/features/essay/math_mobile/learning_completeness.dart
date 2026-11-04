import 'package:flutter/material.dart';

import 'academic_purple.dart';

/// Optional server judgement; never derives a rating from old results or errors.
class LearningCompletenessCard extends StatelessWidget {
  const LearningCompletenessCard({
    required this.value,
    required this.evaluationId,
    this.comparison,
    super.key,
  });
  final Object? value;
  final Object? comparison;
  final String evaluationId;
  @override
  Widget build(BuildContext context) {
    final data = value;
    if (data is! Map ||
        data['version'] != 'learning-completeness-v1' ||
        data['evaluation_id'] != evaluationId) {
      return const SizedBox.shrink();
    }
    final level = data['level'];
    final assessed =
        data['status'] == 'ASSESSED' &&
        level is int &&
        level >= 1 &&
        level <= 5;
    final withheld = data['status'] == 'INSUFFICIENT_EVIDENCE' && level == null;
    if (!assessed && !withheld) return const SizedBox.shrink();
    final rationale = data['rationale'];
    final direction = data['next_direction'];
    if (rationale is! String ||
        rationale.trim().isEmpty ||
        direction is! String) {
      return const SizedBox.shrink();
    }
    return MathCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assessed ? '학습 완성도 · $level/5단계' : '학습 완성도 · 판단 보류',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AcademicPurple.primary,
            ),
          ),
          if (assessed) ...[
            const SizedBox(height: 8),
            Semantics(
              label: '학습 완성도 $level단계, 전체 5단계',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= level ? Icons.star : Icons.star_border,
                        color: AcademicPurple.primary,
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(rationale),
          const SizedBox(height: 12),
          const Text('다음 학습 방향', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(direction),
          if (comparison is Map) ...[
            const SizedBox(height: 16),
            LearningComparison(value: comparison),
          ],
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('평가 기준 및 정책'),
            children: [
              SelectableText(
                '정책: ${data['version']}\n평가 기준: ${data['rubric_version'] ?? '미제공'}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '학습을 돕는 단계이며 대학 공식 점수나 합격 가능성을 뜻하지 않습니다.',
            style: TextStyle(fontSize: 13, color: AcademicPurple.secondary),
          ),
        ],
      ),
    );
  }
}

/// Comparison is computed by the owned server lineage, never from client ratings.
class LearningComparison extends StatelessWidget {
  const LearningComparison({required this.value, super.key});
  final Object? value;
  @override
  Widget build(BuildContext context) {
    final data = value;
    if (data is! Map) return const SizedBox.shrink();
    if (data['comparable'] != true) {
      return Text(
        data['reason'] == 'NO_PREVIOUS_ASSESSMENT'
            ? '이전 평가에는 비교할 학습 완성도가 없습니다.'
            : '평가 기준이 달라 학습 완성도를 직접 비교하지 않습니다.',
      );
    }
    final before = data['before'], after = data['after'], delta = data['delta'];
    if (before is! int ||
        after is! int ||
        delta is! int ||
        before < 1 ||
        before > 5 ||
        after < 1 ||
        after > 5 ||
        delta != after - before) {
      return const SizedBox.shrink();
    }
    final improved = data['improved_criterion_ids'],
        remaining = data['remaining_criterion_ids'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이전 답안과 비교', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          '$before단계 → $after단계 (${delta > 0 ? '+' : ''}$delta)',
          style: const TextStyle(
            fontSize: 18,
            color: AcademicPurple.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (data['prior_rationale'] is String)
          Text('이전 근거: ${data['prior_rationale']}'),
        if (data['current_rationale'] is String)
          Text('현재 근거: ${data['current_rationale']}'),
        if (improved is List && remaining is List)
          Text(
            '개선된 평가 요소 ${improved.length}개 · 보완할 평가 요소 ${remaining.length}개',
          ),
        for (final entry in const {
          'improved_elements': '개선된 평가 요소',
          'remaining_elements': '보완할 평가 요소',
        }.entries)
          if (data[entry.key] is List &&
              (data[entry.key] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              entry.value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final element in data[entry.key] as List)
              if (element is Map && element['rationale'] is String)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('• ${element['rationale']}'),
                ),
          ],
        const SizedBox(height: 8),
        const Text(
          '이 답안의 학습 완성도 변화이며 실제 실력 향상이나 합격 가능성을 뜻하지 않습니다.',
          style: TextStyle(fontSize: 13, color: AcademicPurple.secondary),
        ),
      ],
    );
  }
}
