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
import '../features/auth/presentation/auth_page.dart';
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
  ref.onDispose(router.dispose);
  return router;
});
