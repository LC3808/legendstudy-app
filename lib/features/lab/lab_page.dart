import 'package:flutter/material.dart';

import '../../shared/widgets/shell_widgets.dart';
import '../../shared/widgets/legendstudy_lab_entry.dart';

/// A service entry, not an embedded web session or an unimplemented analysis UI.
class LabPage extends StatelessWidget {
  const LabPage({super.key});
  @override
  Widget build(BuildContext context) => const ShellPage(
    children: [
      AppHeader(title: 'LAB'),
      SectionHeader('논술'),
      LegendStudyLabEntry(),
    ],
  );
}
