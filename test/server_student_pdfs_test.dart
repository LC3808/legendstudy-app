import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';

void main() {
  const exam = '11111111-1111-4111-8111-111111111111';
  const q = '22222222-2222-4222-8222-222222222222';
  final pdf = <String, dynamic>{
    'examId': exam,
    'questionId': q,
    'kind': 'student_question',
    'bucket': 'essay-material-originals',
    'assetId': 'a' * 64,
    'sha256': 'a' * 64,
    'pageCount': 3,
    'startPage': 2,
    'verification': 'VERIFIED',
    'studentDisplay': 'APPROVED',
  };
  setUp(serverStudentPdfs.clear);
  test(
    'new server-approved PDF needs no embedded catalog entry, retains exact identity',
    () {
      expect(QuestionPdfAsset.parse(pdf, q), isNull);
      installServerStudentPdfs({
        'version': 'essay-student-pdfs-v1',
        'questions': [pdf],
      });
      expect(QuestionPdfAsset.parse(pdf, q)?.startPage, 2);
      expect(serverStudentPdfFor(q, q), isNull);
      expect(QuestionPdfAsset.parse({...pdf, 'assetId': 'b' * 64}, q), isNull);
    },
  );
  test(
    'invalid or duplicated manifests cannot partially replace trusted metadata',
    () {
      installServerStudentPdfs({
        'version': 'essay-student-pdfs-v1',
        'questions': [pdf],
      });
      for (final rows in [
        [pdf, pdf],
        [
          {...pdf, 'studentDisplay': 'PENDING'},
        ],
        [
          {...pdf, 'bucket': 'private-solutions'},
        ],
      ]) {
        expect(
          () => installServerStudentPdfs({
            'version': 'essay-student-pdfs-v1',
            'questions': rows,
          }),
          throwsFormatException,
        );
        expect(serverStudentPdfFor(exam, q), pdf);
      }
    },
  );
}
