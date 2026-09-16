import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';
import 'package:legendstudy_app/features/materials/data/supabase_search_repository.dart';

Map<String, dynamic> parent(int n) => {
  'id': 'c$n',
  'slug': 'c$n',
  'content_type': 'exam',
  'title': '자료 $n',
  'source_url': 'https://example.org/$n',
  'is_active': true,
};
Map<String, dynamic> exam(int n) => {
  'content_item_id': 'c$n',
  'year': 2026,
  'sort_date': '2026-09-01',
  'grade_level': 3,
  'exam_month': 9,
  'exam_type': 'evaluation_mock',
  'content': parent(n),
};

void main() {
  test(
    'normalization and metadata preserve calendar/academic-year boundary',
    () {
      final q = SearchQuery('  2026년  9 월 고3 ENGLISH  ');
      expect(q.text, '2026년 9월 고3 english');
      final t = SearchTerms(q);
      expect(t.years, [2026]);
      expect(t.months, [9]);
      expect(t.grades, [3]);
      expect(t.words, ['english']);
      expect(SearchTerms(SearchQuery('2027학년도')).words, ['2027학년도']);
      expect(() => SearchQuery('*'), throwsFormatException);
      expect(() => SearchQuery('x ' * 13), throwsFormatException);
      expect(() => SearchQuery('x' * 201), throwsFormatException);
      expect(const SearchFilters().isEmpty, isTrue);
    },
  );
  test('subject aliases remain bounded to canonical search/display names', () {
    expect(canonicalSubjectSearchName('물리학1'), '물리학Ⅰ');
    expect(canonicalSubjectSearchName(' 생명과학 Ⅱ '), '생명과학Ⅱ');
    expect(canonicalSubjectSearchName('생물1'), isNull);
    expect(displaySubjectName('물리학Ⅰ'), '물리학Ⅰ (물리Ⅰ)');
    expect(displaySubjectName('생명과학Ⅱ'), '생명과학Ⅱ (생물Ⅱ)');
    expect(displaySubjectName('국어'), '국어');
  });
  late List<Uri> calls;
  late SupabaseClient client;
  late SupabaseSearchRepository repository;
  List<Map<String, dynamic>> examRows = [];
  List<Map<String, dynamic>> generalRows = [];
  List<Map<String, dynamic>> attachments = [];
  int? resourceCount;
  setUp(() {
    calls = [];
    examRows = [];
    generalRows = [];
    attachments = [];
    resourceCount = null;
    client = SupabaseClient(
      'https://example.org',
      'test-only-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        calls.add(r.url);
        final table = r.url.pathSegments.last, q = r.url.queryParameters;
        List<Map<String, dynamic>> rows = [];
        int? count;
        if (table == 'subjects') {
          rows = q['name'] == 'ilike.영어'
              ? [
                  {'id': 'english'},
                ]
              : q.containsKey('name')
              ? <Map<String, dynamic>>[]
              : [
                  {'id': 'english', 'name': '영어'},
                ];
        }
        if (table == 'exams') {
          count = examRows.length;
          rows = examRows
              .skip(int.parse(q['offset'] ?? '0'))
              .take(int.parse(q['limit'] ?? '100'))
              .toList();
        }
        if (table == 'content_items') {
          rows = generalRows
              .skip(int.parse(q['offset'] ?? '0'))
              .take(int.parse(q['limit'] ?? '100'))
              .toList();
        }
        if (table == 'exam_subjects') {
          rows = [
            {
              'id': 'o',
              'content_item_id': 'c0',
              'subject_id': 'english',
              'raw_subject_label': '역사적 과목명',
              'subject': {'id': 'english', 'name': '영어'},
            },
          ];
        }
        if (table == 'resources') {
          rows = attachments;
          count = resourceCount;
        }
        return http.Response(
          jsonEncode(rows),
          200,
          request: r,
          headers: {
            'content-type': 'application/json',
            'content-range':
                '0-${rows.isEmpty ? 0 : rows.length - 1}/${count ?? rows.length}',
          },
        );
      }),
    );
    repository = SupabaseSearchRepository(client);
  });
  tearDown(() => client.dispose());
  for (final entry in <String, SearchFilters>{
    'grade': const SearchFilters(grade: 3),
    'year': const SearchFilters(year: 2026),
    'month': const SearchFilters(month: 9),
    'exam': const SearchFilters(examType: 'csat'),
    'subject': const SearchFilters(subjectId: 'english'),
    'combined': const SearchFilters(
      grade: 3,
      year: 2026,
      month: 9,
      examType: 'evaluation_mock',
      subjectId: 'english',
    ),
  }.entries) {
    test('public bounded query: ${entry.key}', () async {
      await repository.search(SearchQuery('', filters: entry.value));
      final q = calls.single.queryParameters;
      expect(q['limit'], '25');
      expect(q['offset'], '0');
      expect(
        q['order'],
        'sort_date.desc.nullslast,content_item_id.desc.nullslast',
      );
      expect(q['content.is_active'], 'eq.true');
      if (entry.value.grade != null) expect(q['grade_level'], 'eq.3');
      if (entry.value.year != null) expect(q['year'], 'eq.2026');
      if (entry.value.month != null) expect(q['exam_month'], 'eq.9');
      if (entry.value.examType != null) {
        expect(q['exam_type'], 'eq.${entry.value.examType}');
      }
      if (entry.value.subjectId != null) {
        expect(q['matches.subject_id'], 'in.("english")');
      }
      expect(q['select'], isNot(contains('*')));
      for (final private in [
        'source_posts',
        'mapping_note',
        'mapping_confidence',
        'ingestion_quarantine',
        'link_status',
      ]) {
        expect(q['select'], isNot(contains(private)));
      }
    });
  }
  test(
    'no-filter browse and general fallback preserve real parent identity',
    () async {
      generalRows = [
        {...parent(1), 'exam': <Map<String, dynamic>>[]},
      ];
      final result = await repository.search(SearchQuery(''));
      expect(result.items.single.content.id, 'c1');
      expect(result.items.single.exam, isNull);
      final q = calls
          .firstWhere((u) => u.path.endsWith('content_items'))
          .queryParameters;
      expect(q['exam'], 'is.null');
      expect(q['order'], 'feed_updated_at.desc.nullslast,id.desc.nullslast');
    },
  );
  test(
    'search plus filters uses typed metadata and actual subject lookup',
    () async {
      await repository.search(
        SearchQuery(
          '2026 9 월 고3 영어 문제',
          filters: const SearchFilters(examType: 'evaluation_mock'),
        ),
      );
      final q = calls
          .firstWhere((u) => u.path.endsWith('/exams'))
          .queryParameters;
      expect(q['year'], 'eq.2026');
      expect(q['exam_month'], 'eq.9');
      expect(q['matches.subject_id'], 'in.("english")');
      expect(q['matches.kind_matches.resource_type'], 'in.("question")');
      expect(q.containsKey('content.or'), isFalse);
    },
  );
  test('observed full-name numeric alias queries canonical subject', () async {
    await repository.search(SearchQuery('물리학1'));
    final subject = calls.firstWhere((u) => u.path.endsWith('/subjects'));
    expect(subject.queryParameters['name'], 'ilike.물리학Ⅰ');
  });
  test('keyword literals cannot inject PostgREST filter syntax', () async {
    // Lookup can return no match without disclosing or interpolating raw SQL.
    expect(SupabaseSearchRepository.literal(r'a%_\b'), r'a\%\_\\b');
    expect(SearchTerms(SearchQuery('수능')).types, ['csat']);
    expect(SearchTerms(SearchQuery('모의평가')).types, ['evaluation_mock']);
  });
  test(
    'same subject attachments aggregate kinds without duplicate cards',
    () async {
      examRows = [exam(0)];
      attachments = [
        for (final kind in ['question', 'question', 'answer', 'explanation'])
          {
            'id': 'r${attachments.length}$kind',
            'content_item_id': 'c0',
            'exam_subject_id': 'o',
            'resource_type': kind,
            'title': kind,
            'source_url': 'https://example.org/file.pdf',
            'link_kind': 'file',
            'display_order': 0,
          },
      ];
      final result = await repository.search(
        SearchQuery('', filters: const SearchFilters(grade: 3)),
      );
      expect(result.items.length, 1);
      expect(result.items.single.groups.single.name, '영어');
      expect(result.items.single.groups.single.kinds, [
        'question',
        'answer',
        'explanation',
      ]);
      expect(result.items.single.exam!.academicYear, isNull);
      expect(result.items.single.sortDate, DateTime(2026, 9, 1));
    },
  );
  test('parent pagination is 24 plus sentinel with stable order', () async {
    examRows = List.generate(49, exam);
    final page = await repository.search(SearchQuery('모의고사'), offset: 24);
    expect(page.items.length, 24);
    expect(page.nextOffset, 48);
    expect(calls.first.queryParameters['offset'], '24');
    expect(calls.first.queryParameters['limit'], '25');
    expect(
      calls
          .where((u) => u.path.endsWith('resources'))
          .single
          .queryParameters['limit'],
      '1000',
    );
  });
  test(
    'overflow and unsafe offsets fail rather than hide attachments',
    () async {
      examRows = [exam(0)];
      resourceCount = 1001;
      await expectLater(
        repository.search(SearchQuery('모의고사')),
        throwsFormatException,
      );
      await expectLater(
        repository.search(SearchQuery(''), offset: 10001),
        throwsFormatException,
      );
    },
  );
  test(
    'dynamic facet pages use public taxonomy and merge without duplicates',
    () async {
      examRows = List.generate(101, exam);
      final facet = await repository.facets();
      expect(facet.years, [2026]);
      expect(facet.months, [9]);
      expect(facet.nextOffset, 100);
      expect(facet.subjects.single.name, '영어');
      expect(facet.merge(facet).subjects.length, 1);
      expect(calls.every((u) => u.queryParameters['limit'] == '101'), isTrue);
    },
  );
  test(
    'exam-to-general boundary uses exact count and no duplicate parents',
    () async {
      examRows = List.generate(23, exam);
      generalRows = [
        for (final n in [30, 31, 32])
          {...parent(n), 'exam': <Map<String, dynamic>>[]},
      ];
      final first = await repository.search(SearchQuery(''));
      expect(first.items.length, 24);
      expect(first.items.last.content.id, 'c30');
      final second = await repository.search(
        SearchQuery(''),
        offset: first.nextOffset!,
      );
      expect(second.items.map((i) => i.content.id), ['c31', 'c32']);
      expect(second.nextOffset, isNull);
      expect(
        {
          ...first.items.map((i) => i.content.id),
          ...second.items.map((i) => i.content.id),
        }.length,
        26,
      );
    },
  );
  test('literal search is safely quoted on each public stream', () async {
    await repository.search(SearchQuery('50%_자료'));
    final exams = calls
        .firstWhere((u) => u.path.endsWith('/exams'))
        .queryParameters;
    final general = calls
        .firstWhere((u) => u.path.endsWith('/content_items'))
        .queryParameters;
    expect(exams['content.or'], contains(r'50\\%\\_자료'));
    expect(exams['content.or'], general['or']);
  });
  test('historical raw subject label survives missing active taxonomy', () {
    final item = ResourceSearchItem.fromRows(
      {...parent(0), 'exam': exam(0)},
      [
        {
          'id': 'o',
          'content_item_id': 'c0',
          'subject_id': null,
          'raw_subject_label': '이전 과목',
          'subject': null,
        },
      ],
      [],
    );
    expect(item.groups.single.name, '이전 과목');
    expect(item.groups.single.kinds, isEmpty);
  });
}
