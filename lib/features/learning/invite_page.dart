import 'learning_widgets.dart' show LearningCard, LearningSectionHeader;

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Column(
      children: [
        if (controller.token != null && controller.message != null)
          Material(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Text('받은 친구 초대가 있어요.'),
                    TextButton(
                      onPressed: () => widget.router.push('/study/invite'),
                      child: const Text('초대 상태 확인'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class InvitePage extends ConsumerStatefulWidget {
  const InvitePage({super.key});
  @override
  ConsumerState<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends ConsumerState<InvitePage> {
  final input = TextEditingController();
  InviteLink? link;
  bool busy = false;
  String? message;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> generate() async {
    final owner = ref.read(authStateProvider).value?.userId;
    if (owner == null || busy) return;
    setState(() {
      busy = true;
      message = null;
      link = null;
    });
    try {
      final created = InviteLink.parse(
        await ref.read(learningRpcProvider)('invite_create', {
          'p_campaign': 'school_rank',
        }),
      );
      if (!mounted || ref.read(authStateProvider).value?.userId != owner) {
        return;
      }
      if (!created.expires.isAfter(DateTime.now())) {
        throw const LearningFailure();
      }
      setState(() => link = created);
    } catch (_) {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() => message = '초대 링크 생성에 실패했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> send(bool share) async {
    final current = link, owner = ref.read(authStateProvider).value?.userId;
    if (current == null || busy || owner == null) return;
    if (!current.expires.isAfter(DateTime.now())) {
      setState(() {
        link = null;
        message = '초대 링크가 만료되었어요. 새 링크를 만들어 주세요.';
      });
      return;
    }
    setState(() => busy = true);
    try {
      if (share) {
        await ref.read(inviteShareProvider)(current.url);
      } else {
        await Clipboard.setData(ClipboardData(text: current.url));
      }
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(
          () => message = share
              ? '공유 창을 열었어요. 친구의 가입 완료와는 별개예요.'
              : '초대 링크를 복사했어요.',
        );
      }
    } catch (_) {
      if (mounted && ref.read(authStateProvider).value?.userId == owner) {
        setState(() => message = '공유하지 못했어요. 다시 시도하거나 링크를 복사해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (old, next) {
      if (old?.value?.userId != next.value?.userId) {
        setState(() {
          link = null;
          message = null;
        });
      }
    });
    final auth = ref.watch(authStateProvider),
        invite = ref.watch(inviteControllerProvider);
    final school = ref.watch(schoolSelectionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('친구 초대')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LearningCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('친구와 공부시간을 기록하고 우리 학교 순위에 참여해 보세요.'),
                  if (auth.isLoading)
                    const LinearProgressIndicator()
                  else if (auth.hasError)
                    const Text('로그인 상태를 확인하지 못했어요.')
                  else if (auth.value?.isAuthenticated != true)
                    TextButton(
                      onPressed: () => context.push('/auth'),
                      child: const Text('로그인하고 초대하기'),
                    )
                  else ...[
                    if (!school.isLoading &&
                        !school.hasError &&
                        school.value == null) ...[
                      const Text(
                        '학교를 등록하지 않아도 친구를 초대할 수 있어요. 학교 순위에 참여하려면 학교를 등록해 주세요.',
                      ),
                      TextButton(
                        onPressed: () => context.push('/my/school'),
                        child: const Text('학교 등록하기'),
                      ),
                    ],
                    FilledButton(
                      onPressed: busy ? null : generate,
                      child: Text(link == null ? '초대 링크 만들기' : '초대 링크 새로 만들기'),
                    ),
                    if (link != null) ...[
                      SelectableText(link!.url),
                      Text(
                        '만료: ${link!.expires.toUtc().add(const Duration(hours: 9)).toIso8601String().substring(0, 16).replaceFirst('T', ' ')} KST',
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          OutlinedButton(
                            onPressed: busy ? null : () => send(false),
                            child: const Text('링크 복사'),
                          ),
                          FilledButton(
                            onPressed: busy ? null : () => send(true),
                            child: const Text('친구에게 공유'),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (busy) const LinearProgressIndicator(),
                  if (message != null)
                    Semantics(liveRegion: true, child: Text(message!)),
                ],
              ),
            ),
            const LearningSectionHeader('받은 초대 확인'),
            LearningCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('친구에게 받은 레전드스터디 초대 링크를 입력해 주세요.'),
                  TextField(
                    controller: input,
                    decoration: const InputDecoration(labelText: '초대 링크'),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                  ),
                  OutlinedButton(
                    onPressed: invite.busy
                        ? null
                        : () {
                            final uri = Uri.tryParse(input.text.trim());
                            if (uri != null) unawaited(invite.receive(uri));
                          },
                    child: const Text('초대 확인'),
                  ),
                  if (invite.message != null)
                    Semantics(liveRegion: true, child: Text(invite.message!)),
                  if (invite.token != null)
                    TextButton(
                      onPressed: invite.busy ? null : invite.retry,
                      child: const Text('초대 연결 다시 확인'),
                    ),
                  if (invite.needsSchoolConfirmation) ...[
                    const Text('내 학교 설정을 확인해 주세요. 친구의 학교로 자동 변경하지 않아요.'),
                    TextButton(
                      onPressed: () => context.push('/my/school'),
                      child: const Text('내 학교 설정 보기'),
                    ),
                    if (!school.isLoading &&
                        !school.hasError &&
                        school.value != null)
                      OutlinedButton(
                        onPressed: invite.markSchoolConfirmed,
                        child: Text('${school.value!.name} · 내 학교 확인'),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
