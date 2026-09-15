import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/content/data/supabase_content_repository.dart';
import 'package:legendstudy_app/features/exams/data/supabase_exam_repository.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/exams/presentation/exam_labels.dart';
import 'package:legendstudy_app/features/resources/data/supabase_resource_repository.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';

Map<String, dynamic> resourceJson({Map<String, dynamic>? occurrence}) => {
  'id': 'resource-1',
  'content_item_id': 'parent-1',
  'exam_subject_id': occurrence == null ? null : 'occurrence-1',
  'resource_type': 'question',
  'title': '원본 문제',
  'source_label': '원본 링크',
  'source_url': 'https://example.org/page',
  'link_kind': 'file',
  'file_url': 'https://example.org/file.pdf',
  'mime_type': 'application/pdf',
  'file_extension': 'pdf',
  'file_size': 123,
  'display_order': 0,
  'is_active': true,
  'occurrence': occurrence,
};
void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  late List<Map<String, dynamic>> rows;
  var paged = false;
  setUp(() {
    paged = false;
    requests = [];
    rows = [];
    client = SupabaseClient(
      'https://example.invalid',
      'test-public-client',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(paged && requests.length > 1 ? [] : rows),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());

  for (final query in ['', '영어 100%_']) {
    test(
      'parent type filter with query "$query" preserves projection and order',
      () async {
        await SupabaseContentRepository(
          client,
        ).searchContent(query, contentType: 'exam');
        final p = requests.single.url.queryParameters;
        expect(p['content_type'], 'eq.exam');
        expect(p['is_active'], 'eq.true');
        expect(p['select'], SupabaseContentRepository.projection);
        expect(p['order'], 'feed_updated_at.desc.nullslast,id.desc.nullslast');
        expect(p['limit'], '30');
        if (query.isEmpty) {
          expect(p.containsKey('or'), isFalse);
        } else {
          expect(
            requests.single.url.queryParametersAll['or']!.join(),
            contains(r'\\%\\_'),
          );
        }
      },
    );
  }
  test('keyword-only search has no type predicate', () async {
    await SupabaseContentRepository(client).searchContent('영어');
    expect(
      requests.single.url.queryParameters.containsKey('content_type'),
      isFalse,
    );
  });
  test(
    'invalid types and query guards reject before filtered network requests',
    () async {
      final repo = SupabaseContentRepository(client);
      for (final q in ['*', 'x' * 201, 'a b c d e f g h i']) {
        await expectLater(
          repo.searchContent(q, contentType: 'exam'),
          throwsFormatException,
        );
      }
      await expectLater(
        repo.searchContent('', contentType: 'unknown'),
        throwsFormatException,
      );
      await expectLater(
        repo.searchContent('', contentType: 'exam', limit: 101),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
    },
  );
  test('exam query is batched and selects only granted fields', () async {
    rows = [
      {
        'content_item_id': 'a',
        'year': 2026,
        'academic_year': 2027,
        'exam_month': 9,
        'grade_level': 3,
        'exam_type': 'evaluation_mock',
      },
    ];
    final result = await SupabaseExamRepository(
      client,
    ).fetchForContentIds(['a', 'b']);
    expect(result['a']!.academicYear, 2027);
    expect(requests.single.url.path, '/rest/v1/exams');
    expect(
      requests.single.url.queryParameters['select'],
      SupabaseExamRepository.projection,
    );
    expect(
      requests.single.url.queryParameters['content_item_id'],
      'in.("a","b")',
    );
    expect(
      requests.single.url.queryParameters['select'],
      isNot(contains('raw_')),
    );
  });
  test('empty exam batch avoids request and oversize batch fails', () async {
    final repo = SupabaseExamRepository(client);
    expect(await repo.fetchForContentIds([]), isEmpty);
    await expectLater(
      repo.fetchForContentIds(List.filled(101, 'a')),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
  });
  test(
    'exam nulls are omitted and academic year never replaces calendar year',
    () {
      const empty = ExamMetadata(contentItemId: 'a');
      expect(examSummary(empty), isEmpty);
      expect(examDetails(empty), isEmpty);
      const exam = ExamMetadata(
        contentItemId: 'a',
        academicYear: 2027,
        gradeLevel: 3,
        examMonth: 9,
        examType: 'evaluation_mock',
      );
      expect(examSummary(exam), '고3 · 9월 · 평가원');
      expect(examDetails(exam), ['고3 · 9월 · 평가원', '2027학년도']);
    },
  );
  test(
    'resource query uses actual public fields and left relationships',
    () async {
      rows = [
        resourceJson(
          occurrence: {'raw_subject_label': '수학 가형', 'subject': null},
        ),
      ];
      final result = await SupabaseResourceRepository(
        client,
      ).fetchForContent('parent-1');
      final p = requests.single.url.queryParameters;
      expect(p['select'], SupabaseResourceRepository.projection);
      expect(p['select'], contains('file_extension,file_size'));
      expect(p['select'], isNot(contains('link_status')));
      expect(p['select'], isNot(contains('!inner')));
      expect(p['content_item_id'], 'eq.parent-1');
      expect(p['is_active'], 'eq.true');
      expect(p['order'], 'display_order.asc.nullslast,id.asc.nullslast');
      expect(result.single.groupLabel, '수학 가형');
      expect(result.single.fileSize, 123);
    },
  );
  test('resource paging keeps all rows at the page boundary', () async {
    paged = true;
    rows = List.generate(
      100,
      (i) => {...resourceJson(), 'id': 'resource-$i', 'display_order': i},
    );
    final result = await SupabaseResourceRepository(
      client,
    ).fetchForContent('parent-1');
    expect(result, hasLength(100));
    expect(requests, hasLength(2));
    expect(requests[1].url.queryParameters['offset'], '100');
    expect(result.last.id, 'resource-99');
  });
  for (final state in ['active', 'inactive', 'missing', 'unmapped']) {
    test('subject fallback keeps resource for $state taxonomy', () {
      final occurrence = <String, dynamic>{'raw_subject_label': '수학 나형'};
      if (state != 'missing' && state != 'unmapped') {
        occurrence['subject'] = {'name': '수학', 'is_active': state == 'active'};
      }
      final resource = ContentResource.fromJson(
        resourceJson(occurrence: occurrence),
      );
      expect(resource.id, 'resource-1');
      expect(resource.groupLabel, state == 'active' ? '수학' : '수학 나형');
    });
  }
  test('missing occurrence and empty raw label use general group', () {
    expect(ContentResource.fromJson(resourceJson()).groupLabel, '일반 자료');
    expect(
      ContentResource.fromJson(
        resourceJson(occurrence: {'raw_subject_label': ' '}),
      ).groupLabel,
      '일반 자료',
    );
  });
  test(
    'resource title and source label take priority over purpose fallback',
    () {
      final json = resourceJson();
      expect(ContentResource.fromJson(json).displayTitle, '원본 문제');
      json['title'] = '';
      expect(ContentResource.fromJson(json).displayTitle, '원본 링크');
      json['source_label'] = null;
      expect(ContentResource.fromJson(json).displayTitle, '문제');
    },
  );
  test('resource URL choice respects link kind and safe HTTP boundary', () {
    final json = resourceJson();
    expect(
      ContentResource.fromJson(json).openUri.toString(),
      'https://example.org/file.pdf',
    );
    json['link_kind'] = 'landing_page';
    expect(
      ContentResource.fromJson(json).openUri.toString(),
      'https://example.org/page',
    );
    json['link_kind'] = 'unknown';
    json['file_url'] = null;
    expect(ContentResource.fromJson(json).openUri, isNull);
    expect(
      resolveResourceOpenUri(
        ContentResource.fromJson(json),
        'https://legendstudy.com/post',
      ).toString(),
      'https://legendstudy.com/post',
    );
    json['link_kind'] = 'landing_page';
    expect(
      resolveResourceOpenUri(
        ContentResource.fromJson(json),
        'https://legendstudy.com/post',
      ).toString(),
      'https://example.org/page',
    );
    json['link_kind'] = 'file';
    json['file_url'] = null;
    expect(
      resolveResourceOpenUri(
        ContentResource.fromJson(json),
        'https://legendstudy.com/post',
      ),
      isNull,
    );
    expect(resourceTypeLabels['question'], '문제');
    expect(resourceTypeLabels['answer_explanation'], '정답·해설');
    expect(resourceTypeLabels['listening_audio'], '영어 듣기');
    json['link_kind'] = 'unknown';
    expect(
      resolveResourceOpenUri(ContentResource.fromJson(json), 'javascript:bad'),
      isNull,
    );
    json['link_kind'] = 'file';
    json['file_url'] = 'javascript:bad';
    expect(
      resolveResourceOpenUri(
        ContentResource.fromJson(json),
        'https://legendstudy.com/post',
      ),
      isNull,
    );
    json['source_url'] = 'javascript:alert(1)';
    expect(ContentResource.fromJson(json).openUri, isNull);
    for (final url in [
      'file:///tmp/x',
      'intent://app',
      'https://user:password@example.org',
      'https://example.org/\nfoo',
    ]) {
      expect(publicWebUri(url), isNull);
    }
  });
}
