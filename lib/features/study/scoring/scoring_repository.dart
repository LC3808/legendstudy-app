// The public `token` parameter is intentionally copied to a private field.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import 'scoring_models.dart';

class ScoringFailure implements Exception {
  const ScoringFailure();
}

class ScoringStale implements Exception {
  const ScoringStale();
}

class ScoringPaper {
  const ScoringPaper(
    this.availability,
    this.title, {
    this.examId,
    this.subjectLabel,
    this.year,
    this.grade,
    this.month,
    this.examType,
    this.subjectCode,
    this.subjectCategory,
    this.subjectId,
    this.taxonomyVersion,
  });
  final MockScoringAvailability availability;
  final String title;
  final String? examId, subjectLabel;
  final int? year, grade, month;
  final String? examType,
      subjectCode,
      subjectCategory,
      subjectId,
      taxonomyVersion;
  String get group => switch (subjectCode) {
    'korean' => '국어',
    'math' => '수학',
    'english' => '영어',
    'korean_history' => '한국사',
    _ => ['사회탐구', '과학탐구', '통합'].contains(subjectCategory) ? '탐구' : '기타',
  };
  String get examIdentity => examId ?? availability.examSubjectId;
}

abstract interface class ScoringRepository {
  String? get owner;
  Future<List<ScoringPaper>> availablePapers();
  Future<AnswerDraft> prepare(MockScoringAvailability availability);
  Future<ScoreResult> submit(ScoringAttempt attempt);
}

class SupabaseScoringRepository implements ScoringRepository {
  SupabaseScoringRepository(
    this.config,
    this.transport, {
    this.owner,
    String? token,
  }) : _token = token;
  factory SupabaseScoringRepository.bind(
    SupabaseClient? client,
    AppConfig config,
    http.Client transport,
  ) {
    final session = client?.auth.currentSession;
    return SupabaseScoringRepository(
      config,
      transport,
      owner: session?.user.id,
      token: session?.accessToken,
    );
  }
  final AppConfig config;
  final http.Client transport;
  @override
  final String? owner;
  final String? _token;
  Future<dynamic> _request(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    if (config.validationErrors.isNotEmpty) throw const ScoringFailure();
    final uri = Uri.parse(
      '${config.supabaseUrl.replaceFirst(RegExp(r'/$'), '')}/rest/v1/$path',
    ).replace(queryParameters: query);
    final request = http.Request(body == null ? 'GET' : 'POST', uri)
      ..followRedirects = false;
    request.headers.addAll({
      'apikey': config.supabasePublishableKey,
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await transport.send(request).timeout(const Duration(seconds: 20)),
    ).timeout(const Duration(seconds: 20));
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      if (response.statusCode == 400 &&
          decoded is Map &&
          decoded['code'] == '23514' &&
          [
            'KEY_UNAVAILABLE',
            'CUTOFF_UNAVAILABLE',
          ].contains(decoded['message'])) {
        throw const ScoringStale();
      }
      throw const ScoringFailure();
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> _rows(
    String path,
    Map<String, String> query,
  ) async => ((await _request(path, query: query)) as List)
      .map((v) => Map<String, dynamic>.from(v as Map))
      .toList();
  Future<void> _current(MockScoringAvailability a) async {
    final rows = await _rows('mock_exam_scoring_availability', {
      'select': '*',
      'exam_subject_id': 'eq.${a.examSubjectId}',
      'paper_variant': 'eq.${a.paperVariant}',
      'limit': '2',
    });
    if (rows.length != 1 ||
        rows.single['answer_key_version_id'] != a.answerKeyVersionId ||
        rows.single['grade_cutoff_version_id'] != a.gradeCutoffVersionId ||
        rows.single['availability'] != 'scoring_available') {
      throw const ScoringStale();
    }
  }

  @override
  Future<List<ScoringPaper>> availablePapers() async {
    final rows = await _rows('mock_exam_scoring_availability', {
      'select': '*',
      'availability': 'eq.scoring_available',
      'order': 'exam_subject_id,paper_variant',
      'limit': '100',
    });
    if (rows.isEmpty) return [];
    final ids = rows.map((r) => r['exam_subject_id'] as String).toSet();
    final titles = await _rows('exam_subjects', {
      'select': 'id,content_item_id,raw_subject_label,subject_id,taxonomy_version,subjects(name,code,category),exams(year,grade_level,exam_month,exam_type,content_items(title))',
      'id': 'in.(${ids.join(',')})',
      'limit': '100',
    });
    final metadata = {for (final row in titles) row['id'] as String: row};
    return rows
        .map((r) {
          final a = MockScoringAvailability.fromJson(r);
          final row = metadata[a.examSubjectId];
          final parent = (row?['exams'] as Map?)?['content_items'];
          final title = parent is Map ? parent['title'] : null;
          final subject = row?['subjects'] as Map?;
          final label = subject?['name'] ?? row?['raw_subject_label'];
          // Display context is joined by identity, never guessed from exam title.
          if (row?['content_item_id'] is! String ||
              title is! String ||
              title.trim().isEmpty ||
              label is! String ||
              label.trim().isEmpty) {
            throw const ScoringFailure();
          }
          return ScoringPaper(
            a,
            title,
            examId: row!['content_item_id'] as String,
            subjectLabel: label,
            year: (row['exams'] as Map?)?['year'] as int?,
            grade: (row['exams'] as Map?)?['grade_level'] as int?,
            month: (row['exams'] as Map?)?['exam_month'] as int?,
            examType: (row['exams'] as Map?)?['exam_type'] as String?,
            subjectCode: subject?['code'] as String?,
            subjectCategory: subject?['category'] as String?,
            subjectId: row['subject_id'] as String?,
            taxonomyVersion: row['taxonomy_version'] as String?,
          );
        })
        .where(
          (p) =>
              ['national_mock', 'evaluation_mock', 'csat'].contains(p.examType),
        )
        .toList();
  }

  @override
  Future<AnswerDraft> prepare(MockScoringAvailability a) async {
    await _current(a);
    final rows = await _rows('exam_questions', {
      'select': 'question_number,answer_type,points',
      'answer_key_version_id': 'eq.${a.answerKeyVersionId}',
      'order': 'question_number',
      'limit': '101',
    });
    return AnswerDraft(a, rows.map(AnswerEntryQuestion.fromJson).toList());
  }

  @override
  Future<ScoreResult> submit(ScoringAttempt attempt) async {
    final a = attempt.draft.availability;
    if (owner == null) {
      await _current(a);
      final questions = await _rows('exam_questions', {
        'select': 'question_number,correct_answer,points',
        'answer_key_version_id': 'eq.${a.answerKeyVersionId}',
        'order': 'question_number',
        'limit': '101',
      });
      final keys = await _rows('answer_key_versions', {
        'select': 'version,source_name,source_url,verified_at',
        'id': 'eq.${a.answerKeyVersionId}',
        'limit': '2',
      });
      scoringCheck(keys.length == 1);
      final keySource = ScoringSource.fromJson(keys.single);
      scoringCheck(keySource.version == a.answerKeyVersion);
      ScoringSource? cutoffSource;
      List<int>? cutoffs;
      var certainty = 'unavailable';
      if (a.gradeCutoffVersionId != null) {
        final rows = await _rows('grade_cutoff_versions', {
          'select': 'minimum_scores,certainty,basis,version,source_name,source_url,verified_at',
          'id': 'eq.${a.gradeCutoffVersionId}',
          'limit': '2',
        });
        scoringCheck(rows.length == 1);
        cutoffs = (rows.single['minimum_scores'] as List).cast<int>();
        certainty = rows.single['certainty'] as String;
        cutoffSource = ScoringSource.fromJson(rows.single);
      }
      final score = scoreMcq5(
        questions
            .map(
              (q) => [
                q['question_number'] as int,
                q['correct_answer'] as int,
                q['points'] as int,
              ],
            )
            .toList(),
        attempt.draft.answers,
        minimumScores: cutoffs,
        certainty: certainty,
      );
      scoringCheck(
        score.maxScore == a.maxScore && score.answers.length == a.questionCount,
      );
      return score.withSources(keySource, cutoffSource);
    }
    // Do not pre-check current here: historical idempotent retry must reach RPC.
    final submitted = Map<String, dynamic>.from(
      await _request('rpc/submit_mock_attempt', body: attempt.payload()) as Map,
    );
    final fetched = Map<String, dynamic>.from(
      await _request(
        'rpc/fetch_own_mock_attempt',
        body: {'p_attempt_id': attempt.id},
      ) as Map,
    );
    final first = _validate(submitted, attempt),
        confirmed = _validate(fetched, attempt);
    scoringCheck(jsonEncode(first.toJson()) == jsonEncode(confirmed.toJson()));
    return confirmed;
  }

  ScoreResult _validate(Map<String, dynamic> row, ScoringAttempt attempt) {
    final a = attempt.draft.availability;
    scoringCheck(
      row['id'] == attempt.id &&
          row['user_id'] == owner &&
          row['answer_key_version_id'] == a.answerKeyVersionId &&
          row['grade_cutoff_version_id'] == a.gradeCutoffVersionId &&
          row['exam_subject_id'] == a.examSubjectId &&
          row['paper_variant'] == a.paperVariant &&
          row['scoring_version'] == a.scoringVersion &&
          (row['study_session_id'] == attempt.studyId ||
              row['study_session_id'] == null),
    );
    final score = ScoreResult.fromJson(row);
    scoringCheck(
      score.keySource != null &&
          score.keySource!.version == a.answerKeyVersion &&
          (a.gradeCutoffVersionId == null
              ? score.gradeStatus == 'unavailable' && score.cutoffSource == null
              : score.cutoffSource != null && score.hasGradeBasis),
    );
    scoringCheck(
      score.answers.length == a.questionCount && score.maxScore == a.maxScore,
    );
    for (var i = 0; i < score.answers.length; i++) {
      final raw = (row['answers'] as List)[i] as Map;
      scoringCheck(
        raw['attempt_id'] == attempt.id &&
            raw['answer_key_version_id'] == a.answerKeyVersionId &&
            score.answers[i].submitted == attempt.draft.answers[i],
      );
    }
    return score;
  }
}
