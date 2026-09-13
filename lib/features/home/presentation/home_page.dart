import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/placeholder_page.dart';
import '../../content/content_providers.dart';
import '../../content/presentation/content_results.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PlaceholderPage(
    title: '오늘의 공부, 여기서 시작해요',
    description: '최근 업데이트된 학습 자료를 확인해 보세요.',
    icon: Icons.auto_stories_outlined,
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentResults(
          state: ref.watch(recentContentProvider),
          onRetry: () => ref.invalidate(recentContentProvider),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go('/browse'),
          child: const Text('자료 둘러보기'),
        ),
      ],
    ),
  );
}
