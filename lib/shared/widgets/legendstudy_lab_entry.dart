import 'package:flutter/material.dart';

import '../../core/links/external_link.dart';
import '../../core/links/service_links.dart';
import 'shell_widgets.dart';

class LegendStudyLabEntry extends StatelessWidget {
  const LegendStudyLabEntry({super.key});

  @override
  Widget build(BuildContext context) => CompactUtilityCard(
    title: '논술 준비',
    body: '논술 준비를 위한 LAB을 웹에서 살펴보세요.',
    action: ExternalLinkButton(
      uri: legendStudyLabEntryUri(legendStudyLabUrl),
      label: 'LAB 살펴보기',
    ),
  );
}
