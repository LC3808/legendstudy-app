import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/links/external_link.dart';
import '../../core/links/service_links.dart';
import '../../core/theme/app_theme.dart';
import 'shell_widgets.dart';

/// Native material browsing first. Feedback remains on the existing server HOLD.
class LegendStudyLabEntry extends StatelessWidget {
  const LegendStudyLabEntry({super.key});

  @override
  Widget build(BuildContext context) => CompactUtilityCard(
    title: '논술 LAB',
    body: '기출문제를 선택하고 확인하세요. AI 첨삭 서비스는 준비 중입니다.',
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary: in-app native 논술 LAB route (not an external URL).
        FilledButton(
          onPressed: () => context.push('/lab/essay'),
          child: const Text('논술 LAB 시작하기'),
        ),
        const SizedBox(height: AppTokens.space12),
        Text(
          '긴 답안을 작성하거나 첨삭 결과를 자세히 살펴볼 때는 웹에서도 더 편리하게 이용할 수 있어요.',
          style: AppTokens.caption.copyWith(color: AppTokens.textSecondary),
        ),
        // Secondary: the same 논술 LAB on the web, opened in an external browser.
        ExternalLinkButton(
          uri: legendStudyLabEntryUri(legendStudyLabUrl),
          label: '웹에서 이용하기 ↗',
        ),
      ],
    ),
  );
}
