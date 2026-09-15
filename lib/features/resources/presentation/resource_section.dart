import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/links/external_link.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../domain/content_resource.dart';
import '../resource_providers.dart';

class ResourceSection extends ConsumerWidget {
  const ResourceSection({
    required this.contentItemId,
    required this.contentSourceUrl,
    required this.isArticle,
    super.key,
  });
  final String contentItemId;
  final String contentSourceUrl;
  final bool isArticle;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(contentResourcesProvider(contentItemId))
      .when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(
          child: CircularProgressIndicator(semanticsLabel: '첨부 자료 불러오는 중'),
        ),
        error: (_, _) => ErrorState(
          message: '첨부 자료를 불러오지 못했어요.',
          onRetry: () =>
              ref.invalidate(contentResourcesProvider(contentItemId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return isArticle
                ? const SizedBox.shrink()
                : const EmptyState('이 자료에는 별도의 첨부 파일이 없어요.');
          }
          // Keep distinct historical occurrences, even when mapped to the same name.
          final groups = <String, List<ContentResource>>{};
          for (final item in items) {
            groups.putIfAbsent(item.examSubjectId ?? '', () => []).add(item);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('첨부 자료'),
              const Text('외부 사이트에서 열립니다. 링크의 현재 이용 가능 여부는 확인되지 않았어요.'),
              for (final group in groups.values) ...[
                SectionHeader(group.first.groupLabel),
                for (final item in group)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    color: AppTokens.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                      side: const BorderSide(color: AppTokens.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            resourceTypeLabels[item.resourceType] ?? '기타',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (item.sourceLabel?.trim().isNotEmpty == true &&
                              item.sourceLabel != item.displayTitle)
                            Text(item.sourceLabel!),
                          if (resolveResourceOpenUri(item, contentSourceUrl) ==
                              null)
                            const Text('열 수 있는 링크가 없어요.')
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.linkKind == 'unknown')
                                  const Text('원본 자료 페이지에서 열립니다.'),
                                ExternalLinkButton(
                                  uri: resolveResourceOpenUri(
                                    item,
                                    contentSourceUrl,
                                  ),
                                  label: '외부 링크 열기',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      );
}
