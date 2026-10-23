import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
void main() {
 const leaf='3bab07d3-c047-53c2-89ad-9fa20ec7b3f3';
 final rows=<Map<String,dynamic>>[{'essay_exam_id':'exam','essay_question_id':'q1','leaf_id':leaf}];
 test('canonical singleton routes to existing Math leaf',(){
  expect(releasedMathSelection(rows,'exam',['q1']),leaf);
 });
 test('wrong exam, other question, multiple selection and duplicate mapping fail closed',(){
  expect(releasedMathSelection(rows,'other',['q1']),isNull);
  expect(releasedMathSelection(rows,'exam',['q2']),isNull);
  expect(releasedMathSelection(rows,'exam',['q1','q2']),isNull);
  expect(releasedMathSelection([...rows,...rows],'exam',['q1']),isNull);
 });
}
