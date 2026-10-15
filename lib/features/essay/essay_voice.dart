import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'evaluation_report.dart';
import 'approved_result_adapter.dart';

/// Device speech only. Reads stored feedback without generating new content.
Map<String, String> essaySpeechSections(
  EvaluationReport report, [
  EvaluationReport? before,
]) => {
  if (before != null && compareEvaluationReports(before, report) != null)
    '평가 변화': compareEvaluationReports(before, report)!
        .map(
          (c) =>
              '${shortCriterionTitle(c.after.name)}. 평가 단계 ${c.before.rating}/5에서 ${c.after.rating}/5. ${c.after.feedback}',
        )
        .join('\n'),
  '종합 평가': report.summary,
  '평가요소별 결과': report.rubric
      .map(
        (r) =>
            '${shortCriterionTitle(r.name)}. ${r.rating == null ? r.value : '평가 단계 ${r.rating}/5.'} ${r.feedback}',
      )
      .join('\n'),
  '잘한 점': report.strengths
      .map((r) => '${r.title}. ${r.explanation}')
      .join('\n'),
  '보완할 점': report.weaknesses
      .map((r) => '${r.title}. ${r.explanation}')
      .join('\n'),
  '수정 방향 안내': [...report.actions, ...report.nextSteps].join('\n'),
};

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
        for (final e in essaySpeechSections(
          widget.report,
          widget.before,
        ).entries) {
          if ((selected != '전체 결과' && selected != e.key) ||
              e.value.trim().isEmpty) {
            continue;
          }
          final body = '${e.key}입니다. ${e.value}';
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
