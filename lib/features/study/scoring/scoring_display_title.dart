import '../../content/presentation/material_display_title.dart';

/// Presentation only. Keep the original title, exam IDs and saved results intact.
String scoringDisplayTitle(String title) {
  final withoutDate = title.replaceFirst(
    RegExp(r'^\s*\[\d{4}년\s*\d{1,2}월\s*시행\]\s*'),
    '',
  );
  final csat = RegExp(r'^(.+?(?:수능|대학수학능력시험)\s*기출)(?:\s*[-–—:].*|\s*)$')
      .firstMatch(withoutDate);
  if (csat != null) return csat.group(1)!.trim();
  // Use the same mock-exam trimming as the materials search/list.
  return materialDisplayTitle(withoutDate, 'exam');
}

/// Use the saved subject, never infer it from a title or score.
String scoringResultTitle(String title, String? subject) => [
  scoringDisplayTitle(title),
  if (subject?.trim().isNotEmpty == true) subject!.trim(),
].join(' · ');
