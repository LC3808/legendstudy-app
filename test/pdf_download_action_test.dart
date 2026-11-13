import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/resources/data/pdf_download.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_download_action.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_viewer_page.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/analytics/analytics_providers.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';

class Recording implements AnalyticsService {
  final names = <String>[];
  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    names.add(name);
    expect(params?['post_id'], '1700');
    expect(params?['resource_id'], '11111111-1111-4111-8111-111111111111');
    expect(params?['resource_type'], 'question');
    expect(
      params?.keys,
      unorderedEquals([
        'platform',
        'screen',
        'source',
        'status',
        'post_id',
        'resource_id',
        'resource_type',
      ]),
    );
  }

  @override
  void setScreen(String value) {}
  @override
  void setUserId(String? value) {}
}

void main() {
  const id = '11111111-1111-4111-8111-111111111111';
  testWidgets('viewer keeps download available when rendering fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfDownloadPolicyProvider(id)
              .overrideWith((ref) async => const PdfDownloadPolicy('ALLOWED')),
        ],
        child: const MaterialApp(
          home: PdfViewerPage(
            args: PdfViewerRouteArgs(
              title: '수학 문제',
              resourceId: id,
              resourceType: 'question',
              delivery: ResourceDelivery(
                kind: ResourceDeliveryKind.sourcePage,
                uri: null,
                sourceFallback: null,
                label: '원문',
                description: '원문',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('자료를 바로 열 수 없어요.'), findsOneWidget);
    expect(find.text('PDF 다운로드'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final state in ['PENDING', 'VIEW_ONLY']) {
    testWidgets('$state does not offer download', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pdfDownloadPolicyProvider(id)
                .overrideWith((ref) async => PdfDownloadPolicy(state)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PdfDownloadAction(
                resourceId: id,
                postId: '1700',
                resourceType: 'question',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PDF 다운로드'), findsNothing);
    });
  }
  testWidgets('official state offers official page only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfDownloadPolicyProvider(id).overrideWith(
            (ref) async => PdfDownloadPolicy(
              'OFFICIAL_LINK',
              official: Uri.parse('https://www.kice.re.kr/'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PdfDownloadAction(
              resourceId: id,
              postId: '1700',
              resourceType: 'question',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('공식 자료 페이지'), findsOneWidget);
    expect(find.text('PDF 다운로드'), findsNothing);
  });
  testWidgets('click and saved event separated by actual saver completion', (
    tester,
  ) async {
    final recording = Recording();
    final completion = Completer<bool>();
    final bytes = Uint8List.fromList('%PDF-fixture'.codeUnits);
    final service = PdfDownloadService(
      (_) async => {
        'status': 'resolved',
        'resource_id': id,
        'policy': {
          'state': 'ALLOWED',
          'filename': 'fixture.pdf',
          'sha256': sha256.convert(bytes).toString(),
        },
        'target': 'https://blog.kakaocdn.net/dna/a/b/f.pdf?credential=x&signature=x&expires=4102444800',
      },
      (_) async => bytes,
      (_, _) => completion.future,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(recording),
          pdfDownloadPolicyProvider(id)
              .overrideWith((ref) async => const PdfDownloadPolicy('ALLOWED')),
          pdfDownloadServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PdfDownloadAction(
              resourceId: id,
              postId: '1700',
              resourceType: 'question',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF 다운로드'));
    await tester.pump();
    expect(recording.names, ['pdf_download_click']);
    expect(find.text('PDF를 저장했어요.'), findsNothing);
    completion.complete(true);
    await tester.pumpAndSettle();
    expect(recording.names, ['pdf_download_click', 'pdf_download_success']);
    expect(find.text('PDF를 저장했어요.'), findsOneWidget);
  });
}
