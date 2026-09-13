import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationShell extends StatelessWidget {
  const NavigationShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: shell),
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article),
          label: '자료',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer),
          label: '학습',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'MY',
        ),
      ],
    ),
  );
}
