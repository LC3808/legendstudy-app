import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/links/external_link.dart';
import '../../core/links/service_links.dart';
import 'shell_widgets.dart';

class LegendStudyLabEntry extends StatelessWidget {
  const LegendStudyLabEntry({super.key});

  @override
  Widget build(BuildContext context) => CompactUtilityCard(
    title: '논술 준비',
    body: '문제를 읽고, 직접 쓰고, 다시 고쳐 쓰는 논술 학습',
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton(
          onPressed: () => context.push('/lab/essay'),
          child: const Text('논술 화면 미리보기'),
        ),
        ExternalLinkButton(
          uri: legendStudyLabEntryUri(legendStudyLabUrl),
          label: 'LAB 살펴보기',
        ),
      ],
    ),
  );
}
