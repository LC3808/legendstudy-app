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
import 'package:legendstudy_app/features/essay/question_pdf.dart';

// Opt-in device test: existing device session only; network guard denies writes,
// evaluation, Edge and payments. No credentials or PDF bytes enter test reports.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('11 universities live metadata and approved native PDFs', (
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
      reason: 'Owner must log in to this verification device first',
    );
    final results = <Map<String, Object?>>[];
    var captureReady = false;
    for (final id in [
      'konkuk',
      'gachon',
      'kyunghee',
      'korea',
      'dongguk',
      'sogang',
      'skku',
      'sookmyung',
      'soongsil',
      'swu',
      'kau',
    ]) {
      final catalog = await SourceCatalog.load(
        university: id,
        accessToken: client.auth.currentSession?.accessToken,
        browse: (id) =>
            client.rpc('essay_browse_catalog', params: {'p_university': id}),
      );
      expect(catalog.browseUnavailable, false);
      final u = catalog.universities.singleWhere(
        (u) => u['sourceUniversityId'] == id,
      );
      final exams = catalog.exams
          .where((e) => e['sourceUniversityId'] == id)
          .toList();
      expect(exams, isNotEmpty);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supabaseClientProvider.overrideWithValue(client)],
          child: MaterialApp(
            home: SourceCatalogPage(
              key: ValueKey(id),
              catalog: Future.value(SourceCatalog([u], exams)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(u['name'] as String).first);
      await tester.pumpAndSettle();
      final periods =
          exams.map((e) => "${e['year']}:${e['kind']}").toSet().toList()..sort(
            (a, b) => b.split(':').first.compareTo(a.split(':').first) == 0
                ? a.compareTo(b)
                : b.compareTo(a),
          );
      if (periods.length > 1) {
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
        await tester.pumpAndSettle();
        final p = periods.first;
        await tester.tap(
          find
              .text(
                '${p.split(':').first}학년도 ${p.endsWith(':mock') ? '모의논술' : '수시논술'}',
              )
              .last,
        );
        await tester.pumpAndSettle();
      }
      final selectedExams = exams
          .where((e) => "${e['year']}:${e['kind']}" == periods.first)
          .toList();
      final tracks = selectedExams
          .map((e) => e['track'] as String)
          .toSet()
          .toList();
      if (tracks.length > 1) {
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tracks.first).last);
        await tester.pumpAndSettle();
      }
      final choices = selectedExams
          .where((e) => e['track'] == tracks.first)
          .toList();
      if (choices.length > 1) {
        await tester.tap(find.byType(DropdownButtonFormField<String>).at(3));
        await tester.pumpAndSettle();
        final label = [
          choices.first['campus'],
          choices.first['session'],
        ].whereType<String>().join(' · ');
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
      }
      expect(find.byType(CheckboxListTile), findsWidgets);
      final question =
          (choices.first['questions'] as List).first as Map<String, dynamic>;
      final asset = QuestionPdfAsset.parse(
        question['studentPdf'],
        question['dbQuestionId'] as String,
      );
      if (asset != null) {
        await tester.ensureVisible(
          find.widgetWithText(OutlinedButton, '문제 보기').first,
        );
        await tester.tap(find.widgetWithText(OutlinedButton, '문제 보기').first);
        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.pump(const Duration(milliseconds: 250));
          final zoom = find.widgetWithIcon(IconButton, Icons.zoom_in);
          if (zoom.evaluate().isNotEmpty &&
              tester.widget<IconButton>(zoom).onPressed != null) {
            break;
          }
        }
        expect(
          find.text('${asset.startPage} / ${asset.pages}'),
          findsOneWidget,
        );
        final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
        if (asset.startPage < asset.pages) {
          expect(
            tester.widget<IconButton>(next).onPressed,
            isNotNull,
            reason: 'Native PDF renderer must be ready',
          );
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(
            find.text('${asset.startPage + 1} / ${asset.pages}'),
            findsOneWidget,
          );
        }
        if (!captureReady) {
          await binding.convertFlutterSurfaceToImage();
          captureReady = true;
        }
        await tester.pump();
        await binding.takeScreenshot('material-$id');
      } else {
        expect(id, 'skku');
      }
      results.add({
        'university': id,
        'exams': exams.length,
        'questions': exams.fold<int>(
          0,
          (n, e) => n + (e['questions'] as List).length,
        ),
        'nativePdf': asset == null ? 'RIGHTS_HOLD' : 'PASS',
        'questionId': question['dbQuestionId'],
        'startPage': asset?.startPage,
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    binding.reportData = {...?binding.reportData, 'universities': results};
  }, timeout: const Timeout(Duration(minutes: 10)));
}
