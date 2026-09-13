import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../content_providers.dart';
import '../domain/content_item.dart';

final contentDetailProvider = FutureProvider.autoDispose
    .family<ContentItem?, String>(
      (ref, slug) =>
          ref.watch(contentRepositoryProvider).fetchContentBySlug(slug),
      retry: (_, _) => null,
    );

class ContentDetailPage extends ConsumerWidget {
  const ContentDetailPage({required this.slug, super.key});
  final String slug;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('자료 상세')),
    body: ShellPage(
      children: [
        ref
            .watch(contentDetailProvider(slug))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: '자료를 불러오지 못했어요.',
                onRetry: () => ref.invalidate(contentDetailProvider(slug)),
              ),
              data: (item) => item == null
                  ? const EmptyState('지금 볼 수 없는 자료예요.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeader(title: item.title),
                        if (item.summary != null) Text(item.summary!),
                        const SizedBox(height: 24),
                        const Text('자료 열람 화면을 곧 만나요.'),
                      ],
                    ),
            ),
      ],
    ),
  );
}
