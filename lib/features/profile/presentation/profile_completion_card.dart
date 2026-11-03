import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';

/// Optional guidance based on stored fields, never on NEIS name availability.
class ProfileCompletionCard extends ConsumerWidget {
  const ProfileCompletionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final profile = ref.watch(currentProfileProvider);
    final owner = auth.asData?.value.userId;
    if (auth.isLoading ||
        auth.hasError ||
        owner == null ||
        profile.isLoading ||
        profile.hasError) {
      return const SizedBox.shrink();
    }
    final value = profile.asData?.value;
    if (value != null && value.id != owner) return const SizedBox.shrink();
    final statusMissing = value?.academicStatus == null;
    final student = value?.academicStatus == 'student';
    final schoolMissing =
        value?.neisOfficeCode == null || value?.neisSchoolCode == null;
    final gradeMissing = value?.gradeLevel == null;
    if (!statusMissing && (!student || (!schoolMissing && !gradeMissing))) {
      return const SizedBox.shrink();
    }
    final title = statusMissing
        ? '현재 상태를 먼저 설정해 주세요.'
        : schoolMissing && gradeMissing
        ? '학교와 학년을 설정해 주세요.'
        : schoolMissing
        ? '학교를 설정해 주세요.'
        : '학년을 설정해 주세요.';
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space12),
      child: LsCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTokens.cardTitle),
            const SizedBox(height: AppTokens.space8),
            Text(
              statusMissing
                  ? '현재 상태에 맞는 정보 설정을 안내해 드릴게요.'
                  : '학교별 학습 정보와 맞춤형 서비스를 이용할 수 있어요.',
              style: AppTokens.secondary,
            ),
            const SizedBox(height: AppTokens.space8),
            OutlinedButton(
              onPressed: () => context.push('/my/school'),
              child: const Text('정보 설정하기'),
            ),
          ],
        ),
      ),
    );
  }
}
