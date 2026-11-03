// Opt-in isolated TEST only. Reuses existing evaluations; no new Provider/credit work.
// Credentials arrive through a one-shot loopback runner, never Dart defines/assets.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_page.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'TEST saved Q1 Q2 render through authenticated native coaching and History',
    (tester) async {
      final config = AppConfig.fromEnvironment();
      expect(config.supabaseUrl, 'https://kpqbedylxlyntrrfybpn.supabase.co');
      expect(config.essayApiOrigin, 'https://legendstudy-task16b.pages.dev');
      final uri = Uri.parse(const String.fromEnvironment('SMOKE_CONFIG_URL'));
      expect(uri.host, '127.0.0.1');
      expect(uri.scheme, 'http');
      final response = await http.get(uri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final client = SupabaseClient(
        config.supabaseUrl,
        config.supabasePublishableKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      try {
        await client.auth.signInWithPassword(
          email: data['email'] as String,
          password: data['password'] as String,
        );
        final owner = client.auth.currentUser!.id;
        final gateway = MathGateway(client, owner);
        // TASK16-H optional cross-platform inputs. Reads only; no evaluation.
        for (final id in (data['web_attempt_ids'] as List? ?? [])) {
          final input = await gateway.call('math_input', 'read_input', {
            'attempt_id': id,
          });
          expect(input['attempt']['attempt_id'] ?? input['attempt']['id'], id);
          expect((input['attempt']['typed_answer'] as String).isNotEmpty, true);
          expect(input['artifacts'], isEmpty);
        }
        if (data['web_revealed_evaluation'] != null) {
          final shared = await gateway.call('math_coaching', 'read', {
            'evaluation_id': data['web_revealed_evaluation'],
          });
          expect(shared['disclosed'], true);
          expect(shared.containsKey('full_solution'), true);
          final history = await gateway.call('math_coaching', 'history', {
            'evaluation_id': data['web_revealed_evaluation'],
          });
          final current = (history['attempts'] as List).cast<Map<String, dynamic>>().singleWhere(
            (a) => a['evaluation_id'] == data['web_revealed_evaluation'],
          );
          expect(current['solution_revealed'], true);
          expect(current['exposed_hint_levels'], containsAll([1, 2]));
        }
        final rows = await gateway.session('math_session_history', {});
        expect((rows['runs'] as List).length, greaterThanOrEqualTo(3));
        final run = await gateway.session('math_session_read', {
          'p_run': data['run_id'],
        });
        expect(run['state'], 'completed');
        final questions = run['questions'] as List;
        expect(questions.length, 2);
        Future<void> settle() => tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
        Future<void> show(String text) async {
          final target = find.text(text);
          final scrollable = find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first;
          for (var i = 0; target.evaluate().isEmpty && i < 100; i++) {
            await tester.drag(scrollable, const Offset(0, -350));
            await tester.pumpAndSettle();
          }
          expect(target, findsWidgets);
          await tester.ensureVisible(target.first);
          await tester.pumpAndSettle();
        }

        for (final q in questions) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [supabaseClientProvider.overrideWithValue(client)],
              child: MaterialApp(
                home: MathCoachingPage(
                  key: ValueKey(q['evaluation_id']),
                  evaluationId: q['evaluation_id'] as String,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 90),
          );
          expect(find.byType(MathCoachingScreen), findsOneWidget);
          final screen = tester.widget<MathCoachingScreen>(
            find.byType(MathCoachingScreen),
          );
          expect(screen.snapshot.tasks.length, lessThanOrEqualTo(5));
          expect(screen.snapshot.id, q['evaluation_id']);
          if (const bool.fromEnvironment('TASK16G_CAPTURE')) {
            await binding.takeScreenshot('q${questions.indexOf(q) + 1}-result');
          }
          if (screen.snapshot.tasks.isNotEmpty) {
            final title = screen.snapshot.tasks.first['title'] as String;
            await show(title);
            await tester.tap(find.text(title).first);
            await settle();
            await show('개념 힌트 보기');
            await tester.tap(find.text('개념 힌트 보기'));
            await settle();
            expect(find.text('힌트를 확인하지 못했습니다. 다시 요청해 주세요.'), findsNothing);
            await show('해결 방향 보기');
            await tester.tap(find.text('해결 방향 보기'));
            await settle();
            expect(find.text('힌트를 확인하지 못했습니다. 다시 요청해 주세요.'), findsNothing);
            expect(
              find.text('조건을 적용한 각 계산을 검산하고 수정한 풀이를 원래 풀이와 비교하세요.'),
              findsOneWidget,
            );
            if (const bool.fromEnvironment('TASK16G_CAPTURE')) {
              await binding.takeScreenshot('q2-step-hints');
            }
            await tester.pageBack();
            await settle();
          }
          await tester.tap(find.text('기본 개념 확인'));
          await tester.pumpAndSettle();
          expect(find.text('문제의 최종 정답은 공개하지 않습니다.'), findsOneWidget);
          await tester.tap(find.text('학습 기록'));
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 60),
          );
          expect(find.text('학습 기록을 불러오지 못했습니다.'), findsNothing);
          expect(find.text('같은 문제, 이어지는 성장'), findsOneWidget);
          expect(find.text('연결된 학습 기록이 없습니다.'), findsNothing);
          if (const bool.fromEnvironment('TASK16G_CAPTURE')) {
            await binding.takeScreenshot(
              'q${questions.indexOf(q) + 1}-history',
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
        // Verify the original bytes over the same gateway used by History, not a public URL.
        for (final artifact in data['artifacts'] as List) {
          expect(
            (await gateway.readEvidence(artifact as String)).length,
            greaterThan(1000),
          );
        }
        if (data['history_only'] == true) {
          gateway.close();
          binding.reportData = {
            ...?binding.reportData,
            'scope': 'new actual reevaluations: result, hints and History',
            'questions': 2,
            'providerCalls': 0,
            'newSubmissions': 0,
          };
          return;
        }
        final nextRun = await gateway.session('math_session_read', {
          'p_run': data['rewrite_run_id'],
        });
        final nextQuestion = (nextRun['questions'] as List).singleWhere(
          (q) => q['question_id'] == '42ebe3b3-2b04-5a21-80a3-75d332611f8b',
        ) as Map;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [supabaseClientProvider.overrideWithValue(client)],
            child: MaterialApp(
              home: MathCoachingPage(
                evaluationId: nextQuestion['evaluation_id'] as String,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
        final beforeReveal = await gateway.call('math_coaching', 'read', {
          'evaluation_id': nextQuestion['evaluation_id'],
        });
        if (beforeReveal['disclosed'] == false) {
          expect(beforeReveal.containsKey('full_solution'), false);
        }
        await show('전체 풀이 및 해설 보기');
        await tester.tap(find.text('전체 풀이 및 해설 보기'));
        await settle();
        expect(find.byType(MathSolutionPage), findsNothing);
        await tester.tap(find.text('조금 더 풀어볼게요'));
        await settle();
        final afterCancel = await gateway.call('math_coaching', 'read', {
          'evaluation_id': nextQuestion['evaluation_id'],
        });
        expect(afterCancel['disclosed'], beforeReveal['disclosed']);
        await tester.tap(find.text('전체 풀이 및 해설 보기'));
        await settle();
        await tester.tap(find.text('정답·해설 공개'));
        await settle();
        expect(find.byType(MathSolutionPage), findsOneWidget);
        final revealed = await gateway.call('math_coaching', 'read', {
          'evaluation_id': nextQuestion['evaluation_id'],
        });
        expect(revealed['disclosed'], true);
        expect(revealed.containsKey('full_solution'), true);
        final history = await gateway.call('math_coaching', 'history', {
          'evaluation_id': nextQuestion['evaluation_id'],
        });
        expect(
          (history['attempts'] as List).any(
            (r) =>
                r['evaluation_id'] == nextQuestion['evaluation_id'] &&
                r['solution_revealed'] == true,
          ),
          true,
        );
        if (const bool.fromEnvironment('TASK16G_CAPTURE')) {
          await binding.takeScreenshot('explicit-solution-reveal');
        }
        await tester.pageBack();
        await settle();
        await tester.scrollUntilVisible(
          find.text('수정 답안 작성하기'),
          350,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 100,
        );
        await tester.tap(find.text('수정 답안 작성하기'));
        await tester.pumpAndSettle();
        expect(
          find.text('무료 재첨삭 1회를 이용합니다. 기간과 자격은 제출 시 서버에서 다시 확인합니다.'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(FilledButton, '수정 답안 작성'));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
        expect(find.byType(SourceCatalogPage), findsOneWidget);
        expect(find.text('다시 써보기 · 최초 제출 문항을 유지합니다.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('답안 작성하기'),
          350,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 100,
        );
        await tester.tap(find.text('답안 작성하기'));
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
        expect(find.byType(TextField), findsWidgets);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('TASK16G_CAPTURE')) {
          await binding.takeScreenshot('next-free-rewrite');
        }
        gateway.close();
        binding.reportData = {
          ...?binding.reportData,
          'scope':
              'existing Q1/Q2 native render/History and private original reads',
          'questions': 2,
          'hintLevels': [1, 2],
          'explicitRevealAndHistory': true,
          'preDisclosureObserved': beforeReveal['disclosed'] == false,
          'providerCalls': 0,
          'newSubmissions': 0,
          'creditMutations': 0,
        };
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await client.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
