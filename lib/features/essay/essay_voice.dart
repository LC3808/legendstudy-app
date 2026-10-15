import 'evaluation_presentation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'evaluation_report.dart';
import 'approved_result_adapter.dart';

/// Device speech only. Reads stored feedback without generating new content.
Map<String, String> essaySpeechSections(
  EvaluationReport report, [
  EvaluationReport? before,
]) {
  final changes = before == null ? null : compareEvaluationReports(before, report);
  if (changes != null) {
    changes.sort((a, b) => (a.direction == 'UNCHANGED' ? 1 : 0).compareTo(b.direction == 'UNCHANGED' ? 1 : 0));
  }
  final improved = changes?.where((c) => c.direction == 'IMPROVED').firstOrNull;
  final resolved = report.previousReviews.where((r) => r['outcome'] == 'resolved').firstOrNull;
  final sections = <String, String>{
    if (changes != null)
      '이번 답안의 변화 한눈에 보기': [
        '좋아진 점.',
        improved == null ? '평가에 명시된 변화가 아직 없어요.' : evaluationChangeSpeech(shortCriterionTitle(improved.after.name), improved.before.rating, improved.after.rating),
        '아직 보완할 점.',
        if (report.weaknesses.isEmpty) '평가에 명시된 보완 내용이 없어요.',
        ...report.weaknesses.take(2).map((r) => '${r.title}. ${r.explanation}'),
        '해결한 부분.',
        resolved == null ? '이번 평가에서 확인된 항목이 없어요.' : evaluationText(resolved['reason']),
        '다음에 확인할 부분.',
        report.nextSteps.firstOrNull ?? '평가에 명시된 확인 항목이 없어요.',
      ].join('\n'),
    if (changes != null)
      '평가 항목 변화': changes.map((c) => evaluationChangeSpeech(shortCriterionTitle(c.after.name), c.before.rating, c.after.rating)).join('\n'),
    '종합 평가': report.summary,
    '잘한 점': report.strengths.map((r) => '${r.title}. ${r.explanation}').join('\n'),
    '평가 항목별 진단': report.rubric.map((r) => '${shortCriterionTitle(r.name)}. ${r.rating == null ? r.value : '5단계 평가 중 ${r.rating}단계입니다.'} ${r.feedback}').join('\n'),
    '보완할 점': report.weaknesses.map((r) => '${r.title}. ${r.explanation}').join('\n'),
    '먼저 고쳐야 할 부분': report.actions.join('\n'),
    '다시 쓸 때 확인할 것': report.nextSteps.join('\n'),
  };
  return sections;
}

class EssayVoice extends StatefulWidget {
  static Future<void> Function()? stopActive;
  const EssayVoice({super.key, required this.report, this.before});
  final EvaluationReport report;
  final EvaluationReport? before;
  @override
  State<EssayVoice> createState() => _EssayVoiceState();
}

class _EssayVoiceState extends State<EssayVoice> with WidgetsBindingObserver {
  final tts = FlutterTts();
  String selected = '전체 결과', current = '', text = '';
  bool playing = false, paused = false;
  int generation = 0;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EssayVoice.stopActive = stop;
  }

  Future<void> stop() async {
    generation++;
    await tts.stop();
    if (mounted) {
      setState(() {
        playing = false;
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
          final lines = e.value.split('\n').where((line) => line.trim().isNotEmpty && seen.add(line.trim())).join('\n');
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
      await tts.setLanguage('ko-KR');
      await tts.awaitSpeakCompletion(true);
      tts.setProgressHandler((_, start, end, word) {
        progress = start;
      });
      if (!mounted || token != generation) return;
      setState(() {
        playing = true;
        paused = false;
        error = null;
      });
      for (; cursor < queue.length; cursor++) {
        if (!mounted || token != generation) return;
        text = queue[cursor].value;
        progress = 0;
        setState(() => current = queue[cursor].key);
        await tts.speak(text);
        if (token != generation) return;
      }
      if (mounted) {
        setState(() {
          playing = false;
          current = '';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          playing = false;
          paused = false;
          error = '기기 음성을 사용할 수 없어요.';
        });
      }
    }
  }

  Future<void> pause() async {
    generation++;
    if (cursor < queue.length) {
      queue[cursor] = MapEntry(
        current,
        text.substring(progress.clamp(0, text.length)),
      );
    }
    await tts.stop();
    if (mounted) setState(() => paused = true);
  }

  @override
  void dispose() {
    generation++;
    EssayVoice.stopActive = null;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('음성으로 듣기'),
    children: [
      DropdownButton<String>(
        isExpanded: true,
        value: selected,
        items: [
          '전체 결과',
          ...essaySpeechSections(widget.report, widget.before).keys,
        ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: playing ? null : (v) => setState(() => selected = v!),
      ),
      if (current.isNotEmpty) Text('듣는 항목: $current'),
      Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: playing && !paused ? null : speak,
            child: Text(paused ? '재개' : '듣기'),
          ),
          TextButton(
            onPressed: playing && !paused ? pause : null,
            child: const Text('일시정지'),
          ),
          TextButton(onPressed: playing ? stop : null, child: const Text('중지')),
        ],
      ),
      if (error != null) Text(error!),
    ],
  );
}
