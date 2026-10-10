import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../universities/application/university_providers.dart';
import '../../universities/domain/university_models.dart';
import '../data/intended_major_repository.dart';

/// Existing WEB applications-v1 read contract; no target/application writes.
final applicationLabelsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final owner = ref.watch(authStateProvider).value?.userId;
  final client = ref.watch(supabaseClientProvider);
  if (owner == null || client == null) return [];
  final labels = <String>[];
  for (var offset = 0; ; offset += 25) {
    final value = await client.rpc<Map<String, dynamic>>(
      'my_applications',
      params: {'p_offset': offset},
    );
    if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
      return [];
    }
    if (value['version'] != 'applications-v1' ||
        value['items'] is! List ||
        value['has_more'] is! bool) {
      throw const FormatException('Invalid applications response');
    }
    final items = value['items'] as List;
    for (final item in items) {
      final row = item as Map<String, dynamic>;
      final name = row['university_name_snapshot'] as String;
      final division = row['intended_division'] as String;
      // These are actual stored application records, never inferred from targets.
      labels.add([name, if (division.isNotEmpty) division].join(' · '));
    }
    if (value['has_more'] == false) return labels;
    if (items.isEmpty) {
      throw const FormatException('Invalid application cursor');
    }
  }
});

class AspirationsCard extends ConsumerWidget {
  const AspirationsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interests = ref.watch(interestedUniversitiesProvider);
    final major = ref.watch(intendedMajorProvider);
    final applications = ref.watch(applicationLabelsProvider);
    final empty =
        interests.asData?.value.isEmpty == true &&
        major.asData?.value == null &&
        applications.asData?.value.isEmpty == true;
    return LsCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (interests.isLoading || major.isLoading || applications.isLoading)
            const LinearProgressIndicator(semanticsLabel: '희망대학·학과 조회'),
          if (interests.hasError || major.hasError || applications.hasError)
            TextButton(
              onPressed: () {
                ref.invalidate(interestedUniversitiesProvider);
                ref.invalidate(intendedMajorProvider);
                ref.invalidate(applicationLabelsProvider);
              },
              child: const Text('정보 다시 불러오기'),
            ),
          if (empty) const Text('희망대학·학과를 설정해 주세요.'),
          for (final target
              in interests.asData?.value ?? <InterestedUniversity>[])
            Text(target.displayLabel),
          if (major.asData?.value case final String field)
            Text('관심 전공 · $field'),
          if (applications.asData?.value.isNotEmpty == true) ...[
            const Divider(),
            const Text('지원 대학·학과'),
            for (final label in applications.asData!.value) Text(label),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/my/school'),
              child: Text(empty ? '설정하기' : '관리하기'),
            ),
          ),
        ],
      ),
    );
  }
}
