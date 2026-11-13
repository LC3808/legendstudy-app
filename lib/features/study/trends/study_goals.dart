import 'package:flutter/material.dart';

import '../application/study_controller.dart';
import '../domain/study_models.dart';

class StudyGoals extends StatelessWidget {
  const StudyGoals({
    super.key,
    required this.study,
    required this.today,
    required this.week,
  });
  final StudyController study;
  final int today, week;
  @override
  Widget build(BuildContext context) {
    final goal = study.studyGoal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('공부시간 목표'),
        const Text('목표는 이 기기에 계정별로 저장돼요. 현재 목표를 이번 기간에 적용해요.'),
        for (final item in [
          ('일일', 'daily_minutes', today),
          ('주간', 'weekly_minutes', week),
        ])
          if ((goal?[item.$2] as int? ?? 0) > 0) ...[
            Text(
              '${item.$1} ${studyDuration(item.$3)} / ${studyDuration((goal![item.$2] as int) * 60000)} · ${(item.$3 / ((goal[item.$2] as int) * 60000) * 100).floor()}%',
            ),
            LinearProgressIndicator(
              value: (item.$3 / ((goal[item.$2] as int) * 60000)).clamp(0, 1),
            ),
          ] else
            Text('${item.$1} 목표 미설정'),
        TextButton(
          onPressed: () async {
            final epoch = study.viewGeneration;
            final value = await showDialog<(int, int)>(
              context: context,
              builder: (_) => _GoalDialog(
                daily: goal?['daily_minutes'] as int? ?? 0,
                weekly: goal?['weekly_minutes'] as int? ?? 0,
              ),
            );
            if (value == null ||
                !context.mounted ||
                study.viewGeneration != epoch) {
              return;
            }
            try {
              await study.setStudyGoals(value.$1, value.$2);
            } catch (_) {
              if (context.mounted && study.viewGeneration == epoch) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('목표를 저장하지 못했어요. 다시 시도해 주세요.')),
                );
              }
            }
          },
          child: const Text('목표 설정'),
        ),
      ],
    );
  }
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.daily, required this.weekly});
  final int daily, weekly;
  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final form = GlobalKey<FormState>();
  late int daily = widget.daily, weekly = widget.weekly;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('공부시간 목표'),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('분 단위로 입력해 주세요. 0은 목표 해제예요.'),
            for (final isDaily in [true, false])
              TextFormField(
                initialValue: '${isDaily ? widget.daily : widget.weekly}',
                decoration: InputDecoration(
                  labelText: isDaily ? '일일 목표 (분)' : '주간 목표 (분)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  final max = isDaily ? 1440 : 10080;
                  return n == null || n < 0 || n > max
                      ? '0~$max 사이 정수를 입력해 주세요.'
                      : null;
                },
                onSaved: (value) {
                  if (isDaily) {
                    daily = int.parse(value!);
                  } else {
                    weekly = int.parse(value!);
                  }
                },
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          form.currentState!.save();
          Navigator.pop(context, (daily, weekly));
        },
        child: const Text('저장'),
      ),
    ],
  );
}
