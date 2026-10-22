import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/features/billing/billing_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/network/review_read_only_client.dart';

void main() {
  test('explicit factory and native billing respect review build flag', () {
    final client = reviewHttpClient();
    expect(client is ReviewReadOnlyClient, reviewReadOnly);
    client.close();
    if (reviewReadOnly ||
        !const bool.fromEnvironment(
          'IAP_TRANSACTIONS_ENABLED',
          defaultValue: true,
        )) {
      final container = ProviderContainer();
      expect(container.read(iapControllerProvider), isNull);
      container.dispose();
    }
  });
  const origin = 'https://stlhijzpjfgwwdgunlsd.supabase.co';
  test(
    'SDK mutations and Edge never reach transport; reads still work',
    () async {
      var sent = 0;
      final transport = ReviewReadOnlyClient(
        MockClient((r) async {
          sent++;
          return http.Response(
            r.url.path.contains('/rpc/') ? '{}' : '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: r,
          );
        }),
      );
      final client = SupabaseClient(
        origin,
        'test-public-key',
        httpClient: transport,
      );
      for (final table in [
        'profiles',
        'recent_views',
        'bookmarks',
        'study_sessions',
        'day_targets',
        'student_target_universities',
        'push_tokens',
      ]) {
        await expectLater(
          client.from(table).upsert({'id': 'test'}),
          throwsA(anything),
        );
      }
      for (final rpc in [
        'essay_submit_attempt',
        'essay_exam_submit_cycle',
        'essay_save_draft',
        'user_notifications_mark_all_read',
        'account_deletion_request',
        'iap_post_verified_purchase',
        'unknown',
      ]) {
        await expectLater(client.rpc<dynamic>(rpc), throwsA(anything));
      }
      await expectLater(
        client.functions.invoke('verify-iap-purchase'),
        throwsA(anything),
      );
      expect(sent, 0);
      await client.from('profiles').select();
      await client.rpc<dynamic>('credit_summary');
      expect(sent, 2);
      await client.dispose();
    },
  );
  test('all default HTTP clients in review zone are guarded', () async {
    var sent = 0;
    await http.runWithClient(
      () async {
        await expectLater(
          http.post(Uri.parse('$origin/rest/v1/study_sessions')),
          throwsA(isA<ReviewWriteBlocked>()),
        );
        await http.get(
          Uri.parse('https://lab.legendstudy.com/api/essay/catalog'),
        );
      },
      () => ReviewReadOnlyClient(
        MockClient((r) async {
          sent++;
          return http.Response('{}', 200);
        }),
      ),
    );
    expect(sent, 1);
  });
  test('catalog POST is read-only, exam POST remains blocked', () {
    expect(
      ReviewReadOnlyClient.allows(
        http.Request(
          'POST',
          Uri.parse('$origin/rest/v1/rpc/essay_browse_catalog'),
        ),
      ),
      true,
    );
    expect(
      ReviewReadOnlyClient.allows(
        http.Request(
          'POST',
          Uri.parse('https://lab.legendstudy.com/api/essay/catalog'),
        ),
      ),
      true,
    );
    expect(
      ReviewReadOnlyClient.allows(
        http.Request(
          'POST',
          Uri.parse('https://lab.legendstudy.com/api/essay/exam'),
        ),
      ),
      false,
    );
  });
  test('auth/environment and redirects fail closed', () async {
    for (final path in [
      '/auth/v1/signup',
      '/auth/v1/user',
      '/functions/v1/resolve',
      '/rest/v1/rpc/essay_open_session',
      '/storage/v1/object/avatar',
    ]) {
      expect(
        ReviewReadOnlyClient.allows(
          http.Request('POST', Uri.parse('$origin$path')),
        ),
        false,
      );
    }
    expect(
      ReviewReadOnlyClient.allows(
        http.Request(
          'POST',
          Uri.parse('$origin/auth/v1/token?grant_type=password'),
        ),
      ),
      true,
    );
    expect(
      ReviewReadOnlyClient.allows(
        http.Request(
          'GET',
          Uri.parse(
            'https://kpqbedylxlyntrrfybpn.supabase.co/rest/v1/profiles',
          ),
        ),
      ),
      false,
    );
    final client = ReviewReadOnlyClient(
      MockClient((r) async {
        expect(r.followRedirects, false);
        return http.Response('', 302);
      }),
    );
    await client.get(Uri.parse('$origin/rest/v1/profiles'));
    client.close();
  });
}
