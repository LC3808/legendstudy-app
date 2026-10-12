import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Native counterpart of WEB freezeExam. This is an immutable request envelope,
/// not billing authority: only the server may authorize content and charge Credit.
/// Source-only catalog keys cannot pass the canonical UUID boundary.
Map<String, dynamic> freezeExamUnit(
  String owner,
  Map<String, dynamic> catalog,
  List<Map<String, dynamic>> answers,
) {
  void require(bool value, String error) {
    if (!value) throw StateError(error);
  }

  bool id(Object? value) =>
      value is String &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(value);
  require(
    catalog['reviewed'] == true && catalog['billing'] == 'EXAM',
    'EXAM_CONTRACT_NOT_READY',
  );
  require(
    id(owner) && id(catalog['examId']) && id(catalog['universityId']),
    'INVALID_IDENTITY',
  );
  require(
    ['REGULAR_ADMISSION_ESSAY', 'MOCK_ESSAY'].contains(catalog['kind']) &&
        catalog['year'] is int &&
        (catalog['year'] as int) >= 2001 &&
        catalog['track'] is String &&
        (catalog['track'] as String).trim().isNotEmpty,
    'INVALID_EXAM',
  );
  final questions = (catalog['questions'] as List).cast<Map<String, dynamic>>();
  require(
    questions.isNotEmpty &&
        questions.map((q) => q['id']).toSet().length == questions.length,
    'INVALID_CATALOG',
  );
  require(
    answers.isNotEmpty &&
        answers.length <= questions.length &&
        answers.map((a) => a['questionId']).toSet().length == answers.length,
    'INVALID_QUESTION_SET',
  );
  final selected =
      answers.map((a) {
        final matches = questions.where((q) => q['id'] == a['questionId']);
        require(matches.length == 1, 'QUESTION_NOT_IN_EXAM');
        final q = matches.single;
        require(
          id(q['id']) &&
              q['rubricVersion'] is String &&
              (q['rubricVersion'] as String).isNotEmpty &&
              q['evidenceVersion'] is String &&
              (q['evidenceVersion'] as String).isNotEmpty,
          'QUESTION_NOT_IN_EXAM',
        );
        require(
          a['body'] is String &&
              (a['body'] as String).trim().isNotEmpty &&
              (a['body'] as String).length <= 30000 &&
              a['revision'] is int &&
              (a['revision'] as int) >= 0 &&
              (a['revision'] as int) <= 9007199254740991,
          'INVALID_ANSWER',
        );
        return <String, dynamic>{
          'questionId': a['questionId'],
          'body': a['body'],
          'revision': a['revision'],
          'rubricVersion': q['rubricVersion'],
          'evidenceVersion': q['evidenceVersion'],
        };
      }).toList()..sort(
        (a, b) =>
            (a['questionId'] as String).compareTo(b['questionId'] as String),
      );
  return Map.unmodifiable({
    'version': 'essay-exam-unit-v1',
    'ownerId': owner,
    'examId': catalog['examId'],
    'universityId': catalog['universityId'],
    'kind': catalog['kind'],
    'year': catalog['year'],
    'track': catalog['track'],
    'session': catalog['session'],
    'campus': catalog['campus'],
    'answers': List<Map<String, dynamic>>.unmodifiable(
      selected.map(Map<String, dynamic>.unmodifiable),
    ),
  });
}

String examUnitRequestHash(
  Map<String, dynamic> snapshot,
  String? parentEvaluationId,
) => sha256
    .convert(
      utf8.encode(
        jsonEncode({
          'snapshot': snapshot,
          'parentEvaluationId': parentEvaluationId,
        }),
      ),
    )
    .toString();

Map<String, dynamic> freezeExamReevaluation(
  String owner,
  Map<String, dynamic> catalog,
  Map<String, dynamic> parent,
  List<Map<String, dynamic>> changes, {
  required DateTime settledAt,
  required DateTime now,
  required bool includedUsed,
}) {
  void require(bool value, String error) {
    if (!value) throw StateError(error);
  }

  require(
    owner == parent['ownerId'] && catalog['examId'] == parent['examId'],
    'CROSS_OWNER_OR_EXAM',
  );
  final age = now.difference(settledAt);
  require(
    !age.isNegative && age <= const Duration(days: 14) && !includedUsed,
    'REEVALUATION_NOT_INCLUDED',
  );
  final previous = (parent['answers'] as List).cast<Map<String, dynamic>>();
  require(
    changes.map((a) => a['questionId']).toSet().length == changes.length &&
        changes.every(
          (a) => previous.any((p) => p['questionId'] == a['questionId']),
        ),
    'FROZEN_QUESTION_SET',
  );
  for (final a in changes) {
    final p = previous.singleWhere((p) => p['questionId'] == a['questionId']);
    require(
      a['revision'] is int &&
          (a['revision'] as int) >= (p['revision'] as int) &&
          (a['body'] == p['body'] ||
              (a['revision'] as int) > (p['revision'] as int)),
      'STALE_REVISION',
    );
  }
  final next = freezeExamUnit(
    owner,
    catalog,
    previous
        .map(
          (p) =>
              changes
                  .where((a) => a['questionId'] == p['questionId'])
                  .firstOrNull ??
              p,
        )
        .toList(),
  );
  require(
    [
      'universityId',
      'kind',
      'year',
      'track',
      'session',
      'campus',
    ].every((k) => next[k] == parent[k]),
    'EXAM_METADATA_CHANGED',
  );
  final answers = (next['answers'] as List).cast<Map<String, dynamic>>();
  require(
    answers.every((a) {
      final p = previous.singleWhere((p) => p['questionId'] == a['questionId']);
      return a['rubricVersion'] == p['rubricVersion'] &&
          a['evidenceVersion'] == p['evidenceVersion'];
    }),
    'RUBRIC_OR_EVIDENCE_CHANGED',
  );
  return next;
}
