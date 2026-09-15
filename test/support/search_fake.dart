import 'package:legendstudy_app/features/materials/domain/search_models.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';

/// Test-only bridge keeps historical shell/detail tests exercising navigation.
class LegacySearchFake implements SearchRepository {
  LegacySearchFake(this.content, {this.exam});
  final ContentRepository content;
  final ExamMetadata? exam;
  @override
  Future<SearchPage> search(SearchQuery query, {int offset = 0}) async =>
      SearchPage([
        for (final item
            in query.isBrowse
                ? <ContentItem>[]
                : await content.searchContent(
                    query.text,
                    contentType: query.filters.contentType,
                  ))
          ResourceSearchItem(content: item, exam: exam, groups: const []),
      ], null);
  @override
  Future<SearchFacets> facets({int offset = 0}) async => const SearchFacets();
}

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({List<ResourceSearchItem>? items})
    : items = items ?? searchFixtures();
  final List<ResourceSearchItem> items;
  final calls = <SearchQuery>[];
  bool fail = false;
  Future<void>? delay;
  int pageSize = 3;
  @override
  Future<SearchPage> search(SearchQuery query, {int offset = 0}) async {
    calls.add(query);
    if (delay != null) await delay;
    if (fail) throw StateError('test-only failure');
    final f = query.filters, t = SearchTerms(query);
    final matches =
        items
            .where(
              (i) =>
                  (f.grade == null || i.exam?.gradeLevel == f.grade) &&
                  (f.year == null || i.exam?.year == f.year) &&
                  (f.month == null || i.exam?.examMonth == f.month) &&
                  (f.examType == null || i.exam?.examType == f.examType) &&
                  (f.contentType == null ||
                      i.content.contentType == f.contentType) &&
                  (f.subjectId == null ||
                      i.groups.any((g) => g.subjectId == f.subjectId)) &&
                  t.years.every((v) => i.exam?.year == v) &&
                  t.months.every((v) => i.exam?.examMonth == v) &&
                  t.grades.every((v) => i.exam?.gradeLevel == v) &&
                  t.types.every((v) => i.exam?.examType == v) &&
                  t.words.every(
                    (v) => normalizeSearch(
                      '${i.content.title} ${i.groups.map((g) => g.name).join(' ')}',
                    ).contains(v),
                  ) &&
                  (t.resourceKinds.isEmpty ||
                      i.groups.any(
                        (g) => g.kinds.any(t.resourceKinds.contains),
                      )),
            )
            .toList()
          ..sort((a, b) {
            final date = (b.sortDate ?? DateTime(1900)).compareTo(
              a.sortDate ?? DateTime(1900),
            );
            return date != 0 ? date : b.content.id.compareTo(a.content.id);
          });
    return SearchPage(
      matches.skip(offset).take(pageSize).toList(),
      matches.length > offset + pageSize ? offset + pageSize : null,
    );
  }

  @override
  Future<SearchFacets> facets({int offset = 0}) async => const SearchFacets(
    years: [2026, 2025, 2024],
    months: [6, 9, 11],
    examTypes: ['evaluation_mock', 'csat'],
    subjects: [
      SearchSubject('korean', '국어'),
      SearchSubject('math', '수학'),
      SearchSubject('english', '영어'),
    ],
  );
}

List<ResourceSearchItem> searchFixtures() => List.generate(9, (n) {
  final subject = ['국어', '수학', '영어'][n % 3];
  final id = 'fixture-$n';
  return ResourceSearchItem(
    content: ContentItem(
      id: id,
      slug: id,
      contentType: 'exam',
      title: n == 0
          ? '아주 긴 시험명으로 표시와 줄바꿈을 확인하는 2026학년도 전국연합 모의평가 자료'
          : '${2026 - n ~/ 3}년 9월 모의평가',
      sourceUrl: 'https://example.org/material',
      isActive: true,
    ),
    exam: ExamMetadata(
      contentItemId: id,
      year: 2026 - n ~/ 3,
      academicYear: 2027 - n ~/ 3,
      gradeLevel: 3 - n ~/ 3,
      examMonth: 9,
      examType: 'evaluation_mock',
    ),
    sortDate: DateTime(2026 - n ~/ 3, 9, 1),
    groups: [
      ResourceGroup(
        name: subject,
        subjectId: ['korean', 'math', 'english'][n % 3],
        examSubjectId: 'occurrence-$n',
        resources: n == 4
            ? []
            : [
                for (final kind in ['question', 'answer', 'explanation'])
                  ContentResource(
                    id: '$id-$kind',
                    contentItemId: id,
                    resourceType: kind,
                    title: kind,
                    sourceUrl: 'https://example.org/test.pdf',
                    linkKind: 'file',
                  ),
              ],
      ),
    ],
  );
});
