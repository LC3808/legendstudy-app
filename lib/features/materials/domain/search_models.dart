import '../../content/domain/content_item.dart';
import '../../exams/domain/exam_metadata.dart';
import '../../resources/domain/content_resource.dart';

const examTypeLabels = {
  'school_assessment': '학교 평가',
  'national_mock': '전국연합 학력평가',
  'evaluation_mock': '평가원 모의평가',
  'csat': '수능',
  'preliminary': '예비시험',
  'other': '기타 시험',
};

String normalizeSearch(String text) => text
    .trim()
    .toLowerCase()
    .replaceAllMapped(RegExp(r'(\d)\s+(월|년)'), (m) => '${m[1]}${m[2]}')
    .replaceAll(RegExp(r'\s+'), ' ');

/// Canonical filter names stay bounded to the released taxonomy. These
/// search-only aliases help users find a canonical subject without creating a
/// new chip or changing ingestion mapping semantics.
String? canonicalSubjectSearchName(String value) {
  final folded = value
      .trim()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('·', '')
      .replaceAll('Ⅰ', '1')
      .replaceAll('Ⅱ', '2');
  const aliases = {
    '물리학1': '물리학Ⅰ',
    '물리학2': '물리학Ⅱ',
    '화학1': '화학Ⅰ',
    '화학2': '화학Ⅱ',
    '생명과학1': '생명과학Ⅰ',
    '생명과학2': '생명과학Ⅱ',
    '지구과학1': '지구과학Ⅰ',
    '지구과학2': '지구과학Ⅱ',
    '생활과윤리': '생활과 윤리',
    '윤리와사상': '윤리와 사상',
    '정치와법': '정치와 법',
    '사회문화': '사회·문화',
  };
  return aliases[folded];
}

String displaySubjectName(String canonicalName) => switch (canonicalName) {
  '물리학Ⅰ' => '물리학Ⅰ (물리Ⅰ)',
  '물리학Ⅱ' => '물리학Ⅱ (물리Ⅱ)',
  '생명과학Ⅰ' => '생명과학Ⅰ (생물Ⅰ)',
  '생명과학Ⅱ' => '생명과학Ⅱ (생물Ⅱ)',
  _ => canonicalName,
};

class SearchFilters {
  const SearchFilters({
    this.grade,
    this.year,
    this.month,
    this.examType,
    this.subjectId,
    this.contentType,
  });
  final int? grade, year, month;
  final String? examType, subjectId, contentType;
  bool get isEmpty =>
      grade == null &&
      year == null &&
      month == null &&
      examType == null &&
      subjectId == null &&
      contentType == null;
  bool get needsExam =>
      grade != null ||
      year != null ||
      month != null ||
      examType != null ||
      subjectId != null;
}

class SearchQuery {
  SearchQuery(String text, {this.filters = const SearchFilters()})
    : text = normalizeSearch(text) {
    if (this.text.length > 200 ||
        this.text.contains('*') ||
        tokens.length > 12) {
      throw const FormatException('검색어는 200자, 12단어 이내로 입력해 주세요. *는 사용할 수 없어요.');
    }
  }
  final String text;
  final SearchFilters filters;
  List<String> get tokens => text.isEmpty ? [] : text.split(' ');
  bool get isBrowse => text.isEmpty && filters.isEmpty;
}

/// Typed tokens use calendar year (not source-labelled academic year).
class SearchTerms {
  SearchTerms(SearchQuery query) {
    for (final token in query.tokens) {
      if (RegExp(r'^(19|20|21|22)\d{2}년?$').hasMatch(token)) {
        years.add(int.parse(token.replaceAll('년', '')));
      } else if (RegExp(r'^(1[0-2]|[1-9])월$').hasMatch(token)) {
        months.add(int.parse(token.replaceAll('월', '')));
      } else if (RegExp(r'^고[123]$').hasMatch(token)) {
        grades.add(int.parse(token.substring(1)));
      } else if (const {'수능', '모의평가', '학력평가'}.contains(token)) {
        types.add(
          {
            '수능': 'csat',
            '모의평가': 'evaluation_mock',
            '학력평가': 'national_mock',
          }[token]!,
        );
      } else if (token == '모의고사') {
        examOnly = true;
      } else if (const {'문제', '정답', '해설', '듣기'}.contains(token)) {
        resourceKinds.addAll(switch (token) {
          '문제' => ['question'],
          '정답' => ['answer', 'answer_explanation'],
          '해설' => ['explanation', 'answer_explanation'],
          _ => ['listening_audio', 'listening_script'],
        });
      } else {
        words.add(token);
      }
    }
  }
  final years = <int>[], months = <int>[], grades = <int>[];
  final types = <String>[], words = <String>[], resourceKinds = <String>[];
  bool examOnly = false;
  bool get needsExam =>
      examOnly ||
      years.isNotEmpty ||
      months.isNotEmpty ||
      grades.isNotEmpty ||
      types.isNotEmpty;
}

class SearchSubject {
  const SearchSubject(this.id, this.name);
  final String id, name;
}

class ResourceGroup {
  const ResourceGroup({
    required this.name,
    this.examSubjectId,
    this.subjectId,
    required this.resources,
  });
  final String name;
  final String? examSubjectId, subjectId;
  final List<ContentResource> resources;
  List<String> get kinds => resourceTypeLabels.keys
      .where((kind) => resources.any((r) => r.resourceType == kind))
      .toList();
}

/// One parent per search result; occurrence IDs remain distinct inside groups.
/// Bookmark/recent-view writes must use content.id, never an occurrence ID.
class ResourceSearchItem {
  const ResourceSearchItem({
    required this.content,
    this.exam,
    this.sortDate,
    required this.groups,
  });
  final ContentItem content;
  final ExamMetadata? exam;
  final DateTime? sortDate;
  final List<ResourceGroup> groups;

  factory ResourceSearchItem.fromRows(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> occurrences,
    List<Map<String, dynamic>> resources,
  ) {
    final content = ContentItem.fromJson(row);
    final metadata = row['exam'] as Map<String, dynamic>?;
    final scoped = occurrences.where((o) => o['content_item_id'] == content.id);
    final attachments = resources
        .where((r) => r['content_item_id'] == content.id)
        .map(ContentResource.fromJson)
        .toList();
    return ResourceSearchItem(
      content: content,
      exam: metadata == null ? null : ExamMetadata.fromJson(metadata),
      sortDate: DateTime.tryParse(metadata?['sort_date'] as String? ?? ''),
      groups: [
        for (final occurrence in scoped)
          ResourceGroup(
            examSubjectId: occurrence['id'] as String,
            subjectId: occurrence['subject_id'] as String?,
            name: displaySubjectName(
              (occurrence['subject']?['name'] as String?) ??
                  (occurrence['raw_subject_label'] as String?) ??
                  '과목 미분류',
            ),
            resources: attachments
                .where((r) => r.examSubjectId == occurrence['id'])
                .toList(),
          ),
        if (attachments.any((r) => r.examSubjectId == null))
          ResourceGroup(
            name: '공통 자료',
            resources: attachments
                .where((r) => r.examSubjectId == null)
                .toList(),
          ),
      ],
    );
  }
}

class SearchPage {
  const SearchPage(this.items, this.nextOffset);
  final List<ResourceSearchItem> items;
  final int? nextOffset;
}

class SearchFacets {
  const SearchFacets({
    this.years = const [],
    this.months = const [],
    this.examTypes = const [],
    this.subjects = const [],
    this.nextOffset,
  });
  final List<int> years, months;
  final List<String> examTypes;
  final List<SearchSubject> subjects;
  final int? nextOffset;
  SearchFacets merge(SearchFacets other) => SearchFacets(
    years: ({...years, ...other.years}.toList()
      ..sort((a, b) => b.compareTo(a))),
    months: ({...months, ...other.months}.toList()..sort()),
    examTypes: {...examTypes, ...other.examTypes}.toList()..sort(),
    subjects: {
      for (final s in [...subjects, ...other.subjects]) s.id: s,
    }.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    nextOffset: other.nextOffset,
  );
}

abstract interface class SearchRepository {
  Future<SearchPage> search(SearchQuery query, {int offset = 0});
  Future<SearchFacets> facets({int offset = 0});
}

enum SearchPhase { loading, empty, noResults, data, error }

class SearchResultState {
  const SearchResultState({
    this.phase = SearchPhase.loading,
    this.items = const [],
    this.nextOffset,
    this.loadingMore = false,
    this.moreFailed = false,
  });
  final SearchPhase phase;
  final List<ResourceSearchItem> items;
  final int? nextOffset;
  final bool loadingMore, moreFailed;
}
