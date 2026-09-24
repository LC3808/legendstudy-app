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
      LsCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.school_outlined),
          title: const Text('내신 분석'),
          subtitle: const Text('내신 성적 입력과 분석은 아직 지원하지 않아요.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/lab/school-scores'),
        ),
      ),
      const SizedBox(height: 12),
      LsCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.assessment_outlined),
          title: const Text('모의고사 분석'),
          subtitle: const Text('확인한 채점 결과와 등급 기준'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/lab/scores'),
        ),
      ),
      const SizedBox(height: 12),
      const LegendStudyLabEntry(),
    ],
  );
}
