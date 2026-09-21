import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/config/app_information.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/materials/presentation/materials_page.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:legendstudy_app/features/profile/presentation/grade_page.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/content/presentation/content_detail_page.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/presentation/resource_section.dart';

import 'support/search_fake.dart';
import 'day9_c2_personal_test.dart'
    show FakeBookmarkRepository, FakeRecentRepository, item;

class ProfileFake implements ProfileRepository {
  UserProfile value = const UserProfile(
    id: 'a',
    gradeLevel: 2,
    displayName: '학생',
  );
  int writes = 0;
  bool fail = false;
  @override
  Future<UserProfile?> fetchCurrentProfile() async => value;
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {}
  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
  }) async {
    writes++;
    if (fail) throw StateError('offline');
    value = UserProfile(
      id: 'a',
      gradeLevel: gradeLevel,
      displayName: value.displayName,
    );
  }
}

final frame = GlobalKey();
Future<void> capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (!const bool.fromEnvironment('CORE_RENDER')) return;
  final boundary =
      frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final img = await boundary.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('/private/tmp/legendstudy-core-ui')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    img.dispose();
  });
}

Widget app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light.copyWith(
    textTheme: AppTheme.light.textTheme.apply(fontFamily: 'CorePreview'),
  ),
  home: RepaintBoundary(
    key: frame,
    child: Scaffold(
      body: SafeArea(
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: child,
        ),
      ),
    ),
  ),
);
void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final file = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
      if (file.existsSync()) {
        await (FontLoader(
              'CorePreview',
            )..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b))))
            .load();
      }
    }
  });
  testWidgets(
    'month and exam type are independent and empty state can recover',
    (tester) async {
      final repo = FakeSearchRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [searchRepositoryProvider.overrideWithValue(repo)],
          child: app(const MaterialsPage()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('시행 월'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('6월'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('시험 종류'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('평가원 모의평가'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.filters.month, 6);
      expect(repo.calls.last.filters.examType, 'evaluation_mock');
      await tester.enterText(find.byType(TextField), '없는검색어');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('자료 전체 보기'));
      await tester.tap(find.text('자료 전체 보기'));
      await tester.pumpAndSettle();
      expect(repo.calls.last.filters.isEmpty, isTrue);
      expect(repo.calls.last.text, '');
    },
  );
  testWidgets(
    'grade loads, saves and surfaces failure without losing selection',
    (tester) async {
      final repo = ProfileFake();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('a')),
            ),
            profileRepositoryProvider.overrideWithValue(repo),
          ],
          child: app(const GradePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '고2'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('고3'));
      repo.fail = true;
      await tester.tap(find.text('학년 저장'));
      await tester.pumpAndSettle();
      expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('학년 저장'));
      await tester.pumpAndSettle();
      expect(repo.value.gradeLevel, 3);
      expect(repo.value.displayName, '학생');
    },
  );
  test(
    'OAuth defaults closed, explicit flags expose only declared providers',
    () {
      final defaults = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(const AppConfig())],
      );
      final enabled = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              googleOAuthEnabled: true,
              googleServerClientId: 'fixture-public-client',
            ),
          ),
        ],
      );
      addTearDown(defaults.dispose);
      addTearDown(enabled.dispose);
      expect(defaults.read(availableOAuthProvidersProvider), isEmpty);
      expect(enabled.read(availableOAuthProvidersProvider), [
        OAuthProvider.google,
      ]);
    },
  );
  testWidgets(
    'policy placeholders never invent URLs and app info uses native version',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            appConfigProvider.overrideWithValue(const AppConfig()),
            appVersionProvider.overrideWith((ref) async => '2.4.1 (37)'),
          ],
          child: app(const ProfilePage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('개인정보처리방침'), findsOneWidget);
      expect(find.text('이용약관'), findsOneWidget);
      expect(find.text('준비 중 · 문의·건의사항으로 연락해 주세요.'), findsNWidgets(2));
      await tester.ensureVisible(find.text('앱 정보'));
      await tester.tap(find.text('앱 정보'));
      await tester.pumpAndSettle();
      expect(find.text('버전 2.4.1 (37)'), findsOneWidget);
      expect(find.text('0.1.0'), findsNothing);
    },
  );
  testWidgets('native app version reflects build metadata', (tester) async {
    const channel = MethodChannel('com.legendstudy.app/info');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => {'version': '2.4.1', 'build': '37'},
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(appVersionProvider.future), '2.4.1 (37)');
  });
  testWidgets(
    'guest save pushes auth and returns to same detail without auto-save',
    (tester) async {
      final events = StreamController<AuthStatus>.broadcast();
      final bookmarks = FakeBookmarkRepository();
      final router = GoRouter(
        initialLocation: '/materials/item-1',
        routes: [
          GoRoute(
            path: '/materials/item-1',
            builder: (_, _) => const ContentDetailPage(slug: 'item-1'),
          ),
          GoRoute(
            path: '/auth',
            builder: (_, _) => const Scaffold(body: AuthPage()),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(events.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) async* {
              yield const AuthStatus(null);
              yield* events.stream;
            }),
            contentDetailProvider('item-1').overrideWith((ref) async => item()),
            contentResourcesProvider('content-1')
                .overrideWith((ref) async => []),
            bookmarkRepositoryProvider.overrideWithValue(bookmarks),
            recentViewRepositoryProvider.overrideWithValue(
              FakeRecentRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);
      events.add(const AuthStatus('a', event: AuthChangeEvent.signedIn));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/materials/item-1',
      );
      expect(find.byType(AuthPage), findsNothing);
      expect(bookmarks.adds, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets('compact resource groups and truthful CTA 360x640 at $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final resources = List.generate(
        12,
        (i) => ContentResource(
          id: '$i',
          contentItemId: 'p',
          resourceType: i.isEven ? 'question' : 'answer_explanation',
          title: '긴 자료 제목 · 2026학년도 공통과목 문제와 정답 해설 $i',
          sourceUrl: 'https://example.org/file',
          linkKind: 'unknown',
          examSubjectId: 'o${i ~/ 4}',
          groupLabel: ['국어', '수학', '영어'][i ~/ 4],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentResourcesProvider('p')
                .overrideWith((ref) async => resources),
          ],
          child: app(
            SingleChildScrollView(
              child: ResourceSection(
                contentItemId: 'p',
                contentSourceUrl: 'https://legendstudy.com/1',
                isArticle: false,
              ),
            ),
            scale: scale,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('원문에서 보기'), findsNothing);
      await capture(tester, 'resources-collapsed-$scale');
      await tester.tap(find.text('국어'));
      await tester.pumpAndSettle();
      expect(find.text('원문에서 보기'), findsNWidgets(4));
      expect(find.textContaining('이용 가능 여부'), findsNothing);
      await capture(tester, 'resources-expanded-$scale');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
