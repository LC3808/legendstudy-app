import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/content_item.dart';
import '../../../shared/widgets/shell_widgets.dart';
import 'content_card.dart';
import '../../exams/exam_providers.dart';

class ContentResults extends StatelessWidget {
  const ContentResults({
    required this.state,
    required this.onRetry,
    this.emptyMessage = '아직 등록된 자료가 없어요.',
    this.maxItems,
    super.key,
  });
  final AsyncValue<List<ContentItem>> state;
  final VoidCallback onRetry;
  final String emptyMessage;
  final int? maxItems;
  @override
  Widget build(BuildContext context) => state.when(
    skipLoadingOnRefresh: false,
    loading: () => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (error, _) => ErrorState(
      message: error is BackendUnavailable
          ? error.message
          : error is FormatException
          ? error.message
          : '자료를 불러오지 못했어요. 다시 시도해 주세요.',
      onRetry: onRetry,
    ),
    data: (items) {
      final visible = maxItems == null ? items : items.take(maxItems!).toList();
      return visible.isEmpty ? EmptyState(emptyMessage) : _ContentList(visible);
    },
  );
}

class _ContentList extends ConsumerWidget {
  const _ContentList(this.items);
  final List<ContentItem> items;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = items
        .where((item) => item.contentType == 'exam')
        .map((item) => item.id)
        .join(',');
    final state = ids.isEmpty ? null : ref.watch(examMetadataProvider(ids));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state?.isLoading ?? false)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: CircularProgressIndicator(semanticsLabel: '시험 정보 불러오는 중'),
            ),
          ),
        if (state?.hasError ?? false)
          ErrorState(
            message: '시험 정보를 불러오지 못했어요.',
            onRetry: () => ref.invalidate(examMetadataProvider(ids)),
          ),
        for (final item in items)
          ContentCard(item, exam: state?.asData?.value[item.id]),
      ],
    );
  }
}
