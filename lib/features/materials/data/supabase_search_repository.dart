import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../content/data/supabase_content_repository.dart';
import '../../exams/data/supabase_exam_repository.dart';
import '../../resources/data/supabase_resource_repository.dart';
import '../domain/search_models.dart';

class SupabaseSearchRepository implements SearchRepository {
  SupabaseSearchRepository(this.client);
  final SupabaseClient client;
  static const pageSize = 24;
  static const facetPageSize = 100;
  static const maxOffset = 10000;
  static const occurrenceProjection =
      'id,content_item_id,subject_id,raw_subject_label,display_order,'
      'subject:subjects!exam_subjects_versioned_mapping(id,name)';

  static String literal(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  void checkOffset(int offset) {
    if (offset < 0 || offset > maxOffset) {
      throw const FormatException('검색 범위를 좁혀 주세요.');
    }
  }

  @override
  Future<SearchPage> search(SearchQuery query, {int offset = 0}) async {
    checkOffset(offset);
    final terms = SearchTerms(query);
    final f = query.filters;
    final subjectSets = <List<String>>[];
    if (f.subjectId != null) subjectSets.add([f.subjectId!]);
    final words = <String>[];
    // Resolve exact public taxonomy names, including historical versions, without
    // loading the entire subject catalogue or depending on facet-page coverage.
    for (final word in terms.words) {
      final matches = await client
          .from('subjects')
          .select('id')
          .eq('is_active', true)
          .ilike('name', literal(word))
          .limit(101);
      if (matches.length > 100) throw const FormatException('과목 조건을 좁혀 주세요.');
      if (matches.isEmpty) {
        words.add(word);
      } else {
        subjectSets.add(matches.map((r) => r['id'] as String).toList());
      }
    }
    // An explicit subject plus a different typed subject is a conjunction.
    Set<String>? subjectIds;
    for (final set in subjectSets) {
      subjectIds = subjectIds == null
          ? set.toSet()
          : subjectIds.intersection(set.toSet());
    }
    if (subjectIds?.isEmpty ?? false) return const SearchPage([], null);
    final needsExam = f.needsExam || terms.needsExam || subjectIds != null;
    final scopedKinds = subjectIds != null && terms.resourceKinds.isNotEmpty;
    final subjectJoin = subjectIds == null
        ? ''
        : ',matches:exam_subjects!inner(id${scopedKinds ? ',kind_matches:resources!resources_subject_same_content!inner(id)' : ''})';
    final resourceJoin = terms.resourceKinds.isEmpty || scopedKinds
        ? ''
        : ',kind_matches:resources!inner(id)';
    var examRequest = client
        .from('exams')
        .select(
          '${SupabaseExamRepository.projection},'
          'content:content_items!exams_content_type!inner('
          '${SupabaseContentRepository.projection}$resourceJoin)$subjectJoin',
        )
        .eq('content.is_active', true);
    if (f.contentType != null) {
      examRequest = examRequest.eq('content.content_type', f.contentType!);
    }
    for (final year in [if (f.year != null) f.year!, ...terms.years]) {
      examRequest = examRequest.eq('year', year);
    }
    for (final month in [if (f.month != null) f.month!, ...terms.months]) {
      examRequest = examRequest.eq('exam_month', month);
    }
    for (final grade in [if (f.grade != null) f.grade!, ...terms.grades]) {
      examRequest = examRequest.eq('grade_level', grade);
    }
    for (final type in [if (f.examType != null) f.examType!, ...terms.types]) {
      examRequest = examRequest.eq('exam_type', type);
    }
    if (subjectIds != null) {
      examRequest = examRequest.inFilter(
        'matches.subject_id',
        subjectIds.toList(),
      );
    }
    if (terms.resourceKinds.isNotEmpty) {
      examRequest = examRequest.inFilter(
        scopedKinds
            ? 'matches.kind_matches.resource_type'
            : 'content.kind_matches.resource_type',
        terms.resourceKinds,
      );
    }
    for (final word in words) {
      final pattern = jsonEncode('%${literal(word)}%');
      examRequest = examRequest.or(
        'title.ilike.$pattern,summary.ilike.$pattern',
        referencedTable: 'content',
      );
    }
    // The composite FK is not recognized as a to-one inverse by PostgREST.
    // Start at exams to use its canonical date index; append extension-less
    // parents in feed order. Counts locate the second stream's bounded offset.
    final exams = await examRequest
        .order('sort_date', ascending: false, nullsFirst: false)
        .order('content_item_id', ascending: false)
        .range(offset, offset + pageSize);
    final rows = <Map<String, dynamic>>[
      for (final row in exams)
        {
          ...(row['content'] as Map<String, dynamic>),
          'exam': {
            for (final entry in row.entries)
              if (entry.key != 'content') entry.key: entry.value,
          },
        },
    ];
    if (rows.length <= pageSize && !needsExam) {
      var general = client
          .from('content_items')
          .select(
            '${SupabaseContentRepository.projection},'
            'exam:exams!exams_content_type(content_item_id)$resourceJoin',
          )
          .eq('is_active', true)
          .isFilter('exam', null);
      if (f.contentType != null) {
        general = general.eq('content_type', f.contentType!);
      }
      if (terms.resourceKinds.isNotEmpty) {
        general = general.inFilter(
          'kind_matches.resource_type',
          terms.resourceKinds,
        );
      }
      for (final word in words) {
        final pattern = jsonEncode('%${literal(word)}%');
        general = general.or('title.ilike.$pattern,summary.ilike.$pattern');
      }
      // Counting an out-of-range page produces PGRST103. Count separately at
      // offset zero only when crossing into the general-content stream.
      final examCount =
          (await examRequest.limit(0).count(CountOption.exact)).count;
      final start = (offset - examCount).clamp(0, maxOffset);
      final generalRows = await general
          .order('feed_updated_at', ascending: false, nullsFirst: false)
          .order('id', ascending: false)
          .range(start, start + pageSize - rows.length);
      rows.addAll(generalRows.map((r) => {...r, 'exam': null}));
    }
    final page = rows.take(pageSize).toList();
    if (page.isEmpty) return const SearchPage([], null);
    final ids = page.map((r) => r['id'] as String).toList();
    // Enrichment is bounded and counted: never silently label a truncated set as
    // complete availability. A crowded page fails safely instead of hiding files.
    final occurrences = await client
        .from('exam_subjects')
        .select(occurrenceProjection)
        .eq('is_active', true)
        .inFilter('content_item_id', ids)
        .order('display_order')
        .order('id')
        .limit(1000)
        .count(CountOption.exact);
    final resources = await client
        .from('resources')
        .select(SupabaseResourceRepository.projection)
        .eq('is_active', true)
        .inFilter('content_item_id', ids)
        .order('display_order')
        .order('id')
        .limit(1000)
        .count(CountOption.exact);
    if (occurrences.count > occurrences.data.length ||
        resources.count > resources.data.length) {
      throw const FormatException('자료가 많은 검색이에요. 조건을 좁혀 다시 검색해 주세요.');
    }
    return SearchPage([
      for (final row in page)
        ResourceSearchItem.fromRows(
          row,
          occurrences.data
              .where(
                (o) =>
                    subjectIds == null || subjectIds.contains(o['subject_id']),
              )
              .toList(),
          resources.data,
        ),
    ], rows.length > pageSize ? offset + pageSize : null);
  }

  @override
  Future<SearchFacets> facets({int offset = 0}) async {
    checkOffset(offset);
    final exams = await client
        .from('exams')
        .select('content_item_id,year,exam_month,exam_type')
        .order('content_item_id')
        .range(offset, offset + facetPageSize);
    final subjects = await client
        .from('subjects')
        .select('id,name')
        .eq('is_active', true)
        .order('id')
        .range(offset, offset + facetPageSize);
    return const SearchFacets().merge(
      SearchFacets(
        years: exams
            .take(facetPageSize)
            .map((r) => r['year'] as int?)
            .whereType<int>()
            .toList(),
        months: exams
            .take(facetPageSize)
            .map((r) => r['exam_month'] as int?)
            .whereType<int>()
            .toList(),
        examTypes: exams
            .take(facetPageSize)
            .map((r) => r['exam_type'] as String?)
            .whereType<String>()
            .toList(),
        subjects: subjects
            .take(facetPageSize)
            .map((r) => SearchSubject(r['id'] as String, r['name'] as String))
            .toList(),
        nextOffset:
            exams.length > facetPageSize || subjects.length > facetPageSize
            ? offset + facetPageSize
            : null,
      ),
    );
  }
}
