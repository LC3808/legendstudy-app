import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/links/external_link.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../exams/exam_providers.dart';
import '../../exams/presentation/exam_labels.dart';
import '../../resources/domain/content_resource.dart';
import '../../resources/presentation/resource_section.dart';
import '../content_providers.dart';
import '../domain/content_item.dart';
import 'content_type_badge.dart';

final contentDetailProvider = FutureProvider.autoDispose
    .family<ContentItem?, String>(
      (ref, slug) =>
          ref.watch(contentRepositoryProvider).fetchContentBySlug(slug),
      retry: (_, _) => null,
    );

class ContentDetailPage extends ConsumerWidget {
  const ContentDetailPage({required this.slug, super.key});
  final String slug;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      leading: BackButton(
        onPressed: () {
          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            router.go('/materials');
          }
        },
      ),
    ),
    body: ShellPage(
      children: [
        ref
            .watch(contentDetailProvider(slug))
            .when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => ErrorState(
                message: '자료를 불러오지 못했어요.',
                onRetry: () => ref.invalidate(contentDetailProvider(slug)),
              ),
              data: (item) => item == null
                  ? const EmptyState('자료를 찾을 수 없어요.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ContentTypeBadge(item.contentType),
                        const SizedBox(height: 8),
                        Semantics(
                          header: true,
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (item.contentType == 'exam') _ExamDetails(item.id),
                        if (item.summary?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 16),
                          Text(item.summary!),
                        ],
                        const SizedBox(height: 16),
                        if (item.publishedAt != null)
                          Text('게시 ${formatDate(item.publishedAt!)}'),
                        if (item.sourceUpdatedAt != null)
                          Text('원문 수정 ${formatDate(item.sourceUpdatedAt!)}'),
                        if (publicWebUri(item.sourceUrl) != null)
                          Text('출처 ${publicWebUri(item.sourceUrl)!.host}'),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ExternalLinkButton(
                            uri: publicWebUri(item.sourceUrl),
                            label: '원문 보기',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ResourceSection(
                          contentItemId: item.id,
                          isArticle: [
                            'education_column',
                            'admissions_info',
                          ].contains(item.contentType),
                        ),
                      ],
                    ),
            ),
      ],
    ),
  );
}

class _ExamDetails extends ConsumerWidget {
  const _ExamDetails(this.id);
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(examMetadataProvider(id))
      .when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: '시험 정보 불러오는 중'),
        ),
        error: (_, _) => ErrorState(
          message: '시험 정보를 불러오지 못했어요.',
          onRetry: () => ref.invalidate(examMetadataProvider(id)),
        ),
        data: (rows) {
          final exam = rows[id];
          final lines = exam == null ? <String>[] : examDetails(exam);
          return lines.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final line in lines) Text(line)],
                  ),
                );
        },
      );
}
