import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:legendstudy_app/features/resources/data/pdf_download.dart';
import 'package:legendstudy_app/features/resources/data/ephemeral_pdf_loader.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_viewer_page.dart';

// Offline synthetic PDF; native renderer, production page, no account or server writes.
Uint8List fixture() {
  final objects = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 5 0 R 7 0 R] /Count 3 >>',
  ];
  for (var i = 0; i < 3; i++) {
    final stream =
        '0.1 0.4 0.8 rg 40 100 220 220 re f BT /F1 28 Tf 40 400 Td (PDF QA PAGE ${i + 1}) Tj ET';
    objects.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 500] /Resources << /Font << /F1 9 0 R >> >> /Contents ${4 + i * 2} 0 R >>',
    );
    objects.add('<< /Length ${stream.length} >>\nstream\n$stream\nendstream');
  }
  objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');
  var pdf = '%PDF-1.4\n';
  final offsets = <int>[0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(pdf.length);
    pdf += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
  }
  final xref = pdf.length;
  pdf += 'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n';
  for (final offset in offsets.skip(1)) {
    pdf += '${offset.toString().padLeft(10, '0')} 00000 n \n';
  }
  pdf +=
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n';
  return Uint8List.fromList(ascii.encode(pdf));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const id = '11111111-1111-4111-8111-111111111111';
  for (final policy in ['VIEW_ONLY', 'ALLOWED']) {
    testWidgets('native PDF viewport remains visible: $policy', (tester) async {
      final bytes = fixture();
      Widget page() => ProviderScope(
        overrides: [
          pdfDownloadServiceProvider.overrideWithValue(
            PdfDownloadService(
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
              (savedBytes, _) async {
                expect(savedBytes, orderedEquals(bytes));
                return true;
              },
            ),
          ),
          pdfDownloadPolicyProvider(id)
              .overrideWith((ref) async => PdfDownloadPolicy(policy)),
          ephemeralPdfLoaderProvider.overrideWithValue((_) async => bytes),
        ],
        child: MaterialApp(
          home: PdfViewerPage(
            args: PdfViewerRouteArgs(
              title: 'PDF QA $policy',
              resourceId: id,
              ephemeral: true,
              delivery: ResourceDelivery(
                kind: ResourceDeliveryKind.externalFile,
                uri: Uri.parse('https://blog.kakaocdn.net/dna/fixture.pdf'),
                sourceFallback: null,
                label: 'PDF',
                description: 'fixture',
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(page());
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        final viewer = find.byType(PdfViewer);
        if (viewer.evaluate().isNotEmpty &&
            tester
                    .widget<PdfViewer>(viewer)
                    .documentRef
                    .resolveListenable()
                    .document !=
                null) {
          break;
        }
      }
      final viewer = find.byType(PdfViewer);
      expect(viewer, findsOneWidget);
      final document = tester
          .widget<PdfViewer>(viewer)
          .documentRef
          .resolveListenable()
          .document;
      expect(document?.pages.length, 3);
      expect(tester.getSize(viewer).height, greaterThan(200));
      for (final pdfPage in document!.pages) {
        final rendered = await pdfPage.render(width: 300, height: 500);
        expect(rendered, isNotNull);
        rendered?.dispose();
      }
      if (policy == 'ALLOWED') {
        await tester.tap(find.text('PDF 다운로드'));
        await tester.pumpAndSettle();
        expect(find.text('PDF를 저장했어요.'), findsOneWidget);
        expect(tester.getSize(viewer).height, greaterThan(200));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(page());
      await tester.pumpAndSettle();
      expect(find.byType(PdfViewer), findsOneWidget);
      expect(tester.getSize(find.byType(PdfViewer)).height, greaterThan(200));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
