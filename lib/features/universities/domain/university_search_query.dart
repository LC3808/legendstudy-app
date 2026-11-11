/// Search terms only: results and IDs always come from the shared server catalog.
/// Aliases never create universities or enable LAB support.
String universitySearchQuery(String input) {
  var q = input.trim().replaceAll(RegExp(r'\s+'), '');
  const aliases = {
    '카이스트': '한국과학기술원',
    '포스텍': '포항공과대학교',
    '지스트': '광주과학기술원',
    '디지스트': '대구경북과학기술원',
    '유니스트': '울산과학기술원',
    '켄텍': '한국에너지공과대학교',
    'kentech': '한국에너지공과대학교',
    '한예종': '한국예술종합학교',
    'karts': '한국예술종합학교',
    'knue': '한국교원대학교',
    '서울교대': '서울교육대학교',
    '경인교대': '경인교육대학교',
    '공주교대': '공주교육대학교',
    '광주교대': '광주교육대학교',
    '대구교대': '대구교육대학교',
    '부산교대': '부산교육대학교',
    '전주교대': '전주교육대학교',
    '진주교대': '진주교육대학교',
    '청주교대': '청주교육대학교',
    '춘천교대': '춘천교육대학교',
  };
  q = aliases[q.toLowerCase()] ?? q;
  // Both historical '부경대학교' and official '국립부경대학교' remain findable.
  if (q.startsWith('국립') && q.length > 2) q = q.substring(2);
  return q;
}
