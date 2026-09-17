import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_page.dart';
import '../features/materials/presentation/materials_page.dart';
import '../features/saved/presentation/saved_page.dart';
import '../features/saved/presentation/recent_page.dart';
import '../features/profile/presentation/profile_page.dart';
import 'navigation_shell.dart';
import '../features/content/presentation/content_detail_page.dart';
import '../features/study/presentation/study_page.dart';
import '../features/profile/presentation/school_page.dart';
import '../features/feedback/presentation/feedback_page.dart';
import '../features/feedback/presentation/admin_feedback_page.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/new_password_page.dart';
import '../features/auth/presentation/password_recovery_page.dart';
import '../core/supabase/supabase_providers.dart';
import '../shared/widgets/nested_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/materials/:slug',
        builder: (_, state) =>
            ContentDetailPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(path: '/browse', redirect: (_, _) => '/materials'),
      GoRoute(path: '/saved', redirect: (_, _) => '/my/saved'),
      GoRoute(path: '/profile', redirect: (_, _) => '/my'),
      GoRoute(
        path: '/auth',
        builder: (_, _) =>
            const NestedPage(title: '로그인 / 시작하기', child: AuthPage()),
      ),
      GoRoute(
        path: '/auth/recovery',
        builder: (_, _) =>
            const NestedPage(title: '비밀번호 재설정', child: PasswordRecoveryPage()),
      ),
      GoRoute(
        path: '/auth/new-password',
        builder: (_, _) =>
            const NestedPage(title: '새 비밀번호 설정', child: NewPasswordPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => NavigationShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/materials',
                builder: (context, state) => MaterialsPage(
                  initialQuery: state.uri.queryParameters['q'] ?? '',
                  initialType: state.uri.queryParameters['type'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (context, state) => const StudyPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'saved',
                    builder: (_, _) =>
                        const NestedPage(title: '저장한 자료', child: SavedPage()),
                  ),
                  GoRoute(
                    path: 'school',
                    builder: (_, _) =>
                        const NestedPage(title: '학교 설정', child: SchoolPage()),
                  ),
                  GoRoute(
                    path: 'recent',
                    builder: (_, _) =>
                        const NestedPage(title: '최근 본 자료', child: RecentPage()),
                  ),
                  GoRoute(
                    path: 'feedback',
                    builder: (_, _) => const NestedPage(
                      title: '문의·건의사항',
                      child: FeedbackPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'admin/feedback',
                    builder: (_, _) => const NestedPage(
                      title: '문의 관리',
                      child: AdminFeedbackPage(),
                    ),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => NestedPage(
                          title: '문의 상세',
                          child: AdminFeedbackDetailPage(
                            id: state.pathParameters['id']!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('페이지를 찾을 수 없어요')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('홈으로 가기'),
        ),
      ),
    ),
  );
  // A recovery link opens a session whose event is passwordRecovery. Routing on
  // the event keeps it distinct from an ordinary sign-in, and the token itself
  // is never read, logged or placed in a route.
  //
  // fireImmediately covers the deep-link race: if the recovery session is
  // already the current auth state when this provider is built, a listener that
  // only reacts to later changes would never see it.
  //
  // This subscription is only delivered while routerProvider itself has a
  // listener. LegendStudyApp watches it (ref.watch), which is what keeps it
  // alive; reading the router with ProviderContainer.read closes that
  // subscription immediately and silently stops recovery navigation.
  ref.listen<AsyncValue<AuthStatus>>(authStateProvider, (_, next) {
    if (next.value?.isPasswordRecovery ?? false) {
      router.go('/auth/new-password');
    }
  }, fireImmediately: true);
  ref.onDispose(router.dispose);
  return router;
});
