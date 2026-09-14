import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';
import '../study_repository_test.dart' show config;

Map<String, dynamic> sourceJson([String? status, int version = 1]) => {
  'version': version,
  'source_name': status == null ? '검증된 정답 출처' : '등급 기준 출처',
  'source_url': 'https://example.com/source/$version',
  'verified_at': '2026-09-14T00:00:00Z',
  if (status != null)
    'basis': status == 'confirmed' ? 'raw_absolute' : 'raw_estimate',
  if (status != null) 'certainty': status,
};
MockScoringAvailability gradeAvailability(String status) =>
    MockScoringAvailability.fromJson({
      'exam_subject_id': 'occurrence',
      'paper_variant': 'common',
      'answer_key_version_id': 'key-v1',
      'answer_key_version': 1,
      'question_count': 100,
      'max_score': 100,
      'grade_cutoff_version_id': status == 'unavailable' ? null : 'cutoff-v1',
      'grade_status': status,
      'scoring_version': 'mcq5-v1',
      'availability': 'scoring_available',
    });
AnswerDraft gradeDraft(String status, List<int?> answers) => AnswerDraft(
  gradeAvailability(status),
  List.generate(100, (i) => AnswerEntryQuestion(i + 1, 1)),
  answers,
);
ScoreResult gradeResult(String status, List<int?> answers) =>
    scoreMcq5(
      List.generate(100, (i) => [i + 1, 1, 1]),
      answers,
      certainty: status,
      minimumScores: status == 'unavailable'
          ? null
          : [90, 80, 70, 60, 50, 40, 30, 20, 0],
    ).withSources(
      ScoringSource.fromJson(sourceJson()),
      status == 'unavailable'
          ? null
          : ScoringSource.fromJson(sourceJson(status)),
    );

/// Synthetic transport only. Exercises the real Guest and Auth repository mapping.
class GradeFixture {
  GradeFixture(this.status, {this.owner});
  final String status;
  final String? owner;
  int version = 1;
  bool malformed = false;
  final requests = <http.Request>[];
  final stored = <String, Map<String, dynamic>>{};
  late final transport = MockClient((r) async {
    requests.add(r);
    final path = r.url.path.split('/').last;
    dynamic body;
    if (path == 'submit_mock_attempt') {
      final p = jsonDecode(r.body) as Map;
      final id = p['p_attempt_id'] as String;
      body = stored.putIfAbsent(id, () {
        final choices = (p['p_answers'] as List)
            .map((a) => a['choice'] as int?)
            .toList();
        final result = gradeResult(status, choices);
        return {
          ...result.toJson(),
          'id': id,
          'user_id': owner,
          'exam_subject_id': 'occurrence',
          'paper_variant': 'common',
          'answer_key_version_id': 'key-v1',
          'grade_cutoff_version_id': status == 'unavailable'
              ? null
              : 'cutoff-v1',
          'scoring_version': 'mcq5-v1',
          'study_session_id': p['p_study_session_id'],
          'submitted_at': '2026-09-14T00:00:00Z',
          'answers': result.answers
              .map(
                (a) => {
                  ...a.toJson(),
                  'attempt_id': id,
                  'answer_key_version_id': 'key-v1',
                },
              )
              .toList(),
        };
      });
    } else if (path == 'fetch_own_mock_attempt') {
      body = stored[(jsonDecode(r.body) as Map)['p_attempt_id']];
    } else if (path == 'mock_exam_scoring_availability') {
      body = [gradeAvailability(status).toJson()];
    } else if (path == 'exam_questions') {
      body = [
        for (var n = 1; n <= 100; n++)
          {
            'question_number': n,
            'points': 1,
            'answer_type': 'multiple_choice',
            if (r.url.queryParameters['select']!.contains('correct_answer'))
              'correct_answer': 1,
          },
      ];
    } else if (path == 'answer_key_versions') {
      body = [sourceJson(null, version)];
    } else if (path == 'grade_cutoff_versions') {
      body = [
        {
          ...sourceJson(status, version),
          'minimum_scores': [90, 80, 70, 60, 50, 40, 30, 20, 0],
        },
      ];
    } else {
      throw StateError('Unexpected fixture request');
    }
    if (malformed && body is Map) {
      body = {
        ...body,
        'cutoff_source': sourceJson(
          status == 'estimated' ? 'confirmed' : 'estimated',
        ),
      };
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  late final repository = SupabaseScoringRepository(
    config,
    transport,
    owner: owner,
    token: owner == null ? null : 'offline-token',
  );
}
