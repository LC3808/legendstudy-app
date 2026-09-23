import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/shell_widgets.dart';
import '../../shared/widgets/legendstudy_lab_entry.dart';

class LabPage extends StatelessWidget {
  const LabPage({super.key});
  @override
  Widget build(BuildContext context) => ShellPage(
    children: [
      const AppHeader(title: 'LAB'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('내신 분석'),
        subtitle: const Text('내신 성적 입력과 분석은 아직 지원하지 않아요.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/lab/school-scores'),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('모의고사 분석'),
        subtitle: const Text('확인한 채점 결과와 등급 기준'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/lab/scores'),
      ),
      const Divider(),
      const SectionHeader('논술 준비'),
      const LegendStudyLabEntry(),
    ],
  );
}
