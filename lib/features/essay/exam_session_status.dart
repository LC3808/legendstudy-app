import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'essay_live_gateway.dart';
import 'exam_submission.dart';
import 'shared_history.dart';
import 'source_draft.dart';

/// Reads the shared server contract; never infers a free retry from a failure.
class ExamSessionStatus {
  ExamSessionStatus(this.data) {
    if (data['version'] != 'exam-session-v1' || data['questions'] is! List) {
      throw const FormatException('INVALID_EXAM_STATUS');
    }
    final ids = <String>{};
    for (final q in data['questions'] as List) {
      if (q is! Map ||
          q['question_id'] is! String ||
          q['state'] is! String ||
          !ids.add(q['question_id'] as String)) {
        throw const FormatException('INVALID_QUESTION_STATUS');
      }
    }
  }
  final Map<String, dynamic> data;
  Map<String, String> get questions => {
    for (final q in data['questions'] as List)
      q['question_id'] as String: q['state'] as String,
  };
  bool get hasFailure => questions.values.contains('failed');
  bool get canRetry =>
      data['state'] == 'reserved' &&
      data['retry_allowed'] == true &&
      hasFailure &&
      questions.values.every((s) => s == 'completed' || s == 'failed');
  bool get terminal =>
      data['state'] == 'completed' || data['state'] == 'failed';
  String get retryExplanation => canRetry
      ? '완료된 문항의 결과는 보존됩니다. 실패한 문항만 추가 Credit 없이 다시 처리합니다.'
      : questions.values.any((s) => s != 'completed' && s != 'failed')
      ? '다른 문항의 처리가 끝난 뒤 재처리 가능 여부를 확인할 수 있어요.'
      : '현재 서버에서 재처리를 허용하지 않습니다. 기존 답안과 결과는 보존됩니다.';
  String get fingerprint => jsonEncode(data);
}

Future<ExamSessionStatus> readExamSessionStatus(
  SupabaseClient client,
  String owner,
  String run,
) async {
  final history = SharedEssayHistory(client, owner)..checkOwner();
  final value = await client
      .rpc<dynamic>('essay_exam_session_status', params: {'p_run': run})
      .timeout(const Duration(seconds: 10));
  history.checkOwner();
  if (value is! Map) throw const FormatException('INVALID_EXAM_STATUS');
  if (value['run_id'] != null && value['run_id'] != run) {
    throw const FormatException('EXAM_STATUS_IDENTITY');
  }
  return ExamSessionStatus(Map<String, dynamic>.from(value));
}

/// Same durable key across history/progress/re-entry. The server selects failed
/// questions and fences concurrent dispatch; this never submits a new run.
Future<void> retryExistingExam({
  required SupabaseClient client,
  required ExamSubmissionGateway gateway,
  required String owner,
  required String run,
  required String exam,
}) async {
  final status = await readExamSessionStatus(client, owner, run);
  if (status.data['exam_id'] != null && status.data['exam_id'] != exam) {
    throw const FormatException('EXAM_STATUS_IDENTITY');
  }
  if (!status.canRetry) throw StateError(status.retryExplanation);
  final store = SourceDraftGateway(owner, 'round-retry:$run');
  final saved = await store.loadDraft();
  final key = saved.body.isEmpty
      ? newEssayUuid()
      : (jsonDecode(saved.body) as Map)['key'] as String;
  if (saved.body.isEmpty) {
    await store.saveLocalDraft(jsonEncode({'key': key}), saved.revision);
  }
  SharedEssayHistory(client, owner).checkOwner();
  final result = await gateway.request({
    'action': 'retry',
    'examId': exam,
    'runId': run,
    'key': key,
  });
  SharedEssayHistory(client, owner).checkOwner();
  if (result['runId'] != run) {
    throw const FormatException('RETRY_NOT_CONFIRMED');
  }
  final current = await store.loadDraft();
  if (current.body == jsonEncode({'key': key})) {
    await store.saveLocalDraft('', current.revision);
  }
}
