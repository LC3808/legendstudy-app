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
    this.onMeaningfulAction,
    super.key,
  });
  final String contentItemId;
  final String contentSourceUrl;
  final bool isArticle;
  final VoidCallback? onMeaningfulAction;
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
              const Text('과목별로 문제·정답·해설·듣기 자료를 확인하세요.'),
              for (final group in groups.values)
                ExpansionTile(
                  key: PageStorageKey(
                    '$contentItemId:${group.first.examSubjectId ?? 'general'}',
                  ),
                  initiallyExpanded: items.length <= 8,
                  title: Text(group.first.groupLabel),
                  subtitle: Text(
                    '${group.length}개 · ${group.map((r) => resourceTypeLabels[r.resourceType] ?? '기타').toSet().join(' · ')}',
                  ),
                  children: [
                    for (final item in group)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: AppTokens.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.cardRadius,
                          ),
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
                              if (resolveResourceOpenUri(
                                    item,
                                    contentSourceUrl,
                                  ) ==
                                  null)
                                const Text('열 수 있는 링크가 없어요.')
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(resourceOpenDescription(item)),
                                    ExternalLinkButton(
                                      uri: resolveResourceOpenUri(
                                        item,
                                        contentSourceUrl,
                                      ),
                                      label: resourceOpenLabel(item),
                                      onOpenAttempted: onMeaningfulAction,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      );
}
