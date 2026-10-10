import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared "서비스 준비 중" detail for a LAB that is not live yet (내신분석 LAB,
/// 수능·수능 LAB). The card on the LAB home is clickable and lands here so the
/// user understands the future value — it is never a dead disabled card. Copy
/// avoids any 합격 가능성/예측 claim (that feature does not exist yet). No analysis
/// logic, no backend.
class LabComingSoonPage extends StatelessWidget {
  const LabComingSoonPage({
    super.key,
    required this.title,
    required this.lead,
    required this.note,
  });

  final String title;
  final String lead;
  final String note;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTokens.primarySoft,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          constraints: const BoxConstraints(maxWidth: 110),
          child: const Text(
            '서비스 준비 중',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTokens.primaryInk,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space16),
        Text(title, style: AppTokens.sectionTitle),
        const SizedBox(height: AppTokens.space12),
        Text(lead, style: AppTokens.body.copyWith(height: 1.6)),
        const SizedBox(height: AppTokens.space12),
        Text(note, style: AppTokens.secondary),
        const SizedBox(height: AppTokens.space16),
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(color: AppTokens.cardBorder),
          ),
          child: Text(
            '첫 실행에서 설정한 학교·학년·관심 대학·희망 전공을 바탕으로 준비하고 있어요. 설정은 MY에서 언제든 바꿀 수 있어요.',
            style: AppTokens.secondary.copyWith(height: 1.6),
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        SizedBox(
          height: 52,
          child: FilledButton(
            // Intentionally disabled — the service is not available yet.
            onPressed: null,
            child: const Text('준비 중'),
          ),
        ),
      ],
    );
  }
}
