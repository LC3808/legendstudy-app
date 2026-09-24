import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../day_target_providers.dart';
import '../domain/day_target.dart';

class DayTargetCard extends ConsumerWidget {
  const DayTargetCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dayTargetProvider);
    final auth = ref.watch(authStateProvider);
    final target = state.isLoading || state.hasError ? null : state.value;
    final now = ref.watch(dayTargetClockProvider).value ?? DateTime.now();
    return DailyUtilityCard(
      title: target?.label ?? 'D-DAY',
      icon: Icons.event_outlined,
      accentColor: AppTokens.primaryInk,
      heading: target == null ? null : _TargetHeading(target: target, now: now),
      action: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed:
            state.isLoading || state.hasError || auth.isLoading || auth.hasError
            ? null
            : () async {
                final owner = ref.read(authStateProvider).value?.userId;
                final controller = ref.read(dayTargetProvider.notifier);
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => _TargetDialog(
                    initial: target,
                    now: now,
                    authenticated: owner != null,
                    onSubmit: (value) async {
                      if (!context.mounted ||
                          ref.read(authStateProvider).value?.userId != owner) {
                        return false;
                      }
                      return controller.setTarget(value);
                    },
                  ),
                );
              },
        child: const Text('설정'),
      ),
      body: state.isLoading
          ? const Text('일정을 불러오는 중이에요.')
          : state.hasError
          ? TextButton(
              onPressed: () => ref.invalidate(dayTargetProvider),
              child: const Text('일정을 불러오지 못했어요. 다시 시도'),
            )
          : Text(
              target?.formattedDate ?? '목표 날짜를 설정해 주세요.',
              style: target == null
                  ? null
                  : Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTokens.textSecondary),
            ),
    );
  }
}

class _TargetHeading extends StatelessWidget {
  const _TargetHeading({required this.target, required this.now});
  final DayTarget target;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = target.daysFrom(now);
    final expired = days < 0;
    final label = expired
        ? '지난 일정'
        : days == 0
        ? 'D-DAY'
        : 'D-$days';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          target.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTokens.cardTitle,
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          label,
          style: expired
              ? AppTokens.secondary
              : AppTokens.hero.copyWith(color: AppTokens.primaryInk),
        ),
      ],
    );
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({
    this.initial,
    required this.now,
    required this.authenticated,
    required this.onSubmit,
  });
  final bool authenticated;
  final Future<bool> Function(DayTarget?) onSubmit;
  final DayTarget? initial;
  final DateTime now;
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _failure;
  Future<void> _submit(DayTarget? target) async {
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      final accepted = await widget.onSubmit(target);
      if (!mounted) return;
      if (accepted) {
        Navigator.pop(context);
      } else {
        setState(() => _failure = '로그인 상태가 변경됐어요. 닫고 다시 시도해 주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => _failure = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
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
                enabled: !_saving,
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
                onPressed: _saving
                    ? null
                    : () async {
                        final today = koreanCalendarDay(widget.now);
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date.isBefore(today) ? today : _date,
                          firstDate: today,
                          lastDate: DateTime(today.year + 20, 12, 31),
                        );
                        if (picked != null && mounted) {
                          setState(() => _date = picked);
                        }
                      },
                child: Text(
                  '날짜: ${_date.year}.${_date.month.toString().padLeft(2, '0')}.${_date.day.toString().padLeft(2, '0')}',
                ),
              ),
              Text(
                widget.authenticated
                    ? '내 계정에 저장돼요.'
                    : '앱을 종료하면 초기화돼요. 계정에는 저장되지 않아요.',
              ),
              if (_failure != null) Text(_failure!, semanticsLabel: _failure),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: _saving ? null : () => _submit(null),
            child: const Text('해제'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  if (_form.currentState!.validate()) {
                    _submit(DayTarget(date: _date, label: _label.text));
                  }
                },
          child: const Text('적용'),
        ),
      ],
    ),
  );
}
