import 'source_catalog.dart';
import 'evaluation_report.dart';

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
          .replaceAll('mock', '모의논술');
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
    SourceCatalog? catalog;
    if (exams.isNotEmpty) {
      try {
        catalog = await SourceCatalog.load(
          accessToken: client.auth.currentSession?.accessToken,
        );
      } catch (_) {
        /* Stored title is the fallback. */
      }
      checkOwner();
    }
    Map<String, dynamic> metadata(Map<String, dynamic> r) {
      final e = catalog?.exams
          .where((e) => e['dbExamId'] == r['exam_id'])
          .firstOrNull;
      return {
        ...r,
        if (e != null)
          'displayExam':
              '${e['year']}학년도 ${e['kind'] == 'admission'
                  ? '수시 논술'
                  : e['kind'] == 'mock'
                  ? '모의논술'
                  : e['kind']} · ${e['track']}${e['session'] == null ? '' : ' · ${e['session']}'}',
        if (e != null) 'questions': e['questions'],
      };
    }

    final records = [
      ...legacy,
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
                    ? 'PROCESSING'
                    : (r['state'] as String).toUpperCase(),
              },
          ],
        ),
    ];
    records.sort((a, b) => b.at.compareTo(a.at));
    return records;
  }

  Future<({EvaluationReport report, EvaluationReport? before})>
  evaluationReport(bool math, String id, {bool exam = false}) async {
    checkOwner();
    if (exam) {
      final parts = id.split('/');
      if (parts.length != 2) throw const FormatException('INVALID_EXAM_ID');
      final rows = await examRuns(parts[0]);
      if (rows.length != 1) throw StateError('READ_FAILED');
      final row = rows.single;
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
        .map((r) => Map<String, dynamic>.from(r as Map))
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

/// Group only explicit parent lineage; independent submissions never merge by exam.
List<List<SharedEssayRecord>> groupEssayHistory(List<SharedEssayRecord> rows) {
  final groups = <String, List<SharedEssayRecord>>{};
  for (final row in rows) {
    final root = row.exam
        ? row.examData['parent_id'] as String? ?? row.id
        : row.id;
    groups.putIfAbsent('${row.math}:$root', () => []).add(row);
  }
  for (final group in groups.values) {
    group.sort((a, b) => a.at.compareTo(b.at));
  }
  final result = groups.values.toList()
    ..sort((a, b) => b.last.at.compareTo(a.last.at));
  return result;
}
