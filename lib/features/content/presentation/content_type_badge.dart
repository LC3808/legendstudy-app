import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/content_types.dart';

class ContentTypeBadge extends StatelessWidget {
  const ContentTypeBadge(this.type, {this.examType, super.key});
  final String type;
  final String? examType;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        materialTypeLabel(type, examType: examType),
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ),
  );
}
