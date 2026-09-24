import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/presentation/content_detail_page.dart';
import 'package:legendstudy_app/features/exams/exam_providers.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';
import 'package:legendstudy_app/features/materials/presentation/materials_page.dart';
import 'package:legendstudy_app/features/personal/bookmark_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';

import 'core_ux_test.dart' as preview;
import 'day6_ui_test.dart' show Parents, Exams, Resources;
import 'day9_c2_personal_test.dart' show FakeRecentRepository;
import 'inline_bookmark_state_test.dart' show BatchBookmarks;
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
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'inline bookmark guest/login/filter/page/detail/rollback/isolation $scale',
      (tester) async {
        if (nativeCapture == null) {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
        }
        final source = searchFixtures().first;
        final items = List.generate(
          4,
          (i) => ResourceSearchItem(
            content: ContentItem(
              id: 'row-$i',
              slug: 'row-$i',
              contentType: 'exam',
              title: '${source.content.title} $i',
              sourceUrl: source.content.sourceUrl,
              isActive: true,
            ),
            exam: source.exam,
            groups: source.groups,
            sortDate: source.sortDate,
          ),
        );
        final search = FakeSearchRepository(items: items)..pageSize = 2;
        final repo = BatchBookmarks();
        final auth = StreamController<AuthStatus>.broadcast();
        final c = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith((ref) => auth.stream),
            searchRepositoryProvider.overrideWithValue(search),
            bookmarkRepositoryProvider.overrideWithValue(repo),
            recentViewRepositoryProvider.overrideWithValue(
              FakeRecentRepository(),
            ),
            contentRepositoryProvider.overrideWithValue(
              Parents()..detail = () async => items.last.content,
            ),
            examRepositoryProvider.overrideWithValue(
              Exams()..result = () async => {},
            ),
            resourceRepositoryProvider.overrideWithValue(
              Resources()..result = () async => [],
            ),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await auth.close();
        });
        final router = c.read(routerProvider)..go('/materials');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
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
        auth.add(const AuthStatus(null));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '모의평가');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        Future<void> choose(String label, String selection) async {
          await tester.ensureVisible(find.widgetWithText(ActionChip, label));
          await tester.tap(find.widgetWithText(ActionChip, label));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ListTile, selection));
          await tester.pumpAndSettle();
        }

        await choose('학년', '고3');
        await choose('연도', '2026년');
        await choose('시행 월', '9월');
        expect(find.widgetWithText(ActionChip, '시험 종류'), findsNothing);
        await choose('과목', '국어');
        await tester.ensureVisible(find.widgetWithText(FilterChip, '모의고사'));
        await tester.tap(find.widgetWithText(FilterChip, '모의고사'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('자료 더 보기'));
        await tester.tap(find.text('자료 더 보기'));
        await tester.pumpAndSettle();
        expect(c.read(searchControllerProvider).items, hasLength(4));
        expect(repo.batches, isEmpty);
        final target = items.last.content;
        final button = find.byKey(ValueKey('bookmark-${target.id}'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final scrollable = find
            .descendant(
              of: find.byType(MaterialsPage),
              matching: find.byType(Scrollable),
            )
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        final offset = position.pixels, requests = search.calls.length;
        void preserved() {
          final query = c.read(searchControllerProvider.notifier).query;
          expect(query.text, '모의평가');
          expect(
            [
              query.filters.grade,
              query.filters.year,
              query.filters.month,
              query.filters.examType,
              query.filters.subjectId,
              query.filters.contentType,
            ],
            [3, 2026, 9, null, 'korean', 'exam'],
          );
          expect(search.calls.length, requests);
          expect(c.read(searchControllerProvider).items, hasLength(4));
          expect(position.pixels, closeTo(offset, 1));
        }

        Future<void> loginPrompt() async {
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.text('자료를 저장하려면 로그인해 주세요.'), findsOneWidget);
          expect(find.byType(ContentDetailPage), findsNothing);
          await tester.tap(find.widgetWithText(TextButton, '로그인'));
          await tester.pumpAndSettle();
          expect(find.byType(AuthPage), findsOneWidget);
        }

        await loginPrompt();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        preserved();
        await loginPrompt();
        auth.add(const AuthStatus('a', event: AuthChangeEvent.signedIn));
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsNothing);
        preserved();
        expect(repo.adds, 0);
        expect(repo.batches, hasLength(1));
        expect(repo.batches.single, hasLength(4));
        expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        repo.writeGate = Completer<void>();
        await tester.tap(button);
        await tester.tap(button);
        await tester.pump();
        expect(repo.adds, 1);
        expect(c.read(bookmarkStateProvider(target.id)).isSaved, isTrue);
        expect(find.byType(ContentDetailPage), findsNothing);
        repo.writeGate!.complete();
        await tester.pumpAndSettle();
        preserved();
        await preview.capture(tester, 'inline-$scale-saved');
        await nativeCapture?.call('inline-$scale-saved');
        await tester.ensureVisible(find.text(target.title));
        await tester.tap(find.text(target.title));
        await tester.pumpAndSettle();
        expect(find.byType(ContentDetailPage), findsOneWidget);
        expect(find.text('저장됨'), findsOneWidget);
        expect(repo.batches, hasLength(1));
        await tester.ensureVisible(find.widgetWithText(TextButton, '저장됨'));
        await tester.tap(find.widgetWithText(TextButton, '저장됨'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(c.read(bookmarkStateProvider(target.id)).isSaved, isFalse);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        repo.writeFailure = true;
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(c.read(bookmarkStateProvider(target.id)).isSaved, isFalse);
        expect(find.text('저장 변경을 완료하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
        expect(find.textContaining('private'), findsNothing);
        expect(c.read(searchControllerProvider).phase, SearchPhase.data);
        await preview.capture(tester, 'inline-$scale-rollback');
        await nativeCapture?.call('inline-$scale-rollback');
        repo.writeFailure = false;
        await tester.tap(button);
        await tester.pumpAndSettle();
        auth.add(const AuthStatus(null));
        await tester.pumpAndSettle();
        expect(c.read(bookmarkStateProvider(target.id)).isSaved, isFalse);
        repo.owner = 'b';
        auth.add(const AuthStatus('b'));
        await tester.pumpAndSettle();
        expect(c.read(bookmarkStateProvider(target.id)).isSaved, isFalse);
        expect(search.calls.length, requests);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
