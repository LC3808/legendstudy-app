/// Metadata fetched only from the authenticated, fixed-origin student-pdfs API.
/// Browse RPC fields and persisted student drafts never populate this registry.
final Map<String, Map<String, dynamic>> serverStudentPdfs = {};

void installServerStudentPdfs(dynamic data) {
  if (data is! Map ||
      data['version'] != 'essay-student-pdfs-v1' ||
      data['questions'] is! List) {
    throw const FormatException('Invalid PDF manifest');
  }
  final next = <String, Map<String, dynamic>>{};
  final uuid = RegExp(r'^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$');
  final hash = RegExp(r'^[a-f0-9]{64}$');
  for (final raw in data['questions'] as List) {
    if (raw is! Map ||
        raw['examId'] is! String ||
        !uuid.hasMatch(raw['examId'] as String) ||
        raw['questionId'] is! String ||
        !uuid.hasMatch(raw['questionId'] as String) ||
        next.containsKey(raw['questionId']) ||
        raw['kind'] != 'student_question' ||
        raw['verification'] != 'VERIFIED' ||
        raw['studentDisplay'] != 'APPROVED' ||
        raw['bucket'] != 'essay-material-originals' ||
        raw['assetId'] is! String ||
        !hash.hasMatch(raw['assetId'] as String) ||
        raw['sha256'] != raw['assetId'] ||
        raw['pageCount'] is! int ||
        raw['startPage'] is! int ||
        (raw['pageCount'] as int) < 1 ||
        (raw['pageCount'] as int) > 3000 ||
        (raw['startPage'] as int) < 1 ||
        (raw['startPage'] as int) > (raw['pageCount'] as int)) {
      throw const FormatException('Invalid PDF identity');
    }
    next[raw['questionId'] as String] = Map<String, dynamic>.from(raw);
  }
  serverStudentPdfs
    ..clear()
    ..addAll(next);
}

Map<String, dynamic>? serverStudentPdfFor(String exam, String question) {
  final pdf = serverStudentPdfs[question];
  return pdf?['examId'] == exam ? pdf : null;
}
