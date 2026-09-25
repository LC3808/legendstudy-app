import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/content_types.dart';

class ContentTypeBadge extends StatelessWidget {
  const ContentTypeBadge(
    this.type, {
    this.examType,
    this.emphasized = false,
    super.key,
  });
  final String type;
  final bool emphasized;
  final String? examType;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: emphasized ? AppTokens.textPrimary : AppTokens.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        materialTypeLabel(type, examType: examType),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: emphasized ? AppTokens.surface : AppTokens.textPrimary,
        ),
      ),
    ),
  );
}
