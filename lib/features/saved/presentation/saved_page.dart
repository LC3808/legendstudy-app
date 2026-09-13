import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: '다시 보고 싶은 자료를 한곳에',
    description: '로그인하면 저장한 자료를 한곳에서 모아 볼 수 있어요.',
    icon: Icons.bookmark_border,
  );
}
