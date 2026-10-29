import 'math_exam_session.dart';
import 'source_catalog.dart';
import 'evaluation_report.dart';
import 'exam_presentation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';

class SharedEssayRecord {
  const SharedEssayRecord({
    required this.id,
    required this.math,
    this.exam = false,
    this.examData = const {},
    required this.at,
    required this.rewrite,
    required this.evaluations,
  });
  final Map<String, dynamic> examData;
  String get title =>
      examData['university'] as String? ?? (math ? '수리논술' : '논술');
  String get examLabel =>
      (examData['displayExam'] as String? ?? examData['title'] as String? ?? '')
          .replaceAll('admission', '수시 논술')
          .replaceAll('mock', '모의논술')
          .replaceAll(title, '')
          .trim();
  final String id;
  final bool math, rewrite, exam;
  final DateTime at;
  final List<Map<String, dynamic>> evaluations;
}

/// Same canonical sources as Web MY. Each source is bounded to the latest 50;
/// no derived score, copied history DB, artifact URL, or service credential.
class SharedEssayHistory {
  SharedEssayHistory(this.client, this.owner);
  final SupabaseClient client;
  final String owner;
  void checkOwner() {
    if (client.auth.currentUser?.id != owner ||
        client.auth.currentSession?.isExpired != false) {
      throw StateError('ACCOUNT_CHANGED');
    }
  }

  Future<Map<String, dynamic>> mathRead(
    String action,
    Map<String, Object> payload,
  ) async {
    checkOwner();
    final data = await client.rpc<dynamic>(
      'math_input',
      params: {
        'p_request': {
          'dto_version': 'math-input-v1',
          'action': action,
          'payload': payload,
        },
      },
    );
    checkOwner();
    if (data is! Map ||
        data['dto_version'] != 'math-input-v1' ||
        data['action'] != action ||
        data['result'] is! Map) {
      throw const FormatException('INVALID_RESPONSE');
    }
    return Map<String, dynamic>.from(data['result'] as Map);
  }

  Future<List<SharedEssayRecord>> read() async {
    checkOwner();
    final results = await Future.wait<Object>([
      mathRead('history', {'limit': 50}),
      client
          .from('essay_attempts')
          .select(
            'id,attempt_no,submitted_at,session:essay_practice_sessions!inner(user_id),'
            'essay_evaluations(id,status,requested_at,invalidated_at)',
          )
          .eq('session.user_id', owner)
          .order('submitted_at', ascending: false)
          .order(
            'requested_at',
            referencedTable: 'essay_evaluations',
            ascending: false,
          )
          .limit(20, referencedTable: 'essay_evaluations')
          .limit(50),
    ]);
    checkOwner();
    final legacy = parseSharedHistory(
      results[0] as Map<String, dynamic>,
      results[1] as List,
    );
    final exams = await examRuns();
    final mathData = await client.rpc<dynamic>('math_session_history');
    checkOwner();
    if (mathData is! Map ||
        mathData['version'] != 'math-session-history-v1' ||
        mathData['runs'] is! List) {
      throw const FormatException('MATH_HISTORY');
    }
    final mathRuns = (mathData['runs'] as List).map(parseMathSession).toList();
    final covered = mathRuns
        .expand((r) => (r['questions'] as List).map((q) => q['attempt_id']))
        .toSet();
    SourceCatalog? catalog;
    if (exams.isNotEmpty || mathRuns.isNotEmpty) {
      try {
        catalog = await SourceCatalog.load(
          accessToken: client.auth.currentSession?.accessToken,
        );
      } catch (_) {
        /* Stored title is the fallback. */
      }
      checkOwner();
      if (catalog != null) {
        // The base catalog does not contain every Registry exam. Resolve only
        // universities represented by owned history, using the existing browse
        // policy. UUID sort order is never an official question number.
        final universities = catalog.universities.where(
          (u) => exams.any((r) => r['university'] == u['name']),
        );
        for (final university in universities.toList()) {
          final source = university['sourceUniversityId'] as String;
          try {
            final raw = await client.rpc<dynamic>(
              'essay_browse_catalog',
              params: {'p_university': source},
            );
            checkOwner();
            catalog = catalog!.withRegistered(source, raw);
          } catch (_) {
            checkOwner(); // Retain stored history when metadata is unavailable.
          }
        }
      }
    }
    Map<String, dynamic> metadata(Map<String, dynamic> r) {
      final e = catalog?.exams
          .where((e) => e['dbExamId'] == r['exam_id'])
          .firstOrNull;
      final university = e == null
          ? r['university']
          : catalog?.universities
                    .where(
                      (u) => u['sourceUniversityId'] == e['sourceUniversityId'],
                    )
                    .firstOrNull?['name'] ??
                r['university'];
      return {
        ...r,
        if (e != null) 'university': university,
        if (e != null)
          'displayExam': essayHistoryExamTitle({
            ...e,
            'universityName': university,
          }),
        if (e != null) 'questions': e['questions'],
        if (e != null) 'track': e['track'],
        if (e != null) 'session': e['session'],
      };
    }

    final records = [
      ...legacy.where((r) => !r.math || !covered.contains(r.id)),
      for (final r in mathRuns)
        SharedEssayRecord(
          id: r['run_id'] as String,
          math: true,
          examData: {...metadata(r), 'mathSession': r},
          at: DateTime.parse(r['created_at'] as String),
          rewrite: r['parent_id'] != null,
          evaluations: [
            for (final q in r['questions'] as List)
              {
                'id': q['evaluation_id'],
                'state': q['state'],
                'question_id': q['question_id'],
              },
          ],
        ),
      for (final r in exams)
        SharedEssayRecord(
          id: r['id'] as String,
          math: false,
          exam: true,
          examData: metadata(r),
          at: DateTime.parse(r['created_at'] as String),
          rewrite: r['parent_id'] != null,
          evaluations: [
            for (final q in r['question_ids'] as List)
              {
                'id': '${r['id']}/$q',
                'state': r['state'] == 'reserved'
                    ? 'UNKNOWN'
                    : (r['state'] as String).toUpperCase(),
              },
          ],
        ),
    ];
    records.sort((a, b) => b.at.compareTo(a.at));
    return numberEssayLearningRounds(records);
  }

  Future<({EvaluationReport report, EvaluationReport? before})>
  evaluationReport(bool math, String id, {bool exam = false}) async {
    checkOwner();
    if (exam) {
      final parts = id.split('/');
      if (parts.length != 2) throw const FormatException('INVALID_EXAM_ID');
      final rows = await examRuns(parts[0]);
      if (rows.length != 1) throw StateError('READ_FAILED');
      var row = rows.single;
      if (row['state'] == 'reserved') {
        final result = await client.rpc<dynamic>(
          'essay_exam_question_result',
          params: {'p_run': parts[0], 'p_question': parts[1]},
        );
        checkOwner();
        if (result is! Map ||
            result['id'] != parts[0] ||
            (result['state'] != 'completed' &&
                (result['result_scope'] != 'completed_question' ||
                    result['question_state'] != 'completed'))) {
          throw const FormatException('INVALID_PARTIAL_RESULT');
        }
        row = Map<String, dynamic>.from(result);
      }
      final report = examEvaluationReport(row, parts[1]);
      EvaluationReport? before;
      if (row['parent_id'] is String) {
        final prior = await examRuns(row['parent_id'] as String);
        if (prior.length == 1) {
          before = examEvaluationReport(prior.single, parts[1]);
        }
      }
      return (report: report, before: before);
    }
    if (math) {
      final wire = await mathRead('read_result', {'evaluation_id': id});
      final report = mathEvaluationReport(wire);
      final before = report.priorId == null
          ? null
          : mathEvaluationReport(
              await mathRead('read_result', {'evaluation_id': report.priorId!}),
            );
      checkOwner();
      return (report: report, before: before);
    }
    const projection =
        'id,attempt_id,session_id,question_id,regime_key,contract_version,evidence_completeness,input_snapshot,overall_summary,strengths,rewrite_checklist,'
        'attempt:essay_attempts!essay_evaluations_attempt_id_session_id_fkey(body,attempt_no,mode,conditions_snapshot,question_metadata_version),'
        'essay_improvement_progress(title,explanation,next_action,status),'
        'essay_evaluation_dimensions(criterion_id,display_order,level_1_to_5,explanation,essay_evaluation_criteria(label,definition_version)),'
        'session:essay_practice_sessions!inner(user_id,essay_questions(label))';
    final row = await client
        .from('essay_evaluations')
        .select(projection)
        .eq('id', id)
        .eq('session.user_id', owner)
        .eq('status', 'completed')
        .isFilter('invalidated_at', null)
        .single();
    checkOwner();
    EvaluationReport? before;
    if (evaluationObject(row['attempt'])['attempt_no'] != 1) {
      final initial = await client
          .from('essay_attempts')
          .select('id')
          .eq('session_id', row['session_id'] as String)
          .eq('attempt_no', 1)
          .maybeSingle();
      checkOwner();
      if (initial != null) {
        final rows = await client
            .from('essay_evaluations')
            .select(projection)
            .eq('attempt_id', initial['id'] as String)
            .eq('session.user_id', owner)
            .eq('status', 'completed')
            .isFilter('invalidated_at', null)
            .order('completed_at')
            .limit(1);
        checkOwner();
        if (rows.isNotEmpty) before = humanEvaluationReport(rows.first);
      }
    }
    return (
      report: humanEvaluationReport(row, priorId: before?.id),
      before: before,
    );
  }

  Future<List<Map<String, dynamic>>> examRuns([String? id]) async {
    checkOwner();
    if (id == null) {
      final rows = <Map<String, dynamic>>[];
      final ids = <String>{};
      Map<String, dynamic>? cursor;
      try {
        do {
          final page = await client.rpc<dynamic>(
            'essay_exam_history_page',
            params: {
              'p_before_at': cursor?['at'],
              'p_before_id': cursor?['id'],
              'p_limit': 50,
            },
          );
          checkOwner();
          if (page is! Map ||
              page['version'] != 'essay-exam-history-page-v1' ||
              page['runs'] is! List) {
            throw const FormatException('INVALID_HISTORY_PAGE');
          }
          for (final value in page['runs'] as List) {
            final row = Map<String, dynamic>.from(value as Map);
            if (row['id'] is! String || !ids.add(row['id'] as String)) {
              throw const FormatException('REPEATED_HISTORY_PAGE');
            }
            rows.add(row);
          }
          final next = page['next'];
          if (next != null &&
              ((page['runs'] as List).isEmpty ||
                  next is! Map ||
                  next['id'] == cursor?['id'])) {
            throw const FormatException('INVALID_HISTORY_CURSOR');
          }
          cursor = next == null ? null : Map<String, dynamic>.from(next as Map);
        } while (cursor != null);
        return rows;
      } on PostgrestException catch (e) {
        if (e.code != 'PGRST202' || rows.isNotEmpty) rethrow;
        // Older deployments stay usable, but never pretend 50 rows is complete.
      }
    }
    dynamic data;
    try {
      data = await client.rpc<dynamic>(
        'essay_exam_history',
        params: {'p_run': id},
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' && id == null) return [];
      rethrow;
    }
    checkOwner();
    if (data is! Map ||
        data['version'] != 'essay-exam-history-v1' ||
        data['runs'] is! List) {
      throw const FormatException('INVALID_RESPONSE');
    }
    return (data['runs'] as List)
        .map(
          (r) => <String, dynamic>{
            ...Map<String, dynamic>.from(r as Map),
            if (id == null && (data['runs'] as List).length == 50)
              '_historyTruncated': true,
          },
        )
        .toList();
  }

  Future<String> evaluationText(bool math, String id) async {
    checkOwner();
    if (math) {
      final value = await mathRead('read_result', {'evaluation_id': id});
      final output = value['output'] as Map?;
      return output?['overall']?['explanation'] as String? ?? '평가 설명이 없습니다.';
    }
    final row = await client
        .from('essay_evaluations')
        .select(
          'overall_summary,session:essay_practice_sessions!inner(user_id)',
        )
        .eq('id', id)
        .eq('session.user_id', owner)
        .eq('status', 'completed')
        .isFilter('invalidated_at', null)
        .single();
    checkOwner();
    return row['overall_summary'] as String? ?? '평가 설명이 없습니다.';
  }
}

List<SharedEssayRecord> parseSharedHistory(
  Map<String, dynamic> math,
  List<dynamic> essays,
) {
  if (math['attempts'] is! List) {
    throw const FormatException('INVALID_RESPONSE');
  }
  final records = <SharedEssayRecord>[
    for (final a in math['attempts'] as List)
      SharedEssayRecord(
        id: a['attempt_id'] as String,
        math: true,
        at: DateTime.parse(a['created_at'] as String),
        rewrite: a['predecessor_id'] != null,
        evaluations: [
          for (final e in a['evaluations'] as List)
            {'id': e['evaluation_id'], 'state': e['state']},
        ],
      ),
    for (final a in essays)
      SharedEssayRecord(
        id: a['id'] as String,
        math: false,
        at: DateTime.parse(a['submitted_at'] as String),
        rewrite: (a['attempt_no'] as int) > 1,
        evaluations: [
          for (final e in a['essay_evaluations'] as List)
            if (e['invalidated_at'] == null)
              {'id': e['id'], 'state': (e['status'] as String).toUpperCase()},
        ],
      ),
  ];
  records.sort((a, b) => b.at.compareTo(a.at));
  return records;
}

final sharedEssayHistoryProvider = FutureProvider.autoDispose
    .family<List<SharedEssayRecord>, String>((ref, owner) async {
      final auth = ref.watch(authStateProvider);
      if (auth.isLoading || auth.hasError || auth.value?.userId != owner) {
        throw StateError('ACCOUNT_UNAVAILABLE');
      }
      final client = ref.watch(supabaseClientProvider);
      if (client == null) throw StateError('UNAVAILABLE');
      return SharedEssayHistory(client, owner).read();
    });

/// Learning presentation joins canonical exam/question sets, never billing rows.
List<List<SharedEssayRecord>> groupEssayHistory(List<SharedEssayRecord> rows) {
  final groups = <String, List<SharedEssayRecord>>{};
  for (final row in rows) {
    final exam = row.examData['exam_id'];
    final key = row.exam && exam is String && exam.isNotEmpty
        ? 'exam:$exam'
        : essayExamGroupKey(row);
    groups.putIfAbsent(key, () => []).add(row);
  }
  for (final group in groups.values) {
    group.sort((a, b) {
      final time = a.at.compareTo(b.at);
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
  }
  final result = groups.values.toList()
    ..sort(
      (a, b) => essayCompletedAt(b.last).compareTo(essayCompletedAt(a.last)),
    );
  return result;
}

/// Presentation grouping is not financial lineage. Missing IDs stay independent.
String essayExamGroupKey(SharedEssayRecord row) {
  final exam = row.examData['exam_id'];
  final questions = row.examData['question_ids'];
  if (!row.exam || exam is! String || questions is! List || questions.isEmpty) {
    return '${row.math}:${row.examData['parent_id'] ?? row.id}';
  }
  return '$exam:${(questions.cast<String>().toList()..sort()).join(',')}';
}

DateTime essayCompletedAt(SharedEssayRecord row) =>
    DateTime.tryParse(row.examData['completed_at'] as String? ?? '') ?? row.at;

/// Derived only after the full owner-scoped read; failed requests are not rounds.
List<SharedEssayRecord> numberEssayLearningRounds(
  List<SharedEssayRecord> rows,
) {
  final numbers = <String, int>{};
  for (final group in groupEssayHistory(rows)) {
    if (group.any((r) => r.examData['_historyTruncated'] == true)) continue;
    var round = 0;
    for (final row in group) {
      if (row.exam && row.examData['state'] == 'completed') {
        numbers[row.id] = ++round;
      }
    }
  }
  return [
    for (final row in rows)
      SharedEssayRecord(
        id: row.id,
        math: row.math,
        exam: row.exam,
        at: row.at,
        rewrite: row.rewrite,
        evaluations: row.evaluations,
        examData: {
          ...row.examData,
          if (numbers[row.id] != null) 'learning_round': numbers[row.id],
        },
      ),
  ];
}

String essayHistoryType(SharedEssayRecord row) {
  final round = row.examData['learning_round'];
  if (round is int) return round == 1 ? '첫 첨삭' : '$round차 첨삭';
  if (row.exam) return '첨삭 기록';
  return row.rewrite ? '재첨삭' : '최초 첨삭';
}

String essayBillingType(SharedEssayRecord row) =>
    row.examData['parent_id'] != null ? '무료 재첨삭' : 'Credit 첨삭';
String essayAnswerVersion(SharedEssayRecord row) {
  final number = row.examData['submission_index'];
  if (number is int && number > 0) {
    return number == 1 ? '최초 제출 답안' : '수정 제출 답안 ${number - 1}';
  }
  // Old independent runs do not carry a verified global submission sequence.
  return row.rewrite ? '수정 제출 답안' : '최초 제출 답안';
}

/// Only canonical Registry metadata can supply an official question label.
/// History question_ids are UUID-sorted, not an official display order.
String essayExamQuestionLabel(SharedEssayRecord row, String questionId) {
  final questions = (row.examData['questions'] as List?)
      ?.cast<Map<String, dynamic>>();
  final label = questions
      ?.where((q) => q['dbQuestionId'] == questionId)
      .firstOrNull?['label'];
  return label is String && label.isNotEmpty ? label : '문항';
}

List<List<SharedEssayRecord>> sortedEssayHistory(
  List<SharedEssayRecord> rows,
  bool byExam,
) {
  final sorted = [...rows]
    ..sort((a, b) {
      final time = essayCompletedAt(b).compareTo(essayCompletedAt(a));
      return time != 0 ? time : b.id.compareTo(a.id);
    });
  if (!byExam) return sorted.map((r) => [r]).toList();
  final groups = <String, List<SharedEssayRecord>>{};
  for (final row in sorted) {
    groups.putIfAbsent(essayExamGroupKey(row), () => []).add(row);
  }
  return groups.values.toList();
}

/// Learning sequence is independent of whether a Credit was charged.
bool essayIsFollowup(SharedEssayRecord row) =>
    (row.examData['learning_round'] is int &&
        (row.examData['learning_round'] as int) > 1) ||
    row.rewrite ||
    row.examData['parent_id'] != null ||
    row.examData['previous_paid_run_id'] != null;

String essayShortDate(SharedEssayRecord row) {
  final d = essayCompletedAt(row).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

/// Stable projection in Registry order. Unknown metadata retains source order.
List<Map<String, dynamic>> orderedEssayEvaluations(SharedEssayRecord row) {
  final questions = row.examData['questions'] as List? ?? const [];
  final order = <String, int>{
    for (final (i, q) in questions.indexed)
      if (q is Map && q['dbQuestionId'] is String)
        q['dbQuestionId'] as String: i,
  };
  final indexed = row.evaluations.indexed.toList();
  indexed.sort((a, b) {
    String id(Map<String, dynamic> e) =>
        '${e['question_id'] ?? e['id']}'.split('/').last;
    final compared = (order[id(a.$2)] ?? questions.length).compareTo(
      order[id(b.$2)] ?? questions.length,
    );
    return compared == 0 ? a.$1.compareTo(b.$1) : compared;
  });
  return indexed.map((e) => e.$2).toList();
}

/// A truncated history is not evidence that an independent paid run was first.
bool essayHistoryMatchesKind(SharedEssayRecord row, String kind) {
  if (kind == 'all') return true;
  if (essayIsFollowup(row)) return kind == 'rewrite';
  if (row.exam &&
      row.examData['_historyTruncated'] == true &&
      row.examData['learning_round'] != 1) {
    return false;
  }
  return kind == 'initial';
}
