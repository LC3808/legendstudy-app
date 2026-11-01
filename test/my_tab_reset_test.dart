import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/app/navigation_shell.dart';

void main() {
  testWidgets('MY reentry returns to profile rather than retained settings', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/my/settings',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => NavigationShell(shell: shell),
          branches: [
            for (final route in ['home', 'materials', 'study', 'lab', 'my'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/$route',
                    builder: (_, _) => Text('root $route'),
                    routes: [
                      if (route == 'my')
                        GoRoute(
                          path: 'settings',
                          builder: (_, _) => const Text('settings page'),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('settings page'), findsOneWidget);
    // Logout/login returns to home, but the indexed shell retains MY's old stack.
    router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();
    expect(find.text('root my'), findsOneWidget);
    expect(find.text('settings page'), findsNothing);
  });
}
