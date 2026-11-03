import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/links/external_link.dart';
import '../../core/supabase/supabase_providers.dart';
import '../personal/personal_providers.dart';
import '../onboarding/onboarding_gate.dart';
import 'app_update_controller.dart';

bool updatePromptRouteAllowed(String location) =>
    !location.startsWith('/auth') &&
    !const {
      '/intro',
      '/onboarding',
      '/app-guide',
      '/my/delete-account',
    }.contains(location);

/// One root Navigator dialog; no routing, auth state or profile writes.
class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({required this.router, required this.child, super.key});
  final GoRouter router;
  final Widget child;
  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  late final AppUpdateController controller;
  DialogRoute<void>? dialog;
  final Set<DialogRoute<void>> removed = {};
  bool scheduled = false;
  bool active = true;
  bool authReady = false;
  @override
  void initState() {
    super.initState();
    controller = ref.read(appUpdateControllerProvider);
    controller.addListener(sync);
    widget.router.routeInformationProvider.addListener(sync);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(controller.check());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) unawaited(controller.check());
    sync();
  }

  void sync() {
    if (!mounted || scheduled) return;
    scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduled = false;
      if (!mounted) return;
      final navigator = widget.router.routerDelegate.navigatorKey.currentState;
      if (navigator == null) return;
      final allowed =
          active &&
          authReady &&
          updatePromptRouteAllowed(
            widget.router.routeInformationProvider.value.uri.path,
          );
      if (!allowed || controller.prompt == null) {
        final route = dialog;
        if (route != null && route.isActive) {
          removed.add(route);
          dialog = null;
          navigator.removeRoute(route);
        }
        return;
      }
      if (dialog != null) return;
      final route = DialogRoute<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (_) => _UpdateDialog(controller: controller),
      );
      dialog = route;
      unawaited(
        navigator.push(route).then((_) {
          if (dialog == route) dialog = null;
          final programmatic = removed.remove(route);
          if (!mounted) return;
          if (!programmatic && controller.prompt?.required == false) {
            unawaited(controller.later());
          }
          sync();
        }),
      );
    });
    // Network completion may arrive while idle; request a frame explicitly.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    authReady = !auth.isLoading && !auth.hasError;
    if (auth.value?.isAuthenticated == true) {
      final profile = ref.watch(currentProfileProvider);
      authReady = onboardingProfileReady(profile);
    }
    sync();
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.router.routeInformationProvider.removeListener(sync);
    controller.removeListener(sync);
    // A root ProviderContainer may outlive its mounted Navigator.
    controller.cancelPendingCheck();
    super.dispose();
  }
}

class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.controller});
  final AppUpdateController controller;
  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  bool opening = false;
  bool failed = false;
  Future<void> openStore() async {
    final prompt = widget.controller.prompt;
    if (prompt == null || opening) return;
    setState(() {
      opening = true;
      failed = false;
    });
    var opened = false;
    try {
      opened = await ref
          .read(externalOpenerProvider)(prompt.policy.storeUrl)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      /* Platform errors must not expose raw links or diagnostics. */
    }
    // Opening the store may background/unmount this dialog before completion.
    // Remember success in the coordinator before checking widget lifetime.
    if (opened) widget.controller.openedStore(prompt);
    if (!mounted) return;
    setState(() {
      opening = false;
      failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final prompt = widget.controller.prompt;
      if (prompt == null) return const SizedBox.shrink();
      return PopScope(
        canPop: !prompt.required,
        child: AlertDialog(
          scrollable: true,
          icon: const Icon(
            Icons.system_update_alt_rounded,
            color: Color(0xFFFFAC14),
            size: 36,
          ),
          title: Text(prompt.required ? '업데이트가 필요해요.' : '새로운 업데이트가 있어요.'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt.required
                    ? '최신 버전으로 업데이트해야 서비스를 계속 이용할 수 있어요.'
                    : '더 편리한 학습을 위해 최신 버전으로 업데이트해 주세요.',
              ),
              const SizedBox(height: 16),
              Text(
                '버전 ${prompt.policy.latest.version}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (prompt.policy.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(prompt.policy.releaseNotes),
              ],
              if (failed) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: const Text('스토어를 열지 못했어요. 다시 시도해 주세요.'),
                ),
              ],
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            if (!prompt.required)
              TextButton(
                onPressed: opening
                    ? null
                    : () => unawaited(widget.controller.later()),
                child: const Text('나중에'),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFAC14),
                foregroundColor: const Color(0xFF1B2A4A),
                minimumSize: const Size(140, 48),
              ),
              onPressed: opening ? null : openStore,
              child: Text(opening ? '스토어 여는 중…' : '업데이트하기'),
            ),
          ],
        ),
      );
    },
  );
}
