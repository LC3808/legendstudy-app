import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/content_item.dart';

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
      child: CircularProgressIndicator(),
    ),
    error: (error, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          error is BackendUnavailable
              ? error.message
              : error is FormatException
              ? error.message
              : '자료를 불러오지 못했어요. 다시 시도해 주세요.',
        ),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
    data: (items) => items.isEmpty
        ? Text(emptyMessage)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (item.summary != null) Text(item.summary!),
                    ],
                  ),
                ),
            ],
          ),
  );
}
