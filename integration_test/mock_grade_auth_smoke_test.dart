// Owner-run D3 smoke: real SDK sessions/RPC/native store; no scoring substitutes.
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/data/study_repository.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'mock_scoring_auth_smoke_test.dart'
    show RegisteredStudy, RegisteredScoring;

class CountedGradeRepository extends RegisteredScoring {
  CountedGradeRepository(super.inner, super.control, this.onSubmit);
  final VoidCallback onSubmit;
  @override
  Future<ScoreResult> submit(ScoringAttempt attempt) {
    onSubmit();
    return super.submit(attempt);
  }
}

// Typed, allowlisted metadata only: never print exception messages or HTTP bodies.
void diagnose(String stage, Object error) {
  var kind = 'unexpected';
  String? code;
  int? status;
  if (error is TestFailure) {
    kind = 'assertion';
  } else if (error is TimeoutException) {
    kind = 'timeout';
  } else if (error is AuthException) {
    kind = 'auth';
    status = int.tryParse(error.statusCode ?? '');
  } else if (error is PostgrestException) {
    kind = 'db_error';
    code = error.code;
  } else if (error is SocketException) {
    kind = 'network';
  } else if (error is FormatException) {
    kind = 'format';
  } else if (error is StateError) {
    kind = 'state';
  }
  const codes = {
    '23514',
    '23505',
    '42501',
    '22023',
    '23503',
    '23502',
    '42P01',
    '42703',
    '55P03',
    '57014',
    'PGRST202',
    'PGRST204',
  };
  final safeCode = codes.contains(code) ? ' code=$code' : '';
  final safeStatus = status != null && status >= 100 && status <= 599
      ? ' http_status=$status'
      : '';
  debugPrint('D3_FLUTTER DIAG stage=$stage kind=$kind$safeCode$safeStatus');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('D3 actual A/B grade, history and native restoration', (t) async {
    final transport = http.Client(), store = NativeStudyLocalStore();
    final clients = <SupabaseClient>[];
    Map<String, dynamic>? original;
    StudyController? c;
    ProviderContainer? container;
    GoRouter? router;
    var stage = 'login_preflight', submitCalls = 0;
    void mark(String s) => debugPrint('D3_FLUTTER PASS $s');
    Future<void> wait(bool Function() ready) async {
      for (var i = 0; i < 400; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (ready()) return;
      }
      throw TimeoutException('Runtime stage timed out');
    }

    Future<void> detach() async {
      if (c != null) {
        await c!.settled;
        await wait(() => !c!.scoringBusy);
      }
      await t.pumpWidget(const SizedBox.shrink());
      if (container != null) {
        container!.dispose();
      } else {
        c?.dispose();
      }
      container = null;
      router = null;
      c = null;
    }

    Future<void> tap(Finder target) async {
      await t.ensureVisible(target);
      await t.tap(target);
      await t.pumpAndSettle();
    }

    try {
      final bridge = Uri.parse(
        const String.fromEnvironment('SMOKE_CONFIG_URL'),
      );
      if (bridge.scheme != 'http' || bridge.host != '127.0.0.1') {
        throw StateError('Runner required');
      }
      final response = await transport.get(bridge);
      expect(response.statusCode, 200);
      final input = jsonDecode(response.body) as Map<String, dynamic>;
      final config = AppConfig(
        supabaseUrl: input['SUPABASE_URL'] as String,
        supabasePublishableKey: input['SUPABASE_PUBLISHABLE_KEY'] as String,
      );
      expect(config.validationErrors, isEmpty);
      final fixture = Map<String, dynamic>.from(input['fixture'] as Map);
      Future<void> control(Map<String, dynamic> data) async {
        final reply = await transport.post(
          bridge,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (reply.statusCode != 200 || jsonDecode(reply.body)['ok'] != true) {
          debugPrint(
            'D3_FLUTTER DIAG stage=$stage kind=http http_status=${reply.statusCode}',
          );
          throw StateError('Fixture control rejected');
        }
      }

      for (final label in ['A', 'B']) {
        final client = SupabaseClient(
          config.supabaseUrl,
          config.supabasePublishableKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        clients.add(client);
        final account = (input['accounts'] as Map)[label] as Map;
        final auth = await client.auth.signInWithPassword(
          email: account['email'] as String,
          password: account['password'] as String,
        );
        expect(auth.user?.id == (input['owners'] as Map)[label], true);
        expect(await client.from('mock_exam_attempts').select('id'), isEmpty);
      }
      input.remove('accounts');
      expect(
        clients[0].auth.currentUser!.id != clients[1].auth.currentUser!.id,
        true,
      );
      mark(stage);
      original = await store.read();
      await store.write({'version': 3, 'owners': <String, dynamic>{}});
      SupabaseClient current = clients[0];
      ScoringRepository scoring() => CountedGradeRepository(
        SupabaseScoringRepository.bind(current, config, transport),
        control,
        () => submitCalls++,
      );
      Future<void> mount(SupabaseClient client) async {
        await detach();
        current = client;
        c = StudyController(
          NativeStudyClock(),
          store,
          () => RegisteredStudy(
            SupabaseStudyRepository.bind(current, config, transport),
            control,
          ),
          scoringRepository: scoring,
        );
        c!.identity(current.auth.currentUser!.id, resolved: true);
        await wait(
          () => c!.ready && c!.authReady && !c!.historyError && !c!.scoringBusy,
        );
        c!.selectMock(true);
        // Production router, Study, History and Home. Unrelated providers remain
        // unconfigured, so no profile/content requests or Focus/notification writes.
        container = ProviderContainer(
          overrides: [
            studyControllerProvider.overrideWith((ref) {
              ref.keepAlive();
              return c!;
            }),
          ],
        );
        router = container!.read(routerProvider);
        router!.go('/study');
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: container!,
            child: MaterialApp.router(
              theme: AppTheme.light,
              routerConfig: router,
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      Future<Map<String, dynamic>> fetch(String id) async =>
          Map<String, dynamic>.from(
            await current.rpc<dynamic>(
                  'fetch_own_mock_attempt',
                  params: {'p_attempt_id': id},
                )
                as Map,
          );
      Future<void> openHistory(ScoringAttempt a) async {
        router!.go('/study');
        c!.selectMock(true);
        await t.pumpAndSettle();
        await tap(
          find.text(
            '${a.title} · ${a.result!.rawScore} / ${a.result!.maxScore}점',
          ),
        );
      }

      void noInternalIds() {
        final text = t
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data ?? '')
            .join('\n');
        for (final id in fixture.values.whereType<String>()) {
          expect(text.contains(id), false);
        }
        expect(
          RegExp(
            r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
          ).hasMatch(text),
          false,
        );
        expect(text.contains('version'), false);
      }

      Future<void> resultChecks(
        ScoringAttempt a,
        Map<String, dynamic> server,
      ) async {
        final outerStage = stage;
        stage = 'result_summary';
        final s = a.result!, canonical = ScoreResult.fromJson(server);
        expect(jsonEncode(s.toJson()), jsonEncode(canonical.toJson()));
        expect(s.rawScore, 2);
        expect(s.maxScore, 9);
        expect(s.correctCount, 1);
        expect(s.answers.length, 3);
        expect(s.wrong, [2]);
        expect(s.unanswered, [3]);
        expect(find.text('2 / 9점'), findsOneWidget);
        expect(find.text('정답 1 / 3'), findsOneWidget);
        expect(find.text('오답 1'), findsOneWidget);
        expect(find.text('미응답 1'), findsOneWidget);
        expect(find.text(s.gradeLabel), findsOneWidget);
        if (s.gradeExplanation != null) {
          expect(find.text(s.gradeExplanation!), findsOneWidget);
        }
        stage = 'answer_review';
        await tap(find.text('답안 확인'));
        const symbols = ['①', '②', '③', '④', '⑤'];
        for (final r in s.answers) {
          final outcome = r.submitted == null
              ? '미응답'
              : r.isCorrect
              ? '정답'
              : '오답';
          await t.ensureVisible(find.text('${r.number}번 · $outcome'));
          expect(
            find.text(
              '내 답 ${r.submitted == null ? '—' : symbols[r.submitted! - 1]}',
            ),
            findsOneWidget,
          );
          expect(find.text('정답 ${symbols[r.correct - 1]}'), findsOneWidget);
          expect(find.text('배점 ${r.points}점'), findsOneWidget);
        }
        stage = 'provenance';
        await tap(find.text('정답·등급 기준 출처'));
        for (final entry in [
          ('정답 기준', s.keySource),
          ('등급 기준', s.cutoffSource),
        ]) {
          final source = entry.$2;
          if (source == null) continue;
          expect(find.text('${entry.$1}: ${source.name}'), findsOneWidget);
          final date = source.verifiedAt.add(const Duration(hours: 9));
          final label =
              '확인: ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
          expect(find.text(label), findsWidgets);
          final button = t.widget<ExternalLinkButton>(
            find.widgetWithText(ExternalLinkButton, '${entry.$1} 원문 보기'),
          );
          expect(button.uri, publicWebUri(source.url));
          expect(button.uri, isNotNull);
          expect(button.uri!.userInfo, isEmpty);
        }
        noInternalIds();
        await tap(find.text('닫기'));
        noInternalIds();
        stage = outerStage;
      }

      final attempts = <ScoringAttempt>[];
      final servers = <String, Map<String, dynamic>>{};
      await mount(clients[0]);
      for (final scenario in [
        ('confirmed', 'key1'),
        ('estimated', 'estimated_key'),
        ('unavailable', 'unavailable_key'),
      ]) {
        stage = '${scenario.$1}_grade';
        router!.go('/study');
        await t.pumpAndSettle();
        final paper = (await scoring().availablePapers()).singleWhere(
          (p) => p.availability.answerKeyVersionId == fixture[scenario.$2],
        );
        await c!.configureScoring(paper.availability);
        c!.configureMock(
          MockSetup('D3 ${scenario.$1} runtime', 'Synthetic subject', 600),
        );
        await c!.startMock();
        await t.pumpAndSettle();
        await tap(find.text('답안 입력 · 0 / 3'));
        expect(find.textContaining('정답'), findsNothing);
        await tap(find.byKey(const ValueKey('answer-1-1')));
        await tap(find.byKey(const ValueKey('answer-2-5')));
        expect(c!.draft!.answers!.answers, [1, 5, null]);
        expect(find.textContaining('정답'), findsNothing);
        await Future<void>.delayed(const Duration(seconds: 2));
        await tap(find.text('제출하고 채점하기'));
        await tap(find.text('제출하고 채점하기').last);
        await wait(
          () =>
              c!.draft == null &&
              !c!.scoringBusy &&
              c!.attempts.last.outcome != ScoringOutcome.pending,
        );
        await t.pumpAndSettle();
        final a = c!.attempts.last, server = await fetch(c!.attempts.last.id);
        attempts.add(a);
        servers[a.id] = server;
        expect(a.outcome, ScoringOutcome.complete);
        expect(a.result!.gradeStatus, scenario.$1);
        if (scenario.$1 == 'unavailable') {
          expect(a.result!.grade, isNull);
          expect(a.result!.cutoffSource, isNull);
          expect(find.text('등급 정보 준비 중'), findsOneWidget);
        } else {
          expect(a.result!.grade, 8);
          expect(
            a.result!.cutoffSource!.basis,
            scenario.$1 == 'confirmed' ? 'raw_absolute' : 'raw_estimate',
          );
          expect(
            find.text(scenario.$1 == 'confirmed' ? '8등급' : '예상 8등급'),
            findsOneWidget,
          );
          expect(
            find.text(scenario.$1 == 'confirmed' ? '확정 등급 기준' : '예상 등급컷 기준'),
            findsOneWidget,
          );
          if (scenario.$1 == 'estimated') {
            expect(find.text('8등급'), findsNothing);
          }
        }
        mark(stage);
        stage = 'result_summary';
        await resultChecks(a, server);
        await tap(find.text('다시 학습으로'));
        expect(router!.routeInformationProvider.value.uri.path, '/study');
        expect(c!.draft, isNull);
      }
      for (final s in ['result_summary', 'answer_review', 'provenance']) {
        mark(s);
      }
      stage = 'auth_restore';
      await mount(clients[0]);
      expect(c!.attempts.length, 3);
      for (final a in attempts) {
        final restored = c!.attempts.singleWhere((v) => v.id == a.id);
        expect(jsonEncode(restored.toJson()), jsonEncode(a.toJson()));
        await openHistory(a);
        await resultChecks(restored, await fetch(a.id));
        await tap(find.text('다시 학습으로'));
      }
      mark(stage);
      stage = 'historical_version';
      await control({'action': 'switch'});
      final currentPapers = await scoring().availablePapers();
      expect(
        currentPapers.any(
          (p) => p.availability.answerKeyVersionId == fixture['key2'],
        ),
        true,
      );
      expect(
        currentPapers.any(
          (p) => p.availability.answerKeyVersionId == fixture['key1'],
        ),
        false,
      );
      final v2 = await current
          .from('grade_cutoff_versions')
          .select('version,source_name')
          .eq('id', fixture['cut2'] as String)
          .single();
      expect(v2['version'], 2);
      expect(
        v2['source_name'] == attempts.first.result!.cutoffSource!.name,
        false,
      );
      await mount(clients[0]);
      await openHistory(attempts.first);
      await resultChecks(c!.attempts.first, await fetch(attempts.first.id));
      expect(
        jsonEncode(c!.attempts.first.result!.toJson()),
        jsonEncode(attempts.first.result!.toJson()),
      );
      mark(stage);
      stage = 'retry';
      for (final a in attempts) {
        final retried = await scoring().submit(a);
        expect(jsonEncode(retried.toJson()), jsonEncode(a.result!.toJson()));
        expect(jsonEncode(await fetch(a.id)), jsonEncode(servers[a.id]));
      }
      expect(
        await current.from('mock_exam_attempts').select('id'),
        hasLength(3),
      );
      mark(stage);
      stage = 'account_isolation';
      current = clients[1];
      c!.identity(current.auth.currentUser!.id, resolved: true);
      expect(c!.attempts, isEmpty);
      await t.pumpAndSettle();
      expect(find.text('8등급'), findsNothing);
      expect(find.text('2 / 9점'), findsNothing);
      await mount(clients[1]);
      expect(c!.attempts, isEmpty);
      expect(find.text('시험 채점 결과'), findsNothing);
      for (final a in attempts) {
        expect(find.textContaining(a.title), findsNothing);
        expect(
          await current.rpc<dynamic>(
            'fetch_own_mock_attempt',
            params: {'p_attempt_id': a.id},
          ),
          isNull,
        );
        expect(
          await current
              .from('mock_exam_answers')
              .select('attempt_id')
              .eq('attempt_id', a.id),
          isEmpty,
        );
      }
      mark(stage);
      stage = 'legacy_fallback';
      await detach();
      final snapshot = await store.read();
      try {
        final legacy = jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;
        final rows =
            ((legacy['owners'] as Map)[clients[0].auth.currentUser!.id]
                    as Map)['attempts']
                as List;
        for (final row in rows) {
          (row['result'] as Map).remove('key_source');
          (row['result'] as Map).remove('cutoff_source');
        }
        await store.write(legacy);
        await mount(clients[0]);
        for (final a in attempts.take(2)) {
          await openHistory(a);
          expect(find.text('등급 정보 준비 중'), findsOneWidget);
          expect(find.text('8등급'), findsNothing);
          expect(find.text('예상 8등급'), findsNothing);
          expect(find.text('저장된 등급의 근거 정보를 확인할 수 없어요.'), findsOneWidget);
          await tap(find.text('다시 학습으로'));
        }
        var rejected = false;
        try {
          ScoreResult.fromJson({
            ...attempts.first.result!.toJson(),
            'grade': null,
          });
        } on FormatException {
          rejected = true;
        }
        expect(rejected, true);
      } finally {
        await detach();
        await store.write(snapshot);
      }
      mark(stage);
      stage = 'navigation';
      await mount(clients[0]);
      final count = submitCalls;
      await openHistory(attempts.first);
      await tap(find.text('다시 학습으로'));
      expect(router!.routeInformationProvider.value.uri.path, '/study');
      expect(c!.draft, isNull);
      await openHistory(attempts[1]);
      await tap(find.text('홈으로'));
      expect(router!.routeInformationProvider.value.uri.path, '/home');
      expect(c!.draft, isNull);
      router!.go('/study');
      await t.pumpAndSettle();
      expect(find.textContaining('답안 입력 ·'), findsNothing);
      expect(c!.attempts.length, 3);
      expect(submitCalls, count);
      expect(
        await current.from('mock_exam_attempts').select('id'),
        hasLength(3),
      );
      mark(stage);
    } catch (error) {
      diagnose(stage, error);
      debugPrint('D3_FLUTTER FAIL $stage');
      throw StateError('D3 runtime stage failed');
    } finally {
      try {
        await detach();
        if (original != null) {
          await store.write(original);
          expect(jsonEncode(await store.read()), jsonEncode(original));
          mark('local_fixture_cleanup');
        }
      } catch (error) {
        diagnose('local_fixture_cleanup', error);
        debugPrint('D3_FLUTTER FAIL local_fixture_cleanup');
        throw StateError('D3 local cleanup failed');
      } finally {
        for (final client in clients) {
          try {
            await client.auth.signOut(scope: SignOutScope.local);
          } finally {
            await client.dispose();
          }
        }
        transport.close();
      }
    }
  });
}
