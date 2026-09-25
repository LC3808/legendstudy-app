import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/presentation/content_type_badge.dart';
import '../../content/presentation/material_display_title.dart';
import '../../exams/exam_providers.dart';
import '../personal_providers.dart';
import '../personal_list_providers.dart';

class PersonalMaterialListPage extends ConsumerWidget {
  const PersonalMaterialListPage({required this.kind, super.key});
  final PersonalListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return ShellPage(
      children: [
        const Text('저장한 자료는 북마크 목록이며 다운로드 파일이 아니에요.'),
        auth.when(
          loading: () =>
              const LinearProgressIndicator(semanticsLabel: '계정 상태 확인'),
          error: (_, _) => ErrorState(
            message: '계정 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(authStateProvider),
          ),
          data: (status) => status.isAuthenticated
              ? PersonalMaterialList(kind: kind)
              : Column(
                  children: [
                    const EmptyState('로그인하면 이 기능을 이용할 수 있어요.'),
                    FilledButton(
                      onPressed: () => context.push('/auth', extra: true),
                      child: const Text('로그인'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class PersonalMaterialList extends ConsumerStatefulWidget {
  const PersonalMaterialList({
    required this.kind,
    this.homeMode = false,
    super.key,
  });
  final PersonalListKind kind;
  final bool homeMode;

  @override
  ConsumerState<PersonalMaterialList> createState() =>
      _PersonalMaterialListState();
}

class _PersonalMaterialListState extends ConsumerState<PersonalMaterialList> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      // Keep the shell settleable while the auth stream has not emitted yet.
      return const Text('자료 목록을 불러오는 중…');
    }
    if (auth.hasError) {
      return ErrorState(
        message: '계정 상태를 확인하지 못했어요.',
        onRetry: () => ref.invalidate(authStateProvider),
      );
    }
    if (auth.value?.isAuthenticated != true) {
      return Column(
        children: [
          const EmptyState('로그인하면 이 기능을 이용할 수 있어요.'),
          FilledButton(
            onPressed: () => context.push('/auth', extra: true),
            child: const Text('로그인'),
          ),
        ],
      );
    }
    final state = widget.homeMode
        ? ref.watch(homeRecentMaterialListProvider)
        : ref.watch(personalMaterialListProvider(widget.kind));
    return state.when(
      skipLoadingOnRefresh: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: error is BackendUnavailable
            ? error.message
            : '자료 목록을 불러오지 못했어요. 다시 시도해 주세요.',
        onRetry: () => widget.homeMode
            ? ref.invalidate(homeRecentMaterialListProvider)
            : ref.invalidate(personalMaterialListProvider(widget.kind)),
      ),
      data: (items) => items.isEmpty
          ? Column(
              children: [
                EmptyState(
                  widget.kind == PersonalListKind.bookmarks
                      ? '저장한 자료가 아직 없어요.'
                      : '최근 본 자료가 아직 없어요.',
                ),
                TextButton(
                  onPressed: () => context.go('/materials'),
                  child: const Text('자료 찾기'),
                ),
              ],
            )
          : _list(context, items),
    );
  }

  Widget _list(BuildContext context, List<PersonalMaterial> items) {
    final visible = widget.homeMode
        ? items.take(expanded ? 6 : 2).toList()
        : items;
    final ids = visible
        .where((m) => m.item.contentType == 'exam')
        .map((m) => m.item.id)
        .join(',');
    final exams = ids.isEmpty
        ? null
        : ref.watch(examMetadataProvider(ids)).asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final material in visible)
          _PersonalMaterialCard(
            material: material,
            examType: exams?[material.item.id]?.examType,
            kind: widget.kind,
            homeMode: widget.homeMode,
            onDelete:
                !widget.homeMode && widget.kind == PersonalListKind.recentViews
                ? () => _deleteOne(material.item.id)
                : null,
          ),
        if (!widget.homeMode && widget.kind == PersonalListKind.recentViews)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _deleteAll(context),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('전체 삭제'),
            ),
          ),
        if (widget.homeMode && items.length > 2)
          _HomeExpandControl(
            expanded: expanded,
            onTap: () => setState(() => expanded = !expanded),
          ),
      ],
    );
  }

  Future<void> _deleteOne(String contentItemId) async {
    try {
      await ref
          .read(recentViewRepositoryProvider)
          .deleteRecentView(contentItemId);
      if (mounted) ref.invalidate(personalMaterialListProvider(widget.kind));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('최근 본 자료를 삭제하지 못했어요.')));
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최근 본 자료 기록을 모두 삭제할까요?'),
        content: const Text('삭제한 기록은 복구할 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(recentViewRepositoryProvider).deleteAllRecentViews();
      if (mounted) ref.invalidate(personalMaterialListProvider(widget.kind));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context)
          .showSnackBar(const SnackBar(content: Text('최근 본 자료를 삭제하지 못했어요.')));
    }
  }
}

class _PersonalMaterialCard extends ConsumerWidget {
  const _PersonalMaterialCard({
    required this.material,
    this.examType,
    required this.kind,
    this.onDelete,
    this.homeMode = false,
  });
  final PersonalMaterial material;
  final String? examType;
  final PersonalListKind kind;
  final bool homeMode;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = material.item;
    final displayTitle = materialDisplayTitle(item.title, item.contentType);
    final timestamp = material.entry.timestamp.toLocal();
    final label = kind == PersonalListKind.bookmarks ? '저장' : '최근 본';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        child: Semantics(
          button: true,
          label: '$displayTitle, $label 자료 열기',
          child: InkWell(
            onTap: () async {
              await context.push(
                '/materials/${Uri.encodeComponent(item.slug)}',
              );
              if (context.mounted) {
                if (homeMode) {
                  ref.invalidate(homeRecentMaterialListProvider);
                } else {
                  ref.invalidate(personalMaterialListProvider(kind));
                }
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContentTypeBadge(item.contentType, examType: examType),
                        const SizedBox(height: 2),
                        Text(
                          '$label ${timestamp.year}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: '최근 본 자료 삭제',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeExpandControl extends StatelessWidget {
  const _HomeExpandControl({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: expanded ? '최근 본 자료 접기' : '최근 본 자료 더보기',
    child: Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
        label: Text(expanded ? '접기' : '더보기'),
      ),
    ),
  );
}
