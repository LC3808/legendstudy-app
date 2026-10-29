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
