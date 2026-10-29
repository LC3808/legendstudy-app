import 'source_draft.dart';

/// Recover TEXT edits from the old paid entry only into an empty included draft.
/// The source is retained; image drafts and existing destination edits are untouched.
Future<bool> recoverIncludedEssayDraft(
  String owner,
  String examKey,
  String questionKey,
  Map<String, dynamic> run,
) async {
  if (run['_additional'] == true ||
      run['free_rewrite_available'] != true ||
      run['parent_id'] != null ||
      run['id'] is! String) {
    return false;
  }
  final pending = await SourceDraftGateway(
    owner,
    'exam-request:$examKey:additional:${run['id']}',
  ).loadDraft();
  if (pending.body.isNotEmpty) return false;
  final target = SourceDraftGateway(owner, '$questionKey:rewrite:${run['id']}');
  final old = await target.loadDraft();
  if (old.body.isNotEmpty || (await target.loadImages()).isNotEmpty) {
    return false;
  }
  final source = SourceDraftGateway(
    owner,
    '$questionKey:additional:${run['id']}',
  );
  final draft = await source.loadDraft();
  if (draft.body.isEmpty || (await source.loadImages()).isNotEmpty) {
    return false;
  }
  await target.saveLocalDraft(draft.body, old.revision);
  return true;
}

/// Frozen question set and parent-relative TEXT revisions, shared with the Web
/// submission contract. This does not grant eligibility or mutate a saved draft.
List<Map<String, dynamic>> examRewriteAnswers(
  List<Map<String, dynamic>> answers,
  Map<String, dynamic> parent,
) {
  final originals = (parent['answers'] as List? ?? [])
      .cast<Map<String, dynamic>>();
  final ids = (parent['question_ids'] as List? ?? []).toSet();
  final selected = answers.map((a) => a['questionId']).toSet();
  if (ids.isEmpty ||
      ids.length != answers.length ||
      selected.length != answers.length ||
      !ids.containsAll(selected) ||
      originals.length != answers.length ||
      !ids.containsAll(originals.map((a) => a['questionId'])) ||
      originals.map((a) => a['questionId']).toSet().length !=
          originals.length) {
    throw StateError('최초 제출과 같은 문항을 선택해 주세요. 답안은 보존됩니다.');
  }
  return answers.map((a) {
    final original = originals
        .where((p) => p['questionId'] == a['questionId'])
        .single;
    final revision = original['revision'];
    if (revision is! int || revision < 0 || original['body'] is! String) {
      throw StateError('이전 답안의 저장 정보를 확인하지 못했어요. 기록에서 다시 열어 주세요.');
    }
    return {
      ...a,
      'revision': revision + (original['body'] == a['body'] ? 0 : 1),
    };
  }).toList();
}
