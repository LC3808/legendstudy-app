import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/universities/data/university_repository.dart';

void main() {
  test(
    'shared catalog aliases preserve active filter and server IDs',
    () async {
      final queries = <String>[];
      final client = SupabaseClient(
        'https://example.test',
        'public-test-key',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/rest/v1/universities');
          expect(request.url.queryParameters['is_active'], 'eq.true');
          queries.add(request.url.queryParameters['name']!);
          return http.Response(
            jsonEncode([
              {'id': 'original-id', 'name': '한국교원대학교', 'slug': 'knue'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      final repo = SupabaseUniversityRepository(client);
      for (final query in [' 한국 교원대 ', 'KNUE', '국립부경대', '카이스트', '서울교대']) {
        expect((await repo.searchCatalog(query)).single.id, 'original-id');
      }
      expect(queries, [
        'ilike.%한국교원대%',
        'ilike.%한국교원대학교%',
        'ilike.%부경대%',
        'ilike.%한국과학기술원%',
        'ilike.%서울교육대학교%',
      ]);
      expect(await repo.searchCatalog('  '), isEmpty);
      expect(queries.length, 5);
      await client.dispose();
    },
  );
}
