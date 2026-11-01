import 'package:flutter/material.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../../universities/presentation/interested_universities_field.dart';
import 'intended_major_field.dart';

/// Reuses the existing university/major editors without school-profile writes.
class AspirationsPage extends StatelessWidget {
  const AspirationsPage({super.key});

  @override
  Widget build(BuildContext context) => const ShellPage(
    children: [
      SectionHeader('관심 대학·학과'),
      InterestedUniversitiesField(source: 'my'),
      SizedBox(height: 24),
      SectionHeader('희망 학과·관심 전공'),
      IntendedMajorField(),
    ],
  );
}
