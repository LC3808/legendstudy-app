// Isolated entrypoint: no Supabase/Firebase initialization or production traffic.
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/features/analytics/analytics_providers.dart';
import 'package:legendstudy_app/features/analytics/data/noop_analytics_service.dart';
import 'package:legendstudy_app/features/resources/data/pdf_download.dart';
import 'package:legendstudy_app/features/resources/data/ephemeral_pdf_loader.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_download_action.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_viewer_page.dart';

import 'pdf_download_fixture.dart';

const fixtureId = '11111111-1111-4111-8111-111111111111';
void main() => runApp(const MaterialApp(home: QaHome()));

class QaHome extends StatefulWidget {
  const QaHome({super.key});
  @override
  State<QaHome> createState() => _QaHomeState();
}

class _QaHomeState extends State<QaHome> {
  String state = 'ALLOWED';
  bool fail = false;
  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey('$state/$fail'),
    overrides: [
      analyticsServiceProvider.overrideWithValue(NoopAnalyticsService()),
      pdfDownloadPolicyProvider(fixtureId).overrideWith(
        (ref) async => PdfDownloadPolicy(
          state,
          official: Uri.parse('https://legendstudy.com/1700'),
        ),
      ),
      ephemeralPdfLoaderProvider.overrideWithValue(
        (_) async => fixturePdfBytes,
      ),
      pdfDownloadServiceProvider.overrideWithValue(
        PdfDownloadService(
          (_) async => {
            'resource_id': fixtureId,
            'status': 'resolved',
            'policy': {
              'state': state,
              'filename': '레전드스터디_합성_검수.pdf',
              'sha256': sha256.convert(fixturePdfBytes).toString(),
            },
            'target': 'https://blog.kakaocdn.net/dna/a/b/fixture.pdf?credential=test&signature=test&expires=4102444800',
          },
          (_) async {
            if (fail) throw StateError('simulated network failure');
            return fixturePdfBytes;
          },
          (bytes, name) async =>
              await const MethodChannel('com.legendstudy.app/pdf-download')
                  .invokeMethod<bool>('save', {'bytes': bytes, 'name': name}) ??
              false,
        ),
      ),
    ],
    child: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('LS PDF TEST — 격리 검수')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '합성 PDF만 사용 · 운영 연결 없음 · GA4 전송 없음\n실제 서버/네트워크 검증을 대체하지 않습니다.',
            ),
            DropdownButton<String>(
              value: state,
              items: [
                'ALLOWED',
                'PENDING',
                'VIEW_ONLY',
                'OFFICIAL_LINK',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) => setState(() => state = s!),
            ),
            SwitchListTile(
              title: const Text('네트워크 실패 모의 (해제 후 재시도)'),
              value: fail,
              onChanged: (v) => setState(() => fail = v),
            ),
            const PdfDownloadAction(
              resourceId: fixtureId,
              postId: '1700',
              resourceType: 'other',
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProviderScope(
                    overrides: [
                      ephemeralPdfLoaderProvider.overrideWithValue(
                        (_) async => fixturePdfBytes,
                      ),
                    ],
                    child: PdfViewerPage(
                      args: PdfViewerRouteArgs(
                        title: '합성 PDF 검수',
                        ephemeral: true,
                        delivery: ResourceDelivery(
                          kind: ResourceDeliveryKind.externalFile,
                          uri: Uri.parse('https://example.invalid/fixture.pdf'),
                          label: 'PDF',
                          description: 'synthetic',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('기존 PDF Viewer 열기'),
            ),
          ],
        ),
      ),
    ),
  );
}
