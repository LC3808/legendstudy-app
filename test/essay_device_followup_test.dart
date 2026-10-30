import 'dart:convert';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/result_disclosure.dart';
import 'package:legendstudy_app/features/essay/approved_result_adapter.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/essay_voice.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/exam-history-v1.json').readAsStringSync(),
  ) as Map;
  for (final key in ['before', 'after']) {
    fixture[key]['result']['questions'][0]['criteria'][0]['label'] =
        List.filled(12, '평가기준 전체 제목').join(' ');
  }
  final before = examEvaluationReport(
    Map<String, dynamic>.from(fixture['before'] as Map),
    'question',
  );
  final after = examEvaluationReport(
    Map<String, dynamic>.from(fixture['after'] as Map),
    'question',
  );
  test('comparison overview carries full stored criterion and feedback', () {
    final e = approvedEssayEvaluation(after, before);
    final body = e.changes['좋아진 부분']!.join();
    expect(body, contains(after.rubric.first.name));
    expect(body, contains(after.rubric.first.feedback));
  });
  test(
    'paragraph markers formulas and table rows survive display formatting',
    () {
      const s = '[문항 1]\n• 첫 번째 기준\n\n① 다음 항목\nx = y + z\n| 값 | 결과 |';
      expect(displayEssayText(s), s);
      expect(
        displayEssayText('이 문장은 표시 계층에서 연결하는 충분히 긴 설명으로\n이어집니다.'),
        '이 문장은 표시 계층에서 연결하는 충분히 긴 설명으로 이어집니다.',
      );
    },
  );
  test('flat grade criteria remain ordered raw lines rather than an invented table', () {
    const raw =
        '1. 공식 항목의 충족을 충분히 자세하게 기술한 경우 10\nS 1, 2, 3을 모두 올바르게 제시하였음\n상\nA 1, 2, 3을 모두 제시했으나 논리가 부족함\n중 C 1, 2를 올바르게 제시하였음';
    expect(displayEssayText(raw), raw);
  });
  test('stored mid-word criterion markers are never reordered or removed', () {
    const raw = '이유를 제시하\n준거 1 는 것이다.\n\n엄청난 힘을 지닌 인\n준거 2 공 지능이';
    expect(displayEssayText(raw), raw);
  });
  test(
    'explicit feedback action receives one paragraph gap without invention',
    () {
      expect(
        displayEssayText('평가 문장입니다.\n개선 방법: 근거를 확인하세요.'),
        '평가 문장입니다.\n\n개선 방법: 근거를 확인하세요.',
      );
      expect(
        displayEssayText('평가 문장입니다.\n\n개선 방법: 확인하세요.'),
        '평가 문장입니다.\n\n개선 방법: 확인하세요.',
      );
      expect(displayEssayText('개선 방법이 없습니다.'), '개선 방법이 없습니다.');
    },
  );
  test('criterion change and stored feedback have independent paragraphs', () {
    final text = approvedEssayEvaluation(
      after,
      before,
    ).changes['좋아진 부분']!.first;
    expect(text, startsWith('평가 기준\n'));
    expect(text, contains('\n\n평가 변화\n'));
    expect(text, contains('\n\n평가 설명\n${after.rubric.first.feedback}'));
    expect(displayEssayText(text), contains('\n\n평가 설명\n'));
  });
  testWidgets('accordion has a visible restrained navy border', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResultAccordion(title: '종합 평가', child: Text('원문')),
        ),
      ),
    );
    final tile = t.widget<ExpansionTile>(find.byType(ExpansionTile));
    expect(
      (tile.collapsedShape as RoundedRectangleBorder).side.color,
      const Color(0xFF9CAABE),
    );
    await t.tap(find.text('종합 평가'));
    await t.pumpAndSettle();
    expect(find.text('원문'), findsOneWidget);
  });
  for (final text in [
    '짧은 평가',
    List.filled(40, '긴 평가 문장입니다.').join(' '),
    '첫 문단\n\n• 항목 하나\n• 항목 둘',
  ]) {
    testWidgets('single full disclosure repeated ${text.length}', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResultTextDisclosure(text: text),
            ),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byType(ResultTextDisclosure));
        await t.pump();
        expect(
          t.widget<Text>(find.text(displayEssayText(text))).maxLines,
          isNull,
        );
        expect(find.text(displayEssayText(text)), findsOneWidget);
        await t.tap(find.byType(ResultTextDisclosure));
        await t.pump();
        expect(t.widget<Text>(find.text(displayEssayText(text))).maxLines, 3);
      }
    });
  }
  testWidgets('criterion title is not duplicated in expanded body', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GrowthCriterionTitle(name: '[문항 1]\n평가 기준 전문이 이어집니다.'),
        ),
      ),
    );
    await t.tap(find.text('[문항 1]'));
    await t.pumpAndSettle();
    expect(find.text('[문항 1]'), findsOneWidget);
    expect(find.text('평가 기준 전문이 이어집니다.'), findsOneWidget);
  });
  testWidgets('processing guidance rotates only for active server processing', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(home: ProcessingGuidance(active: true)),
    );
    await t.pump(const Duration(seconds: 6));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('잠시 쉬어가세요'), findsOneWidget);
    await t.pumpWidget(
      const MaterialApp(home: ProcessingGuidance(active: false)),
    );
    await t.pump(const Duration(seconds: 12));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('접수된 답안'), findsOneWidget);
  });
  testWidgets('direct history navigation clears nested result stack', (
    t,
  ) async {
    late GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => goToEssayHistory(context),
                      child: const Text('기록으로'),
                    ),
                  ),
                ),
              ),
              child: const Text('결과 열기'),
            ),
          ),
        ),
        GoRoute(
          path: '/lab/essay/history',
          builder: (context, state) => const Scaffold(body: Text('기록 목록')),
        ),
      ],
    );
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.tap(find.text('결과 열기'));
    await t.pumpAndSettle();
    await t.tap(find.text('기록으로'));
    await t.pumpAndSettle();
    expect(find.text('기록 목록'), findsOneWidget);
    expect(router.canPop(), isFalse);
    await t.pumpWidget(const SizedBox());
    router.dispose();
  });
  testWidgets(
    'TTS iOS playback config, start confirmation, completion and failure',
    (t) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final engine = IosTestTts();
      const channel = MethodChannel('flutter_tts');
      final calls = <MethodCall>[];
      bool rejected = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'speak' && rejected ? 0 : 1;
          });
      Future<void> event(String name) async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              'flutter_tts',
              const StandardMethodCodec().encodeMethodCall(MethodCall(name)),
              (_) {},
            );
        await t.pump();
      }

      await t.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: EssayVoice(report: after, engine: engine),
          ),
        ),
      );
      await t.tap(find.text('음성으로 듣기'));
      await t.pumpAndSettle();
      t
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .onChanged!('종합 평가');
      await t.pump();
      await t.tap(find.text('듣기'));
      await t.pump();
      await t.pump();
      expect(find.text('재생 중'), findsNothing);
      expect(engine.category, IosTextToSpeechAudioCategory.playback);
      expect(engine.options, isEmpty);
      expect(engine.mode, IosTextToSpeechAudioMode.defaultMode);
      await event('speak.onStart');
      expect(find.text('재생 중'), findsOneWidget);
      await t.tap(find.widgetWithText(TextButton, '일시정지'));
      await t.pump();
      expect(find.text('일시정지'), findsNWidgets(2));
      await event('speak.onCancel');
      await t.tap(find.text('재개'));
      await t.pump();
      await t.pump();
      await event('speak.onStart');
      await event('speak.onComplete');
      expect(find.text('재생 완료'), findsOneWidget);
      await t.tap(find.text('듣기'));
      await t.pump();
      await t.pump();
      await event('speak.onStart');
      await t.tap(find.text('중지'));
      await t.pump();
      expect(find.text('재생 중'), findsNothing);
      rejected = true;
      await t.tap(find.text('듣기'));
      await t.pump();
      await t.pump();
      expect(find.textContaining('음성을 재생하지 못했어요'), findsOneWidget);
      expect(
        calls.where((c) => c.method == 'awaitSpeakCompletion').last.arguments,
        false,
      );
      rejected = false;
      await t.tap(find.text('듣기'));
      await t.pump();
      await t.pump();
      await t.pump(const Duration(seconds: 9));
      await t.pump();
      expect(find.text('재생 중'), findsNothing);
      expect(find.textContaining('음성을 재생하지 못했어요'), findsOneWidget);
      await t.tap(find.text('듣기'));
      await t.pump();
      await t.pump();
      await event('speak.onStart');
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.text('재생 중'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}

// flutter_tts guards its iOS category call with dart:io Platform.isIOS.
// Host tests assert our API arguments; real AVAudioSession/acoustic output needs iPhone QA.
class IosTestTts extends FlutterTts {
  IosTextToSpeechAudioCategory? category;
  List<IosTextToSpeechAudioCategoryOptions>? options;
  IosTextToSpeechAudioMode? mode;
  @override
  Future<dynamic> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, [
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  ]) async {
    this.category = category;
    this.options = options;
    this.mode = mode;
    return 1;
  }
}
