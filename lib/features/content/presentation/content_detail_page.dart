import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/links/external_link.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../exams/exam_providers.dart';
import '../../exams/presentation/exam_labels.dart';
import '../../resources/domain/content_resource.dart';
import '../../resources/presentation/resource_section.dart';
import '../../personal/bookmark_providers.dart';
import '../../personal/personal_providers.dart';
import '../../personal/domain/recent_view_tracking.dart';
import '../content_providers.dart';
import '../domain/content_item.dart';
import 'content_type_badge.dart';

final contentDetailProvider = FutureProvider.autoDispose
    .family<ContentItem?, String>(
      (ref, slug) =>
          ref.watch(contentRepositoryProvider).fetchContentBySlug(slug),
      retry: (_, _) => null,
    );

class ContentDetailPage extends ConsumerStatefulWidget {
  const ContentDetailPage({required this.slug, super.key});
  final String slug;
  @override
  ConsumerState<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends ConsumerState<ContentDetailPage>
    with WidgetsBindingObserver {
  String? _recentOwner;
  String? _recentContentId;
  ForegroundRecentViewTracker? _recentTracker;
  Timer? _recentTimer;
  bool _recentFailureShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(contentDetailProvider(widget.slug), (_, next) {
      final item = next.asData?.value;
      if (item != null) _startRecent(item.id);
    });
    ref.listenManual(authStateProvider, (_, _) {
      final item = ref.read(contentDetailProvider(widget.slug)).asData?.value;
      if (item != null) _startRecent(item.id);
    });
  }

  @override
  void dispose() {
    _recentTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final tracker = _recentTracker;
    if (tracker == null) return;
    tracker.lifecycle(state, DateTime.now());
    if (state == AppLifecycleState.resumed) {
      _scheduleRecentCheck();
    } else {
      _recentTimer?.cancel();
    }
  }

  void _startRecent(String contentItemId) {
    final owner = ref.read(authStateProvider).value?.userId;
    if (owner == null) return;
    if (_recentOwner == owner && _recentContentId == contentItemId) return;
    _recentOwner = owner;
    _recentContentId = contentItemId;
    _recentTracker = ForegroundRecentViewTracker()..start(DateTime.now());
    _scheduleRecentCheck();
  }

  void _scheduleRecentCheck() {
    _recentTimer?.cancel();
    final tracker = _recentTracker;
    if (tracker == null || tracker.qualified) return;
    final remaining = meaningfulRecentViewThreshold - tracker.foregroundDwell;
    _recentTimer = Timer(
      remaining.isNegative || remaining == Duration.zero
          ? const Duration(milliseconds: 1)
          : remaining,
      () {
        if (!mounted || _recentTracker == null) return;
        if (_recentTracker!.thresholdReached()) {
          _recordQualifiedRecent();
        } else {
          _scheduleRecentCheck();
        }
      },
    );
  }

  void _markMeaningfulRecent() {
    final tracker = _recentTracker;
    if (tracker != null && tracker.markMeaningful(DateTime.now())) {
      _recordQualifiedRecent();
    }
  }

  void _recordQualifiedRecent() {
    final contentId = _recentContentId;
    final owner = _recentOwner;
    if (contentId == null || owner == null || _recentTracker == null) return;
    if (ref.read(authStateProvider).value?.userId != owner) return;
    _recentTimer?.cancel();
    _recentTracker = null;
    _recordRecent(contentId, owner);
  }

  Future<void> _recordRecent(String contentItemId, String owner) async {
    try {
      await ref
          .read(recentViewRepositoryProvider)
          .touchRecentView(contentItemId);
    } catch (_) {
      if (mounted && !_recentFailureShown) {
        _recentFailureShown = true;
        // A recent view is auxiliary; never replace the resolved detail.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('최근 본 자료를 기록하지 못했어요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(
        onPressed: () {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            router.go('/materials');
          }
        },
      ),
    ),
    body: ShellPage(
      children: [
        ref
            .watch(contentDetailProvider(widget.slug))
            .when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: '자료를 불러오지 못했어요.',
                onRetry: () =>
                    ref.invalidate(contentDetailProvider(widget.slug)),
              ),
              data: (item) => item == null
                  ? const EmptyState('자료를 찾을 수 없어요.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ContentTypeBadge(item.contentType)),
                            _BookmarkControl(
                              contentItemId: item.id,
                              onMeaningfulAction: _markMeaningfulRecent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          header: true,
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (item.contentType == 'exam') _ExamDetails(item.id),
                        if (item.summary?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 16),
                          Text(item.summary!),
                        ],
                        const SizedBox(height: 16),
                        if (item.publishedAt != null)
                          Text('게시 ${formatDate(item.publishedAt!)}'),
                        if (item.sourceUpdatedAt != null)
                          Text('원문 수정 ${formatDate(item.sourceUpdatedAt!)}'),
                        if (publicWebUri(item.sourceUrl) != null)
                          Text('출처 ${publicWebUri(item.sourceUrl)!.host}'),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ExternalLinkButton(
                            uri: publicWebUri(item.sourceUrl),
                            label: '원문 보기',
                            onOpenAttempted: _markMeaningfulRecent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResourceSection(
                          contentItemId: item.id,
                          contentSourceUrl: item.sourceUrl,
                          isArticle: [
                            'education_column',
                            'admissions_info',
                          ].contains(item.contentType),
                          onMeaningfulAction: _markMeaningfulRecent,
                        ),
                      ],
                    ),
            ),
      ],
    ),
  );
}

class _BookmarkControl extends ConsumerWidget {
  const _BookmarkControl({
    required this.contentItemId,
    this.onMeaningfulAction,
  });
  final String contentItemId;
  final VoidCallback? onMeaningfulAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (auth.hasError) return const SizedBox.shrink();
    final authenticated = auth.value?.isAuthenticated == true;
    final state = ref.watch(bookmarkStateProvider(contentItemId));
    final controller = ref.read(bookmarkStateProvider(contentItemId).notifier);
    final busy = state.isMutating || state.phase == BookmarkPhase.loading;
    return Semantics(
      button: true,
      label: authenticated
          ? (state.isSaved ? '저장됨' : '자료 저장')
          : '자료 저장, 로그인 필요',
      child: SizedBox(
        height: 48,
        child: TextButton.icon(
          onPressed: busy
              ? null
              : () async {
                  if (!authenticated) {
                    await context.push('/auth');
                    // Return to this detail; never replay a save across account changes.
                    return;
                  }
                  final owner = auth.value?.userId;
                  final before = state;
                  final wasSaved = state.isSaved;
                  await controller.toggle();
                  if (context.mounted &&
                      ref.read(authStateProvider).value?.userId == owner &&
                      before.phase != BookmarkPhase.mutating) {
                    final after = ref.read(
                      bookmarkStateProvider(contentItemId),
                    );
                    if (!wasSaved && after.phase == BookmarkPhase.saved) {
                      onMeaningfulAction?.call();
                    }
                    if (after.message != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(after.message!)));
                    }
                  }
                },
          icon: Icon(state.isSaved ? Icons.bookmark : Icons.bookmark_border),
          label: Text(state.isSaved ? '저장됨' : '저장'),
        ),
      ),
    );
  }
}

class _ExamDetails extends ConsumerWidget {
  const _ExamDetails(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(examMetadataProvider(id))
      .when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: '시험 정보 불러오는 중'),
        ),
        error: (_, _) => ErrorState(
          message: '시험 정보를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(examMetadataProvider(id)),
        ),
        data: (rows) {
          final exam = rows[id];
          final lines = exam == null ? <String>[] : examDetails(exam);
          return lines.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final line in lines) Text(line)],
                  ),
                );
        },
      );
}
