import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/content_item.dart';

class ContentCard extends StatelessWidget {
  const ContentCard(this.item, {super.key});
  final ContentItem item;
  String get typeLabel => switch (item.contentType) {
    'exam' => '모의고사',
    'study_material' => '학습자료',
    'university_essay' => '논술',
    'admissions_info' => '입시정보',
    'education_column' => '교육칼럼',
    _ => '기타',
  };

  // This presentation row can later use verified exam metadata. No synthetic data.
  String? get metadata {
    final date = item.publishedAt ?? item.feedUpdatedAt;
    if (date == null) return null;
    final label = item.publishedAt != null ? '게시' : '업데이트';
    return '$label ${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppTokens.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        side: const BorderSide(color: AppTokens.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        onTap: () =>
            context.push('/materials/${Uri.encodeComponent(item.slug)}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (metadata != null) ...[
                const SizedBox(height: 4),
                Text(
                  metadata!,
                  style: Theme.of(context).textTheme.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.summary?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  item.summary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
