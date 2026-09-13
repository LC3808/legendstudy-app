import 'package:flutter/material.dart';
import '../../../shared/widgets/shell_widgets.dart';

class StudyPage extends StatelessWidget {
  const StudyPage({super.key});
  @override
  Widget build(BuildContext context) => ShellPage(
    children: [
      AppHeader(title: '학습', subtitle: '한 번의 집중이 쌓이는 공간'),
      CompactUtilityCard(title: '오늘 공부시간', body: '오늘 공부 기록이 아직 없어요.'),
      SectionHeader('공부 타이머'),
      Semantics(
        label: '공부 타이머, 대기 상태, 0시간 0분 0초',
        excludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '00:00:00',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      FilledButton(onPressed: null, child: Text('공부 시작')),
      SizedBox(height: 12),
      Text('공부 타이머를 곧 만나요. 기록 저장은 로그인 후 이용할 수 있어요.'),
      SectionHeader('최근 7일'),
      EmptyState('공부 기록이 쌓이면 일주일의 흐름을 볼 수 있어요.'),
    ],
  );
}
