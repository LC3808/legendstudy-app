import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';

SharedEssayRecord row(
  String id,
  String exam,
  List<String> questions, {
  String? parent,
  int? version,
}) => SharedEssayRecord(
  id: id,
  math: false,
  exam: true,
  at: DateTime(2026),
  rewrite: parent != null,
  evaluations: [],
  examData: {
    'exam_id': exam,
    'question_ids': questions,
    'parent_id': parent,
    'submission_index': version,
    'completed_at': '2026-10-${id == "b" ? "15" : "14"}T00:00:00Z',
  },
);
void main() {
  test('same labels never merge distinct IDs or question sets; completion sorts first', () {
    final a = row('a', 'exam1', ['q1', 'q2']),
        b = row('b', 'exam1', ['q2', 'q1'], parent: 'a'),
        c = row('c', 'exam2', ['q1', 'q2']),
        d = row('d', 'exam1', ['q1']);
    final groups = sortedEssayHistory([a, c, d, b], true);
    expect(groups.first.map((r) => r.id), ['b', 'a']);
    expect(groups.length, 3);
    expect(sortedEssayHistory([a, b], false).first.single.id, 'b');
    expect(essayAnswerVersion(b), '수정 제출 답안');
    expect(
      essayAnswerVersion(row('e', 'exam1', ['q1'], version: 4)),
      '수정 제출 답안 3',
    );
  });
  test('rewrite draft isolated from original and each paid cycle', () {
    expect(essayWritingDraftKey('q', null), 'q');
    expect(essayWritingDraftKey('q', {'id': 'a'}), 'q:rewrite:a');
    expect(
      essayWritingDraftKey('q', {'id': 'a', '_additional': true}),
      'q:additional:a',
    );
    expect(
      essayWritingDraftKey('q', {'id': 'b'}),
      isNot(essayWritingDraftKey('q', {'id': 'a'})),
    );
  });
}
