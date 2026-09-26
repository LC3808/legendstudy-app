import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../day_event_providers.dart';
import '../day_target_providers.dart' show dayTargetClockProvider;
import '../domain/day_event.dart';
import '../domain/day_target.dart' show koreanCalendarDay;

/// Home representative D-Day card plus a compact list of upcoming events.
/// The representative (user-chosen primary, else nearest upcoming) keeps the
/// existing big-card hierarchy: `title · date(요일)` + 설정, then a large D-N.
class DayTargetCard extends ConsumerWidget {
  const DayTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dayEventsProvider);
    final auth = ref.watch(authStateProvider);
    final now = ref.watch(dayTargetClockProvider).value ?? DateTime.now();
    final events = state.isLoading || state.hasError ? const <DayEvent>[] : state.value!;
    final rep = representativeEvent(events, now);
    final ready = !state.isLoading && !state.hasError && !auth.isLoading && !auth.hasError;

    return DailyUtilityCard(
      title: rep?.label ?? 'D-DAY',
      icon: Icons.event_outlined,
      accentColor: AppTokens.primary,
      heading: rep == null
          ? null
          : Text(
              '${rep.label} · ${rep.displayDate}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.secondary,
            ),
      action: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: ready
            ? () => _openManageSheet(context, ref, now)
            : null,
        child: const Text('설정'),
      ),
      body: state.isLoading
          ? const Text('일정을 불러오는 중이에요.')
          : state.hasError
          ? TextButton(
              onPressed: () => ref.invalidate(dayEventsProvider),
              child: const Text('일정을 불러오지 못했어요. 다시 시도'),
            )
          : rep == null
          ? const Text('목표 날짜를 설정해 주세요.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RepHeading(target: rep, now: now),
                _CompactEvents(
                  events: compactUpcoming(events, now, rep),
                  now: now,
                ),
              ],
            ),
    );
  }
}

Future<void> _openManageSheet(BuildContext context, WidgetRef ref, DateTime now) {
  final owner = ref.read(authStateProvider).value?.userId;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ManageEventsSheet(now: now, authenticated: owner != null),
  );
}

class _RepHeading extends StatelessWidget {
  const _RepHeading({required this.target, required this.now});
  final DayEvent target;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final expired = target.daysFrom(now) < 0;
    return Text(
      target.dLabel(now),
      style: expired
          ? AppTokens.secondary
          : AppTokens.hero.copyWith(color: AppTokens.primaryInk),
    );
  }
}

/// Up to two upcoming non-representative events, one line each, with an
/// expand/collapse toggle when more exist. Local UI state only.
class _CompactEvents extends StatefulWidget {
  const _CompactEvents({required this.events, required this.now});
  final List<DayEvent> events;
  final DateTime now;

  @override
  State<_CompactEvents> createState() => _CompactEventsState();
}

class _CompactEventsState extends State<_CompactEvents> {
  static const _collapsedCount = 2;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();
    final hidden = widget.events.length - _collapsedCount;
    final visible =
        _expanded ? widget.events : widget.events.take(_collapsedCount).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in visible) _CompactRow(event: e, now: widget.now),
          if (hidden > 0)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? '접기 ˄' : '일정 $hidden개 더보기 ˅'),
            ),
        ],
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.event, required this.now});
  final DayEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${event.label} · ${event.displayDate}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event.dLabel(now),
            style: AppTokens.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTokens.primaryInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// Manage sheet: list every saved event, choose the representative (radio),
/// add / edit / delete. Confirmed writes only; a failure keeps the sheet open.
class _ManageEventsSheet extends ConsumerStatefulWidget {
  const _ManageEventsSheet({required this.now, required this.authenticated});
  final DateTime now;
  final bool authenticated;

  @override
  ConsumerState<_ManageEventsSheet> createState() => _ManageEventsSheetState();
}

class _ManageEventsSheetState extends ConsumerState<_ManageEventsSheet> {
  bool _busy = false;

  Future<void> _guard(Future<bool> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await op();
      if (!mounted) return;
      if (!ok) _notify('로그인 상태가 변경됐어요. 다시 시도해 주세요.');
    } catch (_) {
      if (mounted) _notify('저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dayEventsProvider);
    final controller = ref.read(dayEventsProvider.notifier);
    final events = state.value ?? const <DayEvent>[];
    final sorted = [...events]..sort(compareEvents);
    final primaryId = () {
      for (final e in sorted) {
        if (e.isPrimary) return e.id;
      }
      return null;
    }();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
              child: Text('D-Day 관리', style: AppTokens.body.copyWith(
                fontWeight: FontWeight.w700,
              )),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: RadioGroup<String>(
                  groupValue: primaryId ?? '',
                  onChanged: (id) {
                    if (!_busy && id != null && id.isNotEmpty) {
                      _guard(() => controller.setPrimary(id));
                    }
                  },
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sorted.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('아직 저장된 일정이 없어요.'),
                      ),
                    for (final e in sorted)
                      _EventManageRow(
                        event: e,
                        now: widget.now,
                        enabled: !_busy,
                        onEdit: () async {
                          final result = await _showForm(context, e);
                          if (result != null) {
                            await _guard(() => controller.editEvent(
                                e.id!, result.$1, result.$2));
                          }
                        },
                        onDelete: () async {
                          if (await _confirmDelete(context, e)) {
                            await _guard(() => controller.deleteEvent(e.id!));
                          }
                        },
                      ),
                  ],
                ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      widget.authenticated ? '내 계정에 저장돼요.' : '앱을 종료하면 초기화돼요.',
                      style: AppTokens.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            final result = await _showForm(context, null);
                            if (result != null) {
                              await _guard(() => controller.addEvent(
                                    result.$1,
                                    result.$2,
                                    primary: sorted.isEmpty,
                                  ));
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('일정 추가'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<(DateTime, String)?> _showForm(BuildContext context, DayEvent? initial) {
    return showDialog<(DateTime, String)>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventFormDialog(initial: initial, now: widget.now),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, DayEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text("'${e.label}' 일정을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _EventManageRow extends StatelessWidget {
  const _EventManageRow({
    required this.event,
    required this.now,
    required this.enabled,
    required this.onEdit,
    required this.onDelete,
  });
  final DayEvent event;
  final DateTime now;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Primary selection is a radio: at most one representative at a time.
        // The enclosing RadioGroup owns the group value and change handling.
        Radio<String>(value: event.id ?? '', enabled: enabled),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.label, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(
                '${event.displayDate} · ${event.dLabel(now)}',
                style: AppTokens.caption,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: enabled ? onEdit : null,
          icon: const Icon(Icons.edit_outlined),
          tooltip: '수정',
        ),
        IconButton(
          onPressed: enabled ? onDelete : null,
          icon: const Icon(Icons.delete_outline),
          tooltip: '삭제',
        ),
      ],
    );
  }
}

/// Reused add/edit form: name + date picker. Returns (date, label) or null.
class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({required this.initial, required this.now});
  final DayEvent? initial;
  final DateTime now;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label =
      TextEditingController(text: widget.initial?.label);
  late DateTime _date =
      widget.initial?.date ?? koreanCalendarDay(widget.now);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = koreanCalendarDay(widget.now);
    return AlertDialog(
      title: Text(widget.initial == null ? '일정 추가' : '일정 수정'),
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
                child: Text('날짜: ${formatEventDate(_date)}'),
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
        TextButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (_date, _label.text));
            }
          },
          child: const Text('적용'),
        ),
      ],
    );
  }
}
