import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../applications/application_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../universities/application/university_providers.dart';
import '../../universities/domain/university_models.dart';
import '../data/intended_major_repository.dart';

/// Existing WEB applications-v1 read contract; no target/application writes.
final applicationLabelsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final records = await ref.watch(applicationsProvider.future);
  return records
      .map(
        (record) => [
          record.university,
          if (record.division.isNotEmpty) record.division,
        ].join(' · '),
      )
      .toList();
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
              onPressed: () => context.push('/my/aspirations'),
              child: const Text('관심 대학 설정'),
            ),
          ),
        ],
      ),
    );
  }
}
