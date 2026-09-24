import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../application/study_controller.dart';
import '../domain/study_models.dart';
import '../notifications/mock_notification.dart';
import 'study_page.dart';
import 'pause_resume_button.dart';
import '../scoring/scoring_pages.dart';
import '../scoring/scoring_repository.dart';

class MockExamPanel extends StatefulWidget {
  const MockExamPanel({
    super.key,
    required this.study,
    required this.start,
    required this.notifications,
    required this.startBusy,
  });
  final StudyController study;
  final Future<void> Function() start;
  final MockNotificationService notifications;
  final bool startBusy;
  @override
  State<MockExamPanel> createState() => _MockExamPanelState();
}

class _MockExamPanelState extends State<MockExamPanel> {
  final title = TextEditingController();
  final subject = TextEditingController();
  final minutes = TextEditingController(text: '80');
  String preset = '국어';
  bool includeInStudyTotal = true;
  bool alert = false, notificationBusy = false, starting = false;
  String? error, alertMessage;
  List<ScoringPaper> papers = [];
  int? selectedPaper;
  String? selectedExam;
  bool papersLoading = true, papersFailed = false;
  bool preparing = false;
  int selectionEpoch = 0;
  @override
  void initState() {
    super.initState();
    loadPapers();
    final setup = widget.study.mockSetup;
    title.text = setup?.title ?? '국어 실전 모의고사';
    subject.text = setup == null ? '국어' : setup.subject ?? '';
    minutes.text = '${(setup?.plannedSeconds ?? 4800) ~/ 60}';
    if (setup != null) {
      preset = MockSetup.presets.keys.firstWhere(
        (key) =>
            presetSubject(key) == setup.subject &&
            MockSetup.presets[key]! * 60 == setup.plannedSeconds,
        orElse: () => '사용자 지정',
      );
    }
    alert = setup?.notify ?? false;
    includeInStudyTotal =
        setup?.includeInStudyTotal ?? widget.study.includeMockDefault;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) refreshSetup();
    });
  }

  String presetSubject(String key) => key == '영어 듣기 제외' ? '영어' : key;

  Future<void> loadPapers() async {
    if (mounted) {
      setState(() {
        papersLoading = true;
        papersFailed = false;
      });
    }
    try {
      final list = await widget.study.scoringRepository
          ?.call()
          .availablePapers();
      if (mounted) {
        setState(() {
          papers = list ?? [];
          papersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          papersFailed = true;
          papersLoading = false;
        });
      }
    }
  }

  Future<void> chooseExam(String value) async {
    if (preparing || starting) return;
    setState(() => preparing = true);
    await widget.study.configureScoring(null);
    if (!mounted) return;
    setState(() {
      selectedExam = value == 'timer-only' ? null : value;
      selectedPaper = null;
      preparing = false;
      error = null;
      if (selectedExam == null) {
        subject.text = presetSubject(preset) == '사용자 지정'
            ? ''
            : presetSubject(preset);
        title.text = '개인 모의고사 연습';
      }
    });
    refreshSetup();
  }

  Future<void> choosePaper(int? value) async {
    if (preparing || starting || value == null) return;
    final request = ++selectionEpoch;
    setState(() {
      preparing = true;
      selectedPaper = null;
      error = null;
    });
    try {
      await widget.study.configureScoring(null);
      await widget.study.configureScoring(papers[value].availability);
      if (mounted && request == selectionEpoch) {
        setState(() {
          selectedPaper = value;
          title.text = papers[value].title;
          subject.text = papers[value].subjectLabel ?? '과목 정보 없음';
        });
        refreshSetup();
      }
    } catch (_) {
      if (mounted) setState(() => error = '정답 데이터를 확인하지 못했어요. 과목을 다시 선택해 주세요.');
    } finally {
      if (mounted && request == selectionEpoch) {
        setState(() => preparing = false);
      }
    }
  }

  @override
  void dispose() {
    title.dispose();
    subject.dispose();
    minutes.dispose();
    super.dispose();
  }

  MockSetup? readSetup() {
    final n = int.tryParse(minutes.text.trim());
    if (title.text.trim().isEmpty || title.text.trim().runes.length > 80) {
      error = '시험명은 1~80자로 입력해 주세요.';
      return null;
    }
    if (subject.text.trim().runes.length > 40) {
      error = '과목은 40자 이내로 입력해 주세요.';
      return null;
    }
    if (n == null || n < 1 || n > 720) {
      error = '시험 시간은 1~720분으로 입력해 주세요.';
      return null;
    }
    error = null;
    return MockSetup(
      title.text.trim(),
      subject.text.trim().isEmpty ? null : subject.text.trim(),
      n * 60,
      notify: alert,
      includeInStudyTotal: includeInStudyTotal,
    );
  }

  void refreshSetup() {
    if (widget.study.draft != null || widget.study.lastMock != null) return;
    final previousError = error;
    final setup = readSetup();
    error = previousError;
    widget.study.configureMock(setup);
  }

  Future<void> start() async {
    if (starting ||
        preparing ||
        selectedExam != null && selectedPaper == null) {
      return;
    }
    final setup = readSetup();
    setState(() {});
    if (setup == null) return;
    widget.study.configureMock(setup);
    setState(() => starting = true);
    try {
      if (selectedExam != null && selectedPaper != null) {
        await widget.study.configureScoring(
          papers[selectedPaper!].availability,
        );
      } else {
        await widget.study.configureScoring(null);
      }
      if (mounted) await widget.start();
    } catch (_) {
      if (mounted) setState(() => error = '채점 기준을 확인하지 못했어요. 시험을 다시 선택해 주세요.');
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> confirm({bool discard = false}) async {
    if (!discard && widget.study.draft?.answers != null) {
      await confirmScoringSubmit(context, widget.study);
      return;
    }
    final id = widget.study.draft?.id;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(discard ? '시험 기록을 취소할까요?' : '시험을 종료할까요?'),
        content: Text(discard ? '이번 시험은 공부시간에 포함되지 않아요.' : '실제 응시한 시간을 기록해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('돌아가기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(discard ? '기록 취소' : '종료 확인'),
          ),
        ],
      ),
    );
    if (yes == true && mounted && id != null && widget.study.draft?.id == id) {
      if (discard) {
        await widget.study.discardMock();
      } else {
        await widget.study.end();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final study = widget.study;
    final d = study.draft;
    if (!study.ready || study.recovery) return StudyTimerControls(study: study);
    if (d == null && study.lastMock != null) {
      final result = study.lastMock!;
      final seconds = result.activeMs ~/ 1000;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(result.title!, style: Theme.of(context).textTheme.titleMedium),
          Text('${seconds ~/ 60}분 ${seconds % 60}초 응시했어요.'),
          TextButton(
            onPressed: () {
              setState(() => includeInStudyTotal = study.includeMockDefault);
              study.configureMock(null);
            },
            child: const Text('새 모의고사'),
          ),
        ],
      );
    }
    if (d == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('공부시간에 포함'),
            subtitle: const Text('이번 시험에만 적용해요'),
            value: includeInStudyTotal,
            onChanged: starting
                ? null
                : (value) {
                    setState(() => includeInStudyTotal = value);
                    refreshSetup();
                  },
          ),
          if (papersLoading)
            const LinearProgressIndicator(semanticsLabel: '시험 불러오는 중'),
          if (papersFailed) ...[
            const Text('시험을 불러오지 못했어요. 타이머는 사용할 수 있어요.'),
            TextButton(
              onPressed: papersLoading ? null : loadPapers,
              child: const Text('다시 시도'),
            ),
          ] else if (!papersLoading && papers.isEmpty)
            const Text('정답 데이터 없음 · 타이머만 사용할 수 있어요.'),
          if (papers.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: const Key('mock-exam'),
              initialValue: selectedExam ?? 'timer-only',
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              decoration: const InputDecoration(labelText: '시험 선택'),
              items: [
                const DropdownMenuItem(
                  value: 'timer-only',
                  child: Text('타이머만 사용'),
                ),
                for (final id in papers.map((p) => p.examIdentity).toSet())
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      papers.firstWhere((p) => p.examIdentity == id).title,
                    ),
                  ),
              ],
              onChanged: preparing || starting
                  ? null
                  : (v) {
                      if (v != null) chooseExam(v);
                    },
            ),
          ],
          const SizedBox(height: 16),
          if (selectedExam == null)
            TextField(
              key: const Key('mock-title'),
              controller: title,
              decoration: const InputDecoration(labelText: '연습 이름'),
              onChanged: (_) => refreshSetup(),
            ),
          const SizedBox(height: 16),
          if (selectedExam != null)
            DropdownButtonFormField<int>(
              key: ValueKey('mock-paper-$selectedExam'),
              initialValue: selectedPaper,
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              decoration: const InputDecoration(labelText: '과목 선택'),
              items: [
                for (var i = 0; i < papers.length; i++)
                  if (papers[i].examIdentity == selectedExam)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${papers[i].subjectLabel ?? '과목 정보 없음'} · ${papers[i].availability.paperVariant}',
                      ),
                    ),
              ],
              onChanged: preparing || starting ? null : choosePaper,
            )
          else
            DropdownButtonFormField<String>(
              key: ValueKey('mock-subject-${subject.text}'),
              initialValue: subject.text.isEmpty ? '' : subject.text,
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              decoration: const InputDecoration(labelText: '과목'),
              items: [
                const DropdownMenuItem(value: '', child: Text('설정 안 함')),
                for (final name in {
                  '국어',
                  '수학',
                  '영어',
                  '한국사',
                  '탐구',
                  '기타',
                  if (subject.text.isNotEmpty) subject.text,
                })
                  DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: starting
                  ? null
                  : (v) {
                      setState(() => subject.text = v ?? '');
                      refreshSetup();
                    },
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('mock-duration'),
            initialValue: preset,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            decoration: const InputDecoration(labelText: '시험 시간'),
            items: [
              for (final entry in MockSetup.presets.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      entry.key == '영어 듣기 제외'
                          ? '영어 45분 · 듣기 제외'
                          : '${entry.key} ${entry.value}분',
                    ),
                  ),
                ),
              const DropdownMenuItem(value: '사용자 지정', child: Text('사용자 지정')),
            ],
            onChanged: (value) => setState(() {
              final previous = preset;
              preset = value!;
              if (MockSetup.presets.containsKey(value)) {
                minutes.text = '${MockSetup.presets[value]}';
                if (selectedExam == null && title.text == '$previous 실전 모의고사') {
                  title.text = '$value 실전 모의고사';
                }
                if (selectedExam == null &&
                    subject.text == presetSubject(previous)) {
                  subject.text = presetSubject(value);
                }
              }
            }),
          ),
          if (preset == '사용자 지정')
            TextField(
              key: const Key('mock-minutes'),
              controller: minutes,
              onChanged: (_) => refreshSetup(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '시험 시간 (1~720분)'),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('시험 종료 알림'),
            value: alert,
            onChanged: notificationBusy
                ? null
                : (value) async {
                    if (value != true) {
                      setState(() => alert = false);
                      return;
                    }
                    setState(() => notificationBusy = true);
                    var allowed = false;
                    try {
                      allowed = await widget.notifications.request();
                    } catch (_) {
                      /* Optional capability. */
                    }
                    if (!mounted) return;
                    setState(() {
                      notificationBusy = false;
                      alert = allowed;
                      alertMessage = allowed
                          ? '기기 설정에 따라 알림이 늦거나 소리가 나지 않을 수 있어요.'
                          : '알림 없이도 시험을 시작할 수 있어요.';
                    });
                  },
          ),
          if (alertMessage != null)
            Text(
              alertMessage!,
              style: const TextStyle(color: AppTokens.textSecondary),
            ),
          if (error != null) Semantics(liveRegion: true, child: Text(error!)),
          FilledButton(
            onPressed:
                study.authReady &&
                    (selectedExam == null || selectedPaper != null) &&
                    !preparing &&
                    !starting &&
                    !widget.startBusy &&
                    !study.busy
                ? start
                : null,
            child: const Text('시험 시작'),
          ),
        ],
      );
    }
    final remaining = study.remainingMs.clamp(0, 43200000);
    final label = d.frozen
        ? d.frozenReason == 'planElapsed'
              ? '시험 시간이 끝났어요.'
              : '종료 확인 대기'
        : d.phase == TimerPhase.paused
        ? '일시정지'
        : '응시 중';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(d.mock!.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        if (d.mock!.subject != null)
          Text(
            d.mock!.subject!,
            style: const TextStyle(color: AppTokens.textSecondary),
          ),
        LayoutBuilder(
          builder: (context, box) => Semantics(
            label: '남은 시간 ${remaining ~/ 60000}분',
            child: ExcludeSemantics(
              child: Text(
                timerDigits(((remaining + 999) ~/ 1000) * 1000),
                key: const Key('mock-clock'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize:
                      (box.maxWidth /
                              (4.9 * MediaQuery.textScalerOf(context).scale(1)))
                          .clamp(24.0, 48.0),
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Text(label, textAlign: TextAlign.center),
        ),
        Text(
          '응시 ${studyDuration(study.elapsedMs)} / 시험 시간 ${d.mock!.plannedSeconds ~/ 60}분',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTokens.textSecondary),
        ),
        if (d.answers != null)
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => AnswerEntryPage(study: study),
              ),
            ),
            child: Text(
              '답안 입력 · ${d.answers!.answered} / ${d.answers!.answers.length}',
            ),
          ),
        const SizedBox(height: 12),
        if (!d.frozen)
          PauseResumeButton(
            running: d.phase == TimerPhase.running,
            onPressed: study.busy
                ? null
                : d.phase == TimerPhase.running
                ? study.pause
                : study.canResume
                ? study.resume
                : null,
          ),
        if (!d.frozen && !study.canResume && d.phase == TimerPhase.paused)
          const Text('구간 한도에 도달했어요. 이번 시험을 종료해 주세요.'),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: study.busy ? null : () => confirm(),
          child: Text(
            study.busy
                ? '기록 종료 중'
                : d.frozen
                ? '시험 종료'
                : '제출',
          ),
        ),
        TextButton(
          onPressed: study.busy ? null : () => confirm(discard: true),
          child: const Text('기록 취소'),
        ),
      ],
    );
  }
}
