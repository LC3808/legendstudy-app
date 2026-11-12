import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';
void main(){test('Dongguk reuses 7 approved originals and preserves the 2026 mock Q1 HOLD',(){
 final rows=[for(final raw in jsonDecode(File('supabase/candidates/dongguk_public_20261112/student-pdf-mappings.json').readAsStringSync()) as List) {...Map<String,dynamic>.from(raw as Map),'kind':'student_question','bucket':'essay-material-originals','sha256':raw['assetId']}];
 final scope=jsonDecode(File('supabase/candidates/dongguk_public_20261112/scope.json').readAsStringSync()) as Map;
 expect(rows.length,21);expect(rows.map((r)=>r['assetId']).toSet().length,7);expect(scope['questions'],hasLength(20));expect(scope['questions'],isNot(contains('49ea9aaa-1c46-51e7-b148-a03aef20ae4e')));
 serverStudentPdfs.clear();addTearDown(serverStudentPdfs.clear);installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':rows});
 final dir=Platform.environment['DONGGUK_PDF_DIR'];
 for(final row in rows){final q=row['questionId'] as String;final asset=QuestionPdfAsset.parse(serverStudentPdfFor(row['examId'] as String,q),q)!;expect(asset.pages,row['pageCount']);expect(asset.startPage,row['startPage']);if(dir!=null)expect(asset.validate(File('$dir/${asset.id}.pdf').readAsBytesSync()).isNotEmpty,true);}
 });}
