import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/intended_major_repository.dart';

/// Reusable 희망 학과 / 관심 전공 editor (onboarding + My Page). Exploratory
/// interest, not an application choice. Broad fields + an explicit
/// "아직 정하지 못했어요" (stored as null). Selection is not color-only (check +
/// weight + border).
class IntendedMajorField extends ConsumerStatefulWidget {
  const IntendedMajorField({super.key});
  @override
  ConsumerState<IntendedMajorField> createState() => _IntendedMajorFieldState();
}

class _IntendedMajorFieldState extends ConsumerState<IntendedMajorField> {
  bool _busy = false;

  Future<void> _choose(String? value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(intendedMajorRepositoryProvider)?.set(value);
      ref.invalidate(intendedMajorProvider);
      await ref.read(intendedMajorProvider.future);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관심 전공을 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(intendedMajorProvider).asData?.value;
    return Wrap(
      spacing: AppTokens.space8,
      runSpacing: AppTokens.space8,
      children: [
        for (final field in interestFieldOptions)
          _MajorChip(
            label: field,
            selected: current == field,
            onTap: _busy ? null : () => _choose(field),
          ),
        _MajorChip(
          label: '아직 정하지 못했어요',
          selected: current == null,
          onTap: _busy ? null : () => _choose(null),
        ),
      ],
    );
  }
}

class _MajorChip extends StatelessWidget {
  const _MajorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    // Cap each chip to the viewport width so a long Korean label under 200%
    // text scaling wraps inside the chip instead of overflowing the row.
    final maxWidth = MediaQuery.sizeOf(context).width - 48;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth > 0 ? maxWidth : 280),
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected ? AppTokens.primary : AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(
                  color: selected ? AppTokens.primary : AppTokens.cardBorder,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
