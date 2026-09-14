import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/links/external_link.dart';
import 'scoring_models.dart';

/// Shared presentation: authenticated results are already server-confirmed here.
class ScoringResultView extends StatefulWidget {
  const ScoringResultView({
    super.key,
    required this.attempt,
    required this.guest,
  });
  final ScoringAttempt attempt;
  final bool guest;
  @override
  State<ScoringResultView> createState() => _ScoringResultViewState();
}

class _ScoringResultViewState extends State<ScoringResultView> {
  final anchors = <int, GlobalKey>{};
  void jump(int n) {
    final target = anchors[n]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: Duration.zero);
    }
  }

  String choice(int? n) => n == null ? '—' : ['①', '②', '③', '④', '⑤'][n - 1];
  String outcome(AnswerReview a) => a.submitted == null
      ? '미응답'
      : a.isCorrect
      ? '정답'
      : '오답';
  Widget numbers(String label, List<int> values) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      if (values.isEmpty)
        const Text('없음')
      else
        Wrap(
          children: [
            for (final n in values)
              Semantics(
                label: '$label $n번, 답안 확인',
                button: true,
                child: ExcludeSemantics(
                  child: TextButton(
                    key: ValueKey('review-jump-$n'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => jump(n),
                    child: Text('$n'),
                  ),
                ),
              ),
          ],
        ),
      const SizedBox(height: 12),
    ],
  );
  Widget source(String label, ScoringSource? source) {
    if (source == null) return Text('$label: 저장된 출처 정보가 없어요.');
    final date = source.verifiedAt.add(const Duration(hours: 9));
    final formatted =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${source.name}'),
        Text('확인: $formatted'),
        ExternalLinkButton(
          uri: Uri.tryParse(source.url),
          label: '$label 원문 보기',
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attempt, score = widget.attempt.result!;
    final router = GoRouter.maybeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(a.title, style: Theme.of(context).textTheme.titleMedium),
        if (a.subject?.trim().isNotEmpty == true) Text(a.subject!),
        const SizedBox(height: 12),
        Semantics(
          label: '원점수 ${score.rawScore}점, 만점 ${score.maxScore}점',
          child: ExcludeSemantics(
            child: Text(
              '${score.rawScore} / ${score.maxScore}점',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        Semantics(
          label: [
            score.gradeLabel,
            if (score.gradeExplanation != null) score.gradeExplanation!,
          ].join(', '),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.gradeLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (score.gradeExplanation != null)
                  Text(score.gradeExplanation!),
              ],
            ),
          ),
        ),
        if (score.gradeStatus != 'unavailable' && !score.hasGradeBasis)
          const Text('저장된 등급의 근거 정보를 확인할 수 없어요.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text('정답 ${score.correctCount} / ${score.answers.length}'),
            Text('오답 ${score.wrong.length}'),
            Text('미응답 ${score.unanswered.length}'),
          ],
        ),
        Text(
          widget.guest ? '이 기기에 저장됨' : '서버에서 채점한 결과',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(onPressed: () => jump(1), child: const Text('답안 확인')),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('정답·등급 기준 출처'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        source('정답 기준', score.keySource),
                        if (score.cutoffSource != null)
                          source('등급 기준', score.cutoffSource)
                        else
                          const Text('등급 정보 준비 중'),
                        const Text('응시 당시 기준으로 계산한 결과예요. 공식 성적표가 아니에요.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              ),
              child: const Text('정답·등급 기준 출처'),
            ),
            if (Navigator.of(context).canPop() || router != null)
              TextButton(
                onPressed: () {
                  if (router != null) {
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).popUntil((r) => r.isFirst);
                    router.go('/study');
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('다시 학습으로'),
              ),
            if (router != null)
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).popUntil((r) => r.isFirst);
                  router.go('/home');
                },
                child: const Text('홈으로'),
              ),
          ],
        ),
        const Divider(),
        numbers('틀린 문제', score.wrong),
        numbers('미응답', score.unanswered),
        Text('문항별 답안', style: Theme.of(context).textTheme.titleMedium),
        for (final review in score.answers)
          Padding(
            key: anchors.putIfAbsent(review.number, () => GlobalKey()),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              label:
                  '${review.number}번, 내 답 ${review.submitted == null ? '미응답' : '${review.submitted}번'}, 정답 ${review.correct}번, ${outcome(review)}, ${review.points}점',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review.number}번 · ${outcome(review)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text('내 답 ${choice(review.submitted)}'),
                        Text('정답 ${choice(review.correct)}'),
                        Text('배점 ${review.points}점'),
                      ],
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
