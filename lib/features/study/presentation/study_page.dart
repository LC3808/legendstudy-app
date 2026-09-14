import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../study_providers.dart';
import '../focus/focus_ui.dart';
import '../application/study_controller.dart';
import '../domain/study_models.dart';

class StudyPage extends ConsumerWidget {
  const StudyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.watch(studyControllerProvider);
    final focus = ref.watch(studyFocusProvider);
    return ListenableBuilder(
      listenable: focus,
      builder: (context, _) => ShellPage(
        children: [
          const AppHeader(title: '학습'),
          StudyTimerDisplay(study: study),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              study.summary,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          ),
          StudyTimerControls(
            study: study,
            startBusy: focus.busy,
            startAction: () => focus.start(
              startTimer: study.start,
              currentSession: () => study.draft?.id,
              choose: (capability) => chooseStudyFocus(context, capability),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: focus.busy
                  ? null
                  : () => showStudyFocusSettings(context, focus),
              child: const Text('집중 설정'),
            ),
          ),
          if (focus.message != null)
            Semantics(liveRegion: true, child: Text(focus.message!)),
          if (study.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(liveRegion: true, child: Text(study.message!)),
            ),
          if (study.lastCompletedMs > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('${studyDuration(study.lastCompletedMs)} 공부했어요'),
            ),
          if (study.storageLabel.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: Text(
                study.storageLabel,
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
            ),
          if (study.savePhase == SavePhase.pendingSync ||
              study.historyError ||
              study.historyLimit)
            TextButton(
              onPressed: () => study.sync(),
              child: const Text('기록 다시 확인'),
            ),
          const SectionHeader('최근 7일'),
          StudyWeekSummary(study: study),
        ],
      ),
    );
  }
}

class StudyTimerDisplay extends StatelessWidget {
  const StudyTimerDisplay({super.key, required this.study});
  final StudyController study;
  @override
  Widget build(BuildContext context) {
    final phase = study.phase;
    final label = switch (phase) {
      TimerPhase.running => '공부 중',
      TimerPhase.paused => '일시정지',
      TimerPhase.ending => '기록 종료 중',
      TimerPhase.recoveryRequired => '복원 확인 필요',
      TimerPhase.idle => '대기 상태',
    };
    final minutes = study.elapsedMs ~/ 60000;
    return Semantics(
      label: phase == TimerPhase.idle
          ? '공부 타이머, 대기 상태, 0시간 0분 0초'
          : '공부 타이머, $label, ${minutes ~/ 60}시간 ${minutes % 60}분',
      child: ExcludeSemantics(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final size = (box.maxWidth / (4.9 * scale)).clamp(24.0, 48.0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    timerDigits(study.elapsedMs),
                    key: const Key('study-clock'),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: size,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
            Text(label, style: const TextStyle(color: AppTokens.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class StudyTimerControls extends StatelessWidget {
  const StudyTimerControls({
    super.key,
    required this.study,
    this.startAction,
    this.startBusy = false,
  });
  final VoidCallback? startAction;
  final bool startBusy;
  final StudyController study;
  @override
  Widget build(BuildContext context) {
    if (study.recovery) {
      return Column(
        children: [
          const Text('중단된 동안의 시간을 확인할 수 없어요. 마지막 확인 기록만 보존할까요?'),
          TextButton(
            onPressed: study.busy ? null : () => study.recover(keep: true),
            child: const Text('확인된 기록 보존'),
          ),
          TextButton(
            onPressed: study.busy ? null : () => study.recover(keep: false),
            child: const Text('기록 취소'),
          ),
        ],
      );
    }
    if (!study.ready) {
      return TextButton(
        onPressed: study.message == null ? null : study.retryLocal,
        child: Text(
          study.message == null ? '기기 기록을 확인하는 중이에요.' : '기기 기록 다시 확인',
        ),
      );
    }
    final allowed = (study.authReady || study.draft != null) && !study.busy;
    final buttons = study.draft == null
        ? <Widget>[
            FilledButton(
              onPressed: allowed && !startBusy
                  ? startAction ?? () => study.start()
                  : null,
              child: const Text('공부 시작'),
            ),
          ]
        : <Widget>[
            FilledButton(
              onPressed: !allowed
                  ? null
                  : study.draft!.phase == TimerPhase.running
                  ? () => study.pause()
                  : study.canResume
                  ? () => study.resume()
                  : null,
              child: Text(
                study.draft!.phase == TimerPhase.running ? '일시정지' : '계속하기',
              ),
            ),
            OutlinedButton(
              onPressed: allowed ? () => study.end() : null,
              child: const Text('종료'),
            ),
          ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            if (box.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(14) >= 21) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < buttons.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    buttons[i],
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: buttons[i]),
                ],
              ],
            );
          },
        ),
        if (study.draft?.phase == TimerPhase.paused && !study.canResume)
          const Text('이번 기록을 종료한 뒤 새 공부를 시작해 주세요.'),
      ],
    );
  }
}

class StudyWeekSummary extends StatelessWidget {
  const StudyWeekSummary({super.key, required this.study});
  final StudyController study;
  @override
  Widget build(BuildContext context) {
    if (!study.summaryComplete) return const Text('전체 기록 확인 후 일주일 합계를 표시해요.');
    final first = koreanDay(study.nowMs).subtract(const Duration(days: 6));
    final days = study.week;
    return Column(
      children: [
        for (var i = 0; i < 7; i++)
          Builder(
            builder: (context) {
              final date = first.add(Duration(days: i));
              final label = '${date.month}.${date.day}${i == 6 ? ' 오늘' : ''}';
              return Semantics(
                label: '$label, 공부시간 ${studyDuration(days[i])}',
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontWeight: i == 6
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        Text(studyDuration(days[i])),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
