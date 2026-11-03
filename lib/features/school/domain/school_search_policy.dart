import 'school.dart';

String _normalize(String value) => value.replaceAll(RegExp(r'\s+'), '');

/// A level suffix is intent; a syllable inside a name (e.g. 중앙) is not.
String schoolSearchType(String query) {
  final q = _normalize(query);
  return q.endsWith('중학교') || (q.length > 1 && q.endsWith('중'))
      ? '중학교'
      : '고등학교';
}

String schoolSearchQuery(String query) {
  final q = _normalize(query);
  if (q.endsWith('중') && q.length > 1) return '$q학교';
  if (q.endsWith('고') && q.length > 1) return '$q등학교';
  return query.trim();
}

List<School> rankSchoolResults(String query, List<School> schools) {
  final q = _normalize(schoolSearchQuery(query));
  final type = schoolSearchType(query);
  int rank(School school) {
    final name = _normalize(school.name);
    if (name == q) return 0;
    if (name.startsWith(q)) return 1;
    return 2;
  }

  final result = schools
      .where((s) => s.schoolType == type && _normalize(s.name).contains(q))
      .toList();
  result.sort((a, b) {
    final relevance = rank(a).compareTo(rank(b));
    if (relevance != 0) return relevance;
    final name = a.name.compareTo(b.name);
    return name != 0 ? name : a.identity.compareTo(b.identity);
  });
  return result;
}
