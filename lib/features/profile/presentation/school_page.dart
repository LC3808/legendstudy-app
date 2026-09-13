import 'package:flutter/material.dart';
import '../../../shared/widgets/shell_widgets.dart';

class SchoolPage extends StatelessWidget {
  const SchoolPage({super.key});
  @override
  Widget build(BuildContext context) => const ShellPage(
    children: [
      AppHeader(title: '우리 학교 찾기'),
      EmptyState('학교를 설정하면 오늘 급식을 볼 수 있어요.'),
      Text('학교 검색은 곧 이용할 수 있어요. 선택한 학교의 저장은 로그인 후 가능해요.'),
    ],
  );
}
