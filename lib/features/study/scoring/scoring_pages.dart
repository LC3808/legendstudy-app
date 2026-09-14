import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../application/study_controller.dart';
import '../domain/study_models.dart';
import 'scoring_models.dart';

Future<void> confirmScoringSubmit(
  BuildContext context,
  StudyController c,
) async {
  final id = c.draft?.id, epoch = c.viewGeneration;
  final blank = c.draft?.answers?.unanswered ?? 0;
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('시험을 제출할까요?'),
      content: Text(blank > 0 ? '아직 답하지 않은 문제가 $blank개 있어요.' : '모든 문항에 답했어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('돌아가기'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('제출하고 채점하기'),
        ),
      ],
    ),
  );
  if (yes == true && c.viewGeneration == epoch && c.draft?.id == id) {
    await c.end();
  }
}

class AnswerEntryPage extends StatefulWidget {
  const AnswerEntryPage({super.key, required this.study});
  final StudyController study;
  @override
  State<AnswerEntryPage> createState() => _AnswerEntryPageState();
}

class _AnswerEntryPageState extends State<AnswerEntryPage> {
  late final epoch = widget.study.viewGeneration;
  final anchors = <int, GlobalKey>{};
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.study,
    builder: (context, _) {
      final c = widget.study, d = c.draft;
      if (epoch != c.viewGeneration) {
        return const Scaffold(
          body: SafeArea(
            child: Center(child: Text('계정이 변경되었어요. 학습 화면으로 돌아가 주세요.')),
          ),
        );
      }
      if (d?.answers == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('시험 결과')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: c.attempts.isEmpty
                  ? const Text('시험 기록을 확인해 주세요.')
                  : ScoringAttemptView(study: c, id: c.attempts.last.id),
            ),
          ),
        );
      }
      final draft = d!.answers!,
          enabled =
              d.phase == TimerPhase.running &&
              !d.frozen &&
              !c.busy &&
              !c.recovery;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            d.mock!.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  children: [
                    Semantics(
                      label: '남은 시간',
                      child: Text(
                        timerDigits(c.remainingMs.clamp(0, 43200000)),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text('답안 ${draft.answered} / ${draft.answers.length}'),
                    if (d.frozen)
                      const Text('시험 시간이 끝났어요.')
                    else if (d.phase == TimerPhase.paused)
                      const Text('일시정지 중'),
                    if (d.frozen) Text('미응답 ${draft.unanswered}문항'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SafeArea(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(ctx).height * .65,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          children: [
                            for (var n = 1; n <= draft.answers.length; n++)
                              Semantics(
                                label:
                                    '$n번 ${draft.answers[n - 1] == null ? '미응답' : '답변함'}',
                                button: true,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(56, 48),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    final target = anchors[n]?.currentContext;
                                    if (target != null) {
                                      Scrollable.ensureVisible(
                                        target,
                                        duration: Duration.zero,
                                      );
                                    }
                                  },
                                  child: Text(
                                    '$n${draft.answers[n - 1] == null ? ' ·' : ' ✓'}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('문항 바로가기'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      for (var n = 1; n <= draft.answers.length; n++)
                        Column(
                          key: anchors.putIfAbsent(n, () => GlobalKey()),
                          children: [
                            if ((n - 1) % 5 == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$n–${(n + 4).clamp(1, draft.answers.length)}번',
                                    style: const TextStyle(
                                      color: AppTokens.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '$n',
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                for (var choice = 1; choice <= 5; choice++)
                                  Expanded(
                                    child: Semantics(
                                      label: '$n번, $choice번 선택지',
                                      selected: draft.answers[n - 1] == choice,
                                      enabled: enabled,
                                      button: true,
                                      child: ExcludeSemantics(
                                        child: TextButton(
                                          key: ValueKey('answer-$n-$choice'),
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(48, 48),
                                            padding: EdgeInsets.zero,
                                            backgroundColor:
                                                draft.answers[n - 1] == choice
                                                ? AppTokens.primarySoft
                                                : null,
                                            foregroundColor:
                                                AppTokens.textPrimary,
                                          ),
                                          onPressed: enabled
                                              ? () => c.selectAnswer(
                                                  n,
                                                  draft.answers[n - 1] == choice
                                                      ? null
                                                      : choice,
                                                )
                                              : null,
                                          child: Text(
                                            ['①', '②', '③', '④', '⑤'][choice -
                                                1],
                                            style: const TextStyle(
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 1),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (!d.frozen)
                      OutlinedButton(
                        onPressed: c.busy
                            ? null
                            : d.phase == TimerPhase.running
                            ? c.pause
                            : c.canResume
                            ? c.resume
                            : null,
                        child: Text(
                          d.phase == TimerPhase.running ? '일시정지' : '계속하기',
                        ),
                      ),
                    FilledButton(
                      onPressed: c.busy || c.recovery
                          ? null
                          : () => confirmScoringSubmit(context, c),
                      child: const Text('제출하고 채점하기'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ScoringAttemptView extends StatelessWidget {
  const ScoringAttemptView({super.key, required this.study, required this.id});
  final StudyController study;
  final String id;
  @override
  Widget build(BuildContext context) {
    if (study.draft?.answers != null) {
      return const Text('시험을 제출한 뒤 결과를 확인할 수 있어요.');
    }
    final matches = study.attempts.where((a) => a.id == id);
    if (matches.isEmpty) return const Text('이 계정의 결과를 찾을 수 없어요.');
    final a = matches.single, score = a.result;
    if (score == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(a.title),
          Text(
            a.outcome == ScoringOutcome.stale
                ? '채점 기준이 업데이트되었어요. 답안과 시험 기록은 보관되어 있어요. 새 시험을 선택해 다시 응시할 수 있어요.'
                : study.scoringBusy
                ? '채점 중'
                : '채점 재시도 필요',
          ),
          Text('답안 ${a.draft.answered} / ${a.draft.answers.length}'),
          ExpansionTile(
            title: const Text('보관한 답안 보기'),
            children: [
              for (var i = 0; i < a.draft.answers.length; i++)
                ListTile(
                  title: Text('${i + 1}번 · ${a.draft.answers[i] ?? '미응답'}'),
                ),
            ],
          ),
          if (a.outcome == ScoringOutcome.pending)
            TextButton(
              onPressed: study.scoringBusy ? null : () => study.sync(),
              child: const Text('채점 다시 시도'),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(a.title, style: Theme.of(context).textTheme.titleMedium),
        Semantics(
          label: '원점수 ${score.rawScore}점, 만점 ${score.maxScore}점',
          child: Text(
            '${score.rawScore} / ${score.maxScore}점',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Text('정답 ${score.correctCount} / ${score.answers.length}'),
        Text('오답: ${score.wrong.isEmpty ? '없음' : score.wrong.join(' · ')}'),
        Text(
          '미응답: ${score.unanswered.isEmpty ? '없음' : score.unanswered.join(' · ')}',
        ),
        Text(
          study.guest ? '이 기기에 저장됨' : '서버에서 채점한 결과',
          style: const TextStyle(color: AppTokens.textSecondary),
        ),
        const SizedBox(height: 12),
        const Text('답안 확인'),
        for (final r in score.answers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Semantics(
              label:
                  '${r.number}번, 내 답 ${r.submitted ?? '미응답'}, 정답 ${r.correct}, ${r.points}점, ${r.isCorrect ? '정답' : '오답'}',
              child: Text(
                '${r.number}번 · 내 답 ${r.submitted ?? '—'} · 정답 ${r.correct} · ${r.points}점 · ${r.isCorrect
                    ? '정답'
                    : r.submitted == null
                    ? '미응답'
                    : '오답'}',
              ),
            ),
          ),
      ],
    );
  }
}

class ScoringHistory extends StatelessWidget {
  const ScoringHistory({super.key, required this.study});
  final StudyController study;
  @override
  Widget build(BuildContext context) => study.draft != null
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (study.attempts.isNotEmpty) const Text('시험 채점 결과'),
            for (final attempt in study.attempts.reversed)
              TextButton(
                onPressed: () {
                  final epoch = study.viewGeneration;
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: study,
                        builder: (context, _) => Scaffold(
                          appBar: AppBar(title: const Text('시험 결과')),
                          body: SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: epoch != study.viewGeneration
                                  ? const Text('계정이 변경되었어요.')
                                  : ScoringAttemptView(
                                      study: study,
                                      id: attempt.id,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Text(
                  '${attempt.title} · ${attempt.result == null ? '채점 확인' : '${attempt.result!.rawScore} / ${attempt.result!.maxScore}점'}',
                ),
              ),
          ],
        );
}
