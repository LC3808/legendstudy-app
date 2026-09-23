import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/study/data/study_repository.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';

const owner = '11111111-1111-4111-8111-111111111111';
const config = AppConfig(
  supabaseUrl: 'https://stlhijzpjfgwwdgunlsd.supabase.co',
  supabasePublishableKey: 'sb_publishable_offline',
);
Future<void> login(SupabaseClient client, String id, String token) =>
    client.auth.setInitialSession(
      jsonEncode({
        'access_token': token,
        'refresh_token': 'offline-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': id,
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'offline@example.invalid',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
StudyRecord record(String id, {int? start}) => StudyRecord(
  id: id,
  startedMs: start ?? DateTime.utc(2026, 9, 14).millisecondsSinceEpoch,
  endedMs: (start ?? DateTime.utc(2026, 9, 14).millisecondsSinceEpoch) + 180000,
  segments: [
    const ActiveSegment(0, 60000),
    const ActiveSegment(120000, 180000),
  ],
);
Map<String, dynamic> row(StudyRecord r) => {
  ...r.payload(),
  'user_id': owner,
  'duration_seconds': 120,
  'created_at': '2026-09-14T00:00:00Z',
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  setUp(() async {
    client = SupabaseClient(
      'https://example.invalid',
      'offline',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await login(client, owner, 'offline-a');
  });
  tearDown(() => client.dispose());
  test(
    'excluded mock payload/readback and missing migration fail safely',
    () async {
      final now = DateTime.utc(2026, 9, 23).millisecondsSinceEpoch;
      final r = StudyRecord(
        id: 'mock',
        startedMs: now,
        endedMs: now + 120000,
        segments: [const ActiveSegment(0, 120000)],
        mode: 'mock_exam',
        title: '시험',
        plannedSeconds: 4800,
        includeInStudyTotal: false,
      );
      final transport = MockClient((req) async {
        if (req.method == 'POST') {
          expect(jsonDecode(req.body)['include_in_study_total'], false);
        }
        return http.Response(
          jsonEncode([row(r)]),
          req.method == 'POST' ? 201 : 200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await SupabaseStudyRepository.bind(
        client,
        config,
        transport,
      ).insertCompleted(r);
      final restored = await SupabaseStudyRepository.bind(
        client,
        config,
        transport,
      ).fetchWindow(now);
      expect(restored.single.includeInStudyTotal, false);
      expect(restored.single.activeMs, 120000);
      final old = MockClient(
        (_) async => http.Response('{"code":"PGRST204"}', 400),
      );
      await expectLater(
        SupabaseStudyRepository.bind(client, config, old).insertCompleted(r),
        throwsA(isA<StudyStorageError>()),
      );
    },
  );
  test('narrow immutable POST and confirmation preserve request identity through switch', () async {
    final requests = <http.Request>[];
    final r = record('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
    final transport = MockClient((req) async {
      requests.add(req);
      return http.Response(
        jsonEncode([row(r)]),
        req.method == 'POST' ? 201 : 200,
      );
    });
    final repo = SupabaseStudyRepository.bind(client, config, transport);
    await login(client, '22222222-2222-4222-8222-222222222222', 'offline-b');
    await repo.insertCompleted(r);
    expect(jsonDecode(requests.first.body), r.payload());
    expect(jsonDecode(requests.first.body).keys, isNot(contains('user_id')));
    expect(
      jsonDecode(requests.first.body).keys,
      isNot(contains('duration_seconds')),
    );
    expect(
      requests.every((r) => r.url.path == '/rest/v1/study_sessions'),
      isTrue,
    );
    expect(
      requests.every((r) => r.headers['Authorization'] == 'Bearer offline-a'),
      isTrue,
    );
    expect(requests.first.headers['Prefer'], contains('ignore-duplicates'));
    expect(requests.every((r) => r.method != 'PATCH'), isTrue);
  });
  test(
    'duplicate retry verifies whole row and mismatch is not success',
    () async {
      final r = record('a');
      final transport = MockClient(
        (req) async => http.Response(
          jsonEncode(
            req.method == 'POST'
                ? []
                : [
                    {...row(r), 'title': 'different'},
                  ],
          ),
          200,
        ),
      );
      await expectLater(
        SupabaseStudyRepository.bind(
          client,
          config,
          transport,
        ).insertCompleted(r),
        throwsA(isA<StudyStorageError>()),
      );
    },
  );
  test(
    '2000 plus sentinel overflow, fixed KST bounds and keyset pagination',
    () async {
      var pages = 0;
      final start = DateTime.utc(2026, 9, 14).millisecondsSinceEpoch;
      final transport = MockClient((req) async {
        final q = req.url.queryParameters;
        expect(q['user_id'], 'eq.$owner');
        expect(q['and'], contains('2026-09-06T15:00:00.000Z'));
        if (pages > 0) expect(q['or'], contains('started_at.lt.'));
        final count = pages == 20 ? 1 : 100;
        expect(q['limit'], '$count');
        final base = pages++ * 100;
        return http.Response(
          jsonEncode(
            List.generate(
              count,
              (i) =>
                  row(record('${base + i}', start: start - (base + i) * 1000)),
            ),
          ),
          200,
        );
      });
      await expectLater(
        SupabaseStudyRepository.bind(
          client,
          config,
          transport,
        ).fetchWindow(start),
        throwsA(isA<StudyHistoryLimit>()),
      );
      expect(pages, 21);
    },
  );
  test('keyset cursor retains PostgreSQL sub-millisecond precision', () async {
    var pages = 0;
    final start = DateTime.utc(2026, 9, 14).millisecondsSinceEpoch;
    final transport = MockClient((req) async {
      if (pages++ == 0) {
        return http.Response(
          jsonEncode(
            List.generate(100, (i) {
              final value = row(record('$i', start: start - i * 1000));
              value['started_at'] = (value['started_at'] as String)
                  .replaceFirst('.000Z', '.000123Z');
              return value;
            }),
          ),
          200,
        );
      }
      expect(req.url.queryParameters['or'], contains('000123Z'));
      return http.Response('[]', 200);
    });
    final fetched = await SupabaseStudyRepository.bind(
      client,
      config,
      transport,
    ).fetchWindow(start);
    expect(fetched.length, 100);
    expect(pages, 2);
  });
  test(
    'short page ends fetch, generated value verified, own DELETE only',
    () async {
      final r = record('a');
      final requests = <http.Request>[];
      final transport = MockClient((req) async {
        requests.add(req);
        return http.Response(jsonEncode([row(r)]), 200);
      });
      final repo = SupabaseStudyRepository.bind(client, config, transport);
      expect((await repo.fetchWindow(r.startedMs)).single.activeMs, 120000);
      await repo.deleteOwn(r.id);
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.queryParameters['user_id'], 'eq.$owner');
    },
  );
}
