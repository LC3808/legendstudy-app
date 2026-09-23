import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';

class GradePage extends ConsumerStatefulWidget {
  const GradePage({super.key});
  @override
  ConsumerState<GradePage> createState() => _GradePageState();
}

class _GradePageState extends ConsumerState<GradePage> {
  int? selected;
  String? owner, error;
  bool loading = true, saving = false, loadFailed = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) {
      final id = next.value?.userId;
      if (id != owner) {
        owner = id;
        load();
      }
    });
    Future.microtask(() {
      if (mounted) {
        owner = ref.read(authStateProvider).value?.userId;
        load();
      }
    });
  }

  Future<void> load() async {
    final request = ++generation;
    setState(() {
      loading = true;
      loadFailed = false;
      saving = false;
      error = null;
      selected = null;
    });
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .fetchCurrentProfile();
      if (!mounted || request != generation) return;
      setState(() => selected = profile?.gradeLevel);
    } catch (_) {
      if (mounted && request == generation) {
        setState(() {
          loadFailed = true;
          error = '학년을 불러오지 못했어요. 다시 시도해 주세요.';
        });
      }
    }
    if (mounted && request == generation) setState(() => loading = false);
  }

  Future<void> save() async {
    final id = ref.read(authStateProvider).value?.userId;
    if (saving || id == null || id != owner) return;
    final request = generation;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .upsertCurrentProfile(
            gradeLevel: selected,
            clearGrade: selected == null,
          );
      if (!mounted ||
          request != generation ||
          ref.read(authStateProvider).value?.userId != id) {
        return;
      }
      ref.invalidate(currentProfileProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('학년을 저장했어요.')));
    } catch (_) {
      if (mounted && request == generation) {
        setState(() => error = '학년을 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted && request == generation) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return const Center(child: CircularProgressIndicator());
    if (auth.hasError) {
      return ErrorState(
        message: '계정 상태를 확인하지 못했어요.',
        onRetry: () => ref.invalidate(authStateProvider),
      );
    }
    if (auth.value?.userId == null) {
      return ShellPage(
        children: [
          const Text('학년을 저장하려면 로그인이 필요해요.'),
          FilledButton(
            onPressed: () => context.push('/auth', extra: true),
            child: const Text('로그인'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('학년 (선택)'),
        if (loading)
          const CircularProgressIndicator()
        else ...[
          Wrap(
            spacing: 8,
            children: [
              for (final grade in [null, 1, 2, 3])
                ChoiceChip(
                  label: Text(grade == null ? '설정 안 함' : '$grade학년'),
                  selected: selected == grade,
                  onSelected: saving
                      ? null
                      : (_) => setState(() => selected = grade),
                ),
            ],
          ),
          if (error != null) ...[
            Text(error!),
            TextButton(
              onPressed: saving ? null : load,
              child: const Text('다시 불러오기'),
            ),
          ],
          FilledButton(
            onPressed: saving || loadFailed ? null : save,
            child: Text(saving ? '저장 중…' : '학년 저장'),
          ),
        ],
      ],
    );
  }
}
