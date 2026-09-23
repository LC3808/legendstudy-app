import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../personal/personal_providers.dart';
import '../../school/school_providers.dart';

class LearningInfoRow extends ConsumerWidget {
  const LearningInfoRow({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final school = ref.watch(schoolSelectionProvider);
    final profile = ref.watch(currentProfileProvider);
    final loading = auth.isLoading || school.isLoading || profile.isLoading;
    final failed = auth.hasError || school.hasError || profile.hasError;
    final name = school.value?.name;
    final grade = profile.value?.gradeLevel;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('학교·학년'),
      subtitle: loading
          ? const LinearProgressIndicator(semanticsLabel: '학교·학년 불러오는 중')
          : Text(
              failed
                  ? '학교·학년 정보를 불러오지 못했어요.'
                  : name == null
                  ? '학교를 설정해 주세요'
                  : '$name${grade == null ? '' : ' · $grade학년'}',
            ),
      trailing: loading
          ? null
          : TextButton(
              onPressed: failed
                  ? () {
                      ref.invalidate(authStateProvider);
                      ref.invalidate(schoolSelectionProvider);
                      ref.invalidate(currentProfileProvider);
                    }
                  : () => context.push('/my/school'),
              child: Text(
                failed
                    ? '재시도'
                    : name == null
                    ? '설정'
                    : '변경',
              ),
            ),
    );
  }
}
