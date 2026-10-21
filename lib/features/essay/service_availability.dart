// Owner launch hold. Does not change Catalog order, data or backend admission.
const servicePreparingUniversityIds = <String>{
  'yonsei',
  'hongik',
  'uos',
  'sungshin',
  'eulji',
  'dankook',
  'syu',
  'duksung',
  'dongduk',
  'seokyeong',
  'suwon',
  'shinhan',
  'tukorea',
  'koreatech',
  'hanshin',
  'kangnam',
};
bool isUniversityServicePreparing(Object? id) =>
    servicePreparingUniversityIds.contains(id);
