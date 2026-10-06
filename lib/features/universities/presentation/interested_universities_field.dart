import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../application/university_providers.dart';
import '../domain/university_models.dart';

/// Reusable 관심 대학 editor (first-run onboarding + My Page). Interest, not
/// application. Search the catalog, select up to [maxInterested]; selected
/// universities rise into an emphasized foreground list and can be removed.
/// Selection state is never color-only (check icon + weight + border + label).
class InterestedUniversitiesField extends ConsumerStatefulWidget {
  const InterestedUniversitiesField({super.key, required this.source});

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
    if (_busy || q.isEmpty || q == _query) return;
    FocusScope.of(context).unfocus();
    setState(() => _query = q);
  }

  Future<void> _add(University uni) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(interestedUniversitiesProvider.notifier)
          .add(uni.id, source: widget.source);
    } catch (_) {
      _snack('대학을 추가하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(String rowId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(interestedUniversitiesProvider.notifier).remove(rowId);
    } catch (_) {
      _snack('대학을 제거하지 못했어요. 다시 시도해 주세요.');
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
          '선택하지 않아도 괜찮아요 · 최대 $maxInterested개, 약 $recommendedInterested개 추천',
          style: AppTokens.caption.copyWith(color: AppTokens.textTertiary),
        ),
        const SizedBox(height: AppTokens.space8),
        TextField(
          controller: _input,
          enabled: !_busy && !atCap,
          maxLength: 60,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: atCap ? '최대 $maxInterested개까지 선택했어요' : '대학 이름을 검색해 주세요',
            prefixIcon: const Icon(Icons.search),
            counterText: '',
          ),
          onChanged: (v) {
            if (v.trim().isEmpty && _query.isNotEmpty) {
              setState(() => _query = '');
            }
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
              if (list.isEmpty) return const EmptyState('검색 결과가 없어요.');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final uni in available)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _UniversityAvatar(name: uni.name, selected: false),
                      title: Text(uni.name),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: _busy ? null : () => _add(uni),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: AppTokens.space12),
        if (selected.isEmpty)
          const EmptyState('아직 선택한 관심 대학이 없어요. 나중에 설정해도 괜찮아요.')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final uni in selected)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space8),
                  child: _SelectedUniversityCard(
                    name: uni.name,
                    onRemove: _busy ? null : () => _remove(uni.id),
                  ),
                ),
            ],
          ),
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
  const _SelectedUniversityCard({required this.name, required this.onRemove});
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
