import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: '다시 보고 싶은 자료를 한곳에',
    description: '자료 저장 기능을 준비하고 있어요. 나만의 학습 자료를 모아 보세요.',
    icon: Icons.bookmark_border,
  );
}
