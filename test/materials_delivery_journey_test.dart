import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/content/presentation/content_detail_page.dart';
import 'package:legendstudy_app/features/exams/exam_providers.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:legendstudy_app/features/materials/presentation/materials_page.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';

import 'core_ux_test.dart' as preview;
import 'day6_ui_test.dart' show Parents, Exams, Resources;
import 'support/search_fake.dart';

Future<void> Function(String)? nativeCapture;
void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  Future<void> capture(WidgetTester tester, String name) async {
    await preview.capture(tester, name);
    if (nativeCapture != null) await nativeCapture!(name);
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Guest search/filter/page/detail/external/return retains state $scale',
      (tester) async {
        if (nativeCapture == null) {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        final search = FakeSearchRepository()..pageSize = 1;
        final first = search.items.first;
        final parents = Parents()..detail = () async => first.content;
        final resources = Resources()
          ..result = () async => [
            ContentResource(
              id: 'question',
              contentItemId: first.content.id,
              examSubjectId: 'korean',
              groupLabel: '국어',
              resourceType: 'question',
              title: '국어 문제지',
              sourceUrl: first.content.sourceUrl,
              linkKind: 'file',
              fileUrl: 'https://files.example.test/paper',
            ),
            ContentResource(
              id: 'answer',
              contentItemId: first.content.id,
              examSubjectId: 'korean',
              groupLabel: '국어',
              resourceType: 'answer_explanation',
              title: '국어 정답과 해설',
              sourceUrl: first.content.sourceUrl,
              linkKind: 'unknown',
            ),
          ];
        final opened = <Uri>[];
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            searchRepositoryProvider.overrideWithValue(search),
            contentRepositoryProvider.overrideWithValue(parents),
            examRepositoryProvider.overrideWithValue(
              Exams()..result = () async => {first.content.id: first.exam!},
            ),
            resourceRepositoryProvider.overrideWithValue(resources),
            externalOpenerProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return uri.host != 'files.example.test';
            }),
          ],
        );
        addTearDown(container.dispose);
        final router = container.read(routerProvider)..go('/materials');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: preview.frame,
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                locale: const Locale('ko'),
                supportedLocales: const [Locale('ko')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                theme: const bool.fromEnvironment('CORE_RENDER')
                    ? AppTheme.light.copyWith(
                        textTheme: AppTheme.light.textTheme.apply(
                          fontFamily: 'CorePreview',
                        ),
                      )
                    : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '모의평가');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(ActionChip, '학년'));
        await tester.tap(find.widgetWithText(ActionChip, '학년'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, '고3'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('자료 더 보기'));
        await tester.tap(find.text('자료 더 보기'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('자료 더 보기'));
        await tester.tap(find.text('자료 더 보기'));
        await tester.pumpAndSettle();
        expect(container.read(searchControllerProvider).items.length, 3);
        await tester.ensureVisible(find.text(first.content.title));
        await tester.pumpAndSettle();
        final materialScroll = find
            .descendant(
              of: find.byType(MaterialsPage),
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        final scrollable = find
            .descendant(of: materialScroll, matching: find.byType(Scrollable))
            .first;
        final requests = search.calls.length;
        await capture(tester, 'delivery-$scale-search');
        // Native keyboard/safe-area animation can finish while the compositor
        // captures the frame; record the settled viewport, not its intermediate state.
        await tester.pumpAndSettle();
        final beforeOffset = tester
            .state<ScrollableState>(scrollable)
            .position
            .pixels;
        await tester.tap(find.text(first.content.title));
        await tester.pumpAndSettle();
        expect(find.byType(ContentDetailPage), findsOneWidget);
        expect(
          FocusManager.instance.primaryFocus?.hasFocus == true &&
              FocusManager.instance.primaryFocus?.context?.widget
                  is EditableText,
          isFalse,
        );
        await tester.ensureVisible(find.text('문제 보기'));
        await tester.tap(find.text('문제 보기'));
        await tester.pumpAndSettle();
        expect(opened.single.toString(), 'https://files.example.test/paper');
        expect(find.textContaining('외부 링크를 열지 못했어요'), findsOneWidget);
        expect(find.text('자료를 불러오지 못했어요.'), findsNothing);
        await capture(tester, 'delivery-$scale-failure');
        await tester.ensureVisible(find.text('원문에서 찾기'));
        await tester.tap(find.text('원문에서 찾기'));
        await tester.pumpAndSettle();
        expect(opened.last.toString(), first.content.sourceUrl);
        final detailScroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ContentDetailPage),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final detailOffset = detailScroll.position.pixels;
        // Offline opener/lifecycle simulation: no claim of real browser/file reading.
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pumpAndSettle();
        expect(
          tester.widget<ContentDetailPage>(find.byType(ContentDetailPage)).slug,
          first.content.slug,
        );
        expect(
          ModalRoute.of(tester.element(find.byType(ContentDetailPage)))!
              .isCurrent,
          isTrue,
        );
        expect(detailScroll.position.pixels, detailOffset);
        await tester.ensureVisible(find.text('원문에서 보기'));
        await capture(tester, 'delivery-$scale-source');
        await tester.tap(find.text('원문에서 보기'));
        await tester.pumpAndSettle();
        expect(opened.length, 3);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/materials',
        );
        expect(search.calls.length, requests);
        expect(container.read(searchControllerProvider).items.length, 3);
        expect(
          container.read(searchControllerProvider.notifier).query.filters.grade,
          3,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '모의평가',
        );
        final restored = tester.state<ScrollableState>(scrollable).position;
        // OS keyboard removal changes both viewport and bottom safe area. Allow
        // at most that system inset, never a list reset or loss of the selected row.
        expect(
          restored.pixels,
          closeTo(
            beforeOffset.clamp(0.0, restored.maxScrollExtent),
            1 + tester.view.viewPadding.bottom / tester.view.devicePixelRatio,
          ),
        );
        expect(find.text(first.content.title).hitTestable(), findsOneWidget);
        await capture(tester, 'delivery-$scale-return');
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
