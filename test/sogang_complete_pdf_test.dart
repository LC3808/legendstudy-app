import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';

void main() {
 test('Sogang corrected official PDF overrides the embedded three-page mapping', () {
  const exam='e08ff787-f4d4-5da9-8922-d78d2c45f443';
  const hash='2bbadaf676cb022a98e4b81ea527332940b7862a95d95c38ff392c665ef8bc5a';
  final rows=[for(final q in ['d79c31c0-4d95-54df-87bf-132082d25ea7','cf5f3f9a-66e1-5e52-881a-6dad8ed84eb8'])
   <String,dynamic>{'examId':exam,'questionId':q,'assetId':hash,'sha256':hash,'kind':'student_question','bucket':'essay-material-originals','pageCount':4,'startPage':q.startsWith('d79')?1:3,'verification':'VERIFIED','studentDisplay':'APPROVED'}];
  serverStudentPdfs.clear();
  addTearDown(serverStudentPdfs.clear);
  installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':rows});
  for(final row in rows) {
   final q=row['questionId'] as String;
   final asset=QuestionPdfAsset.parse(serverStudentPdfFor(exam,q),q)!;
   expect(asset.pages,4);expect(asset.startPage,row['startPage']);expect(asset.hash,hash);
   final source=Platform.environment['SOGANG_VERIFIED_PDF'];
   if(source!=null) expect(asset.validate(File(source).readAsBytesSync()).length,349986);
  }
 });
}
