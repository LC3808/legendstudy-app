// Opt-in native runtime test. Production repositories, SDK login and server RPC.
// Only fixture registration/lifecycle uses the runner's private loopback bridge.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/data/study_repository.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_pages.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';

typedef Control = Future<void> Function(Map<String, dynamic> request);

class RegisteredStudy implements StudyRepository {
  RegisteredStudy(this.inner, this.control);
  final StudyRepository inner;
  final Control control;
  @override
  String get owner => inner.owner;
  @override
  Future<List<StudyRecord>> fetchWindow(int nowMs) => inner.fetchWindow(nowMs);
  @override
  Future<void> deleteOwn(String id) => throw StateError('No runtime deletion');
  @override
  Future<void> insertCompleted(StudyRecord record) async {
    await control({'action': 'register', 'kind': 'study', 'id': record.id});
    try {
      await inner.insertCompleted(record);
    } finally {
      await control({'action': 'checkpoint'});
    }
  }
}

class RegisteredScoring implements ScoringRepository {
  RegisteredScoring(this.inner, this.control);
  final ScoringRepository inner;
  final Control control;
  @override
  String? get owner => inner.owner;
  @override
  Future<List<ScoringPaper>> availablePapers() => inner.availablePapers();
  @override
  Future<AnswerDraft> prepare(MockScoringAvailability a) => inner.prepare(a);
  @override
  Future<ScoreResult> submit(ScoringAttempt attempt) async {
    await control({'action': 'register', 'kind': 'attempt', 'id': attempt.id});
    try {
      return await inner.submit(attempt);
    } finally {
      await control({'action': 'checkpoint'});
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('actual A/B Flutter scoring RPC and native restore', (t) async {
    final transport = http.Client();
    final store = NativeStudyLocalStore();
    Map<String, dynamic>? original;
    StudyController? c;
    final clients = <SupabaseClient>[];
    var stage = 'login_preflight';
    void mark(String name) => debugPrint('D2_FLUTTER PASS $name');
    Future<void> wait(bool Function() ready) async {
      for (var i = 0; i < 400; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (ready()) return;
      }
      throw StateError('Runtime stage timed out');
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
      final fixture = input['fixture'] as Map;
      Future<void> control(Map<String, dynamic> data) async {
        final reply = await transport.post(
          bridge,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );
        if (reply.statusCode != 200 || jsonDecode(reply.body)['ok'] != true) {
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
      // Backup stays in memory and is restored even on test failure.
      await store.write({'version': 3, 'owners': <String, dynamic>{}});
      SupabaseClient current = clients[0];
      RegisteredScoring scoring() => RegisteredScoring(
        SupabaseScoringRepository.bind(current, config, transport),
        control,
      );
      Future<void> mount(SupabaseClient client) async {
        await t.pumpWidget(const SizedBox.shrink());
        if (c != null) {
          await c!.settled;
          expect(c!.scoringBusy, false);
          c!.dispose();
        }
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
          () =>
              c!.ready && c!.authReady && !c!.historyError && !c!.historyStale,
        );
        expect(c!.historyError, false);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              home: AnswerEntryPage(study: c!),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      Future<void> tapAnswer(int question, int choice) async {
        final target = find.byKey(ValueKey('answer-$question-$choice'));
        await t.ensureVisible(target);
        await t.tap(target);
        await t.pumpAndSettle();
      }

      Future<void> submit() async {
        await Future<void>.delayed(const Duration(seconds: 2));
        await t.tap(find.text('제출하고 채점하기'));
        await t.pumpAndSettle();
        await t.tap(find.text('제출하고 채점하기').last);
        await wait(
          () =>
              c!.draft == null &&
              c!.attempts.isNotEmpty &&
              !c!.scoringBusy &&
              c!.attempts.last.outcome != ScoringOutcome.pending,
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

      stage = 'auth_scoring_start';
      await mount(clients[0]);
      final papers = await scoring().availablePapers();
      final paper = papers.singleWhere(
        (p) => p.availability.answerKeyVersionId == fixture['key1'],
      );
      await c!.configureScoring(paper.availability);
      c!.configureMock(const MockSetup('Synthetic Flutter scoring', null, 600));
      await c!.startMock();
      await t.pumpAndSettle();
      expect(c!.draft!.answers!.questions.length, 3);
      final runningId = c!.draft!.id;
      mark(stage);
      stage = 'answer_entry';
      await tapAnswer(1, 2);
      await tapAnswer(1, 1);
      await tapAnswer(2, 5);
      expect(c!.draft!.answers!.answers, [1, 5, null]);
      mark(stage);
      stage = 'pause_resume';
      await t.tap(find.text('일시정지'));
      await t.pumpAndSettle();
      await tapAnswer(1, 2);
      expect(c!.draft!.answers!.answers, [1, 5, null]);
      await t.tap(find.text('계속하기'));
      await t.pumpAndSettle();
      await tapAnswer(1, 2);
      await tapAnswer(1, 1);
      mark(stage);
      stage = 'draft_restore';
      await c!.settled;
      await mount(clients[0]);
      expect(c!.draft!.id, runningId);
      expect(c!.draft!.answers!.answers, [1, 5, null]);
      // Running ID is the Study draft ID. Attempt ID is allocated on submission.
      expect(c!.attempts, isEmpty);
      mark(stage);
      stage = 'auth_submit';
      await submit();
      final attempt = c!.attempts.single;
      expect(attempt.outcome, ScoringOutcome.complete);
      final server = await fetch(attempt.id);
      expect(server['user_id'], clients[0].auth.currentUser!.id);
      mark(stage);
      stage = 'auth_result';
      final score = attempt.result!;
      expect(score.grade, 8);
      expect(score.gradeStatus, 'confirmed');
      expect(score.gradeLabel, '8등급');
      expect(score.gradeExplanation, '확정 등급 기준');
      expect(score.keySource, isNotNull);
      expect(score.cutoffSource!.basis, 'raw_absolute');
      expect(find.text('8등급'), findsOneWidget);
      expect(score.rawScore, 2);
      expect(score.maxScore, 9);
      expect(score.correctCount, 1);
      expect(score.wrong.length, 1);
      expect(score.unanswered.length, 1);
      expect(
        jsonEncode(ScoreResult.fromJson(server).toJson()),
        jsonEncode(score.toJson()),
      );
      expect(find.text('2 / 9점'), findsOneWidget);
      final sourceAction = find.text('정답·등급 기준 출처');
      await t.ensureVisible(sourceAction);
      await t.tap(sourceAction);
      await t.pumpAndSettle();
      expect(find.text('정답 기준: ${score.keySource!.name}'), findsOneWidget);
      expect(find.text('등급 기준: ${score.cutoffSource!.name}'), findsOneWidget);
      await t.tap(find.text('닫기'));
      await t.pumpAndSettle();
      mark(stage);
      stage = 'auth_restore';
      await mount(clients[0]);
      expect(c!.attempts.single.id, attempt.id);
      final restoredServer = await fetch(attempt.id);
      expect(jsonEncode(restoredServer), jsonEncode(server));
      expect(
        jsonEncode(c!.attempts.single.result!.toJson()),
        jsonEncode(ScoreResult.fromJson(restoredServer).toJson()),
      );
      expect(find.text('2 / 9점'), findsOneWidget);
      mark(stage);
      stage = 'account_isolation';
      current = clients[1];
      c!.identity(current.auth.currentUser!.id, resolved: true);
      expect(c!.attempts, isEmpty);
      expect(c!.draft, isNull);
      await wait(() => c!.ready && !c!.historyError);
      await t.pumpAndSettle();
      expect(c!.attempts, isEmpty);
      expect(c!.draft, isNull);
      expect(find.text('2 / 9점'), findsNothing);
      expect(find.text('8등급'), findsNothing);
      expect(
        await current.rpc<dynamic>(
          'fetch_own_mock_attempt',
          params: {'p_attempt_id': attempt.id},
        ),
        isNull,
      );
      expect(
        await current
            .from('mock_exam_answers')
            .select('attempt_id')
            .eq('attempt_id', attempt.id),
        isEmpty,
      );
      await mount(clients[0]);
      mark(stage);
      // Prepare a second running draft while v1 is current, then supersede it.
      await c!.configureScoring(paper.availability);
      c!.configureMock(const MockSetup('Synthetic stale scoring', null, 600));
      await c!.startMock();
      await t.pumpAndSettle();
      await tapAnswer(1, 1);
      await control({'action': 'switch'});
      stage = 'retry';
      final retried = await scoring().submit(attempt);
      expect(jsonEncode(retried.toJson()), jsonEncode(score.toJson()));
      expect(
        await current
            .from('mock_exam_attempts')
            .select('id')
            .eq('id', attempt.id),
        hasLength(1),
      );
      expect(jsonEncode(await fetch(attempt.id)), jsonEncode(server));
      mark(stage);
      stage = 'stale_version';
      await submit();
      final stale = c!.attempts.last;
      expect(stale.id != attempt.id, true);
      expect(stale.outcome, ScoringOutcome.stale);
      expect(stale.result, isNull);
      expect(stale.draft.answers, [1, null, null]);
      expect(
        await current.rpc<dynamic>(
          'fetch_own_mock_attempt',
          params: {'p_attempt_id': stale.id},
        ),
        isNull,
      );
      expect(find.text('2 / 9점'), findsNothing);
      expect(find.text('8등급'), findsNothing);
      mark(stage);
    } catch (_) {
      // Never let test-framework failures serialize credentials or raw responses.
      debugPrint('D2_FLUTTER FAIL $stage');
      throw StateError('D2 runtime stage failed');
    } finally {
      await t.pumpWidget(const SizedBox.shrink());
      if (c != null) {
        await c!.settled;
        await wait(() => !c!.scoringBusy);
        c!.dispose();
      }
      if (original != null) {
        await store.write(original);
        expect(jsonEncode(await store.read()), jsonEncode(original));
        mark('local_fixture_cleanup');
      }
      for (final client in clients) {
        try {
          await client.auth.signOut(scope: SignOutScope.local);
        } finally {
          await client.dispose();
        }
      }
      transport.close();
    }
  });
}
