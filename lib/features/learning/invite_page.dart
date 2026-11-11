import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../school/school_providers.dart';
import 'invite_controller.dart';
import 'learning_repository.dart';

// Independent listener: never exchanges an Auth URL or changes OAuth callbacks.
Stream<Uri> inviteUris(Stream<Uri> source, Future<Uri?> initial) {
  late StreamController<Uri> output;
  StreamSubscription<Uri>? subscription;
  Uri? last;
  var cancelled = false;
  void emit(Uri uri) {
    if (cancelled || inviteTokenFromUri(uri) == null || uri == last) return;
    last = uri;
    output.add(uri);
  }

  output = StreamController<Uri>(
    onListen: () {
      // Subscribe before awaiting the initial link: a warm link must not be lost.
      subscription = source.listen(
        emit,
        onError: (Object e, StackTrace st) {
          if (!cancelled) output.addError(e, st);
        },
      );
      unawaited(
        initial.then((uri) {
          if (uri != null) emit(uri);
        }, onError: (Object _) {}),
      );
    },
    onCancel: () async {
      cancelled = true;
      await subscription?.cancel();
    },
  );
  return output.stream;
}

final incomingInviteLinksProvider = StreamProvider<Uri>((ref) {
  final links = AppLinks();
  return inviteUris(links.uriLinkStream, links.getInitialLink());
}, retry: (_, _) => null);

class InviteListener extends ConsumerStatefulWidget {
  const InviteListener({super.key, required this.child, required this.router});
  final Widget child;
  final GoRouter router;
  @override
  ConsumerState<InviteListener> createState() => _InviteListenerState();
}

class _InviteListenerState extends ConsumerState<InviteListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(learningSummaryProvider);
      ref.invalidate(schoolRanksProvider);
      ref.invalidate(ownSchoolCardProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(inviteControllerProvider);
    ref.listen(incomingInviteLinksProvider, (_, next) {
      final uri = next.value;
      if (uri != null) unawaited(controller.receive(uri));
    });
    final school = ref.watch(schoolSelectionProvider).value;
    return Column(
      children: [
        if (controller.needsSchoolConfirmation && school != null)
          Material(
            child: SafeArea(
              bottom: false,
              child: TextButton(
                onPressed: controller.busy
                    ? null
                    : controller.markSchoolConfirmed,
                child: Text('${school.name} · 내 학교 확인'),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// One tap from Study creates the attribution link and opens the OS share sheet.
class InviteShareButton extends ConsumerStatefulWidget {
  const InviteShareButton({super.key});
  @override
  ConsumerState<InviteShareButton> createState() => _InviteShareButtonState();
}

class _InviteShareButtonState extends ConsumerState<InviteShareButton> {
  bool busy = false;
  String? error;
  Future<void> share() async {
    if (busy) return;
    final auth = ref.read(authStateProvider);
    if (auth.isLoading || auth.hasError) return;
    final owner = auth.value?.userId;
    if (owner == null) {
      context.push('/auth');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final link = InviteLink.parse(
        await ref.read(learningRpcProvider)('invite_create', {
          'p_campaign': 'school_rank',
        }),
      );
      if (!mounted || ref.read(authStateProvider).value?.userId != owner)
        return;
      if (!link.expires.isAfter(DateTime.now())) throw const LearningFailure();
      await ref.read(inviteShareProvider)(link.url);
      // Opening/dismissing the share sheet is not a signup or successful send.
    } catch (_) {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() => error = '공유창을 열지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    ref.listen(authStateProvider, (_, _) {
      if (mounted && error != null) setState(() => error = null);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: busy || auth.isLoading || auth.hasError ? null : share,
          icon: const Icon(Icons.ios_share),
          label: Text(busy ? '공유 준비 중…' : '초대하기'),
        ),
        if (auth.hasError) const Text('로그인 상태를 확인하지 못했어요.'),
        if (error != null) Semantics(liveRegion: true, child: Text(error!)),
      ],
    );
  }
}
