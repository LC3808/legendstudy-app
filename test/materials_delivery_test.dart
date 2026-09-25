import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_viewer_page.dart';

import 'day6_ui_test.dart' show resource;

void main() {
  const source = 'https://legendstudy.com/1';
  test(
    'explicit file metadata routes extensionless file, never suffix inference',
    () {
      final action = resolveResourceDelivery(
        resource(fileUrl: 'https://files.example.test/123'),
        source,
      );
      expect(action.kind, ResourceDeliveryKind.externalFile);
      expect(action.uri.toString(), 'https://files.example.test/123');
      expect(action.sourceFallback.toString(), source);
      expect(action.label, '문제 보기');
      final unknown = resolveResourceDelivery(
        resource(
          linkKind: 'unknown',
          sourceUrl: 'https://files.example.test/exam.pdf',
        ),
        source,
      );
      expect(unknown.kind, ResourceDeliveryKind.sourcePage);
      expect(unknown.uri.toString(), source);
    },
  );
  test('PDF detection uses MIME or extension metadata only', () {
    expect(isPdfMetadata('application/pdf', null), isTrue);
    expect(isPdfMetadata('application/pdf; charset=binary', null), isTrue);
    expect(isPdfMetadata(null, 'PDF'), isTrue);
    expect(isPdfMetadata(null, null), isFalse);
    expect(isPdfMetadata('audio/mpeg', 'mp3'), isFalse);
    expect(isPdfMetadata(null, null), isFalse);
  });
  for (final type in [
    'question',
    'answer',
    'explanation',
    'answer_explanation',
  ]) {
    test('$type PDF metadata is eligible for the internal viewer', () {
      final item = ContentResource(
        id: type,
        contentItemId: 'parent',
        resourceType: type,
        title: type,
        sourceUrl: source,
        linkKind: 'file',
        fileUrl: 'https://files.example.test/$type',
        mimeType: 'application/pdf',
      );
      expect(item.isPdf, isTrue);
      expect(
        resolveResourceDelivery(item, source).kind,
        ResourceDeliveryKind.externalFile,
      );
    });
  }
  test('landing PDF suffix and non-PDF file remain outside the viewer', () {
    final landing = ContentResource(
      id: 'landing',
      contentItemId: 'parent',
      resourceType: 'question',
      title: 'landing',
      sourceUrl: 'https://files.example.test/paper.pdf',
      linkKind: 'landing_page',
      fileExtension: 'pdf',
    );
    final audio = ContentResource(
      id: 'audio',
      contentItemId: 'parent',
      resourceType: 'listening_audio',
      title: 'audio',
      sourceUrl: source,
      linkKind: 'file',
      fileUrl: 'https://files.example.test/audio',
      mimeType: 'audio/mpeg',
      fileExtension: 'mp3',
    );
    expect(landing.isPdf, isFalse);
    expect(audio.isPdf, isFalse);
  });
  for (final invalid in <String?>[
    null,
    '',
    'javascript:bad',
    'file:///tmp/a',
    'https://user:pass@example.test/f',
    'https://example.test/a\nb',
    '/relative',
    'https://',
  ]) {
    test(
      'invalid/missing file uses parent fallback case ${invalid?.length}',
      () {
        final action = resolveResourceDelivery(
          resource(fileUrl: invalid),
          source,
        );
        expect(action.kind, ResourceDeliveryKind.sourcePage);
        expect(action.uri.toString(), source);
        expect(action.label, '원문에서 보기');
        expect(action.sourceFallback, isNull);
        expect(
          resolveResourceDelivery(resource(fileUrl: invalid), '').kind,
          ResourceDeliveryKind.unavailable,
        );
      },
    );
  }
  for (final suffix in [
    '?expires=1',
    '?X-Amz-Signature=test-only',
    '?download=1',
    '#fragment',
    '/login',
    '/oauth/authorize',
    '?token=test-only',
  ]) {
    test(
      'uncertain direct URL falls back without exposing details $suffix',
      () {
        final action = resolveResourceDelivery(
          resource(fileUrl: 'https://files.example.test$suffix'),
          source,
        );
        expect(action.kind, ResourceDeliveryKind.sourcePage);
        expect(action.uri.toString(), source);
        expect(action.description, isNot(contains(suffix)));
      },
    );
  }
  test('landing is a page even with PDF suffix; unknown future kind fails to parent', () {
    final action = resolveResourceDelivery(
      resource(
        linkKind: 'landing_page',
        sourceUrl: 'https://files.example.test/paper.pdf',
      ),
      source,
    );
    expect(action.kind, ResourceDeliveryKind.externalPage);
    expect(action.label, '문제 자료 페이지 보기');
    expect(
      resolveResourceDelivery(resource(linkKind: 'future_kind'), source).kind,
      ResourceDeliveryKind.sourcePage,
    );
  });
  test(
    'auth landing falls back; no invented official-source or rights status',
    () {
      expect(
        resolveResourceDelivery(
          resource(
            linkKind: 'landing_page',
            sourceUrl: 'https://example.test/login',
          ),
          source,
        ).uri.toString(),
        source,
      );
      expect(
        resolveResourceDelivery(
          resource(linkKind: 'unknown'),
          'javascript:bad',
        ).uri,
        isNull,
      );
      expect(
        resolveResourceDelivery(
          resource(linkKind: 'landing_page', sourceUrl: source),
          source,
        ).sourceFallback,
        isNull,
      );
    },
  );
  for (final type in [
    'question',
    'answer',
    'explanation',
    'answer_explanation',
    'listening_audio',
  ]) {
    test('CTA describes resource purpose $type', () {
      final action = resolveResourceDelivery(
        resource(resourceType: type),
        source,
      );
      expect(action.label, '${resourceTypeLabels[type]} 보기');
      expect(action.label, isNot(contains('다운로드')));
      expect(action.description, isNot(contains('공식')));
    });
  }
  testWidgets(
    'launch failure is inline, retryable, serialized and cleared for new URL',
    (tester) async {
      final pending = Completer<bool>();
      var calls = 0;
      Uri target = Uri.parse('https://example.test/first');
      late StateSetter update;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            externalOpenerProvider.overrideWithValue((uri) async {
              calls++;
              return calls == 1 ? pending.future : true;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return ExternalLinkButton(uri: target, label: '자료 열기');
                },
              ),
            ),
          ),
        ),
      );
      final action = tester
          .widget<TextButton>(find.byType(TextButton))
          .onPressed!;
      action();
      action();
      await tester.pump();
      expect(calls, 1);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('외부 링크를 열지 못했어요'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      update(() => target = Uri.parse('https://example.test/replaced'));
      await tester.pump();
      expect(find.textContaining('외부 링크를 열지 못했어요'), findsNothing);
      await tester.tap(find.text('자료 열기'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    },
  );

  testWidgets('invalid viewer target has safe retry/fallback UX', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PdfViewerPage(
          args: PdfViewerRouteArgs(
            title: '문제지',
            delivery: ResourceDelivery(
              kind: ResourceDeliveryKind.unavailable,
              uri: null,
              label: '열 수 없음',
              description: 'unavailable',
              sourceFallback: Uri.parse('https://legendstudy.com/1'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('문제지'), findsOneWidget);
    expect(find.text('자료를 바로 열 수 없어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('원문에서 보기'), findsOneWidget);
  });
}
