import 'package:flutter/material.dart';
import '../domain/content_types.dart';

class ContentTypeBadge extends StatelessWidget {
  const ContentTypeBadge(this.type, {super.key});
  final String type;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        contentTypeLabels[type] ?? '기타',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ),
  );
}
