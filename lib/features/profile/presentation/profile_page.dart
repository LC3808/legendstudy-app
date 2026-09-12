import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => PlaceholderPage(
    title: '나의 학습 공간',
    description: '프로필과 학습 기록 기능을 준비하고 있어요. 공개 자료는 로그인 없이 둘러볼 수 있어요.',
    icon: Icons.person_outline,
  );
}
