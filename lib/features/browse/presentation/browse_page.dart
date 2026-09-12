import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class BrowsePage extends StatelessWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: '나에게 필요한 학습 자료',
    description: '학년과 과목별 자료 찾기와 검색 기능을 준비하고 있어요.',
    icon: Icons.search,
  );
}
