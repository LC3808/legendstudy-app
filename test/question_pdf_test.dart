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
  test(
    'only the approved Hanyang question source may use originals bucket',
    () {
      const q = '4cbe8b69-2ccc-5c4e-9e77-0644f90e2cde';
      const hash =
          '4f3b87f2197a042c8abdd361584e3e03ab4bd4d15bc5341273dee27b7b6fc73b';
      final value = <String, dynamic>{
        'kind': 'student_question',
        'questionId': q,
        'assetId': hash,
        'sha256': hash,
        'pageCount': 3,
        'startPage': 2,
        'verification': 'VERIFIED',
        'studentDisplay': 'APPROVED',
        'bucket': 'essay-material-originals',
      };
      expect(
        QuestionPdfAsset.parse(value, q)?.bucket,
        'essay-material-originals',
      );
      expect(QuestionPdfAsset.parse({...value, 'assetId': 'other'}, q), isNull);
      expect(
        QuestionPdfAsset.parse({...value, 'questionId': 'other'}, 'other'),
        isNull,
      );
      expect(
        QuestionPdfAsset.parse({...value, 'bucket': 'private-evidence'}, q),
        isNull,
      );
    },
  );
}
