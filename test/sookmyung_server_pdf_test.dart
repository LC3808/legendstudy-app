import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/question_pdf.dart';
import 'package:legendstudy_app/features/essay/server_student_pdfs.dart';
void main(){test('38 Sookmyung originals use exact SHA and original shared-page positions',(){
 final audit=jsonDecode(File('supabase/candidates/sookmyung_public_20261112/pdf-audit.json').readAsStringSync()) as Map;
 final rows=[for(final raw in audit['student_question_mappings'] as List) {...Map<String,dynamic>.from(raw as Map),'kind':'student_question','bucket':'essay-material-originals','sha256':raw['assetId']}];
 expect(rows.length,38);serverStudentPdfs.clear();addTearDown(serverStudentPdfs.clear);
 installServerStudentPdfs({'version':'essay-student-pdfs-v1','questions':rows});
 final path=Platform.environment['SOOKMYUNG_SOURCE_MAP'];final paths=path==null?null:jsonDecode(File(path).readAsStringSync()) as Map;
 for(final row in rows){final q=row['questionId'] as String;final asset=QuestionPdfAsset.parse(serverStudentPdfFor(row['examId'] as String,q),q)!;expect(asset.pages,row['pageCount']);expect(asset.startPage,row['startPage']);if(paths!=null) expect(asset.validate(File(paths[asset.id] as String).readAsBytesSync()).isNotEmpty,true);}
 final shared=rows.where((r)=>r['examId']=='4c582db3-d518-57f9-b3b1-56c257aca2e5').toList();expect(shared.map((r)=>r['startPage']).toList(),[1,2,3]);expect(shared.every((r)=>r['pageCount']==3),true);
 });}
