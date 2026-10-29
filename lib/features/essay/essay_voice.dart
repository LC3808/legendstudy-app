import 'result_disclosure.dart';
import 'evaluation_presentation.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'evaluation_report.dart';
import 'approved_result_adapter.dart';

/// Device speech only. Reads stored feedback without generating new content.
Map<String, String> essaySpeechSections(
  EvaluationReport report, [
  EvaluationReport? before,
]) {
  final changes = before == null
      ? null
      : compareEvaluationReports(before, report);
  if (changes != null) {
    changes.sort(
      (a, b) => (a.direction == 'UNCHANGED' ? 1 : 0).compareTo(
        b.direction == 'UNCHANGED' ? 1 : 0,
      ),
    );
  }
  final improved = changes?.where((c) => c.direction == 'IMPROVED').firstOrNull;
  final resolved = report.previousReviews
      .where((r) => r['outcome'] == 'resolved')
      .firstOrNull;
  final sections = <String, String>{
    if (before == null)
      '내 답안 한눈에 보기': [
        '잘한 점.',
        if (report.strengths.isEmpty) '평가에 명시된 내용이 없어요.',
        ...report.strengths.take(1).map((r) => '${r.title}. ${r.explanation}'),
        '보완할 점.',
        if (report.weaknesses.isEmpty) '평가에 명시된 내용이 없어요.',
        ...report.weaknesses.take(2).map((r) => '${r.title}. ${r.explanation}'),
        '가장 먼저 고칠 것.',
        report.actions.firstOrNull ?? '평가에 명시된 우선순위가 없어요.',
        '다시 쓸 때 확인.',
        report.nextSteps.firstOrNull ?? '평가에 명시된 확인 항목이 없어요.',
      ].join('\n'),
    if (changes != null)
      '이번 답안의 변화 한눈에 보기': [
        '좋아진 점.',
        improved == null
            ? '평가에 명시된 변화가 아직 없어요.'
            : evaluationChangeSpeech(
                shortCriterionTitle(improved.after.name),
                improved.before.rating,
                improved.after.rating,
              ),
        '아직 보완할 점.',
        if (report.weaknesses.isEmpty) '평가에 명시된 보완 내용이 없어요.',
        ...report.weaknesses.take(2).map((r) => '${r.title}. ${r.explanation}'),
        '해결한 부분.',
        resolved == null
            ? '이번 평가에서 확인된 항목이 없어요.'
            : evaluationText(resolved['reason']),
        '다음에 확인할 부분.',
        report.nextSteps.firstOrNull ?? '평가에 명시된 확인 항목이 없어요.',
      ].join('\n'),
    if (changes != null)
      '평가 항목 변화': changes
          .map(
            (c) => evaluationChangeSpeech(
              shortCriterionTitle(c.after.name),
              c.before.rating,
              c.after.rating,
            ),
          )
          .join('\n'),
    '종합 평가': report.summary,
    '잘한 점': report.strengths
        .map((r) => '${r.title}. ${r.explanation}')
        .join('\n'),
    '평가 항목별 진단': report.rubric
        .map(
          (r) =>
              '${shortCriterionTitle(r.name)}. ${r.rating == null ? r.value : '5단계 평가 중 ${r.rating}단계입니다.'} ${r.feedback}',
        )
        .join('\n'),
    '보완할 점': report.weaknesses
        .map((r) => '${r.title}. ${r.explanation}')
        .join('\n'),
    '먼저 고쳐야 할 부분': report.actions.join('\n'),
    '다시 쓸 때 확인할 것': report.nextSteps.join('\n'),
  };
  return sections;
}

class EssayVoice extends StatefulWidget {
  static Future<void> Function()? stopActive;
  const EssayVoice({super.key, required this.report, this.before, this.engine});
  final EvaluationReport report;
  final EvaluationReport? before;
  @visibleForTesting
  final FlutterTts? engine;
  @override
  State<EssayVoice> createState() => _EssayVoiceState();
}

class _EssayVoiceState extends State<EssayVoice> with WidgetsBindingObserver {
  late final FlutterTts tts;
  String selected = '전체 결과', current = '', text = '';
  bool playing = false, paused = false, preparing = false;
  Timer? startWatchdog;
  Completer<void>? utterance;
  bool starting = false, finished = false;
  int generation = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    tts = widget.engine ?? FlutterTts();
    WidgetsBinding.instance.addObserver(this);
    EssayVoice.stopActive = stop;
    tts.setStartHandler(() {
      startWatchdog?.cancel();
      if (mounted && preparing) {
        setState(() {
          playing = true;
          preparing = false;
          paused = false;
        });
      }
    });
    tts.setCancelHandler(() {
      if (!playing && !preparing) return;
      generation++;
      startWatchdog?.cancel();
      if (utterance?.isCompleted == false) utterance!.complete();
      if (mounted) {
        setState(() {
          playing = false;
          preparing = false;
          current = '';
        });
      }
    });
    tts.setCompletionHandler(() {
      if (utterance?.isCompleted == false) utterance!.complete();
    });
    tts.setErrorHandler((message) {
      unawaited(fail());
    });
  }

  Future<void> fail() async {
    await stop();
    if (mounted) {
      setState(
        () => error = '음성을 재생하지 못했어요. 기기 음량과 연결된 오디오 장치를 확인한 뒤 다시 시도해 주세요.',
      );
    }
  }

  Future<void> stop() async {
    generation++;
    if (utterance?.isCompleted == false) utterance!.complete();
    startWatchdog?.cancel();
    try {
      await tts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        playing = false;
        preparing = false;
        paused = false;
        current = '';
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(stop());
  }

  List<MapEntry<String, String>> queue = [];
  int cursor = 0, progress = 0;
  Future<void> speak() async {
    if (starting) return;
    setState(() {
      starting = true;
      finished = false;
    });
    try {
      final resuming = paused;
      if (!resuming) {
        await stop();
        queue = [];
        cursor = 0;
        final seen = <String>{};
        for (final e in essaySpeechSections(
          widget.report,
          widget.before,
        ).entries) {
          if ((selected != '전체 결과' && selected != e.key) ||
              e.value.trim().isEmpty) {
            continue;
          }
          final lines = e.value
              .split('\n')
              .where((line) => line.trim().isNotEmpty && seen.add(line.trim()))
              .join('\n');
          if (lines.isEmpty) continue;
          final body = '${e.key}. $lines';
          for (var i = 0; i < body.length; i += 1500) {
            queue.add(
              MapEntry(
                e.key,
                body.substring(i, (i + 1500).clamp(0, body.length)),
              ),
            );
          }
        }
      }
      final token = ++generation;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await tts.setSharedInstance(true);
        await tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }
      await tts.setLanguage('ko-KR');
      await tts.setVolume(1.0);
      await tts.setSpeechRate(0.45);
      await tts.awaitSpeakCompletion(false);
      tts.setProgressHandler((_, start, end, word) {
        progress = start;
      });
      if (!mounted || token != generation) return;
      setState(() {
        preparing = true;
        paused = false;
        error = null;
      });
      for (; cursor < queue.length; cursor++) {
        if (!mounted || token != generation) return;
        text = queue[cursor].value;
        progress = 0;
        setState(() => current = queue[cursor].key);
        setState(() {
          preparing = true;
          playing = false;
        });
        startWatchdog?.cancel();
        startWatchdog = Timer(const Duration(seconds: 8), () {
          if (mounted && token == generation && preparing) unawaited(fail());
        });
        utterance = Completer<void>();
        final result = await tts
            .speak(text)
            .timeout(const Duration(seconds: 15));
        if (result == 0) throw StateError('TTS rejected speech');
        await utterance!.future.timeout(const Duration(minutes: 10));
        startWatchdog?.cancel();
        if (token != generation) return;
      }
      if (mounted) {
        setState(() {
          playing = false;
          preparing = false;
          current = '';
          finished = true;
        });
      }
    } catch (_) {
      await fail();
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> pause() async {
    generation++;
    if (utterance?.isCompleted == false) utterance!.complete();
    if (cursor < queue.length) {
      queue[cursor] = MapEntry(
        current,
        text.substring(progress.clamp(0, text.length)),
      );
    }
    await tts.stop();
    if (mounted) {
      setState(() {
        paused = true;
        playing = false;
        preparing = false;
      });
    }
  }

  @override
  void dispose() {
    generation++;
    if (utterance?.isCompleted == false) utterance!.complete();
    startWatchdog?.cancel();
    EssayVoice.stopActive = null;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResultAccordion(
    title: '음성으로 듣기',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<String>(
          isExpanded: true,
          value: selected,
          items: [
            '전체 결과',
            ...essaySpeechSections(widget.report, widget.before).keys,
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: playing || preparing
              ? null
              : (v) => setState(() => selected = v!),
        ),
        if (current.isNotEmpty) Text('듣는 항목: $current'),
        Text(
          preparing
              ? '음성 준비 중'
              : paused
              ? '일시정지'
              : playing
              ? '재생 중'
              : finished
              ? '재생 완료'
              : '재생 대기',
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: playing || preparing || starting ? null : speak,
              child: Text(paused ? '재개' : '듣기'),
            ),
            TextButton(
              onPressed: playing && !paused ? pause : null,
              child: const Text('일시정지'),
            ),
            TextButton(
              onPressed: playing || paused || preparing || starting
                  ? stop
                  : null,
              child: const Text('중지'),
            ),
          ],
        ),
        if (error != null) Text(error!),
      ],
    ),
  );
}
