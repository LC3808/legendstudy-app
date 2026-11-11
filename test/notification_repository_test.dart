import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/notifications/data/notification_repository.dart';

void main() {
  SupabaseNotificationRepository repository(Object? data, {int status = 200}) {
    final client = SupabaseClient(
      'https://example.invalid',
      'fixture-publishable-key',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/user_notifications_list');
        expect(jsonDecode(request.body), {
          'p_limit': 50,
          'p_offset': 0,
          'p_unread_only': false,
        });
        return http.Response(
          jsonEncode(data),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    return SupabaseNotificationRepository(client);
  }

  test(
    'existing RPC contract accepts successful empty and nonempty results',
    () async {
      expect(
        (await repository({
          'dto_version': 'notification-v1',
          'items': <Object?>[],
        }).list()).items,
        isEmpty,
      );
      final result = await repository({
        'dto_version': 'notification-v1',
        'items': [
          {'id': 'one', 'title': '새 소식', 'is_read': false},
        ],
        'unread': 1,
      }).list();
      expect(result.items.single.title, '새 소식');
      expect(result.unread, 1);
    },
  );
  for (final malformed in [
    null,
    <Object?>[],
    <String, dynamic>{},
    {'items': <Object?>[]},
    {'dto_version': 'notification-v1'},
    {'dto_version': 'notification-v1', 'items': 'invalid'},
    {
      'dto_version': 'notification-v1',
      'items': ['invalid'],
    },
    {
      'dto_version': 'notification-v1',
      'items': [
        {'id': ''},
      ],
    },
  ]) {
    test('malformed response is not an empty inbox: $malformed', () async {
      await expectLater(
        repository(malformed).list(),
        throwsA(isA<FormatException>()),
      );
    });
  }
  test('missing production RPC preserves the API error', () async {
    await expectLater(
      repository({
        'message': 'missing',
        'code': 'PGRST202',
      }, status: 404).list(),
      throwsA(
        isA<PostgrestException>().having((e) => e.code, 'code', 'PGRST202'),
      ),
    );
  });
}
