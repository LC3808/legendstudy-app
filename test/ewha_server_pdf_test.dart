import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';

void main() {
  final rows = (jsonDecode(File('supabase/candidates/ewha_public_20261112/student-pdf-mappings.json').readAsStringSync()) as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  final originals = (jsonDecode(File('supabase/candidates/ewha_public_20261112/pdf-originals.json').readAsStringSync()) as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
  List<Map<String,dynamic>> dto() => rows.map((r) => <String,dynamic>{...r,'kind':'student_question','bucket':'essay-material-originals','sha256':r['assetId']}).toList();
  setUp(() { serverStudentPdfs.clear(); });
  tearDown(serverStudentPdfs.clear);
  test('63 existing Registry identities receive 21 exact official problem PDFs', () {
    final data=dto(); installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':data});
    expect(data.length,63);expect(originals.length,21);expect(data.map((r)=>r['questionId']).toSet().length,63);expect(data.map((r)=>r['examId']).toSet().length,21);expect(data.map((r)=>r['assetId']).toSet().length,21);
    for(final row in data) {
      final question=row['questionId'] as String; final exam=row['examId'] as String;
      final asset=QuestionPdfAsset.parse(serverStudentPdfFor(exam,question),question)!;
      expect(asset.id,row['assetId']);expect(asset.bucket,'essay-material-originals');expect(asset.startPage,row['startPage']);expect(asset.pages,row['pageCount']);expect(serverStudentPdfFor('foreign-exam',question),isNull);
      expect(QuestionPdfAsset.parse({...row,'assetId':'f'*64,'sha256':'f'*64},question),isNull);
    }
  });
  test('a duplicate or invalid manifest does not replace the existing valid map', () {
    final data=dto();installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':data});
    expect(()=>installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':[...data,data.first]}),throwsFormatException);expect(serverStudentPdfs.length,63);
    expect(()=>installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':[{...data.first,'startPage':999}]}),throwsFormatException);expect(serverStudentPdfs.length,63);
  });
  test('the canonical original bytes pass the unchanged native viewer validator', () {
    final root=Platform.environment['EWHA_ORIGINAL_PDF_DIR'];
    if(root==null) fail('Set EWHA_ORIGINAL_PDF_DIR to the Owner-confirmed canonical originals directory');
    final data=dto();installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':data});
    for(final original in originals) {
      final row=data.firstWhere((r)=>r['assetId']==original['assetId']);final asset=QuestionPdfAsset.parse(row,row['questionId'] as String)!;
      final bytes=File('$root/${original['filename']}').readAsBytesSync();expect(bytes.length,original['bytes']);expect(asset.validate(bytes),same(bytes));
    }
  },skip:Platform.environment['EWHA_ORIGINAL_PDF_DIR']==null?'Canonical originals path required for byte-level PDF validation':false);
}
