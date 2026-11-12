import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase/supabase_providers.dart';
import '../features/home/guide/home_menu_guide.dart';

class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  final targets = List.generate(5, (_) => GlobalKey());
  bool showing = false;
  bool pending = false;
  String? guideOwner;

  void scheduleGuide(String? owner) {
    if (pending || showing) return;
    pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted ||
            widget.shell.currentIndex != 0 ||
            GoRouterState.of(context).uri.path != '/home' ||
            ref.read(authStateProvider).value?.userId != owner ||
            !ref.read(homeGuideEligibleProvider)) {
          return;
        }
        final claimed =
            await ref.read(homeGuideStoreProvider)?.claim() ?? false;
        if (!mounted ||
            !claimed ||
            widget.shell.currentIndex != 0 ||
            GoRouterState.of(context).uri.path != '/home' ||
            ref.read(authStateProvider).value?.userId != owner) {
          return;
        }
        setState(() {
          showing = true;
          guideOwner = owner;
        });
      } finally {
        pending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final owner = auth.value?.userId;
    ref.listen(authStateProvider, (_, next) {
      if (showing &&
          (next.isLoading ||
              next.hasError ||
              next.value?.userId != guideOwner)) {
        setState(() => showing = false);
      }
    });
    final atHome =
        widget.shell.currentIndex == 0 &&
        GoRouterState.of(context).uri.path == '/home';
    if (showing && !atHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && showing) setState(() => showing = false);
      });
    }
    final visible =
        showing &&
        atHome &&
        !auth.isLoading &&
        !auth.hasError &&
        owner == guideOwner;
    if (atHome &&
        !auth.isLoading &&
        !auth.hasError &&
        !showing &&
        ref.watch(homeGuideEligibleProvider)) {
      scheduleGuide(owner);
    }
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: visible,
          child: ExcludeFocus(
            excluding: visible,
            child: Scaffold(
              body: SafeArea(child: widget.shell),
              bottomNavigationBar: NavigationBar(
                selectedIndex: widget.shell.currentIndex,
                onDestinationSelected: (index) => widget.shell.goBranch(
                  index,
                  initialLocation:
                      index == 4 || index == widget.shell.currentIndex,
                ),
                destinations: [
                  NavigationDestination(
                    key: targets[0],
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: '홈',
                  ),
                  NavigationDestination(
                    key: targets[1],
                    icon: const Icon(Icons.article_outlined),
                    selectedIcon: const Icon(Icons.article),
                    label: '자료',
                  ),
                  NavigationDestination(
                    key: targets[2],
                    icon: const Icon(Icons.timer_outlined),
                    selectedIcon: const Icon(Icons.timer),
                    label: '학습',
                  ),
                  NavigationDestination(
                    key: targets[3],
                    icon: const Icon(Icons.insights_outlined),
                    selectedIcon: const Icon(Icons.insights),
                    label: 'LAB',
                  ),
                  NavigationDestination(
                    key: targets[4],
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person),
                    label: 'MY',
                  ),
                ],
              ),
            ),
          ),
        ),
        if (visible)
          Positioned.fill(
            child: HomeMenuGuide(
              targets: targets,
              onDone: () => setState(() => showing = false),
            ),
          ),
      ],
    );
  }
}
