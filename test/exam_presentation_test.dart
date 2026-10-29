import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/exam_presentation.dart';

void main() {
  test(
    'full browse title does not repeat university year track or session',
    () {
      final exam = {
        'year': 2023,
        'kind': 'admission',
        'universityName': '건국대학교',
        'track': '2023학년도 건국대학교 수시논술 인문사회Ⅰ',
        'session': '2023학년도 건국대학교 수시논술 인문사회Ⅰ',
      };
      final before = Map.of(exam);
      expect(essayExamTitle(exam), '2023학년도 수시논술 인문사회Ⅰ');
      expect(exam, before);
      expect(
        essayExamTitle({
          'year': 2026,
          'kind': 'mock',
          'track': '인문',
          'session': '인문',
        }),
        '2026학년도 · 모의논술 · 인문',
      );
    },
  );
  test(
    'Registry track vocabulary stays separate from Math input and readiness',
    () {
      final areas = {
        EssayServiceArea.humanities: [
          '인문계열',
          '인문',
          '언어형',
          '인문·체육계',
          '인문계',
          '인문계열Ⅰ',
          '인문계열Ⅱ',
          '인문계열(일반)',
          '언어 논술',
        ],
        EssayServiceArea.socialBusiness: [
          '사회계',
          '인문계열(경제경영)',
          '인문계열(인문사회)',
          '인문사회',
          '경영경제',
          '상경계열',
          '인문사회계열',
          '인문사회Ⅰ',
          '인문사회Ⅱ',
          '사회계열',
          '경상계열',
          '인문사회(창의)',
          '경영경제(일반)',
          '경영경제(창의)',
        ],
        EssayServiceArea.science: [
          '자연계열',
          '자연',
          '의예',
          '자연계',
          '이학계열',
          '공학계열',
          '자연계열(수학)',
          '의·약학계',
          '생명과학',
          '화학',
          '자연계열(약학부)',
          '지구과학',
          '자연계열Ⅱ',
          '자연계열(B형)',
          '자연계열(일반)',
          '물리',
          '한의예·약학',
          '자연 A',
          '자연계열(약학부 제외)',
          '자연계(과학)',
          '자연 B',
          '자연계열Ⅰ',
          '자연계열(A형)',
        ],
      };
      for (final entry in areas.entries) {
        for (final track in entry.value) {
          for (final mode in ['text', 'image']) {
            expect(
              essayServiceArea({
                'track': track,
                'inputMode': mode,
                'evaluationReady': true,
              }),
              entry.key,
              reason: track,
            );
          }
        }
      }
      for (final track in [
        '수리형',
        '수학',
        'A형',
        'B형',
        '통합',
        '자유전공',
        '수리 논술',
        null,
      ]) {
        expect(
          essayServiceArea({'track': track}),
          isNull,
          reason: 'Ambiguous labels must not activate an engine.',
        );
      }
    },
  );
  test('completed question stays completed while another fails; unknown is not failed', () {
    expect(essayQuestionStatus('completed'), '완료');
    expect(essayQuestionStatus('failed'), '재처리 필요');
    expect(essayQuestionStatus('processing'), '첨삭 중');
    expect(essayQuestionStatus(null), '상태 확인 중');
    expect(essayQuestionStatus('reserved'), '상태 확인 중');
  });
}
