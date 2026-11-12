import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';
void main(){test('corrected Dongguk Q1 reuses original student PDF and exact Registry identity',(){
 const q='49ea9aaa-1c46-51e7-b148-a03aef20ae4e';
 final scope=jsonDecode(File('supabase/candidates/dongguk_correction_20261112/scope.json').readAsStringSync()) as Map;
 expect(scope['questions'],[q]);expect(scope['new_rows'],13);expect(scope['student_pdf_changed'],false);
 final rows=jsonDecode(File('supabase/candidates/dongguk_public_20261112/student-pdf-mappings.json').readAsStringSync()) as List;
 final raw=Map<String,dynamic>.from(rows.singleWhere((r)=>r['questionId']==q) as Map);
 final row={...raw,'kind':'student_question','bucket':'essay-material-originals','sha256':raw['assetId']};
 serverStudentPdfs.clear();addTearDown(serverStudentPdfs.clear);installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':[row]});
 final asset=QuestionPdfAsset.parse(serverStudentPdfFor(raw['examId'] as String,q),q)!;
 expect(asset.id,'12efd22c5adb0ad79c8556e738d57da8e3fb361a020f9fc88194e35d3150c9af');expect(asset.startPage,2);
 final root=Platform.environment['DONGGUK_PDF_DIR'];if(root!=null)expect(asset.validate(File('$root/${asset.id}.pdf').readAsBytesSync()).isNotEmpty,true);
});}
