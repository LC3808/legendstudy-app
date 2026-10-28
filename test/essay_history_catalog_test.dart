import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';

void main() {
  final university = {
    'name': '서강대학교',
    'sourceUniversityId': 'sogang',
    'universityId': 'u',
  };
  final run = <String, dynamic>{
    'id': 'run',
    'exam_id': 'exam',
    'university': '서강대학교',
    'state': 'completed',
    'question_ids': ['q1', 'q2'],
    'answers': [
      {'questionId': 'q1', 'body': '첫 답안'},
      {'questionId': 'q2', 'body': '둘째 답안'},
    ],
    'parent_id': null,
    'free_rewrite_available': true,
  };
  final exam = <String, dynamic>{
    'dbExamId': 'exam',
    'sourceUniversityId': 'sogang',
    'verification': 'REVIEW_REQUIRED',
    'evaluationReady': false,
    'questions': [
      {'dbQuestionId': 'q1', 'label': '1번'},
      {'dbQuestionId': 'q2', 'label': '2번'},
      {'dbQuestionId': 'other', 'label': '다른 문항'},
    ],
  };
  Future<SourceCatalog> load(String? source) async => SourceCatalog(
    [university],
    source == null
        ? []
        : [
            exam,
            {...exam, 'dbExamId': 'unrelated'},
          ],
  );
  test(
    'owned history restores an absent public exam, exact frozen subset only',
    () async {
      final c = await SourceCatalog.forHistory(run, load);
      expect(c.exams.length, 1);
      expect(c.exams.single['historyRunId'], 'run');
      expect(c.exams.single['evaluationReady'], false);
      expect(c.exams.single['verification'], 'REVIEW_REQUIRED');
      expect(
        (c.exams.single['questions'] as List).map((q) => q['dbQuestionId']),
        ['q1', 'q2'],
      );
      expect(run['free_rewrite_available'], true);
      expect((run['answers'] as List).first['body'], '첫 답안');
    },
  );
  test('unknown university, missing IDs, duplicate answers and failure do not restore', () async {
    for (final patch in <Map<String, dynamic>>[
      {'university': 'unknown'},
      {
        'question_ids': ['q1', 'missing'],
      },
      {
        'answers': [
          {'questionId': 'q1', 'body': 'a'},
          {'questionId': 'q1', 'body': 'b'},
        ],
      },
      {'state': 'failed'},
      {'universityId': 'wrong'},
    ]) {
      await expectLater(
        SourceCatalog.forHistory({...run, ...patch}, load),
        throwsFormatException,
      );
    }
  });
  test('metadata failure and ambiguous university fail closed', () async {
    await expectLater(
      SourceCatalog.forHistory(
        run,
        (source) async => SourceCatalog(
          [university],
          [exam],
          browseUnavailable: source != null,
        ),
      ),
      throwsFormatException,
    );
    await expectLater(
      SourceCatalog.forHistory(
        run,
        (source) async => SourceCatalog([university, university], [exam]),
      ),
      throwsFormatException,
    );
  });
}
