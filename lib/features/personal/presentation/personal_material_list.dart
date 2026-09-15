import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../content/presentation/content_type_badge.dart';
import '../personal_list_providers.dart';

class PersonalMaterialListPage extends ConsumerWidget {
  const PersonalMaterialListPage({required this.kind, super.key});
  final PersonalListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return ShellPage(
      children: [
        auth.when(
          loading: () =>
              const LinearProgressIndicator(semanticsLabel: '계정 상태 확인'),
          error: (_, _) => ErrorState(
            message: '계정 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(authStateProvider),
          ),
          data: (status) => status.isAuthenticated
              ? PersonalMaterialList(kind: kind)
              : const EmptyState('로그인하면 이 기능을 이용할 수 있어요.'),
        ),
      ],
    );
  }
}

class PersonalMaterialList extends ConsumerWidget {
  const PersonalMaterialList({required this.kind, super.key});
  final PersonalListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) {
      // Keep the shell settleable while the auth stream has not emitted yet.
      return const Text('자료 목록을 불러오는 중…');
    }
    if (auth.hasError) {
      return ErrorState(
        message: '계정 상태를 확인하지 못했어요.',
        onRetry: () => ref.invalidate(authStateProvider),
      );
    }
    if (auth.value?.isAuthenticated != true) {
      return const EmptyState('로그인하면 이 기능을 이용할 수 있어요.');
    }
    final state = ref.watch(personalMaterialListProvider(kind));
    return state.when(
      skipLoadingOnRefresh: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: error is BackendUnavailable
            ? error.message
            : '자료 목록을 불러오지 못했어요. 다시 시도해 주세요.',
        onRetry: () => ref.invalidate(personalMaterialListProvider(kind)),
      ),
      data: (items) => items.isEmpty
          ? EmptyState(
              kind == PersonalListKind.bookmarks
                  ? '저장한 자료가 아직 없어요.'
                  : '최근 본 자료가 아직 없어요.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final material in items)
                  _PersonalMaterialCard(material: material, kind: kind),
              ],
            ),
    );
  }
}

class _PersonalMaterialCard extends ConsumerWidget {
  const _PersonalMaterialCard({required this.material, required this.kind});
  final PersonalMaterial material;
  final PersonalListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = material.item;
    final timestamp = material.entry.timestamp.toLocal();
    final label = kind == PersonalListKind.bookmarks ? '저장' : '최근 본';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        child: Semantics(
          button: true,
          label: '${item.title}, $label 자료 열기',
          child: InkWell(
            onTap: () async {
              await context.push(
                '/materials/${Uri.encodeComponent(item.slug)}',
              );
              if (context.mounted) {
                ref.invalidate(personalMaterialListProvider(kind));
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 88),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ContentTypeBadge(item.contentType),
                        const SizedBox(height: 2),
                        Text(
                          '$label ${timestamp.year}.${timestamp.month.toString().padLeft(2, '0')}.${timestamp.day.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
