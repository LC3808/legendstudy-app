// Opt-in native smoke. Auth secrets arrive through a one-use loopback endpoint.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/data/study_repository.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';

void check(bool value) {
  if (!value) throw StateError('Safe runtime check failed');
}

void mark(String stage) => debugPrint('STUDY_FLUTTER PASS $stage');

class FailingWrites implements StudyRepository {
  FailingWrites(this.inner);
  final StudyRepository inner;
  @override
  String get owner => inner.owner;
  @override
  Future<List<StudyRecord>> fetchWindow(int now) => inner.fetchWindow(now);
  @override
  Future<void> insertCompleted(StudyRecord r) async {
    throw const StudyStorageError();
  }

  @override
  Future<void> deleteOwn(String id) => inner.deleteOwn(id);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Study native storage and optional real JWT runtime', (
    tester,
  ) async {
    const endpoint = String.fromEnvironment('SMOKE_CONFIG_URL');
    final native = NativeStudyLocalStore();
    final original = await native.read();
    final clients = <SupabaseClient>[];
    final fixtureIds = <String>{};
    final transport = http.Client();
    ProviderContainer? container;
    var config = AppConfig.fromEnvironment();
    Map<String, dynamic>? credentials;
    var stage = 'native_preflight';
    var cleanupOk = true;
    List<List<Map<String, dynamic>>> profiles = [];
    Future<List<Map<String, dynamic>>> profile(SupabaseClient c) => c
        .from('profiles')
        .select(
          'id,display_name,grade_level,neis_office_code,neis_school_code,target_date,target_label',
        )
        .eq('id', c.auth.currentUser!.id);
    Future<List<Map<String, dynamic>>> sessions(SupabaseClient c) => c
        .from('study_sessions')
        .select('id')
        .eq('user_id', c.auth.currentUser!.id);
    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 300; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (condition()) return;
      }
      throw StateError('Safe runtime timeout');
    }

    Future<void> mount(
      SupabaseClient? client, {
      bool failWrites = false,
    }) async {
      await tester.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          supabaseClientProvider.overrideWithValue(client),
          backendIssueProvider.overrideWithValue(null),
          if (failWrites)
            studyRepositoryFactoryProvider.overrideWithValue(
              () => FailingWrites(
                SupabaseStudyRepository.bind(client, config, transport),
              ),
            ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: const LegendStudyApp(),
        ),
      );
      await waitFor(() => container!.read(studyControllerProvider).ready);
      if (client != null) {
        await waitFor(
          () => !container!.read(studyControllerProvider).historyError,
        );
      }
      await tester.pumpAndSettle();
    }

    StudyController current() => container!.read(studyControllerProvider);
    Future<void> tab(String name) async {
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text(name),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }

    Future<void> press(String name) async {
      await tester.ensureVisible(find.text(name).last);
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    Future<void> studyForTwoSeconds() async {
      await tab('학습');
      await press('공부 시작');
      check(current().draft != null);
      fixtureIds.add(current().draft!.id);
      await tester.pump(const Duration(seconds: 2));
      await current().tick();
      check(current().elapsedMs >= 1000);
    }

    try {
      await native.write({'version': 1, 'owners': <String, dynamic>{}});
      if (endpoint.isNotEmpty) {
        final uri = Uri.parse(endpoint);
        check(uri.scheme == 'http' && uri.host == '127.0.0.1');
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 15));
        check(response.statusCode == 200);
        credentials = jsonDecode(response.body) as Map<String, dynamic>;
        config = AppConfig(
          supabaseUrl: credentials['SUPABASE_URL'] as String,
          supabasePublishableKey:
              credentials['SUPABASE_PUBLISHABLE_KEY'] as String,
        );
        check(config.validationErrors.isEmpty);
      }
      await mount(null);
      stage = 'guest_start';
      await studyForTwoSeconds();
      mark(stage);
      stage = 'guest_pause_resume';
      await press('일시정지');
      final paused = current().elapsedMs;
      await tester.pump(const Duration(seconds: 1));
      await current().tick();
      check(current().elapsedMs == paused);
      await press('계속하기');
      await tester.pump(const Duration(seconds: 1));
      mark(stage);
      stage = 'guest_running_restore';
      final runningId = current().draft!.id;
      await mount(null);
      check(
        current().draft?.id == runningId &&
            !current().recovery &&
            current().elapsedMs >= paused,
      );
      mark(stage);
      await tab('학습');
      stage = 'guest_end_local';
      await press('종료');
      check(
        current().records.length == 1 && current().savePhase == SavePhase.local,
      );
      check(find.text('이 기기에 저장됨').evaluate().isNotEmpty);
      mark(stage);
      stage = 'guest_home_restore';
      await mount(null);
      check(current().records.length == 1 && current().week.last >= 1000);
      await tester.ensureVisible(find.text(current().summary));
      check(find.text(current().summary).evaluate().isNotEmpty);
      mark(stage);
      if (credentials != null) {
        stage = 'login_preflight';
        for (final label in ['A', 'B']) {
          check(
            credentials['TEST_${label}_EMAIL'] ==
                'legendstudy${label == 'A' ? '1' : '2'}@legendstudy.com',
          );
          final c = SupabaseClient(
            config.supabaseUrl,
            config.supabasePublishableKey,
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          );
          clients.add(c);
          await c.auth.signInWithPassword(
            email: credentials['TEST_${label}_EMAIL'] as String,
            password: credentials['TEST_${label}_PASSWORD'] as String,
          );
          check(c.auth.currentUser != null && (await sessions(c)).isEmpty);
        }
        check(
          clients[0].auth.currentUser!.id != clients[1].auth.currentUser!.id,
        );
        profiles = await Future.wait(clients.map(profile));
        mark(stage);
        final a = clients[0], b = clients[1];
        await mount(a);
        check(current().records.isEmpty); // Guest is never uploaded.
        stage = 'auth_save';
        await studyForTwoSeconds();
        final savedId = current().draft!.id;
        await press('종료');
        await waitFor(() => current().savePhase == SavePhase.saved);
        check(find.text('저장됨').evaluate().isNotEmpty);
        check((await sessions(a)).single['id'] == savedId);
        mark(stage);
        stage = 'auth_restore_home';
        await mount(a);
        check(
          current().records.single.id == savedId && current().week.last >= 1000,
        );
        await tester.ensureVisible(find.text(current().summary));
        check(find.text(current().summary).evaluate().isNotEmpty);
        mark(stage);
        stage = 'account_isolation';
        await mount(b);
        check(current().records.isEmpty && current().week.every((v) => v == 0));
        check((await sessions(b)).isEmpty);
        mark(stage);
        stage = 'pending_sync';
        await mount(a, failWrites: true);
        await studyForTwoSeconds();
        final pendingId = current().draft!.id;
        await press('종료');
        await waitFor(() => current().savePhase == SavePhase.pendingSync);
        check(current().records.any((r) => r.id == pendingId && !r.synced));
        check(find.text('동기화 대기').evaluate().isNotEmpty);
        check((await sessions(a)).length == 1);
        mark(stage);
        stage = 'pending_retry';
        await mount(a);
        await waitFor(() => current().savePhase == SavePhase.saved);
        check((await sessions(a)).length == 2);
        mark(stage);
        stage = 'profile_preserved';
        check(
          jsonEncode(await Future.wait(clients.map(profile))) ==
              jsonEncode(profiles),
        );
        mark(stage);
      }
    } catch (_) {
      debugPrint('STUDY_FLUTTER FAIL $stage');
      throw StateError('Study runtime failed; sensitive details suppressed');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      // Only run-owned UUIDs; no profile mutation and no Auth deletion.
      for (final c in clients) {
        try {
          if (c.auth.currentUser == null) continue;
          final repo = SupabaseStudyRepository.bind(c, config, transport);
          for (final id in fixtureIds) {
            await repo.deleteOwn(id);
          }
          final after = await sessions(c);
          check(!after.any((r) => fixtureIds.contains(r['id'])));
          check((await c.auth.getUser()).user?.id == c.auth.currentUser!.id);
        } catch (_) {
          cleanupOk = false;
        }
      }
      try {
        await native.write(original);
        check(jsonEncode(await native.read()) == jsonEncode(original));
      } catch (_) {
        cleanupOk = false;
      }
      for (final c in clients) {
        try {
          await c.auth.signOut(scope: SignOutScope.local);
          await c.dispose();
        } catch (_) {
          cleanupOk = false;
        }
      }
      transport.close();
      debugPrint(
        'STUDY_FLUTTER ${cleanupOk ? 'PASS' : 'FAIL'} fixture_cleanup',
      );
      if (cleanupOk && clients.length == 2) mark('auth_users_retained');
      check(cleanupOk);
    }
  });
}
