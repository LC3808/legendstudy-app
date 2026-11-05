import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/exam_service_state.dart';

void main() {
  test(
    'partial availability explains the allowed question without opening others',
    () {
      final ids = availableExamQuestionIds(
        admission: {'ready': false, 'code': 'ACCESS_DENIED'},
        standaloneMathQuestions: {'q1'},
      );
      expect(ids, {'q1'});
      final message = examServiceNoticeMessage(
        ExamServiceState.blocked,
        availableLabels: ['문제 1'],
        partialRelease: true,
      );
      expect(message, contains('현재 첨삭 가능: 문제 1'));
      expect(message, contains('가능한 문항만 선택'));
      expect(
        examServiceNoticeMessage(
          ExamServiceState.available,
          availableLabels: ['문제 1'],
          partialRelease: true,
        ),
        contains('다른 문항은 아직'),
      );
      expect(
        examServiceNoticeMessage(
          ExamServiceState.error,
          availableLabels: ['문제 1'],
          partialRelease: true,
        ),
        examServiceMessage(ExamServiceState.error),
      );
      expect(
        availableExamQuestionIds(
          admission: {'ready': false, 'code': 'MIXED_QA_PENDING'},
          standaloneMathQuestions: {'q1'},
        ),
        isEmpty,
      );
      expect(
        availableExamQuestionIds(
          policyBlocked: true,
          standaloneMathQuestions: {'q1'},
        ),
        isEmpty,
      );
    },
  );
  test(
    'mixed and changed scope holds cannot be overridden by standalone data',
    () {
      for (final code in ['MIXED_QA_PENDING', 'RELEASE_SCOPE_CHANGED']) {
        expect(
          resolveExamServiceState(
            questions: {'q'},
            admission: {'ready': false, 'code': code},
            standaloneMathQuestions: {'q'},
          ),
          ExamServiceState.blocked,
        );
      }
    },
  );
  test('server admission covers exams outside the first catalog window', () {
    expect(
      resolveExamServiceState(
        questions: {'q72'},
        admission: {
          'ready': true,
          'questionIds': ['q72'],
        },
      ),
      ExamServiceState.available,
    );
  });
  test('standalone partial release never opens the remaining questions', () {
    for (final selection in [
      <String>{},
      {'q1'},
    ]) {
      expect(
        resolveExamServiceState(
          questions: selection,
          admission: {'ready': false, 'code': 'ACCESS_DENIED'},
          standaloneMathQuestions: {'q1'},
        ),
        ExamServiceState.available,
      );
    }
    expect(
      resolveExamServiceState(
        questions: {'q1', 'q2'},
        admission: {'ready': false, 'code': 'ACCESS_DENIED'},
        standaloneMathQuestions: {'q1'},
      ),
      ExamServiceState.blocked,
    );
  });
  test('failure and loading are never described as preparing', () {
    expect(
      resolveExamServiceState(questions: {'q'}, failed: true),
      ExamServiceState.error,
    );
    expect(
      resolveExamServiceState(questions: {'q'}, loading: true),
      ExamServiceState.loading,
    );
    expect(
      resolveExamServiceState(questions: {'q'}, admission: {}),
      ExamServiceState.error,
    );
  });
  test('policy hold wins over a stale positive response', () {
    expect(
      resolveExamServiceState(
        questions: {'q'},
        admission: {
          'ready': true,
          'questionIds': ['q'],
        },
        policyBlocked: true,
      ),
      ExamServiceState.blocked,
    );
  });
  test('valid negative admission is preparing; restricted is blocked', () {
    expect(
      resolveExamServiceState(questions: {'q'}, admission: {'ready': false}),
      ExamServiceState.preparing,
    );
    expect(
      resolveExamServiceState(
        questions: {'q'},
        admission: {'ready': false, 'code': 'RELEASE_SCOPE_CHANGED'},
      ),
      ExamServiceState.blocked,
    );
  });
}
