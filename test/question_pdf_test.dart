import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';

void main() {
  test('shared PDF DTO accepts exact reviewed student asset only', () {
    final value = <String, dynamic>{
      'kind': 'student_question',
      'questionId': 'q',
      'assetId': 'asset-1',
      'sha256': 'a' * 64,
      'pageCount': 3,
      'startPage': 2,
      'verification': 'VERIFIED',
      'studentDisplay': 'APPROVED',
    };
    expect(QuestionPdfAsset.parse(value, 'q')?.startPage, 2);
    expect(QuestionPdfAsset.parse(value, 'other'), isNull);
    for (final invalid in [
      {'kind': 'original'},
      {'studentDisplay': 'UNVERIFIED'},
      {'assetId': '../source'},
      {'startPage': 4},
    ]) {
      expect(QuestionPdfAsset.parse({...value, ...invalid}, 'q'), isNull);
    }
  });
}
