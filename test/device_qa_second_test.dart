import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/answer_sections.dart';
import 'package:legendstudy_app/features/essay/exam_draft_actions.dart';
import 'package:legendstudy_app/features/essay/exam_presentation.dart';
import 'package:legendstudy_app/features/essay/exam_rewrite.dart';
import 'package:legendstudy_app/features/essay/exam_session_status.dart';
import 'package:legendstudy_app/features/essay/exam_submission.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';

import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';
import 'package:legendstudy_app/features/essay/round_history_actions.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

class QaGateway extends ExamSubmissionGateway {
  QaGateway(super.client, super.owner, this.handler);
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) handler;
  final calls = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> request(Map<String, dynamic> payload) async {
    calls.add(payload);
    if (payload['action'] == 'availability') {
      return {
        'ready': true,
        'questionIds': ['q1', 'q2', 'q3'],
      };
    }
    return handler(payload);
  }
}

class QaRoutes extends NavigatorObserver {
  final routes = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      routes.add(route);
}

const owner = 'fixture-a';
Map<String, dynamic> exam([int size = 2]) => {
  'key': 'exam',
  'dbExamId': 'exam-id',
  'sourceUniversityId': 'fixture',
  'verification': 'VERIFIED',
  'evaluationReady': true,
  'track': '인문계열',
  'year': 2026,
  'kind': 'admission',
  'universityName': '대학',
  'questions': [
    for (var i = 1; i <= size; i++)
      {
        'key': 'q$i',
        'dbQuestionId': 'q$i',
        'label': '문제 $i',
        'inputMode': 'text',
      },
  ],
};
Map<String, dynamic> parent() => {
  'id': 'parent',
  'exam_id': 'exam-id',
  'state': 'completed',
  'parent_id': null,
  'free_rewrite_available': true,
  'created_at': '2026-10-29T00:00:00Z',
  'question_ids': ['q1', 'q2'],
  'answers': [
    {'questionId': 'q1', 'body': '원본 1', 'revision': 41},
    {'questionId': 'q2', 'body': '원본 2', 'revision': 17},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, String> disk;
  setUp(() {
    disk = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
          if (call.method == 'read') return disk[call.arguments];
          if (call.method == 'readImage') return null;
          if (call.method == 'write') {
            final args = call.arguments as Map;
            final previous = disk[args['key']];
            expect(
              previous == null ? 0 : jsonDecode(previous)['revision'],
              args['expected'],
            );
            disk[args['key'] as String] = args['value'] as String;
            return null;
          }
          throw StateError('Unexpected storage action');
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, null),
  );

  Future<SupabaseClient> client(
    WidgetTester t,
    Future<http.Response> Function(http.Request) handler,
  ) async {
    final value = SupabaseClient(
      'https://fixture.supabase.co',
      'public-fixture',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        final response = r.url.path.contains('/auth/')
            ? http.Response(jsonEncode(fixtureSession()), 200)
            : await handler(r);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: r,
        );
      }),
    );
    await value.auth.signInWithPassword(
      email: 'student@example.test',
      password: 'fixture',
    );
    addTearDown(() {
      unawaited(value.dispose());
    });
    return value;
  }

  http.Response json(Object data) => http.Response(
    jsonEncode(data),
    200,
    headers: {'content-type': 'application/json'},
  );
  Future<void> mount(
    WidgetTester t,
    SupabaseClient c,
    QaGateway gateway,
    Widget child,
  ) async {
    addTearDown(() async {
      await t.pumpWidget(const SizedBox());
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(c),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(owner)),
          ),
          examSubmissionGatewayProvider(owner).overrideWithValue(gateway),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  test(
    'parent-relative revision and exact question set preserve frozen lineage',
    () {
      final source = parent();
      final result = examRewriteAnswers([
        {'questionId': 'q2', 'body': '원본 2', 'revision': 1},
        {'questionId': 'q1', 'body': '수정 1', 'revision': 2},
      ], source);
      expect(result.map((a) => a['revision']), [17, 42]);
      expect(source, parent());
      expect(
        () => examRewriteAnswers([result.first], source),
        throwsStateError,
      );
      expect(
        () => examRewriteAnswers([result.first, result.first], source),
        throwsStateError,
      );
      expect(
        () => examRewriteAnswers(result, {
          ...source,
          'answers': [
            {'questionId': 'wrong', 'body': 'original', 'revision': 1},
            {'questionId': 'q2', 'body': 'original', 'revision': 1},
          ],
        }),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'safe reason',
            contains('최초 제출'),
          ),
        ),
      );
    },
  );

  testWidgets(
    'eligible result action selects included lineage even when paid cycles are supported',
    (t) async {
      bool? paid;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EssayFollowupAction(
              run: {...parent(), 'continuous_cycles_supported': true},
              onOpen: (v) async {
                paid = v;
              },
            ),
          ),
        ),
      );
      expect(find.text('추가 첨삭 · 1 Credit'), findsNothing);
      await t.tap(find.text('다시 써보기 · 무료 재첨삭'));
      expect(paid, false);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EssayFollowupAction(
              run: {
                ...parent(),
                'free_rewrite_available': false,
                'continuous_cycles_supported': true,
              },
              onOpen: (v) async {
                paid = v;
              },
            ),
          ),
        ),
      );
      await t.tap(find.text('추가 첨삭 · 1 Credit'));
      expect(paid, true);
    },
  );

  test('draft recovery never overwrites edits or copies an unresolved paid submission', () async {
    final source = SourceDraftGateway('owner', 'q1:additional:parent');
    await source.saveLocalDraft('이전 경로에서 수정한 답안', 0);
    final target = SourceDraftGateway('owner', 'q1:rewrite:parent');
    await target.saveLocalDraft('이미 작성 중인 무료 답안', 0);
    expect(
      await recoverIncludedEssayDraft('owner', 'exam', 'q1', parent()),
      false,
    );
    expect((await target.loadDraft()).body, '이미 작성 중인 무료 답안');
    expect((await source.loadDraft()).body, '이전 경로에서 수정한 답안');
    await SourceDraftGateway(
      'owner',
      'q2:additional:parent',
    ).saveLocalDraft('보존할 답안', 0);
    await SourceDraftGateway(
      'owner',
      'exam-request:exam:additional:parent',
    ).saveLocalDraft('{"key":"unconfirmed"}', 0);
    expect(
      await recoverIncludedEssayDraft('owner', 'exam', 'q2', parent()),
      false,
    );
    expect(
      (await SourceDraftGateway('owner', 'q2:rewrite:parent').loadDraft()).body,
      '',
    );
    expect(
      await recoverIncludedEssayDraft('owner', 'other', 'q2', {
        ...parent(),
        'free_rewrite_available': false,
      }),
      false,
    );
    expect(
      await recoverIncludedEssayDraft('owner', 'other', 'q2', {
        ...parent(),
        '_additional': true,
      }),
      false,
    );
  });

  for (final additional in [false, true]) {
    testWidgets(
      '${additional ? 'paid followup' : 'free rewrite'} quote and submit preserve canonical IDs and Credit consent',
      (t) async {
        final source = parent();
        if (additional) source['_additional'] = true;
        final c = await client(t, (r) async {
          if (r.url.path.endsWith('essay_exam_history')) {
            final id = jsonDecode(r.body)['p_run'];
            return json({
              'version': 'essay-exam-history-v1',
              'runs': id == 'parent'
                  ? [parent()]
                  : id == 'new-run'
                  ? [
                      {
                        'id': 'new-run',
                        'state': 'reserved',
                        'question_ids': ['q1', 'q2'],
                      },
                    ]
                  : <Map<String, dynamic>>[],
            });
          }
          if (r.url.path.endsWith(
            const bool.fromEnvironment('ESSAY_OBSERVATION_V1_ENABLED')
                ? 'essay_exam_observation'
                : 'essay_exam_session_status',
          )) {
            return json({
              'version': 'exam-session-v1',
              'state': 'reserved',
              'retry_allowed': false,
              'questions': [
                {'question_id': 'q1', 'state': 'waiting'},
                {'question_id': 'q2', 'state': 'waiting'},
              ],
            });
          }
          return json({});
        });
        if (!additional) {
          final proof = await SharedEssayHistory(c, owner).examRuns('parent');
          expect(proof.single['free_rewrite_available'], true);
        }
        final gateway = QaGateway(
          c,
          owner,
          (p) async => p['action'] == 'quote'
              ? {
                  'version': 'essay-exam-quote-v1',
                  'credits': additional ? 1 : 0,
                  'credit_source': {
                    'version': 'essay-credit-source-v1',
                    'grant_id': additional
                        ? '11111111-1111-4111-8111-111111111111'
                        : null,
                    'source': additional ? 'purchase' : 'included',
                    'purchase': 3,
                    'beta': 0,
                    'signup_bonus': 0,
                    'other': 0,
                  },
                }
              : {'runId': 'new-run'},
        );
        for (var i = 1; i <= 2; i++) {
          await SourceDraftGateway(
            owner,
            essayWritingDraftKey('q$i', {...source, '_additional': true}),
          ).saveLocalDraft(i == 1 ? '수정 1' : '원본 2', 0);
          if (!additional) {
            expect(
              await recoverIncludedEssayDraft(owner, 'exam', 'q$i', source),
              true,
            );
            expect(
              (await SourceDraftGateway(
                owner,
                essayWritingDraftKey('q$i', {...source, '_additional': true}),
              ).loadDraft()).body,
              i == 1 ? '수정 1' : '원본 2',
            );
          }
        }
        await mount(
          t,
          c,
          gateway,
          ExamSubmissionPanel(
            owner: owner,
            exam: exam(),
            included: {'q1', 'q2'},
            rewriteRun: source,
          ),
        );
        await t.tap(find.text('첨삭 요청'));
        await t.pumpAndSettle();
        expect(
          find.text('첨삭을 시작할까요?'),
          findsOneWidget,
          reason: t
              .widgetList<Text>(find.byType(Text))
              .map((x) => x.data)
              .join(' | '),
        );
        await t.tap(find.text('첨삭 시작'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        final quote = gateway.calls.singleWhere((p) => p['action'] == 'quote');
        final submit = gateway.calls.singleWhere(
          (p) => p['action'] == 'submit',
        );
        expect(quote['questionIds'], ['q1', 'q2']);
        expect(quote['parentId'], additional ? null : 'parent');
        expect(quote['previousPaidRunId'], additional ? 'parent' : null);
        expect(submit['parentId'], additional ? null : 'parent');
        expect(submit['previousPaidRunId'], additional ? 'parent' : null);
        expect(
          submit['expectedGrant'],
          additional ? '11111111-1111-4111-8111-111111111111' : null,
        );
        expect((submit['answers'] as List).map((a) => a['body']), [
          '수정 1',
          '원본 2',
        ]);
        if (!additional) {
          expect((submit['answers'] as List).map((a) => a['revision']), [
            42,
            17,
          ]);
        }
        expect(find.text('첨삭을 진행하고 있어요'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await t.pumpWidget(const SizedBox());
        await t.pump();
      },
    );
  }

  testWidgets(
    'retry reuses uncertain request key; only an explicit server grant allows dispatch',
    (t) async {
      var allowed = true, fail = true;
      final c = await client(
        t,
        (r) async => json({
          'version': 'exam-session-v1',
          'run_id': 'run',
          'state': 'reserved',
          'retry_allowed': allowed,
          'questions': [
            {'question_id': 'q1', 'state': 'failed'},
            {'question_id': 'q2', 'state': 'completed'},
          ],
        }),
      );
      final gateway = QaGateway(c, owner, (p) async {
        if (fail) throw StateError('NETWORK');
        return {'runId': 'run'};
      });
      Future<void> retry() => retryExistingExam(
        client: c,
        gateway: gateway,
        owner: owner,
        run: 'run',
        exam: 'exam-id',
      );
      // Use runAsync for SDK futures; no network (MockClient only).
      await expectLater(retry(), throwsStateError);
      fail = false;
      await retry();
      expect(gateway.calls.length, 2);
      expect(gateway.calls[0]['key'], gateway.calls[1]['key']);
      expect(gateway.calls.map((c) => c['action']), ['retry', 'retry']);
      expect(gateway.calls.every((c) => !c.containsKey('answers')), isTrue);
      allowed = false;
      await expectLater(retry(), throwsStateError);
      expect(gateway.calls.length, 2);
    },
  );

  testWidgets(
    'existing account draft restores read-only and selection distinguishes partial answers',
    (t) async {
      final requests = <http.Request>[];
      final c = await client(t, (r) async {
        requests.add(r);
        return json(
          r.url.queryParameters['question_id'] == 'eq.q1'
              ? [
                  {
                    'id': 'session',
                    'essay_drafts': {'body': '계정 답안'},
                  },
                ]
              : [],
        );
      });
      final api = QaGateway(
        c,
        owner,
        (_) async => throw StateError('No evaluation allowed'),
      );
      var reviews = 0;
      await mount(
        t,
        c,
        api,
        ExamDraftActions(
          owner: owner,
          questions: (exam()['questions'] as List).cast<Map<String, dynamic>>(),
          onWrite: () async {},
          onReview: () async {
            reviews++;
          },
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('선택한 2문항 중 1문항에 저장된 답안이 있어요.'), findsOneWidget);
      expect(find.text('답안 이어쓰기'), findsOneWidget);
      await t.tap(find.text('답안 확인하기'));
      await t.pumpAndSettle();
      expect(reviews, 1);
      expect(requests.every((r) => r.method == 'GET'), isTrue);
      expect((await SourceDraftGateway(owner, 'q1').loadDraft()).body, '계정 답안');
      expect(api.calls, isEmpty);
    },
  );

  testWidgets(
    'verified subparts preserve both answers and whole OCR replacement',
    (t) async {
      final labels = essayAnswerSections(
        '6679b5ff-d797-53c9-8a2a-424375d7210c',
        'a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6',
      );
      final editor = TextEditingController();
      addTearDown(editor.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SectionedAnswerInput(
                controller: editor,
                labels: labels,
                enabled: true,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField).first, '소문항 하나');
      expect(missingAnswerSections(editor.text, labels), ['1-(2)']);
      await t.enterText(find.byType(TextField).last, '소문항 둘');
      expect(splitAnswerSections(editor.text, labels), ['소문항 하나', '소문항 둘']);
      editor.text = '학생이 확인한 OCR 전체 문장';
      await t.pump();
      expect(find.byType(TextField), findsOneWidget);
      expect(editor.text, '학생이 확인한 OCR 전체 문장');
      expect(
        essayAnswerSections('other', 'a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'refresh reports unchanged/error and retry preserves successful question with one dispatch',
    (t) async {
      var retryAccepted = false;
      var statusFails = false;
      final api = await client(t, (r) async {
        if (r.url.path.endsWith(
          const bool.fromEnvironment('ESSAY_OBSERVATION_V1_ENABLED')
              ? 'essay_exam_observation'
              : 'essay_exam_session_status',
        )) {
          if (statusFails) {
            return http.Response(
              '{"code":"PT500","message":"fixture read failure"}',
              400,
            );
          }
          return json({
            'version': 'exam-session-v1',
            'state': 'reserved',
            'run_id': 'run',
            'exam_id': 'exam-id',
            'retry_allowed': !retryAccepted,
            'questions': [
              {
                'question_id': 'q1',
                'state': retryAccepted ? 'waiting' : 'failed',
              },
              {'question_id': 'q2', 'state': 'completed'},
            ],
          });
        }
        if (r.url.path.endsWith('essay_exam_history')) {
          return json({
            'version': 'essay-exam-history-v1',
            'runs': [
              {
                'id': 'run',
                'exam_id': 'exam-id',
                'state': 'reserved',
                'question_ids': ['q1', 'q2'],
              },
            ],
          });
        }
        return http.Response('{}', 200);
      });
      await SourceDraftGateway(
        owner,
        'exam-request:exam:initial',
      ).saveLocalDraft(jsonEncode({'key': 'pending-key', 'runId': 'run'}), 0);
      final gateway = QaGateway(api, owner, (payload) async {
        expect(payload['action'], 'retry');
        expect(payload['runId'], 'run');
        expect(payload.containsKey('answers'), isFalse);
        retryAccepted = true;
        return {'runId': 'run'};
      });
      await mount(
        t,
        api,
        gateway,
        ExamSubmissionPanel(
          owner: owner,
          exam: exam(),
          included: const {'q1', 'q2'},
        ),
      );
      await t.pumpAndSettle();
      final completed = find.widgetWithText(OutlinedButton, '완료된 결과 보기');
      expect(
        t.widget<OutlinedButton>(completed).onPressed,
        const bool.fromEnvironment('ESSAY_OBSERVATION_V1_ENABLED')
            ? isNotNull
            : isNull,
      );
      expect(find.text('실패한 문항 다시 처리 · 0 Credit'), findsOneWidget);
      await t.tap(find.text('처리 상태 새로고침'));
      await t.pumpAndSettle();
      expect(find.text('아직 처리 상태에 변화가 없습니다.'), findsOneWidget);
      expect(
        gateway.calls.where((c) => c['action'] != 'availability'),
        isEmpty,
      );
      statusFails = true;
      await t.tap(find.text('처리 상태 새로고침'));
      await t.pumpAndSettle();
      expect(find.text('문항별 상태를 확인하지 못했어요. 다시 확인해 주세요.'), findsOneWidget);
      expect(find.text('실패한 문항 다시 처리 · 0 Credit'), findsNothing);
      expect(
        gateway.calls.where((c) => c['action'] != 'availability'),
        isEmpty,
      );
      statusFails = false;
      await t.tap(find.text('처리 상태 새로고침'));
      await t.pumpAndSettle();
      await t.tap(find.text('실패한 문항 다시 처리 · 0 Credit'));
      await t.tap(find.text('실패한 문항 다시 처리 · 0 Credit'));
      await t.pumpAndSettle();
      expect(gateway.calls.where((c) => c['action'] == 'retry').length, 1);
      expect(find.text('실패 문항 재처리가 접수됐어요. 완료된 문항은 보존됩니다.'), findsOneWidget);
      expect(find.text('완료'), findsOneWidget);
      expect(find.text('대기 중'), findsOneWidget);
      expect(find.text('잠시 쉬어가세요 ☕'), findsOneWidget);
    },
  );

  testWidgets(
    'iOS university push prevents duplicate routes and restores selected questions after pop',
    (t) async {
      final api = await client(t, (r) async => json([]));
      final catalog = SourceCatalog(
        [
          {
            'sourceUniversityId': 'fixture',
            'universityId': 'fixture',
            'name': '검증대학교',
          },
        ],
        [
          {...exam(), 'universityId': 'fixture'},
        ],
      );
      final observer = QaRoutes();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(api),
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(owner)),
            ),
            publicServiceUniversitiesProvider.overrideWith(
              (ref, owner) async => {'fixture'},
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            navigatorObservers: [observer],
            home: SourceCatalogPage(catalog: Future.value(catalog)),
          ),
        ),
      );
      addTearDown(() async {
        await t.pumpWidget(const SizedBox.shrink());
      });
      await t.pumpAndSettle();
      await t.tap(find.text('검증대학교'));
      await t.tap(find.text('검증대학교'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(
        observer.routes.whereType<CupertinoPageRoute<dynamic>>().length,
        1,
      );
      await t.ensureVisible(find.byType(CheckboxListTile).last);
      await t.tap(find.byType(CheckboxListTile).last);
      await t.pumpAndSettle();
      expect(find.text('선택한 문항 1개'), findsOneWidget);
      // A real edge swipe exercises the Cupertino route's interactive pop.
      await t.dragFrom(const Offset(1, 300), const Offset(650, 0));
      await t.pumpAndSettle();
      expect(find.text('문항 선택'), findsNothing);
      await t.tap(find.text('검증대학교'));
      await t.pumpAndSettle();
      expect(
        observer.routes.whereType<CupertinoPageRoute<dynamic>>().length,
        2,
      );
      expect(find.text('선택한 문항 1개'), findsOneWidget);
      expect(
        t.widget<CheckboxListTile>(find.byType(CheckboxListTile).last).value,
        isTrue,
      );
    },
  );

  testWidgets(
    'history retry follows accepted run through completion without another request',
    (t) async {
      var phase = 0;
      final c = await client(
        t,
        (r) async => json({
          'version': 'exam-session-v1',
          'state': phase == 2 ? 'completed' : 'reserved',
          'run_id': 'run',
          'exam_id': 'exam-id',
          'retry_allowed': phase == 0,
          'questions': [
            {
              'question_id': 'q1',
              'state': phase == 0
                  ? 'failed'
                  : phase == 1
                  ? 'processing'
                  : 'completed',
            },
            {'question_id': 'q2', 'state': 'completed'},
          ],
        }),
      );
      final gateway = QaGateway(c, owner, (payload) async {
        expect(payload['action'], 'retry');
        phase = 1;
        return {'runId': 'run'};
      });
      await mount(
        t,
        c,
        gateway,
        RoundHistoryActions(
          owner: owner,
          record: SharedEssayRecord(
            id: 'run',
            math: false,
            exam: true,
            examData: const {
              'exam_id': 'exam-id',
              'question_ids': ['q1', 'q2'],
            },
            at: DateTime.utc(2026, 10, 29),
            rewrite: false,
            evaluations: const [],
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('회차 처리 상태 확인'));
      await t.pumpAndSettle();
      expect(find.text('아직 처리 상태에 변화가 없습니다.'), findsOneWidget);
      await t.tap(find.text('실패 문항만 재처리 · 0 크레딧'));
      await t.pumpAndSettle();
      expect(find.text('실패 문항 재처리가 접수됐어요. 완료된 문항은 보존됩니다.'), findsOneWidget);
      phase = 2;
      await t.pump(const Duration(seconds: 10));
      await t.pumpAndSettle();
      expect(find.text('첨삭이 완료됐어요. 저장된 결과를 확인하세요.'), findsOneWidget);
      expect(gateway.calls.length, 1);
      expect(find.text('실패 문항만 재처리 · 0 크레딧'), findsNothing);
    },
  );

  for (final size in [1, 2, 3]) {
    testWidgets(
      'answer review $size questions uses consistent dividers and reachable actions at 320px',
      (t) async {
        t.view.physicalSize = const Size(320, 568);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final c = await client(t, (r) async => json({}));
        for (var i = 1; i <= size; i++) {
          await SourceDraftGateway(owner, 'q$i').saveLocalDraft('합성 답안 $i', 0);
        }
        final gateway = QaGateway(
          c,
          owner,
          (_) async => throw StateError('No submit in review layout test'),
        );
        await mount(
          t,
          c,
          gateway,
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ExamAnswerReview(
                    owner: owner,
                    exam: exam(size),
                    currentQuestion: 'q1',
                    selectedQuestions: {for (var i = 1; i <= size; i++) 'q$i'},
                  ),
                );
              },
              child: const Text('확인 열기'),
            ),
          ),
        );
        await t.tap(find.text('확인 열기'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(find.byType(CheckboxListTile), findsNWidgets(size));
        final dividers = t.widgetList<Divider>(find.byType(Divider));
        expect(dividers.length, greaterThanOrEqualTo(size + 1));
        expect(
          dividers.every((d) => d.color == AppTokens.majorSurfaceBorder),
          isTrue,
        );
        final lastBottom = t
            .getBottomLeft(find.byType(CheckboxListTile).last)
            .dy;
        final footerTop = t
            .getTopLeft(
              find.text(
                '제출 문항: $size'
                '개',
              ),
            )
            .dy;
        expect(footerTop - lastBottom, lessThanOrEqualTo(48));
        await t.ensureVisible(find.text('첨삭 요청'));
        expect(find.text('첨삭 요청').hitTestable(), findsOneWidget);
        expect(find.textContaining('Essay(TEXT)'), findsNothing);
        expect(find.textContaining('문항 실행 승인'), findsNothing);
        expect(
          gateway.calls.where((c) => c['action'] != 'availability'),
          isEmpty,
        );
        expect(t.takeException(), isNull);
      },
    );
  }

  test('student availability copy hides internal engines without changing admission', () {
    final q = {'dbQuestionId': 'q1'};
    expect(
      essayQuestionAvailability(exam(), q, {
        'ready': true,
        'questionIds': ['q1'],
      }),
      '',
    );
    expect(
      essayQuestionAvailability(exam(), q, {'ready': false}),
      contains('이용할 수 없어요'),
    );
    expect(essayQuestionAvailability(exam(), q, null), contains('확인하고 있어요'));
  });
}
