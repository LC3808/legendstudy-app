import 'package:flutter/material.dart';

/// Categories are observations about this evaluation, not permanent student traits.
enum EssaySentenceCategory {
  grammar('맞춤법·문법'),
  expression('어색한 표현'),
  structure('문장 구조'),
  logic('논리 표현');

  const EssaySentenceCategory(this.label);
  final String label;
}

/// Order is educational impact, independent of category.
enum EssaySentencePriority {
  contradiction,
  unclearMeaning,
  grammarAgreement,
  wording,
}

@immutable
class EssaySentenceItem {
  const EssaySentenceItem({
    required this.id,
    required this.category,
    required this.priority,
    required this.start,
    required this.end,
    required this.quote,
    required this.diagnosis,
    required this.direction,
    this.example,
  });
  final String id, quote, diagnosis, direction;
  final String? example;
  final EssaySentenceCategory category;
  final EssaySentencePriority priority;
  // Unicode code point offsets, zero-based, end exclusive; no normalization.
  final int start, end;
}

@immutable
class EssaySentenceReview {
  const EssaySentenceReview({
    required this.evaluationId,
    required this.attemptId,
    required this.items,
  });
  final String evaluationId, attemptId;
  final List<EssaySentenceItem> items;

  /// UI defense in depth only. Server must repeat validation before persistence.
  List<EssaySentenceItem> verified(
    String evaluation,
    String attempt,
    String answer,
  ) {
    if (evaluationId.isEmpty ||
        attemptId.isEmpty ||
        evaluationId != evaluation ||
        attemptId != attempt) {
      return [];
    }
    final points = answer.runes.toList();
    final seen = <String>{};
    final spans = <String>{};
    final valid = items.where((item) {
      if (item.id.trim().isEmpty ||
          item.quote.trim().isEmpty ||
          item.diagnosis.trim().isEmpty ||
          item.direction.trim().isEmpty ||
          item.start < 0 ||
          item.end <= item.start ||
          item.end > points.length) {
        return false;
      }
      if (String.fromCharCodes(points.sublist(item.start, item.end)) !=
          item.quote) {
        return false;
      }
      return seen.add(item.id) && spans.add('${item.start}:${item.end}');
    }).toList();
    valid.sort((a, b) {
      final rank = a.priority.index.compareTo(b.priority.index);
      return rank != 0 ? rank : a.start.compareTo(b.start);
    });
    return valid.take(5).toList(growable: false);
  }
}

class EssaySentenceSection extends StatelessWidget {
  const EssaySentenceSection({
    this.review,
    this.evaluationId,
    this.attemptId,
    this.submittedAnswer,
    super.key,
  });
  final EssaySentenceReview? review;
  // Supplied by trusted result/immutable submission adapter, never current draft.
  final String? evaluationId, attemptId, submittedAnswer;

  @override
  Widget build(BuildContext context) {
    final items =
        review?.verified(
          evaluationId ?? '',
          attemptId ?? '',
          submittedAnswer ?? '',
        ) ??
        [];
    final unavailable = review == null;
    final unverified =
        !unavailable &&
        (review!.evaluationId != evaluationId ||
            review!.attemptId != attemptId ||
            submittedAnswer == null ||
            (review!.items.isNotEmpty && items.isEmpty));
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: Text(
                '문장 다듬기 · ${items.length}개',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF192D50),
                ),
              ),
              subtitle: Text(
                unavailable
                    ? '문장별 진단이 아직 제공되지 않았어요.'
                    : unverified
                    ? '원문과의 연결을 확인할 수 없어 진단을 표시하지 않았어요.'
                    : items.isEmpty
                    ? '이번 평가에서 추가로 안내할 문장 항목이 없어요.'
                    : '학습에 도움이 되는 문장부터 확인해 보세요.',
              ),
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.category.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        _field('원문', item.quote),
                        _field('진단', item.diagnosis),
                        _field('수정 방향', item.direction),
                        if (item.example?.trim().isNotEmpty == true)
                          _field('수정 예시', item.example!),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String body) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555B61),
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          body,
          style: const TextStyle(
            fontSize: 15,
            height: 1.65,
            color: Color(0xFF202124),
          ),
        ),
      ],
    ),
  );
}
