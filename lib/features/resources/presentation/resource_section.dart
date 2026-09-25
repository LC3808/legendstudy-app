import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/links/external_link.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../domain/content_resource.dart';
import 'pdf_viewer_page.dart';
import '../data/trusted_resolver_client.dart';
import '../resource_providers.dart';

class ResourceSection extends ConsumerWidget {
  const ResourceSection({
    required this.contentItemId,
    required this.contentSlug,
    required this.contentSourceUrl,
    required this.isArticle,
    this.onMeaningfulAction,
    super.key,
  });
  final String contentItemId;
  final String contentSlug;
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
          // Group labels for display only; occurrence/resource identities stay distinct.
          final groups = <String, List<ContentResource>>{};
          for (final item in items) {
            groups.putIfAbsent(item.groupLabel, () => []).add(item);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('첨부 자료'),
              const Text('과목별로 문제·정답·해설·듣기 자료를 확인하세요.'),
              for (final group in groups.values)
                ExpansionTile(
                  key: PageStorageKey(
                    '$contentItemId:${group.first.groupLabel}',
                  ),
                  initiallyExpanded: items.length <= 8,
                  title: Text(group.first.groupLabel),
                  subtitle: Text(
                    '${group.length}개 · ${group.map((r) => resourceTypeLabels[r.resourceType] ?? '기타').toSet().join(' · ')}',
                  ),
                  children: [
                    for (final occurrence in _occurrences(group)) ...[
                      if (group.map((r) => r.examSubjectId).toSet().length >
                              1 &&
                          occurrence.first.occurrenceLabel != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            occurrence.first.occurrenceLabel!,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      for (final item in occurrence)
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  resourceTypeLabels[item.resourceType] ?? '기타',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                                if (item.sourceLabel?.trim().isNotEmpty ==
                                        true &&
                                    item.sourceLabel != item.displayTitle)
                                  Text(item.sourceLabel!),
                                _ResourceDeliveryActions(
                                  key: ValueKey(item.id),
                                  contentSlug: contentSlug,
                                  resource: item,
                                  delivery: resolveResourceDelivery(
                                    item,
                                    contentSourceUrl,
                                  ),
                                  onOpenAttempted: onMeaningfulAction,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
            ],
          );
        },
      );
}

List<List<ContentResource>> _occurrences(List<ContentResource> resources) {
  final groups = <String, List<ContentResource>>{};
  for (final resource in resources) {
    groups.putIfAbsent(resource.examSubjectId ?? '', () => []).add(resource);
  }
  return groups.values.toList();
}

class _ResourceDeliveryActions extends StatelessWidget {
  const _ResourceDeliveryActions({
    required this.contentSlug,
    required this.resource,
    required this.delivery,
    this.onOpenAttempted,
    super.key,
  });
  final String contentSlug;
  final ContentResource resource;
  final ResourceDelivery delivery;
  final VoidCallback? onOpenAttempted;
  @override
  Widget build(BuildContext context) => resolverCapable(resource)
      ? _ResolvedPdfAction(
          resource: resource,
          contentSlug: contentSlug,
          fallback: delivery.uri ?? delivery.sourceFallback,
          onOpenAttempted: onOpenAttempted,
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.isPdf &&
                      delivery.kind == ResourceDeliveryKind.externalFile
                  ? '앱에서 자료를 엽니다.'
                  : delivery.kind == ResourceDeliveryKind.sourcePage
                  ? '상단 원문 보기에서 자료를 확인하세요.'
                  : delivery.description,
            ),
            if (delivery.uri != null &&
                delivery.kind != ResourceDeliveryKind.sourcePage) ...[
              // Display the host only: paths/queries can carry transient credentials.
              if (!(resource.isPdf &&
                  delivery.kind == ResourceDeliveryKind.externalFile))
                Text('이동할 사이트: ${delivery.uri!.host}'),
              if (resource.isPdf &&
                  delivery.kind == ResourceDeliveryKind.externalFile)
                TextButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    '${resourceTypeLabels[resource.resourceType] ?? '자료'} 보기',
                  ),
                  onPressed: () {
                    onOpenAttempted?.call();
                    context.push(
                      '/materials/${Uri.encodeComponent(contentSlug)}/resource/${Uri.encodeComponent(resource.id)}',
                      extra: PdfViewerRouteArgs(
                        title: resource.displayTitle,
                        delivery: delivery,
                      ),
                    );
                  },
                )
              else
                ExternalLinkButton(
                  uri: delivery.uri,
                  label: delivery.label,
                  onOpenAttempted: onOpenAttempted,
                ),
            ],
          ],
        );
}

class _ResolvedPdfAction extends ConsumerStatefulWidget {
  const _ResolvedPdfAction({
    required this.resource,
    required this.contentSlug,
    this.fallback,
    this.onOpenAttempted,
  });
  final ContentResource resource;
  final String contentSlug;
  final Uri? fallback;
  final VoidCallback? onOpenAttempted;
  @override
  ConsumerState<_ResolvedPdfAction> createState() => _ResolvedPdfActionState();
}

class _ResolvedPdfActionState extends ConsumerState<_ResolvedPdfAction> {
  bool busy = false, failed = false;
  Future<void> open() async {
    if (busy) return;
    setState(() {
      busy = true;
      failed = false;
    });
    widget.onOpenAttempted?.call();
    final uri = await ref
        .read(trustedResolverProvider)
        .resolve(widget.resource.id);
    if (!mounted) return;
    setState(() {
      busy = false;
      failed = uri == null;
    });
    if (uri == null) return;
    context.push(
      '/materials/${Uri.encodeComponent(widget.contentSlug)}/resource/${Uri.encodeComponent(widget.resource.id)}',
      extra: PdfViewerRouteArgs(
        title: widget.resource.displayTitle,
        ephemeral: true,
        resolverResourceId: widget.resource.id,
        delivery: ResourceDelivery(
          kind: ResourceDeliveryKind.externalFile,
          uri: uri,
          sourceFallback: widget.fallback,
          label: '자료 보기',
          description: '앱에서 자료를 엽니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: busy ? null : open,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          failed
              ? '다시 시도'
              : '${resourceTypeLabels[widget.resource.resourceType] ?? '자료'} 보기',
        ),
      ),
      if (failed) const Text('자료를 바로 열 수 없어요.'),
      if (failed && widget.fallback != null)
        ExternalLinkButton(
          uri: widget.fallback,
          label: '원문에서 보기',
          onOpenAttempted: widget.onOpenAttempted,
        ),
    ],
  );
}
