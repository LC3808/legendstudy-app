import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../study/study_providers.dart';
import '../study/scoring/scoring_models.dart';
import '../study/scoring/scoring_pages.dart';
import '../../shared/widgets/shell_widgets.dart';

String mockScoreSummary(List<ScoringAttempt> attempts) {
  final rows =
      attempts
          .where(
            (a) => a.outcome == ScoringOutcome.complete && a.result != null,
          )
          .toList()
        ..sort(
          (a, b) => (b.result!.submittedAt ?? b.completedAt ?? DateTime(1970))
              .compareTo(
                a.result!.submittedAt ?? a.completedAt ?? DateTime(1970),
              ),
        );
  if (rows.isEmpty) return '확인된 성적이 없어요. 모의고사에서 답안을 입력해 주세요.';
  final a = rows.first, r = rows.first.result!;
  return '${a.subject ?? a.title} · ${r.rawScore}/${r.maxScore}점 · ${r.gradeLabel}';
}

class MyScoreSummary extends ConsumerWidget {
  const MyScoreSummary({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.watch(studyControllerProvider);
    return Column(
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('내신 성적 분석'),
          subtitle: Text('내신 성적 입력은 아직 지원하지 않아요.'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('모의고사 성적 분석'),
          subtitle: Text(
            !study.ready ? '성적을 확인하고 있어요.' : mockScoreSummary(study.attempts),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/lab/scores'),
        ),
      ],
    );
  }
}

class ScoreOverviewPage extends ConsumerWidget {
  const ScoreOverviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.watch(studyControllerProvider);
    return ShellPage(
      children: [
        const SectionHeader('모의고사'),
        const Text('이 기기에서 확인한 채점 결과예요. 원점수와 등급 기준을 함께 확인해 주세요.'),
        if (!study.ready)
          const LinearProgressIndicator()
        else ...[
          Text(mockScoreSummary(study.attempts)),
          ScoringHistory(study: study),
        ],
        TextButton(
          onPressed: () {
            study.selectMock(true);
            context.go('/study');
          },
          child: const Text('모의고사로 가기'),
        ),
        const SectionHeader('내신'),
        const Text('내신 성적 입력과 상세 분석은 아직 지원하지 않아요.'),
      ],
    );
  }
}
