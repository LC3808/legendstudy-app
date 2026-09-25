/// Display only: source titles and search matching remain unchanged.
String materialDisplayTitle(String title, String contentType) {
  if (contentType != 'exam') return title;
  final mock = RegExp(r'모의고사|모의평가').firstMatch(title);
  if (mock != null) return title.substring(0, mock.end);
  final match = RegExp(
    r'^(.*(?:모의고사|모의평가|수능|대학수학능력시험))\s+기출\s*-\s*문제\s*[,/]\s*(?:정답|답)\s*[,/]\s*해설(?:\s|[,/:]|$)',
  ).firstMatch(title);
  return match?.group(1)?.trimRight() ?? title;
}
