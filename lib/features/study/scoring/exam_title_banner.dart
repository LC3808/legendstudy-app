import 'package:flutter/material.dart';

import 'scoring_display_title.dart';

class ExamTitleBanner extends StatelessWidget {
  const ExamTitleBanner({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0D6),
      border: Border.all(color: const Color(0xFFB65300), width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      scoringDisplayTitle(title),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Color(0xFF713400),
      ),
    ),
  );
}
