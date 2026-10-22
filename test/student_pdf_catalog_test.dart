import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/student_pdf_catalog.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/university_catalog.dart';
import 'package:legendstudy_app/features/essay/service_availability.dart';

void main() {
  test(
    'all approved WEB mappings preserve exact question, exam, asset and page',
    () {
      expect(approvedStudentPdfs.length, 485);
      expect(
        approvedStudentPdfs.values.map((q) => q['assetId']).toSet().length,
        153,
      );
      for (final q in approvedStudentPdfs.values) {
        final dto = studentPdfFor(
          q['examId'] as String,
          q['questionId'] as String,
        )!;
        final asset = QuestionPdfAsset.parse(dto, q['questionId'] as String);
        expect(asset, isNotNull);
        expect(asset!.startPage, q['startPage']);
        expect(asset.startPage, inInclusiveRange(1, asset.pages));
        expect(studentPdfFor('wrong-exam', q['questionId'] as String), isNull);
        for (final patch in [
          {'examId': 'wrong'},
          {'assetId': 'a' * 64},
          {'sha256': 'b' * 64},
          {'startPage': asset.startPage + 1},
          {'pageCount': asset.pages + 1},
          {'studentDisplay': 'HOLD'},
          {'questionId': 'wrong'},
        ]) {
          expect(
            QuestionPdfAsset.parse({
              ...dto,
              ...patch,
            }, q['questionId'] as String),
            isNull,
          );
        }
      }
    },
  );
  test('RPC projection attaches approved asset without enabling feedback or accepting private RPC fields', () {
    final q = approvedStudentPdfs.values.first;
    const universityId = '11111111-1111-4111-8111-111111111111';
    final c =
        SourceCatalog([
          {'sourceUniversityId': 'fixture', 'universityId': universityId},
        ], []).withRegistered('fixture', [
          {
            'examId': q['examId'],
            'universityId': universityId,
            'year': 2027,
            'kind': 'mock',
            'track': '자연',
            'questionCount': 1,
            'questions': [
              {'id': q['questionId'], 'label': '1번', 'answer': 'private'},
            ],
          },
        ]);
    final exam = c.exams.single;
    final question = (exam['questions'] as List).single;
    expect(exam['evaluationReady'], false);
    expect(question['answer'], isNull);
    expect(question['accountDraftReady'], false);
    expect(question['studentPdf']['startPage'], q['startPage']);
  });
  test(
    '42 catalog identities retained and all 16 preparing universities last',
    () {
      expect(essayUniversityCatalog.length, 42);
      expect(
        essayUniversityCatalog
            .map((u) => u['sourceUniversityId'])
            .toSet()
            .length,
        42,
      );
      expect(
        essayUniversityCatalog
            .take(26)
            .any((u) => isUniversityServicePreparing(u['sourceUniversityId'])),
        false,
      );
      expect(
        essayUniversityCatalog
            .skip(26)
            .every(
              (u) => isUniversityServicePreparing(u['sourceUniversityId']),
            ),
        true,
      );
      for (final id in ['swu', 'kau']) {
        expect(
          essayUniversityCatalog.singleWhere(
            (u) => u['sourceUniversityId'] == id,
          )['universityId'],
          isNotNull,
        );
      }
    },
  );
}
