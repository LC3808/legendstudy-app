import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';

void main() {
  final rows = (jsonDecode(File('supabase/candidates/khu_mock_science_20261112/science-student-pdf-mappings.json').readAsStringSync()) as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  List<Map<String,dynamic>> dto() => rows.map((r) => <String,dynamic>{...r,'kind':'student_question','bucket':'essay-material-originals','sha256':r['assetId']}).toList();
  setUp(() { serverStudentPdfs.clear(); });
  tearDown(serverStudentPdfs.clear);
  test('18 science Registry identities reuse 7 problem-only PDF assets', () {
    final data=dto(); installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':data});
    expect(data.length,18);expect(data.map((r)=>r['questionId']).toSet().length,18);expect(data.map((r)=>r['examId']).toSet().length,5);expect(data.map((r)=>r['assetId']).toSet().length,7);
    for(final row in data) {
      final question=row['questionId'] as String; final exam=row['examId'] as String;
      final asset=QuestionPdfAsset.parse(serverStudentPdfFor(exam,question),question)!;
      expect(asset.id,row['assetId']);expect(asset.bucket,'essay-material-originals');expect(asset.startPage,row['startPage']);expect(asset.pages,row['pageCount']);expect(serverStudentPdfFor('foreign-exam',question),isNull);
      expect(QuestionPdfAsset.parse({...row,'assetId':'f'*64,'sha256':'f'*64},question),isNull);
    }
  });
  test('a duplicate or invalid manifest does not replace the existing valid map', () {
    final data=dto();installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':data});
    expect(()=>installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':[...data,data.first]}),throwsFormatException);expect(serverStudentPdfs.length,18);
    expect(()=>installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':[{...data.first,'startPage':999}]}),throwsFormatException);expect(serverStudentPdfs.length,18);
  });
}
