import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../domain/feedback_models.dart';
import '../feedback_providers.dart';

class AdminFeedbackPage extends ConsumerStatefulWidget {
  const AdminFeedbackPage({super.key});

  @override
  ConsumerState<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends ConsumerState<AdminFeedbackPage> {
  FeedbackStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final admin = ref.watch(adminAccessProvider);
    if (auth.isLoading || admin.isLoading) {
      return const ShellPage(
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    if (auth.hasError || admin.hasError) {
      return ShellPage(
        children: [
          ErrorState(
            message: '관리자 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(adminAccessProvider),
          ),
        ],
      );
    }
    final currentUserId = auth.value?.userId;
    final access = admin.value;
    if (currentUserId == null || access?.userId != currentUserId || access?.isAdmin != true) {
      return const ShellPage(
        children: [
          SectionHeader('문의 관리'),
          EmptyState('관리자만 이용할 수 있어요.'),
        ],
      );
    }
    final state = ref.watch(adminFeedbackListProvider(_filter));
    return ShellPage(
      children: [
        const AppHeader(title: '문의 관리', subtitle: '최신 문의부터 확인하고 상태를 관리해요.'),
        _FilterBar(
          selected: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 8),
        state.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error is BackendUnavailable
                ? error.message
                : '문의 목록을 불러오지 못했어요.',
            onRetry: () => ref.invalidate(adminFeedbackListProvider(_filter)),
          ),
          data: (items) => items.isEmpty
              ? const EmptyState('접수된 문의가 없습니다.')
              : Column(
                  children: [
                    for (final item in items)
                      _FeedbackListTile(
                        item: item,
                        onTap: () async {
                          await context.push('/my/admin/feedback/${item.id}');
                          if (mounted) {
                            ref.invalidate(adminFeedbackListProvider(_filter));
                          }
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final FeedbackStatus? selected;
  final ValueChanged<FeedbackStatus?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      FilterChip(
        label: const Text('전체'),
        selected: selected == null,
        onSelected: (_) => onChanged(null),
      ),
      for (final status in FeedbackStatus.values)
        FilterChip(
          label: Text(status.label),
          selected: selected == status,
          onSelected: (_) => onChanged(status),
        ),
    ],
  );
}

class _FeedbackListTile extends StatelessWidget {
  const _FeedbackListTile({required this.item, required this.onTap});
  final FeedbackSubmission item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      title: Row(
        children: [
          _StatusChip(item.status),
          const SizedBox(width: 8),
          Text(item.category.label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${item.title}\n${_formatDate(item.createdAt)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.label),
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
  );
}

class AdminFeedbackDetailPage extends ConsumerStatefulWidget {
  const AdminFeedbackDetailPage({required this.id, super.key});
  final String id;

  @override
  ConsumerState<AdminFeedbackDetailPage> createState() =>
      _AdminFeedbackDetailPageState();
}

class _AdminFeedbackDetailPageState
    extends ConsumerState<AdminFeedbackDetailPage> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final admin = ref.watch(adminAccessProvider);
    final state = ref.watch(adminFeedbackDetailProvider(widget.id));
    if (auth.isLoading || admin.isLoading || state.isLoading) {
      return const ShellPage(children: [Center(child: CircularProgressIndicator())]);
    }
    if (auth.value?.userId == null || admin.value?.userId != auth.value?.userId || admin.value?.isAdmin != true) {
      return const ShellPage(children: [EmptyState('관리자만 이용할 수 있어요.')]);
    }
    return ShellPage(
      children: [
        state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            message: error is BackendUnavailable
                ? error.message
                : '문의 내용을 불러오지 못했어요.',
            onRetry: () => ref.invalidate(adminFeedbackDetailProvider(widget.id)),
          ),
          data: (item) => _detail(context, item),
        ),
      ],
    );
  }

  Widget _detail(BuildContext context, FeedbackSubmission item) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          _StatusChip(item.status),
          const SizedBox(width: 8),
          Text(item.category.label),
        ],
      ),
      const SizedBox(height: 16),
      Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      SelectableText(item.body),
      const SizedBox(height: 20),
      _MetadataTable(item: item),
      const SizedBox(height: 20),
      if (item.status == FeedbackStatus.newStatus)
        _statusButton(item, FeedbackStatus.reviewing, '확인중으로 변경'),
      if (item.status == FeedbackStatus.reviewing)
        _statusButton(item, FeedbackStatus.resolved, '처리완료로 변경'),
    ],
  );

  Widget _statusButton(FeedbackSubmission item, FeedbackStatus next, String label) =>
      FilledButton(
        onPressed: _updating ? null : () => _updateStatus(item, next),
        child: _updating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );

  Future<void> _updateStatus(FeedbackSubmission item, FeedbackStatus next) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final updated = await ref
          .read(feedbackRepositoryProvider)
          .updateFeedbackStatus(item.id, next);
      if (!mounted) return;
      if (updated.status != next) throw StateError('status mismatch');
      ref.invalidate(adminFeedbackDetailProvider(widget.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의 상태를 변경하지 못했어요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _MetadataTable extends StatelessWidget {
  const _MetadataTable({required this.item});
  final FeedbackSubmission item;

  @override
  Widget build(BuildContext context) => Table(
    columnWidths: const {0: IntrinsicColumnWidth()},
    defaultVerticalAlignment: TableCellVerticalAlignment.top,
    children: [
      _row('접수 시각', _formatDate(item.createdAt)),
      _row('앱 버전', item.appVersion),
      _row('빌드 번호', item.buildNumber),
      _row('플랫폼', item.platform),
      _row('OS', item.osVersion),
      _row('locale', item.locale ?? '-'),
    ],
  );

  TableRow _row(String label, String value) => TableRow(
    children: [
      Padding(padding: const EdgeInsets.only(right: 16, bottom: 8), child: Text(label)),
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(value)),
    ],
  );
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
