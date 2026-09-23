import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/profile/avatar.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
);

class Photos implements AvatarRepository {
  Uint8List? value;
  int writes = 0;
  bool fail = false;
  @override
  Future<Uint8List?> load() async => value;
  @override
  Future<void> save(Uint8List bytes) async {
    if (fail) throw Exception();
    writes++;
    value = bytes;
  }

  @override
  Future<void> remove() async {
    writes++;
    value = null;
  }
}

class Picker implements AvatarPicker {
  bool fail = false;
  @override
  Future<Uint8List?> pick() async {
    if (fail) throw Exception();
    return png;
  }
}

class LoadingPhotos extends Photos {
  final loaded = Completer<Uint8List?>();
  @override
  Future<Uint8List?> load() => loaded.future;
}

class DelayedPicker implements AvatarPicker {
  final result = Completer<Uint8List?>();
  @override
  Future<Uint8List?> pick() => result.future;
}

void main() {
  testWidgets('late avatar from A never appears for B or Guest', (t) async {
    final auth = StreamController<AuthStatus>();
    final a = LoadingPhotos(), b = Photos();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => auth.stream),
          avatarRepositoryProvider.overrideWith(
            (ref) => switch (ref.watch(authStateProvider).value?.userId) {
              'a' => a,
              'b' => b,
              _ => null,
            },
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileAvatar())),
      ),
    );
    auth.add(const AuthStatus('a'));
    await t.pump();
    await t.pump();
    auth.add(const AuthStatus(null));
    await t.pump();
    await t.pump();
    auth.add(const AuthStatus('b'));
    await t.pumpAndSettle();
    a.loaded.complete(png);
    await t.pumpAndSettle();
    expect(
      t.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage,
      isNull,
    );
    await t.pumpWidget(const SizedBox());
    unawaited(auth.close());
    await t.pump();
  });
  testWidgets('upload failure retains existing image and permits retry', (
    t,
  ) async {
    final photos = Photos()
      ..value = png
      ..fail = true;
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          avatarRepositoryProvider.overrideWithValue(photos),
          avatarPickerProvider.overrideWithValue(Picker()),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileAvatar())),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('프로필 사진 변경'));
    await t.pumpAndSettle();
    await t.tap(find.text('사진 선택'));
    await t.pumpAndSettle();
    expect(photos.writes, 0);
    expect(photos.value, png);
    expect(find.textContaining('사진을 변경하지 못했어요'), findsOneWidget);
    photos.fail = false;
    await t.tap(find.byTooltip('프로필 사진 변경'));
    await t.pumpAndSettle();
    await t.tap(find.text('사진 선택'));
    await t.pumpAndSettle();
    expect(photos.writes, 1);
  });

  testWidgets('account switch during picker cannot upload for either account', (
    t,
  ) async {
    final auth = StreamController<AuthStatus>();
    final photos = Photos(), picker = DelayedPicker();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => auth.stream),
          avatarRepositoryProvider.overrideWithValue(photos),
          avatarPickerProvider.overrideWithValue(picker),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileAvatar())),
      ),
    );
    auth.add(const AuthStatus('a'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('프로필 사진 변경'));
    await t.pumpAndSettle();
    await t.tap(find.text('사진 선택'));
    await t.pump();
    auth.add(const AuthStatus('b'));
    await t.pump();
    picker.result.complete(png);
    await t.pumpAndSettle();
    expect(photos.writes, 0);
    await t.pumpWidget(const SizedBox());
    unawaited(auth.close());
    await t.pump();
  });

  test(
    'private exact owner path, overwrite, delete and immutable credential',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((r) async {
        requests.add(r);
        return http.Response(
          r.method == 'GET'
              ? 'bytes'
              : r.method == 'DELETE'
              ? '[]'
              : '{"Key":"ok"}',
          200,
        );
      });
      final headers = {'Authorization': 'Bearer offline-owner-a'};
      final repo = StorageAvatarRepository(
        SupabaseStorageClient(
          'https://example.invalid/storage/v1',
          headers,
          httpClient: client,
        ).from(avatarBucket),
        'owner-a',
      );
      headers['Authorization'] = 'Bearer offline-owner-b';
      await repo.load();
      await repo.save(png);
      await repo.remove();
      expect(
        requests.every(
          (r) => r.headers['Authorization'] == 'Bearer offline-owner-a',
        ),
        true,
      );
      expect(
        requests.first.url.path,
        contains('/object/profile-avatars/owner-a/avatar.png'),
      );
      expect(requests.first.url.queryParameters['cacheNonce'], isNotEmpty);
      expect(requests[1].headers['x-upsert'], 'true');
      expect(jsonDecode(requests.last.body)['prefixes'], [
        'owner-a/avatar.png',
      ]);
      await expectLater(
        repo.save(Uint8List(avatarMaxBytes + 1)),
        throwsFormatException,
      );
    },
  );
  test(
    'missing object is empty; bucket or permission failure is error',
    () async {
      for (final code in ['NoSuchKey', 'NoSuchBucket', 'AccessDenied']) {
        final repo = StorageAvatarRepository(
          SupabaseStorageClient(
            'https://example.invalid',
            {},
            httpClient: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'message': 'failure',
                  'error': code,
                  'statusCode': '404',
                }),
                404,
                headers: {'content-type': 'application/json'},
              ),
            ),
          ).from(avatarBucket),
          'a',
        );
        if (code == 'NoSuchKey') {
          expect(await repo.load(), null);
        } else {
          await expectLater(repo.load(), throwsA(isA<StorageException>()));
        }
      }
    },
  );
  testWidgets('pick upload display replace remove; safe failure', (t) async {
    final photos = Photos(), picker = Picker();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          avatarRepositoryProvider.overrideWithValue(photos),
          avatarPickerProvider.overrideWithValue(picker),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileAvatar())),
      ),
    );
    await t.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byTooltip('프로필 사진 변경'));
      await t.pumpAndSettle();
      await t.tap(find.text('사진 선택'));
      await t.pumpAndSettle();
      expect(photos.writes, i + 1);
      expect(
        t.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage,
        isA<MemoryImage>(),
      );
    }
    await t.tap(find.byTooltip('프로필 사진 변경'));
    await t.pumpAndSettle();
    await t.tap(find.text('기본 이미지로 변경'));
    await t.pumpAndSettle();
    expect(photos.value, null);
    picker.fail = true;
    await t.tap(find.byTooltip('프로필 사진 변경'));
    await t.pumpAndSettle();
    await t.tap(find.text('사진 선택'));
    await t.pumpAndSettle();
    expect(photos.writes, 3);
    expect(t.takeException(), null);
  });
}
