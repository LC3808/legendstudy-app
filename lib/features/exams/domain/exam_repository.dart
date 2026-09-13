import 'exam_metadata.dart';

abstract interface class ExamRepository {
  Future<Map<String, ExamMetadata>> fetchForContentIds(List<String> ids);
}
