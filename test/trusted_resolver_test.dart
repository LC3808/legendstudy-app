import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/features/resources/data/trusted_resolver_client.dart';
import 'package:legendstudy_app/features/resources/data/ephemeral_pdf_loader.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';
import 'package:legendstudy_app/features/resources/presentation/resource_section.dart';
import 'package:legendstudy_app/features/resources/presentation/pdf_viewer_page.dart';

const id = '11111111-1111-4111-8111-111111111111';
const target =
    'https://blog.kakaocdn.net/dna/a/b/file.pdf?credential=fixture&signature=fixture&expires=1999999999';
const source = 'https://legendstudy.com/1705';
Map<String, Object> success() => {
  'status': 'resolved',
  'kind': 'pdf',
  'resource_id': id,
  'target': target,
};
ContentResource item(String type) => ContentResource(
  id: id,
  contentItemId: 'parent',
  resourceType: type,
  title: '자료',
  sourceUrl: 'https://blog.kakaocdn.net/dna/a/b/file.pdf',
  linkKind: 'unknown',
);
void main() {
  test('ephemeral loader downloads only validated target, no redirect and PDF bytes only', () async {
    final client = MockClient((request) async {
      expect(request.followRedirects, isFalse);
      expect(request.url.toString(), target);
      return http.Response('%PDF-1.7 fixture', 200);
    });
    expect(
      String.fromCharCodes(
        await loadEphemeralPdf(Uri.parse(target), transport: client),
      ),
      startsWith('%PDF-'),
    );
    for (final response in [
      http.Response('', 302),
      http.Response('not pdf', 200),
      http.Response('', 200, headers: {'content-length': '33554433'}),
    ]) {
      await expectLater(
        loadEphemeralPdf(
          Uri.parse(target),
          transport: MockClient((_) async => response),
        ),
        throwsStateError,
      );
    }
  });

  test(
    'client sends resource_id only, returns transient validated target',
    () async {
      final client = TrustedResolverClient((body) async {
        expect(body, {'resource_id': id});
        return success();
      });
      expect((await client.resolve(id)).toString(), target);
      expect(await client.resolve('bad-id'), isNull);
    },
  );
  test('safe-open rejects unsafe response and mismatched contract', () async {
    for (final bad in [
      'http://blog.kakaocdn.net/dna/a/b/f?credential=x&signature=y&expires=1',
      'https://127.0.0.1/a',
      'https://blog.kakaocdn.net.evil.test/dna/a/b/f',
      'https://user:pass@blog.kakaocdn.net/dna/a/b/f',
      'file:///tmp/f',
      '$target#x',
      '$target&signature=duplicate',
    ]) {
      expect(
        await TrustedResolverClient((_) async => {...success(), 'target': bad})
            .resolve(id),
        isNull,
      );
    }
    expect(
      await TrustedResolverClient(
        (_) async => {...success(), 'resource_id': 'other'},
      ).resolve(id),
      isNull,
    );
    expect(
      await TrustedResolverClient((_) async => throw StateError(target))
          .resolve(id),
      isNull,
    );
  });
  test('audio and non-PDF keep existing delivery contract', () {
    expect(resolverCapable(item('listening_audio')), isFalse);
    expect(resolverCapable(item('other')), isFalse);
    expect(
      resolverCapable(
        const ContentResource(
          id: id,
          contentItemId: 'parent',
          resourceType: 'question',
          title: '압축 자료',
          sourceUrl: 'https://blog.kakaocdn.net/dna/a/b/f.zip',
          linkKind: 'unknown',
          fileExtension: 'zip',
        ),
      ),
      isFalse,
    );
    expect(
      resolveResourceDelivery(item('question'), source).kind,
      ResourceDeliveryKind.sourcePage,
    );
    expect(item('question').isPdf, isFalse);
  });
  for (final type in [
    'question',
    'answer',
    'explanation',
    'answer_explanation',
  ]) {
    testWidgets('Guest $type unknown to existing PdfViewerPage, intent once', (
      tester,
    ) async {
      var attempts = 0, calls = 0;
      Uri? delivery;
      final pending = Completer<Uint8List>();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ResourceSection(
                contentItemId: 'parent',
                contentSlug: 'exam',
                contentSourceUrl: source,
                isArticle: false,
                onMeaningfulAction: () => attempts++,
              ),
            ),
          ),
          GoRoute(
            path: '/materials/:slug/resource/:id',
            builder: (_, state) =>
                PdfViewerPage(args: state.extra as PdfViewerRouteArgs),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentResourcesProvider('parent')
                .overrideWith((_) async => [item(type)]),
            trustedResolverProvider.overrideWithValue(
              TrustedResolverClient((_) async {
                calls++;
                return success();
              }),
            ),
            ephemeralPdfLoaderProvider.overrideWithValue((uri) {
              delivery = uri;
              return pending.future;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('${resourceTypeLabels[type]} 보기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PdfViewerPage), findsOneWidget);
      expect(delivery.toString(), target);
      expect(attempts, 1);
      expect(calls, 1);
      final page = tester.widget<PdfViewerPage>(find.byType(PdfViewerPage));
      expect(page.args!.ephemeral, isTrue);
      expect(page.args!.delivery.sourceFallback.toString(), source);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('viewer loading/error/re-resolve ${size.width} / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final first = Completer<Uint8List>();
        final retry = Completer<Uint8List>();
        var loads = 0, resolves = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ephemeralPdfLoaderProvider.overrideWithValue(
                (_) => ++loads == 1 ? first.future : retry.future,
              ),
              trustedResolverProvider.overrideWithValue(
                TrustedResolverClient((_) async {
                  resolves++;
                  return success();
                }),
              ),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: PdfViewerPage(
                  args: PdfViewerRouteArgs(
                    title: '자료',
                    ephemeral: true,
                    resolverResourceId: id,
                    delivery: ResourceDelivery(
                      kind: ResourceDeliveryKind.externalFile,
                      uri: Uri.parse(target),
                      label: '자료 보기',
                      description: '',
                      sourceFallback: Uri.parse(source),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('자료 불러오는 중'), findsOneWidget);
        first.completeError(StateError('private transport error'));
        await tester.pumpAndSettle();
        expect(find.text('자료를 바로 열 수 없어요.'), findsOneWidget);
        expect(find.textContaining('private transport'), findsNothing);
        await tester.tap(find.text('다시 시도'));
        await tester.pump();
        expect(resolves, 1);
        expect(loads, 2);
        expect(find.text('자료 불러오는 중'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('recoverable error renders ${size.width} / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentResourcesProvider('parent')
                  .overrideWith((_) async => [item('question')]),
              trustedResolverProvider.overrideWithValue(
                TrustedResolverClient(
                  (_) async => {'status': 'fallback', 'reason': 'rate_limited'},
                ),
              ),
              externalOpenerProvider.overrideWithValue((uri) async {
                expect(uri.toString(), source);
                opened++;
                return true;
              }),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: const Scaffold(
                  body: SingleChildScrollView(
                    child: ResourceSection(
                      contentItemId: 'parent',
                      contentSlug: 'exam',
                      contentSourceUrl: source,
                      isArticle: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('문제 보기'));
        await tester.pumpAndSettle();
        expect(find.text('자료를 바로 열 수 없어요.'), findsOneWidget);
        expect(find.text('다시 시도'), findsOneWidget);
        await tester.ensureVisible(find.text('원문에서 보기'));
        await tester.tap(find.text('원문에서 보기'));
        await tester.pumpAndSettle();
        expect(opened, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final reason in [
    'not_found',
    'inactive',
    'not_resolvable',
    'source_unavailable',
    'ambiguous',
    'unsupported',
    'rate_limited',
  ]) {
    test('fallback $reason', () async {
      expect(
        await TrustedResolverClient(
          (_) async => {'status': 'fallback', 'reason': reason},
        ).resolve(id),
        isNull,
      );
    });
  }
}
