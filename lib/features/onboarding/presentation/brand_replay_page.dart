import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../brand/brand_wordmark.dart';
import 'onboarding_page.dart' show brandSlides;

/// "앱 사용 안내 다시 보기" (Settings replay). Shows the brand intro slides only —
/// it never resets personalization or the onboarding-completed flag.
class BrandReplayPage extends StatelessWidget {
  const BrandReplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space20),
      children: [
        for (final (i, (title, body, icon)) in brandSlides.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space16),
            child: Container(
              padding: const EdgeInsets.all(AppTokens.space20),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                border: Border.all(color: AppTokens.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 36, color: AppTokens.primary),
                  const SizedBox(height: AppTokens.space12),
                  if (i == 0)
                    const BrandWordmark(fontSize: 20)
                  else
                    Text(
                      title,
                      style: AppTokens.sectionTitle.copyWith(
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    body,
                    style: AppTokens.body.copyWith(
                      color: AppTokens.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppTokens.space8),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => context.pop(),
            child: const Text('확인'),
          ),
        ),
      ],
    );
  }
}
