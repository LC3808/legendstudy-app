import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/content_item.dart';
import '../../exams/domain/exam_metadata.dart';
import '../../exams/presentation/exam_labels.dart';
import 'content_type_badge.dart';

class ContentCard extends StatelessWidget {
  const ContentCard(this.item, {this.exam, super.key});
  final ExamMetadata? exam;
  final ContentItem item;
  String? get metadata {
    if (item.contentType == 'exam') {
      final summary = exam == null ? '' : examSummary(exam!);
      return summary.isEmpty ? null : summary;
    }
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
              ContentTypeBadge(item.contentType),
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
