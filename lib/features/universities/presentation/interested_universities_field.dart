import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../application/university_providers.dart';
import '../domain/university_models.dart';

/// Reusable 관심 대학 editor (first-run onboarding + My Page). Interest, not
/// application. Search the catalog, select up to [maxInterested]; selected
/// universities rise into an emphasized foreground list and can be removed.
/// Selection state is never color-only (check icon + weight + border + label).
class InterestedUniversitiesField extends ConsumerStatefulWidget {
  const InterestedUniversitiesField({
    super.key,
    required this.source,
    this.onSearchPendingChanged,
  });
  final ValueChanged<bool>? onSearchPendingChanged;

  /// `'onboarding'` or `'my'` — recorded on each selection row.
  final String source;

  @override
  ConsumerState<InterestedUniversitiesField> createState() =>
      _InterestedUniversitiesFieldState();
}

class _InterestedUniversitiesFieldState
    extends ConsumerState<InterestedUniversitiesField> {
  final _input = TextEditingController();
  String _query = '';
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _input.text.trim();
    if (_busy || q.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (q != _query) setState(() => _query = q);
    widget.onSearchPendingChanged?.call(false);
  }

  Future<void> _add(University uni) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(interestedUniversitiesProvider.notifier)
          .add(uni.id, source: widget.source);
      _snack('관심 대학이 저장되었습니다.');
    } catch (_) {
      _snack('대학을 추가하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String rowId) async {
    if (_busy) return;
    final owner = ref.read(authStateProvider).value?.userId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('관심 대학을 삭제할까요?'),
        content: const Text('학교·현재 상태·학년 정보는 변경되지 않습니다.'),
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
    if (!mounted ||
        confirmed != true ||
        owner != ref.read(authStateProvider).value?.userId) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(interestedUniversitiesProvider.notifier).remove(rowId);
      _snack('관심 대학이 저장되었습니다.');
    } catch (_) {
      _snack('대학을 제거하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(InterestedUniversity row) async {
    if (_busy) return;
    final owner = ref.read(authStateProvider).value?.userId;
    final division = TextEditingController(text: row.intendedDivision ?? '');
    final priority = TextEditingController(
      text: row.priority?.toString() ?? '',
    );
    final key = GlobalKey<FormState>();
    final route = DialogRoute<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(row.name),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: division,
                maxLength: 100,
                decoration: const InputDecoration(labelText: '관심 학과 (선택)'),
              ),
              TextFormField(
                controller: priority,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '우선순위 (선택)',
                  helperText: '작은 숫자부터 표시됩니다.',
                ),
                validator: (v) =>
                    v == null ||
                        v.trim().isEmpty ||
                        (int.tryParse(v.trim()) != null &&
                            int.parse(v.trim()) >= 1 &&
                            int.parse(v.trim()) <= 32767)
                    ? null
                    : '1 이상 32767 이하의 숫자를 입력해 주세요.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    final accepted = await Navigator.of(context).push(route);
    final divisionValue = division.text;
    final priorityValue = int.tryParse(priority.text.trim());
    await route.completed;
    division.dispose();
    priority.dispose();
    if (!mounted ||
        accepted != true ||
        owner != ref.read(authStateProvider).value?.userId) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(interestedUniversitiesProvider.notifier)
          .edit(row.id, division: divisionValue, priority: priorityValue);
      _snack('관심 대학이 저장되었습니다.');
    } catch (_) {
      _snack('관심 대학을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final interested = ref.watch(interestedUniversitiesProvider);
    final selected = interested.asData?.value ?? const <InterestedUniversity>[];
    final atCap = selected.length >= maxInterested;
    final results = ref.watch(universitySearchProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '목표 대학은 최대 $maxInterested개 · $recommendedInterested개부터 시작해 보세요',
          style: AppTokens.caption.copyWith(color: AppTokens.textTertiary),
        ),
        const SizedBox(height: AppTokens.space8),
        if (interested.isLoading) const LinearProgressIndicator(),
        if (interested.hasError)
          ErrorState(
            message: '관심 대학을 불러오지 못했어요.',
            onRetry: () => ref.invalidate(interestedUniversitiesProvider),
          ),
        if (!interested.isLoading && !interested.hasError && selected.isEmpty)
          const EmptyState('첫 번째 목표 대학을 찾아보세요.')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final uni in selected)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space8),
                  child: _SelectedUniversityCard(
                    name: uni.displayLabel,
                    priority: uni.priority,
                    onEdit: _busy ? null : () => _edit(uni),
                    onRemove: _busy ? null : () => _remove(uni.id),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppTokens.space12),
        TextField(
          controller: _input,
          enabled:
              !_busy && !atCap && !interested.isLoading && !interested.hasError,
          maxLength: 60,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: atCap ? '최대 $maxInterested개까지 선택했어요' : '대학 이름을 검색해 주세요',
            suffixIcon: Padding(
              padding: const EdgeInsets.all(4),
              child: OutlinedButton(
                onPressed:
                    !_busy &&
                        !atCap &&
                        !interested.isLoading &&
                        !interested.hasError &&
                        _input.text.trim().isNotEmpty
                    ? _runSearch
                    : null,
                child: const Text('검색'),
              ),
            ),
            counterText: '',
          ),
          onChanged: (v) {
            setState(() {
              if (v.trim().isEmpty) _query = '';
            });
            widget.onSearchPendingChanged?.call(
              v.trim().isNotEmpty && v.trim() != _query,
            );
          },
          onSubmitted: (_) => _runSearch(),
        ),
        if (!atCap && _query.isNotEmpty)
          results.when(
            skipLoadingOnRefresh: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(AppTokens.space16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => ErrorState(
              message: '대학을 불러오지 못했어요.',
              onRetry: () => ref.invalidate(universitySearchProvider(_query)),
            ),
            data: (list) {
              final available = list
                  .where((u) => !selected.any((s) => s.universityId == u.id))
                  .toList();
              if (list.isEmpty) return const EmptyState('검색 결과가 없습니다.');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final uni in available)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _UniversityAvatar(
                        name: uni.name,
                        selected: false,
                      ),
                      title: Text(uni.name),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: _busy ? null : () => _add(uni),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: AppTokens.space12),
      ],
    );
  }
}

/// School/university logo stand-in. No external logo source exists, so this is
/// always a graceful fallback: the name's initial on a neutral surface. UX never
/// depends on a real logo being present.
class _UniversityAvatar extends StatelessWidget {
  const _UniversityAvatar({required this.name, required this.selected});
  final String name;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '대' : trimmed.substring(0, 1);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppTokens.primary.withValues(alpha: 0.14)
            : AppTokens.primarySoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(
        initial,
        style: AppTokens.cardTitle.copyWith(
          color: selected ? AppTokens.primaryInk : AppTokens.textSecondary,
        ),
      ),
    );
  }
}

class _SelectedUniversityCard extends StatelessWidget {
  const _SelectedUniversityCard({
    required this.name,
    required this.onRemove,
    required this.onEdit,
    this.priority,
  });
  final int? priority;
  final VoidCallback? onEdit;
  final String name;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '관심 대학 선택됨: $name',
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space12,
          AppTokens.space8,
          AppTokens.space4,
          AppTokens.space8,
        ),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: AppTokens.primary, width: 1.5),
          boxShadow: AppTokens.shadowSm,
        ),
        child: Row(
          children: [
            _UniversityAvatar(name: name, selected: true),
            const SizedBox(width: AppTokens.space12),
            Expanded(
              child: Text(
                name,
                style: AppTokens.cardTitle.copyWith(
                  color: AppTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (priority != null) Text('$priority순위'),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: '학과·우선순위 수정',
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              tooltip: '제거',
              color: AppTokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
