import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/essay_live_gateway.dart';
import 'package:legendstudy_app/features/essay/essay_live_controller.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/essay/essay_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeEssayStore implements EssayStore {
  @override
  String? userId = 'owner';
  final calls = <String>[];
  final params = <Map<String, Object?>>[];
  final tables = <String, List<Map<String, dynamic>>>{};
  Future<Object?> Function(String, Map<String, Object?>)? handler;
  FakeEssayStore() {
    tables['essay_practice_sessions'] = [
      {
        'id': 'session',
        'user_id': 'owner',
        'question_id': 'q',
        'created_at': '2026',
      },
    ];
    tables['essay_drafts'] = [
      {
        'session_id': 'session',
        'body': '답안',
        'revision': 1,
        'mode': 'practice',
      },
    ];
  }
  @override
  Future<List<Map<String, dynamic>>> rows(
    String table,
    Map<String, Object> filter,
  ) async => (tables[table] ?? [])
      .where((r) => filter.entries.every((e) => r[e.key] == e.value))
      .toList();
  @override
  Future<Object?> rpc(String name, Map<String, Object?> args) async {
    calls.add(name);
    params.add(args);
    if (handler != null) return handler!(name, args);
    return switch (name) {
      'essay_open_session' => args['p_id'],
      'essay_save_draft' => (args['p_revision'] as int) + 1,
      'essay_submit_attempt' => 'attempt',
      'essay_request_evaluation' => 'evaluation',
      'essay_evaluation_status' => projection(),
      _ => throw StateError('Unexpected RPC'),
    };
  }
}

Map<String, dynamic> projection({
  String state = 'processing',
  String credit = 'reserved',
  String mode = 'paid',
  bool free = false,
}) => {
  'state': state,
  'credit_state': credit,
  'credit_mode': mode,
  'release_confirmed': credit == 'released',
  'no_credit_consumed': free,
};
SupabaseEssayGateway gateway(FakeEssayStore store) => SupabaseEssayGateway(
  store,
  questionId: 'q',
  writesEnabled: true,
  evaluationsEnabled: true,
);
Map<String, dynamic> evaluation({String version = '1.3'}) => {
  'id': 'e',
  'attempt_id': 'a',
  'session_id': 'session',
  'status': 'completed',
  'contract_version': version,
  'regime_key': 'essay-v$version',
  'model_provider': 'fixture',
  'model_name': 'fixture',
  'model_version': '1',
  'overall_summary': '종합 평가',
  'strengths': ['장점'],
  'rewrite_checklist': ['확인'],
  'input_snapshot': <String, dynamic>{
    'criteria': [
      {'id': 'c', 'version': '1'},
    ],
    'evidence': <Object>[],
  },
};
const answer = '😀 가 답안';
Map<String, dynamic> attempt() => {
  'id': 'a',
  'body': answer,
  'body_sha256': sha256.convert(utf8.encode(answer)).toString(),
};
Map<String, dynamic> sentence() => {
  'observation_key': 's',
  'category': 'expression',
  'priority': 'wording',
  'start': 0,
  'end': 1,
  'quote': '😀',
  'diagnosis': '확인해 보세요.',
  'direction': '의미를 설명해 보세요.',
};
Map<String, dynamic> progress({
  bool core = true,
  List<Map<String, dynamic>>? sentences,
}) => {
  'id': 'p',
  'issue_id': 'root',
  'evaluation_id': 'e',
  'status': 'open',
  'priority': 1,
  'explanation': '보완',
  'next_action': '실행',
  'scaffolding_observation': {
    'version': 1,
    'core_focus': core,
    'sentences': sentences ?? [],
  },
};
MappedEssayResult mapped({
  Map<String, dynamic>? e,
  List<Map<String, dynamic>>? items,
  Map<String, dynamic>? previous,
  List<Map<String, dynamic>> previousDimensions = const [],
}) => mapEssayResult(
  evaluation: e ?? evaluation(),
  attempt: attempt(),
  dimensions: [
    {
      'evaluation_id': 'e',
      'criterion_id': 'c',
      'display_order': 0,
      'level_1_to_5': 4,
      'explanation': '진단',
    },
  ],
  criteria: [
    {
      'id': 'c',
      'definition_version': '1',
      'label': '이해',
      'official_weight_percent': 25.5,
    },
  ],
  progress: items ?? [],
  history: const EssayHistory([], [], []),
  evidence: [],
  mappings: [],
  examples: [],
  included: false,
  previousEvaluation: previous,
  previousDimensions: previousDimensions,
);
void main() {
  test('open resumes owner session without generating a new cycle', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    final d = await g.open();
    expect(g.sessionId, 'session');
    expect(d.revision, 1);
    expect(s.params.single['p_id'], 'session');
    final g2 = gateway(s);
    await g2.open();
    expect(g2.sessionId, 'session');
  });
  test(
    'first open key survives lost response and a new client instance',
    () async {
      final s = FakeEssayStore();
      s.tables['essay_practice_sessions'] = [];
      final keys = <Object?>[];
      s.handler = (name, args) async {
        keys.add(args['p_id']);
        throw const PostgrestException(message: 'network', code: 'NETWORK');
      };
      await expectLater(gateway(s).open(), throwsA(isA<EssayClientError>()));
      await expectLater(gateway(s).open(), throwsA(isA<EssayClientError>()));
      expect(keys.toSet().length, 1);
    },
  );
  test('same request cannot silently switch to another attempt', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    await g.open();
    await expectLater(g.requestEvaluation('a'), throwsA(isA<EssayPending>()));
    await expectLater(
      g.requestEvaluation('b'),
      throwsA(isA<EssayClientError>()),
    );
  });
  test('foreign explicit session denied', () async {
    final s = FakeEssayStore();
    s.userId = 'other';
    await expectLater(
      gateway(s).open(resumeSession: 'session'),
      throwsA(isA<EssayClientError>()),
    );
  });
  test('draft CAS revision, null active time, device metadata', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    await g.open();
    expect((await g.saveDraft('수정', 1)).revision, 2);
    expect(s.params.last['p_active_seconds'], null);
    expect(s.params.last['p_device'], 'app_mobile');
  });
  test('stale draft maps to conflict without overwrite', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    await g.open();
    s.handler = (_, _) async =>
        throw const PostgrestException(message: 'STALE_DRAFT', code: 'PT409');
    await expectLater(g.saveDraft('남길 글', 1), throwsA(isA<EssayConflict>()));
  });
  test(
    'submission key stable on retry/restart and changes with payload',
    () async {
      final s = FakeEssayStore();
      final g = gateway(s);
      await g.open();
      await g.submit(answer, 1, 'unused');
      final first = s.params.last;
      await g.submit(answer, 1, 'different');
      expect(s.params.last, first);
      final g2 = gateway(s);
      await g2.open();
      await g2.submit(answer, 1, '');
      expect(s.params.last, first);
      await g2.submit('다른 글', 1, '');
      expect(s.params.last['p_key'], isNot(first['p_key']));
      expect(
        first['p_body_hash'],
        sha256.convert(utf8.encode(answer)).toString(),
      );
    },
  );
  for (final credit in ['reserved', 'included']) {
    test(
      'request $credit uses server decision, never a balance precheck',
      () async {
        final s = FakeEssayStore();
        final g = gateway(s);
        await g.open();
        s.handler = (name, args) async => name == 'essay_request_evaluation'
            ? 'e'
            : projection(
                credit: credit,
                mode: credit == 'included' ? 'included' : 'paid',
              );
        await expectLater(
          g.requestEvaluation('a'),
          throwsA(isA<EssayPending>()),
        );
        expect(g.status!.creditState, credit);
        expect(s.calls.where((c) => c.contains('balance')), isEmpty);
        await expectLater(
          g.requestEvaluation('a'),
          throwsA(isA<EssayPending>()),
        );
        expect(s.calls.where((c) => c == 'essay_request_evaluation').length, 1);
      },
    );
  }
  for (final code in ['PT401', 'PT402', 'PT403', 'PT404', 'PT409', 'PT422']) {
    test('$code sanitized student error', () async {
      final s = FakeEssayStore();
      final g = gateway(s);
      await g.open();
      s.handler = (_, _) async => throw PostgrestException(
        message: 'private provider SQL secret',
        code: code,
      );
      try {
        await g.requestEvaluation('a');
        fail('allowed');
      } on EssayClientError catch (e) {
        expect(e.code, code);
        expect(e.message, isNot(contains('secret')));
        expect(e.message, isNot(contains('잔액 0')));
      }
    });
  }
  test('timeout projection never asserts free even if malformed contradictory bool', () {
    final v = EssayServerStatus.parse(
      projection(
        state: 'reconciling',
        credit: 'included',
        mode: 'included',
        free: true,
      ),
    );
    expect(v.noCreditConsumed, false);
    expect(v.creditMessage, null);
    expect(v.message, contains('다시 요청하지 않아도'));
  });
  test('failed release message only when server confirms', () {
    expect(
      EssayServerStatus.parse(projection(state: 'failed')).message,
      isNot(contains('차감되지')),
    );
    expect(
      EssayServerStatus.parse(
        projection(state: 'failed', credit: 'released', free: true),
      ).message,
      contains('차감되지'),
    );
  });
  test(
    'invalid server status fails closed',
    () => expect(
      () => EssayServerStatus.parse({'state': 'provider_error'}),
      throwsA(isA<EssayClientError>()),
    ),
  );
  test('account switch, logout, and revoked same-user return denied', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    await g.open();
    s.userId = 'other';
    await expectLater(g.loadDraft(), throwsA(isA<EssayClientError>()));
    s.userId = null;
    await expectLater(g.loadHistory(), throwsA(isA<EssayClientError>()));
    g.revoke();
    s.userId = 'owner';
    await expectLater(g.loadDraft(), throwsA(isA<EssayClientError>()));
  });
  test('inflight response discarded after account switch', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    await g.open();
    final response = Completer<Object?>();
    s.handler = (_, _) => response.future;
    final pending = g.submit(answer, 1, '');
    s.userId = 'other';
    response.complete('a');
    await expectLater(pending, throwsA(isA<EssayClientError>()));
    expect(g.attemptId, null);
  });
  test('live writes disabled by default no request', () async {
    final s = FakeEssayStore();
    final g = SupabaseEssayGateway(s, questionId: 'q');
    await g.open();
    await expectLater(
      g.submit(answer, 1, ''),
      throwsA(isA<EssayClientError>()),
    );
    expect(s.calls, isEmpty);
  });
  test('same session revision clears request not cycle', () async {
    final s = FakeEssayStore();
    final g = gateway(s);
    await g.open();
    g.evaluationId = 'e';
    g.beginRevision();
    expect(g.sessionId, 'session');
    expect(g.evaluationId, null);
  });
  test('legacy NULL vs 1.3 supported zero observations', () {
    expect(mapped(e: evaluation(version: '1.2')).sentences, null);
    expect(mapped().sentences!.items, isEmpty);
    expect(mapped(items: [progress(core: false)]).sentences!.items, isEmpty);
    expect(mapped().evaluation.dimensions.single.officialWeight, 25.5);
  });
  test('1.3 exact codepoints + core focus, no invented official evidence', () {
    final r = mapped(
      items: [
        progress(sentences: [sentence()]),
      ],
    );
    expect(r.sentences!.items.single.quote, '😀');
    expect(r.evaluation.priorities, ['실행']);
    expect(r.evidence, isEmpty);
  });
  test('fabricated or UTF16 quote fails closed', () {
    expect(
      () => mapped(
        items: [
          progress(
            sentences: [
              {...sentence(), 'end': 2},
            ],
          ),
        ],
      ),
      throwsA(isA<EssayClientError>()),
    );
    expect(
      () => mapped(
        items: [
          progress(
            sentences: [
              {...sentence(), 'quote': '거짓'},
            ],
          ),
        ],
      ),
      throwsA(isA<EssayClientError>()),
    );
  });
  test(
    'NULL in 1.3 is not silently empty',
    () => expect(
      () => mapped(
        items: [
          {...progress(), 'scaffolding_observation': null},
        ],
      ),
      throwsA(isA<EssayClientError>()),
    ),
  );
  test('duplicate sentence and >5 fail closed', () {
    expect(
      () => mapped(
        items: [
          progress(sentences: [sentence(), sentence()]),
        ],
      ),
      throwsA(isA<EssayClientError>()),
    );
    expect(
      () => mapped(
        items: [progress(sentences: List.generate(6, (_) => sentence()))],
      ),
      throwsA(isA<EssayClientError>()),
    );
  });
  test('history explicit resolved and snapshot comparable; different model not growth', () {
    final e = evaluation();
    final old = {...evaluation(), 'id': 'prior', 'attempt_id': 'prior-a'};
    (e['input_snapshot'] as Map)['scaffolding_context'] = {
      'selected_previous_evaluation_id': 'prior',
      'items': [
        {'progress_id': 'old-p'},
      ],
    };
    final r = mapped(
      e: e,
      previous: old,
      previousDimensions: [
        {'evaluation_id': 'prior', 'criterion_id': 'c', 'level_1_to_5': 3},
      ],
      items: [
        {
          ...progress(core: false),
          'status': 'resolved',
          'previous_progress_id': 'old-p',
        },
      ],
    );
    expect(r.evaluation.comparable, true);
    expect(r.evaluation.dimensions.single.previousLevel, 3);
    expect(r.evaluation.changes['해결한 부분'], ['보완']);
    expect(
      mapped(
        e: e,
        previous: {...old, 'model_version': 'new'},
      ).evaluation.comparable,
      false,
    );
  });
  test(
    'controller pending stays pending; failure/network never fake result',
    () async {
      final s = FakeEssayStore();
      final g = gateway(s);
      final d = await g.open();
      final c = EssayLiveController(g, d);
      await c.submit();
      expect(c.stage, EssayStage.processing);
      expect(c.evaluation, null);
      final n = s.calls.length;
      await c.submit();
      expect(s.calls.length, n);
      c.dispose();
    },
  );
  testWidgets('live completed result has no preview fallback at 360px / 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final result = mapped(
      items: [
        progress(sentences: [sentence()]),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: EssayResultView(
              evaluation: result.evaluation,
              question: essayPreviewQuestions.first,
              comparison: false,
              onRewrite: () {},
              isPreview: false,
              sentenceReview: result.sentences,
              evaluationId: 'e',
              attemptId: 'a',
              submittedAnswer: answer,
              evidenceLabels: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    expect(find.textContaining('표시 예시'), findsNothing);
    expect(find.textContaining('미리보기'), findsNothing);
    expect(find.text('첨삭을 반영한 예시답안 보기'), findsNothing);
  });
  testWidgets('unsaved live text requires explicit discard on leaving', (
    tester,
  ) async {
    final store = FakeEssayStore();
    final g = gateway(store);
    final draft = await g.open();
    final c = EssayLiveController(g, draft);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Text('home')),
      ),
    );
    unawaited(
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => EssayWorkspacePage(
            question: essayPreviewQuestions.first,
            controller: c,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    c.edit('아직 저장되지 않은 원문');
    await tester.pump();
    await nav.currentState!.maybePop();
    await tester.pump();
    expect(find.text('아직 저장하지 못한 내용이 있어요.'), findsOneWidget);
    await tester.tap(find.text('작성 계속'));
    await tester.pump();
    expect(c.body, '아직 저장되지 않은 원문');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  for (final state in ['processing', 'reconciling', 'failed']) {
    testWidgets('live $state at 360px / 200%', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = FakeEssayStore();
      final g = gateway(s);
      final d = await g.open();
      final c = EssayLiveController(g, d);
      c.stage = state == 'failed' ? EssayStage.failed : EssayStage.processing;
      c.serverStatus = EssayServerStatus.parse(projection(state: state));
      c.message = c.serverStatus!.message;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: EssayWorkspacePage(
              question: essayPreviewQuestions.first,
              controller: c,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), null);
      expect(find.textContaining('미리보기'), findsNothing);
      expect(find.text(c.message!), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
