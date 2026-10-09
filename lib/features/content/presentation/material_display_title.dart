/// Display only: source titles and search matching remain unchanged.
String materialDisplayTitle(String title, String contentType) {
  // 논술(essay) list titles carry a feed prefix and a long resource-descriptor
  // tail (문제·해설·예시답안 등 + 경쟁률). Strip both for display only — the DB
  // title and search matching are unchanged (Owner 2026-10-09). e.g.
  // "서강대] 2025학년도 서강대 논술 & 모의논술 기출 - 문제, 해설, 답안 등 + 2026학년도 논술 경쟁률"
  //   → "2025학년도 서강대 논술 & 모의논술 기출".
  if (contentType == 'university_essay') {
    var cleaned = title
        // Leading feed prefix of plain name letters, e.g. "서강대] ".
        .replaceFirst(RegExp(r'^\s*[가-힣A-Za-z]{1,12}\]\s*'), '')
        // Descriptor tail introduced by a delimiter, to the end of the title.
        .replaceFirst(
          RegExp(
            r'\s*[-–—·:,/]\s*(?:문제|해설|예시\s*답안|모범\s*답안|답안|정답).*$',
          ),
          '',
        )
        .trim();
    return cleaned.isEmpty ? title : cleaned;
  }
  if (contentType != 'exam') return title;
  final mock = RegExp(r'모의고사|모의평가').firstMatch(title);
  if (mock != null) return title.substring(0, mock.end);
  final match = RegExp(
    r'^(.*(?:모의고사|모의평가|수능|대학수학능력시험))\s+기출\s*-?\s*문제\s*[,/]\s*(?:정답|답)\s*[,/]\s*해설(?:\s|[,/:]|$)',
  ).firstMatch(title);
  return match?.group(1)?.trimRight() ?? title;
}
