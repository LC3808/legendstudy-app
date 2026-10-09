import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/content/data/supabase_content_repository.dart';
import 'package:legendstudy_app/features/materials/data/supabase_search_repository.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';

void main() {
  late SupabaseClient client;
  late List<Uri> calls;
  Map<String, dynamic> content(String id, String type) => {
    'id': id,
    'slug': id,
    'content_type': type,
    'title': id,
    'source_url': 'https://legendstudy.com/1',
    'is_active': true,
    'published_at': '2009-01-01T00:00:00Z',
  };
  final years = [2009, 2010, 2011, 2025];
  setUp(() {
    calls = [];
    client = SupabaseClient(
      'https://example.org',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        calls.add(request.url);
        final q = request.url.queryParameters;
        final table = request.url.pathSegments.last;
        List<Map<String, dynamic>> rows = [];
        if (table == 'exams') {
          // Assert the server filter exists before simulating SQL >= semantics.
          expect(q['content.is_active'], 'eq.true');
          rows = [
            for (final year in years)
              {
                'content_item_id': 'e$year',
                'year': year,
                'grade_level': 3,
                'exam_type': 'national_mock',
                'content': content('e$year', 'exam'),
              },
          ];
          if (q['year'] != null) {
            rows = rows.where((r) => 'eq.${r['year']}' == q['year']).toList();
          }
        } else if (table == 'content_items') {
          if (q.containsKey('slug')) {
            expect(q.containsKey('discovery_exam.year'), false);
            return http.Response(
              jsonEncode(content('e2009', 'exam')),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(q.containsKey('discovery_exam.year'), false);
          final advanced = q['select']!.contains('exam:exams');
          rows = [
            for (final year in years)
              {
                ...content('e$year', 'exam'),
                if (advanced)
                  'exam': [
                    {
                      'content_item_id': 'e$year',
                      'year': year,
                      'grade_level': 3,
                      'exam_type': 'national_mock',
                    },
                  ],
              },
          ];
          if (q['exam.year'] != null) {
            rows = rows
                .where(
                  (r) =>
                      'eq.${(r['exam'] as List).single['year']}' ==
                      q['exam.year'],
                )
                .toList();
          } else {
            rows.addAll([
              content('essay2009', 'university_essay'),
              content('general2009', 'study_material'),
            ]);
          }
        }
        final count = rows.length;
        rows = rows
            .skip(int.parse(q['offset'] ?? '0'))
            .take(int.parse(q['limit'] ?? '100'))
            .toList();
        return http.Response(
          jsonEncode(rows),
          200,
          request: request,
          headers: {
            'content-type': 'application/json',
            'content-range': '0-${rows.isEmpty ? 0 : rows.length - 1}/$count',
          },
        );
      }),
    );
  });
  tearDown(() => client.dispose());

  test('browse includes every active year in one parent stream', () async {
    final page = await SupabaseSearchRepository(client).search(SearchQuery(''));
    expect(page.items.map((r) => r.content.id), [
      'e2009',
      'e2010',
      'e2011',
      'e2025',
      'essay2009',
    ]);
  });
  test('explicit older year is searchable', () async {
    final page = await SupabaseSearchRepository(client)
        .search(SearchQuery('', filters: const SearchFilters(year: 2009)));
    expect(page.items.single.content.id, 'e2009');
  });
  test('2010 is included with explicit year filter', () async {
    final page = await SupabaseSearchRepository(client)
        .search(SearchQuery('', filters: const SearchFilters(year: 2010)));
    expect(page.items.single.content.id, 'e2010');
  });
  test('facets only advertise visible exam years', () async {
    final facets = await SupabaseSearchRepository(client).facets();
    expect(facets.years, containsAll([2010, 2011, 2025]));
    expect(facets.years, contains(2009));
  });
  test(
    'Home and legacy search share visibility without removing old essays',
    () async {
      final repo = SupabaseContentRepository(client);
      for (final rows in [
        await repo.fetchRecentContent(),
        await repo.searchContent('자료'),
      ]) {
        expect(rows.map((r) => r.id), [
          'e2009',
          'e2010',
          'e2011',
          'e2025',
          'essay2009',
          'general2009',
        ]);
      }
    },
  );
  test('direct saved/history detail remains accessible', () async {
    expect(
      (await SupabaseContentRepository(client).fetchContentBySlug('e2009'))!.id,
      'e2009',
    );
  });
}
