// Explicit opt-in TEST integration. Only OS photo selection is supplied by the
// runner; uploads, recognition, confirmation, evaluation and History are live.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_exam_session.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_recognition_panel.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';
import 'package:legendstudy_app/features/essay/math_mobile/academic_purple.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_image_tools.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';

class RunnerPhotos extends ImagePickerPlatform {
  Uint8List? next;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(next!, mimeType: 'image/png', name: 'answer.png');
}

List<Map<String, dynamic>> questionsFor(Map<String, dynamic> exam) =>
    (exam['questions'] as List).cast<Map<String, dynamic>>();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('TEST new photo learning loop', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(config.supabaseUrl, 'https://kpqbedylxlyntrrfybpn.supabase.co');
    expect(config.essayApiOrigin, 'https://legendstudy-task16b.pages.dev');
    final uri = Uri.parse(const String.fromEnvironment('SMOKE_CONFIG_URL'));
    expect(uri.host, '127.0.0.1');
    expect(uri.scheme, 'http');
    final data = jsonDecode((await http.get(uri)).body) as Map<String, dynamic>;
    final client = SupabaseClient(
      config.supabaseUrl,
      config.supabasePublishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final picker = RunnerPhotos(), oldPicker = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = picker;
    Future<void> checkpoint(String name, Object value) async {
      final r = await http.post(
        uri.resolve('/checkpoint'),
        body: jsonEncode({'name': name, 'value': value}),
      );
      expect(r.statusCode, 200);
    }

    Future<void> settle() => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    Future<void> until(bool Function() ready, {int seconds = 160}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      expect(ready(), true);
    }

    Future<void> show(Finder target) async {
      Finder rootScroll() {
        final lists = find.byType(ListView);
        return lists.evaluate().isNotEmpty
            ? find
                  .descendant(
                    of: lists.first,
                    matching: find.byType(Scrollable),
                  )
                  .first
            : find
                  .byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.down,
                  )
                  .first;
      }

      // A lazily built control may be ABOVE the current editor, not below it.
      if (target.evaluate().isEmpty) {
        await tester.drag(rootScroll(), const Offset(0, 10000));
        await settle();
      }
      for (var i = 0; target.evaluate().isEmpty && i < 100; i++) {
        await tester.drag(rootScroll(), const Offset(0, -450));
        await settle();
      }
      expect(target, findsWidgets);
      await tester.ensureVisible(target.first);
      await settle();
    }

    Future<void> tap(String label) async {
      debugPrint('E2E tap $label');
      final f = find.text(label);
      await show(f);
      await tester.tap(f.first);
      await settle();
    }

    try {
      await client.auth.signInWithPassword(
        email: data['email'] as String,
        password: data['password'] as String,
      );
      final owner = client.auth.currentUser!.id,
          gateway = MathGateway(client, client.auth.currentUser!.id);
      final actual = await SourceCatalog.load(
        accessToken: client.auth.currentSession!.accessToken,
      );
      final exam = actual.exams.singleWhere(
        (e) => e['dbExamId'] == 'b98fd0c9-8a84-5747-a35c-25755312aede',
      );
      final scoped = SourceCatalog(
        actual.universities
            .where((u) => u['sourceUniversityId'] == exam['sourceUniversityId'])
            .toList(),
        [exam],
      );
      // Flutter drive reinstalls this TEST bundle. Restore only this run's
      // saved local request checkpoint and authenticated original bytes so a
      // build retry cannot create new OCR attempts or financial requests.
      if (data['resume'] case final Map<String, dynamic> resume) {
        final pending = resume['pending'] as Map;
        final fingerprint = jsonDecode(pending['fingerprint'] as String) as Map;
        for (final q in questionsFor(exam)) {
          final input = (resume['inputs'] as Map)[q['dbQuestionId']] as Map;
          final answer = (fingerprint['answers'] as List).singleWhere(
            (a) => a['id'] == q['dbQuestionId'],
          ) as Map;
          final store = SourceDraftGateway(owner, q['key'] as String);
          final draft = await store.loadDraft();
          await store.saveLocalDraft(answer['body'] as String, draft.revision);
          final ids = (input['candidate_regions'] as List)
              .map((r) => r['artifact_id'] as String)
              .toSet();
          await store.saveImages([
            for (final id in ids) await gateway.readEvidence(id),
          ]);
        }
        final selected = questionsFor(
          exam,
        ).map((q) => q['key'] as String).toList()..sort();
        final store = SourceDraftGateway(
          owner,
          'math-session:${exam['dbExamId']}:initial:${selected.join(',')}',
        );
        final saved = await store.loadDraft();
        await store.saveLocalDraft(jsonEncode(pending), saved.revision);
      }
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => SourceCatalogPage(catalog: Future.value(scoped)),
          ),
          GoRoute(
            path: '/lab/essay/history',
            builder: (_, _) => const SharedEssayHistoryPage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseClientProvider.overrideWithValue(client)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await until(() => find.text('한양대학교').evaluate().isNotEmpty);
      debugPrint('E2E university loaded');
      await tap('한양대학교');
      final questions = (exam['questions'] as List)
          .cast<Map<String, dynamic>>();
      for (final q in questions) {
        await tap(q['label'] as String);
      }
      await binding.takeScreenshot('new-exam-selection');
      await tap('답안 작성하기');
      await until(() => find.byType(TextField).evaluate().isNotEmpty);
      debugPrint('E2E writer loaded');
      for (var i = 0; i < questions.length; i++) {
        if (i > 0) {
          final dropdown = find.byType(DropdownButton<String>);
          await show(dropdown);
          await tester.tap(dropdown);
          await settle();
          await tester.tap(find.text(questions[i]['label'] as String).last);
          await settle();
        }
        final store = SourceDraftGateway(owner, questions[i]['key'] as String);
        if ((await store.loadImages()).isEmpty) {
          picker.next = base64Decode((data['photos'] as List)[i] as String);
          if (find.text('수식·도표 이미지 첨부').evaluate().isNotEmpty) {
            await tap('수식·도표 이미지 첨부');
          }
          await tap('이미지 첨부');
          await until(
            () => find.text('사진: 이 기기에 임시 저장됨').evaluate().isNotEmpty,
          );
          await tap('확대 · 회전 · 자르기');
          await tap('오른쪽으로 90° 회전');
          await tap('원본으로 되돌리기');
          await binding.takeScreenshot('new-photo-${i + 1}-correction');
          await tap('적용');
          await tap('첨부하기');
          await until(() => find.text('사진 저장 중').evaluate().isEmpty);
        }
      }
      await tap(
        exam['verification'] == 'REVIEW_REQUIRED' ? '답안 확인' : '답안 확인 · 첨삭 요청',
      );
      await until(() => find.byType(MathExamSession).evaluate().isNotEmpty);
      final resumingRun = data['resume']?['pending']?['runId'] != null;
      if (!resumingRun) {
        await until(
          () => find.text('저장한 답안 입력 확인 · 0 크레딧').evaluate().isNotEmpty,
        );
        debugPrint('E2E prepare inputs');
        await tap('저장한 답안 입력 확인 · 0 크레딧');
        await until(
          () => find.text('처리 중입니다…').evaluate().isEmpty,
          seconds: 250,
        );
      } else {
        await until(() => find.text('같은 회차 상태 확인').evaluate().isNotEmpty);
      }
      final selected = questions.map((q) => q['key'] as String).toList()
        ..sort();
      final draft = await SourceDraftGateway(
        owner,
        'math-session:${exam['dbExamId']}:initial:${selected.join(',')}',
      ).loadDraft();
      final pending = jsonDecode(draft.body) as Map<String, dynamic>;
      final inputs = <String, dynamic>{};
      for (final q in questions) {
        final id = (pending['attempts'] as Map)[q['key']];
        if (id != null) {
          inputs[q['dbQuestionId'] as String] = await gateway.call(
            'math_input',
            'read_input',
            {'attempt_id': id},
          );
        }
      }
      await checkpoint('new-photo-inputs', {
        'pending': pending,
        'inputs': inputs,
        'exam': exam,
      });
      expect(inputs.length, 2);
      if (data['phase'] == 'prepare') {
        expect(
          inputs.values.every(
            (v) => v['input_state'] == 'CONFIRMATION_REQUIRED',
          ),
          true,
        );
        expect(find.byType(MathRecognitionPanel), findsNWidgets(2));
        await show(find.text('인식 결과 확인'));
        await binding.takeScreenshot('new-recognition');
      } else {
        while (find.byType(MathRecognitionPanel).evaluate().isNotEmpty) {
          debugPrint('E2E confirm panel');
          final panel = find.byType(MathRecognitionPanel).first;
          final widget = tester.widget<MathRecognitionPanel>(panel);
          final regions = widget.regions;
          expect(
            widget.sources.isNotEmpty,
            true,
            reason: 'Original images must survive reentry',
          );
          final cards = find.descendant(
            of: panel,
            matching: find.byType(MathCard),
          );
          for (var i = 0; i < regions.length; i++) {
            debugPrint('E2E region ${i + 1}/${regions.length}');
            final r = regions[i],
                id = '${regions[i]['region_id'] ?? regions[i]['id']}';
            final corrected = (data['edits'] as Map)[id] as String?;
            expect(
              corrected,
              isNotNull,
              reason: 'Reviewed source required before confirming',
            );
            final card = cards.at(i);
            final edit = find.descendant(
              of: card,
              matching: find.text('전사 내용 수정'),
            );
            await show(edit);
            await tester.tap(edit);
            await settle();
            final field = find.descendant(
              of: card,
              matching: find.byType(TextField),
            );
            await show(field);
            await tester.enterText(field, corrected!);
            FocusManager.instance.primaryFocus?.unfocus();
            await settle();
            final check = find.descendant(
              of: card,
              matching: find.byType(CheckboxListTile),
            );
            await show(check);
            expect(tester.widget<CheckboxListTile>(check).onChanged, isNotNull);
            await tester.tap(check);
            await settle();
            expect(r['uncertain'], isA<bool>());
          }
          final finalCheck = find.descendant(
            of: panel,
            matching: find.text('모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.'),
          );
          await show(finalCheck);
          await tester.tap(finalCheck);
          await settle();
          final button = find.descendant(
            of: panel,
            matching: find.text('답안 입력 완료'),
          );
          await show(button);
          await binding.takeScreenshot(
            'confirmed-question-${find.byType(MathRecognitionPanel).evaluate().length}',
          );
          await tester.tap(button);
          await tester.pump();
          await until(() => find.byKey(widget.key!).evaluate().isEmpty);
          await settle();
        }
        Future<Map<String, dynamic>> storedRun(String? parent) async {
          final stored = await SourceDraftGateway(
            owner,
            'math-session:${exam['dbExamId']}:${parent ?? 'initial'}:${selected.join(',')}',
          ).loadDraft();
          final p = jsonDecode(stored.body) as Map;
          return Map<String, dynamic>.from(
            await gateway.session('math_session_read', {'p_run': p['runId']})
                as Map,
          );
        }

        if (!resumingRun) {
          await tap('논술 첨삭하기 · 이용권 확인');
          await tap('이용권 1개 사용하고 첨삭하기');
          await until(
            () => find.text('처리 중입니다…').evaluate().isEmpty,
            seconds: 240,
          );
        }
        final initial = await storedRun(null);
        await checkpoint('new-photo-run', initial);
        expect(initial['state'], 'completed');
        expect(
          (initial['questions'] as List).every(
            (q) => q['state'] == 'COMPLETED',
          ),
          true,
        );
        await binding.takeScreenshot('initial-evaluation-completed');
        await tap('답안 수정');
        await settle();
        await tester.pageBack();
        await settle();
        router.go('/');
        await settle();
        router.go('/lab/essay/history');
        await until(() => find.text('첨삭 결과 보기').evaluate().isNotEmpty);
        await tap('첨삭 결과 보기');
        await until(
          () => find.byType(MathCoachingScreen).evaluate().isNotEmpty,
        );
        final screen = tester.widget<MathCoachingScreen>(
          find.byType(MathCoachingScreen),
        );
        expect(
          (initial['questions'] as List).any(
            (q) => q['evaluation_id'] == screen.snapshot.id,
          ),
          true,
        );
        expect(screen.snapshot.tasks.length, lessThanOrEqualTo(5));
        await binding.takeScreenshot('new-initial-result');
        if (screen.snapshot.tasks.isNotEmpty) {
          await tap(screen.snapshot.tasks.first['title'] as String);
          await tap('개념 힌트 보기');
          await tap('해결 방향 보기');
          await binding.takeScreenshot('new-initial-hints');
          await tester.pageBack();
          await settle();
        }
        await tap('기본 개념 확인');
        await tap('학습 기록');
        await binding.takeScreenshot('new-initial-history');
        await tap('첨삭 결과');
        final hidden = await gateway.call('math_coaching', 'read', {
          'evaluation_id': screen.snapshot.id,
        });
        if (hidden['disclosed'] == false) {
          expect(hidden.containsKey('full_solution'), false);
        }
        await tap('전체 풀이 및 해설 보기');
        await tap('정답·해설 공개');
        await until(() => find.byType(MathSolutionPage).evaluate().isNotEmpty);
        await tester.pageBack();
        await settle();
        await tap('수정 답안 작성하기');
        await tap('수정 답안 작성');
        await until(() => find.byType(SourceCatalogPage).evaluate().isNotEmpty);
        await tap('답안 작성하기');
        await until(() => find.byType(TextField).evaluate().isNotEmpty);
        for (var i = 0; i < questions.length; i++) {
          if (i > 0) {
            final dropdown = find.byType(DropdownButton<String>);
            await show(dropdown);
            await tester.tap(dropdown);
            await settle();
            await tester.tap(find.text(questions[i]['label'] as String).last);
            await settle();
          }
          expect(
            tester.widget<MathImageInput>(find.byType(MathImageInput)).values,
            isEmpty,
            reason: 'No automatic submitted-photo copy into a fresh rewrite',
          );
          final field = find.byType(TextField);
          await show(field);
          await tester.enterText(
            field,
            (data['rewrites'] as List)[i] as String,
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await settle();
        }
        await tap(
          exam['verification'] == 'REVIEW_REQUIRED' ? '답안 확인' : '답안 확인 · 첨삭 요청',
        );
        await until(
          () => find.text('저장한 답안 입력 확인 · 0 크레딧').evaluate().isNotEmpty,
        );
        await tap('저장한 답안 입력 확인 · 0 크레딧');
        await until(() => find.text('처리 중입니다…').evaluate().isEmpty);
        await tap('논술 첨삭하기 · 이용권 확인');
        await tap('무료 재첨삭하기');
        await until(
          () => find.text('처리 중입니다…').evaluate().isEmpty,
          seconds: 240,
        );
        final free = await storedRun(initial['run_id'] as String);
        await checkpoint('new-free-run', free);
        expect(free['state'], 'completed');
        expect(free['previous_run_id'], initial['run_id']);
        expect(free['credits_required'], 0);
        await binding.takeScreenshot('new-free-completed');
        await tap('답안 수정');
        await settle();
        await tester.pageBack();
        await settle();
        router.go('/');
        await settle();
        router.go('/lab/essay/history');
        await until(() => find.text('첨삭 결과 보기').evaluate().isNotEmpty);
        await tap('첨삭 결과 보기');
        await until(
          () => find.byType(MathCoachingScreen).evaluate().isNotEmpty,
        );
        final freeScreen = tester.widget<MathCoachingScreen>(
          find.byType(MathCoachingScreen),
        );
        expect(
          (free['questions'] as List).any(
            (q) => q['evaluation_id'] == freeScreen.snapshot.id,
          ),
          true,
        );
        await tap('학습 기록');
        await settle();
        await binding.takeScreenshot('new-free-history');
        final history = await gateway.session('math_session_history', {});
        expect(
          (history['runs'] as List).any(
            (r) => r['run_id'] == initial['run_id'],
          ),
          true,
        );
        expect(
          (history['runs'] as List).any((r) => r['run_id'] == free['run_id']),
          true,
        );
        await checkpoint('new-loop-result', {
          'initial': initial['run_id'],
          'free': free['run_id'],
          'history': history,
          'providerEvaluationRequests': 4,
          'recognitionRequests': 6,
        });
      }
      binding.reportData = {
        ...?binding.reportData,
        'phase': data['phase'],
        'inputCount': 2,
      };
      gateway.close();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    } finally {
      ImagePickerPlatform.instance = oldPicker;
      await client.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
