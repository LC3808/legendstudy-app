import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';

// The canonical academic-status editor reused by MY. Onboarding writes the same
// `profiles.academic_status` field through the same repository; this is the
// second UI entry point onto one canonical value.
const _statusLabels = <String, String>{
  'student': '재학생',
  'retaker': 'N수·검정고시 등',
  'other': '기타',
};

class AcademicStatusField extends ConsumerStatefulWidget {
  const AcademicStatusField({super.key});
  @override
  ConsumerState<AcademicStatusField> createState() =>
      _AcademicStatusFieldState();
}

class _AcademicStatusFieldState extends ConsumerState<AcademicStatusField> {
  bool _saving = false;

  Future<void> _save(String? status, String? current) async {
    if (_saving || status == current) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .upsertCurrentProfile(
            academicStatus: status,
            clearAcademicStatus: status == null,
          );
      ref.invalidate(currentProfileProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 상태를 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final current = profile.value?.academicStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('현재 상태'),
        if (profile.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 8,
            children: [
              for (final entry in [
                const MapEntry<String?, String>(null, '설정 안 함'),
                ..._statusLabels.entries,
              ])
                ChoiceChip(
                  label: Text(entry.value),
                  selected: current == entry.key,
                  onSelected: _saving
                      ? null
                      : (_) => _save(entry.key, current),
                ),
            ],
          ),
      ],
    );
  }
}
