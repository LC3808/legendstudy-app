import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/content_item.dart';

class ContentCard extends StatelessWidget {
  const ContentCard(this.item, {super.key});
  final ContentItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppTokens.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        side: const BorderSide(color: AppTokens.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        onTap: () =>
            context.push('/materials/${Uri.encodeComponent(item.slug)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              if (item.summary != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.summary!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              const Text('자료 살펴보기'),
            ],
          ),
        ),
      ),
    ),
  );
}
