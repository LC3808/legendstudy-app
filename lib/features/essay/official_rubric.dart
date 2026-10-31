import 'package:flutter/material.dart';

/// Optional presentation reference. Never derive rows from flattened prose.
/// Candidates are deliberately rejected; activation needs a separately reviewed
/// producer and an exact historical criterion/package binding.
class OfficialRubric {
  const OfficialRubric(this.rows, this.bonus, this.page, this.packageVersion);
  final List<({String score, String grade, String description})> rows;
  final String bonus;
  final int page, packageVersion;

  static OfficialRubric? read(
    dynamic value, {
    required String criterionId,
    required String packageDigest,
    required String originalText,
  }) {
    if (value is! Map ||
        value['schema'] != 'official-rubric-read-v1' ||
        value['status'] != 'VERIFIED' ||
        value['criterion_id'] != criterionId ||
        value['original_text'] != originalText) {
      return null;
    }
    final source = value['source'];
    if (source is! Map ||
        packageDigest.isEmpty ||
        source['package_digest'] != packageDigest ||
        source['page'] is! int ||
        (source['page'] as int) < 1 ||
        source['package_version'] is! int ||
        (source['package_version'] as int) < 1 ||
        source['pdf_hash'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(source['pdf_hash'] as String)) {
      return null;
    }
    final rows = value['rows'];
    if (rows is! List || rows.isEmpty || value['bonus'] is! String) return null;
    final parsed = <({String score, String grade, String description})>[];
    for (final row in rows) {
      if (row is! Map ||
          row['description'] is! String ||
          (row['description'] as String).trim().isEmpty ||
          row['score'] is! String ||
          row['grade'] is! String ||
          ((row['score'] as String).isEmpty &&
              (row['grade'] as String).isEmpty)) {
        return null;
      }
      parsed.add((
        score: row['score'],
        grade: row['grade'],
        description: row['description'],
      ));
    }
    return OfficialRubric(
      List.unmodifiable(parsed),
      value['bonus'] as String,
      source['page'] as int,
      source['package_version'] as int,
    );
  }
}

class OfficialRubricView extends StatelessWidget {
  const OfficialRubricView({super.key, required this.rubric});
  final OfficialRubric rubric;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('평가 당시 자료 v${rubric.packageVersion} · PDF ${rubric.page}쪽'),
      for (final row in rubric.rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  if (row.score.isNotEmpty) '배점 ${row.score}',
                  if (row.grade.isNotEmpty) '등급 ${row.grade}',
                ].join(' · '),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(row.description, textAlign: TextAlign.left),
            ],
          ),
        ),
      if (rubric.bonus.isNotEmpty) Text('가점 조건\n${rubric.bonus}'),
    ],
  );
}
