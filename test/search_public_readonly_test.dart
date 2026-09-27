import 'dart:convert';
import 'dart:io';

import 'package:legendstudy_app/features/content/data/supabase_content_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/materials/data/supabase_search_repository.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';

// Explicit opt-in. No Auth sign-in, writes, fixtures or raw response output.
class _PublicNetwork extends HttpOverrides {}

void main() {
  const enabled = bool.fromEnvironment('SEARCH_PUBLIC_READONLY');
  test('public search repository live read-only contract', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      SupabaseClient? client;
      try {
        const path = String.fromEnvironment('SEARCH_CONFIG_PATH');
        final config =
            jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
        final url = config['SUPABASE_URL'] as String;
        if (Uri.parse(url).host != 'stlhijzpjfgwwdgunlsd.supabase.co') {
          throw const FormatException('project mismatch');
        }
        final key =
            (config['SUPABASE_PUBLISHABLE_KEY'] ?? config['SUPABASE_ANON_KEY'])
                as String;
        client = SupabaseClient(
          url,
          key,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        final repo = SupabaseSearchRepository(client);
        final browse = await repo.search(SearchQuery(''));
        // A later content-ingestion run is allowed; IDs and paging stay typed.
        expect(
          browse.items.length,
          lessThanOrEqualTo(SupabaseSearchRepository.pageSize),
        );
        expect(
          (await repo.search(
            SearchQuery('', filters: const SearchFilters(year: 2009)),
          )).items,
          isEmpty,
        );
        final y2010 = await repo.search(
          SearchQuery('', filters: const SearchFilters(year: 2010)),
        );
        expect(y2010.items, isNotEmpty);
        expect(y2010.items.every((item) => item.exam?.year == 2010), true);
        await SupabaseContentRepository(client).fetchRecentContent();
        await SupabaseContentRepository(client).searchContent('논술');
        await repo.search(SearchQuery('2026 9 월 고3 영어 문제'));
        await repo.search(SearchQuery('9월 모의평가'));
        await repo.search(SearchQuery('2025 수능 수학'));
        await repo.search(
          SearchQuery(
            '',
            filters: const SearchFilters(
              subjectId: '00000000-0000-0000-0000-000000000001',
            ),
          ),
        );
        await repo.search(SearchQuery(''), offset: 10);
        await repo.facets();
        await repo.facets(offset: 100);
        // ignore: avoid_print
        print('SEARCH_PUBLIC PASS read_only_repository');
      } catch (error) {
        final code =
            error is PostgrestException &&
                RegExp(r'^[A-Z0-9]{5,12}$').hasMatch(error.code ?? '')
            ? error.code
            : 'unavailable';
        fail('Public read-only verification failed: $code');
      } finally {
        await client?.dispose();
      }
    }, _PublicNetwork());
  }, skip: !enabled);
}
