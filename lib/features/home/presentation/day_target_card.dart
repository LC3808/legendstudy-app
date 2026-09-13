import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../day_target_providers.dart';
import '../domain/day_target.dart';

class DayTargetCard extends ConsumerWidget {
  const DayTargetCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(dayTargetProvider);
    final now = ref.watch(dayTargetClockProvider).value ?? DateTime.now();
    return DailyUtilityCard(
      title: target?.label ?? 'D-DAY',
      action: TextButton(
        onPressed: () async {
          final owner = ref.read(authStateProvider).value?.userId;
          final selection = await showDialog<_TargetSelection>(
            context: context,
            builder: (_) => _TargetDialog(initial: target, now: now),
          );
          if (!context.mounted || selection == null) return;
          if (ref.read(authStateProvider).value?.userId != owner) return;
          ref.read(dayTargetProvider.notifier).setTarget(selection.target);
        },
        child: const Text('설정'),
      ),
      body: Text(target?.description(now) ?? '목표 날짜를 설정해 주세요.'),
    );
  }
}

class _TargetSelection {
  const _TargetSelection(this.target);
  final DayTarget? target;
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({this.initial, required this.now});
  final DayTarget? initial;
  final DateTime now;
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.label,
  );
  late DateTime _date = widget.initial?.date ?? koreanCalendarDay(widget.now);
  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('D-Day 설정'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _label,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: '이름 / 메모',
                hintText: '예: 수능, 중간고사',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '이름을 입력해 주세요.'
                  : value.trim().runes.length > 80
                  ? '80자 이내로 입력해 주세요.'
                  : null,
            ),
            TextButton(
              onPressed: () async {
                final today = koreanCalendarDay(widget.now);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date.isBefore(today) ? today : _date,
                  firstDate: today,
                  lastDate: DateTime(today.year + 20, 12, 31),
                );
                if (picked != null && mounted) setState(() => _date = picked);
              },
              child: Text(
                '날짜: ${_date.year}.${_date.month.toString().padLeft(2, '0')}.${_date.day.toString().padLeft(2, '0')}',
              ),
            ),
            const Text('앱을 종료하면 초기화돼요. 계정에는 저장되지 않아요.'),
          ],
        ),
      ),
    ),
    actions: [
      if (widget.initial != null)
        TextButton(
          onPressed: () => Navigator.pop(context, const _TargetSelection(null)),
          child: const Text('해제'),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      TextButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(
              context,
              _TargetSelection(DayTarget(date: _date, label: _label.text)),
            );
          }
        },
        child: const Text('적용'),
      ),
    ],
  );
}
