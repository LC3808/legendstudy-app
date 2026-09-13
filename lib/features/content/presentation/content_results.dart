import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/content_item.dart';
import '../../../shared/widgets/shell_widgets.dart';
import 'content_card.dart';

class ContentResults extends StatelessWidget {
  const ContentResults({
    required this.state,
    required this.onRetry,
    this.emptyMessage = '아직 등록된 자료가 없어요.',
    super.key,
  });
  final AsyncValue<List<ContentItem>> state;
  final VoidCallback onRetry;
  final String emptyMessage;
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
    data: (items) => items.isEmpty
        ? EmptyState(emptyMessage)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final item in items) ContentCard(item)],
          ),
  );
}
