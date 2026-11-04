import 'package:flutter/material.dart';

import 'academic_purple.dart';

/// Optional server judgement; never derives a rating from old results or errors.
class LearningCompletenessCard extends StatelessWidget {
  const LearningCompletenessCard({
    required this.value,
    required this.evaluationId,
    super.key,
  });
  final Object? value;
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
