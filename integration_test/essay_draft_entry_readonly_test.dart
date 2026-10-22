import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/network/review_read_only_client.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';

// Existing signed-in verification device; reads only. Does not edit the owner's
// draft or capture its contents. Submission/Provider/finance denied by transport.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('registered HOLD question enters existing native writer', (
    tester,
  ) async {
    expect(reviewReadOnly, true);
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: false,
      httpClient: reviewHttpClient(),
    );
    final client = Supabase.instance.client;
    expect(
      client.auth.currentUser,
      isNotNull,
      reason: 'Existing device login required',
    );
    final catalog = await SourceCatalog.load(
      university: 'konkuk',
      accessToken: client.auth.currentSession?.accessToken,
      browse: (id) =>
          client.rpc('essay_browse_catalog', params: {'p_university': id}),
    );
    expect(catalog.browseUnavailable, false);
    final exam = catalog.exams.singleWhere(
      (e) => e['dbExamId'] == '1033e20b-9a20-5622-a67b-c288ace2734f',
    );
    expect(exam['verification'], 'REVIEW_REQUIRED');
    final university = catalog.universities.singleWhere(
      (u) => u['sourceUniversityId'] == 'konkuk',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
        child: MaterialApp(
          home: SourceCatalogPage(
            catalog: Future.value(SourceCatalog([university], [exam])),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(university['name'] as String).first);
    await tester.pumpAndSettle();
    final questions = (exam['questions'] as List).cast<Map<String, dynamic>>();
    final question = questions.singleWhere(
      (q) => q['dbQuestionId'] == '1f980d57-683e-5d49-b2ed-4bbb554b967b',
    );
    await tester.ensureVisible(
      find.widgetWithText(CheckboxListTile, question['label'] as String),
    );
    await tester.tap(
      find.widgetWithText(CheckboxListTile, question['label'] as String),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, '답안 작성하기'));
    await tester.tap(find.widgetWithText(FilledButton, '답안 작성하기'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('계정 답안 확인·저장'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('답안 확인'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('답안 확인'), findsOneWidget);
    expect(find.text('첨삭 요청 · 1 Credit'), findsNothing);
    binding.reportData = {
      'scope': 'native writer entry only; no draft changes or submission',
      'examId': exam['dbExamId'],
      'questionId': question['dbQuestionId'],
      'writerEntry': 'PASS',
      'accountSave': 'HOLD',
      'providerCalls': 0,
      'creditTransactions': 0,
    };
    await tester.pageBack();
    await tester.pumpAndSettle();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
