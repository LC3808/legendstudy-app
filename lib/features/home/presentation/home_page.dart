import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/placeholder_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: '오늘의 공부, 여기서 시작해요',
    description: '필요한 학습 자료를 쉽게 찾을 수 있도록 준비하고 있어요.',
    icon: Icons.auto_stories_outlined,
    action: FilledButton(
      onPressed: () => context.go('/browse'),
      child: const Text('자료 둘러보기'),
    ),
  );
}
