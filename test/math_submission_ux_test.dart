import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_exam_session.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_recognition_panel.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';

import 'math_exam_session_test.dart' show RoundGateway;

class ProgressGateway extends RoundGateway {
  int reads = 0, extractions = 0;
  bool finish = false, failRead = false;
  final extraction = Completer<void>();
  bool ocrStarted = false, ocrCompleted = false;
  @override
  Future<dynamic> session(String name, Map<String, dynamic> params) async {
    if (name == 'math_session_read') {
      reads++;
      if (failRead) throw StateError('offline');
      return {
        'version': 'math-session-v1',
        'run_id': 'run',
        'exam_id': 'exam',
        'state': finish ? 'completed' : 'reserved',
        'questions': [
          for (final id in ['q1', 'q2'])
            {
              'evaluation_id': 'e$id',
              'attempt_id': 'a$id',
              'question_id': id,
              'state': id == 'q1' || finish ? 'COMPLETED' : 'PROCESSING',
            },
        ],
      };
    }
    return super.session(name, params);
  }

  @override
  Future<Map<String, dynamic>> call(
    String fn,
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (action == 'register_evidence') return {'artifact_id': 'image'};
    if (action == 'read_input') {
      return {
        'can_request_evaluation': false,
        'input_state': ocrCompleted
            ? 'CONFIRMATION_REQUIRED'
            : 'INPUT_REQUIRED',
        if (ocrStarted)
          'candidate': {
            'run_id': 'ocr',
            'state': ocrCompleted ? 'COMPLETED' : 'PROCESSING',
          },
        'candidate_regions': ocrCompleted
            ? [
                {
                  'region_id': 'r',
                  'raw_text': 'r = -1/6',
                  'normalized_math': 'r = -1/6',
                  'uncertain': true,
                },
              ]
            : <dynamic>[],
      };
    }
    return super.call(fn, action, payload);
  }

  @override
  Future<void> uploadEvidence(String id, Uint8List bytes) async {}
  @override
  Future<void> extract(String id) async {
    extractions++;
    ocrStarted = true;
    await extraction.future;
  }
}

void main() {
  late Map<String, String> disk;
  late Map<String, Uint8List> images;
  setUp(() {
    disk = {};
    images = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
          if (call.method == 'read') return disk[call.arguments];
          if (call.method == 'readImage') return images[call.arguments];
          final args = call.arguments;
          if (args is Map && call.method == 'write') {
            disk[args['key'] as String] = args['value'] as String;
          }
          if (args is Map && call.method == 'writeImage') {
            images[args['key'] as String] = args['value'] as Uint8List;
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, null),
  );

  Future<void> mount(
    WidgetTester t,
    ProgressGateway gateway, {
    bool pending = false,
  }) async {
    await t.binding.setSurfaceSize(const Size(393, 1100));
    addTearDown(() => t.binding.setSurfaceSize(null));
    if (pending) {
      await SourceDraftGateway(
        'owner',
        'math-session:exam:initial:draft1,draft2',
      ).saveLocalDraft(
        jsonEncode({'key': 'same-request', 'submitted': true, 'runId': 'run'}),
        0,
      );
    }
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('owner')),
          ),
          mathGatewayProvider('owner').overrideWithValue(gateway),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExamSession(
                owner: 'owner',
                exam: {
                  'dbExamId': 'exam',
                  'questions': [
                    {'key': 'draft1', 'dbQuestionId': 'q1', 'label': '문제 1'},
                    {'key': 'draft2', 'dbQuestionId': 'q2', 'label': '문제 2'},
                  ],
                },
                selected: {'draft1', 'draft2'},
                leaves: {'q1': 'leaf1', 'q2': 'leaf2'},
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'partial evaluation shows real progress; foreground polls are read-only and stop on completion',
    (t) async {
      final fake = ProgressGateway();
      await mount(t, fake, pending: true);
      expect(find.byType(StepProgressBar), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('첨삭이 완료됐어요'), findsNothing);
      expect(find.text('문제 1 첨삭 결과 보기'), findsNothing);
      final reads = fake.reads;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(seconds: 5));
      expect(fake.reads, reads);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      fake.finish = true;
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.text('첨삭이 완료됐어요'), findsOneWidget);
      expect(find.text('문제 1 첨삭 결과 보기'), findsOneWidget);
      expect(find.text('문제 2 첨삭 결과 보기'), findsOneWidget);
      expect(find.text('새 답안 준비'), findsNothing);
      expect(find.text('첨삭 상태 새로고침'), findsNothing);
      expect(fake.evaluated, isEmpty);
      expect(fake.submissions, isEmpty);
      final completeReads = fake.reads;
      await t.pump(const Duration(seconds: 30));
      expect(fake.reads, completeReads);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failed poll stops activity and manual refresh keeps the same run without evaluating',
    (t) async {
      final fake = ProgressGateway();
      await mount(t, fake, pending: true);
      fake.failRead = true;
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('연결을 확인하지 못했어요'), findsOneWidget);
      final reads = fake.reads;
      await t.pump(const Duration(seconds: 30));
      expect(fake.reads, reads);
      fake.failRead = false;
      fake.finish = true;
      await t.tap(find.text('첨삭 상태 새로고침'));
      await t.pumpAndSettle();
      expect(find.text('첨삭이 완료됐어요'), findsOneWidget);
      expect(fake.evaluated, isEmpty);
      expect(fake.submissions, isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'photo OCR shows progress and polls once; uncertain input cannot evaluate',
    (t) async {
      final fake = ProgressGateway();
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aV3sAAAAASUVORK5CYII=',
      );
      await SourceDraftGateway('owner', 'draft1').saveImages([png]);
      await SourceDraftGateway('owner', 'draft2').saveLocalDraft('x=1', 0);
      await mount(t, fake);
      await t.pumpAndSettle();
      await t.tap(find.text('저장한 답안 확인'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('수식과 문장을 인식'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('첨삭 요청하기'), findsNothing);
      fake.extraction.complete();
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      fake.ocrCompleted = true;
      await t.pump(const Duration(seconds: 3));
      await t.pumpAndSettle();
      expect(find.byType(MathRecognitionPanel), findsNWidgets(2));
      expect(find.text('첨삭 요청하기'), findsNothing);
      expect(fake.extractions, 1);
      expect(fake.evaluated, isEmpty);
      expect(fake.submissions, isEmpty);
      await t.pumpWidget(const SizedBox());
    },
  );
}
