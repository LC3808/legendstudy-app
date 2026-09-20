import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/bookmark_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';

import 'day9_c2_personal_test.dart';

class BatchBookmarks extends FakeBookmarkRepository {
  String owner = 'a';
  final owners = <String, Set<String>>{};
  final batches = <List<String>>[];
  Completer<void>? writeGate, readGate;
  bool readFailure = false, writeFailure = false;
  Set<String> get ids => owners.putIfAbsent(owner, () => {});
  @override
  Future<Set<String>> fetchBookmarkedIds(List<String> requested) async {
    batches.add(List.of(requested));
    final result = ids.intersection(requested.toSet());
    await readGate?.future;
    if (readFailure) throw StateError('private read error');
    return result;
  }

  @override
  Future<bool> isBookmarked(String id) => throw StateError('N+1 forbidden');
  @override
  Future<void> addBookmark(String id) async {
    adds++;
    final target = ids;
    await writeGate?.future;
    if (writeFailure) throw StateError('private write error');
    target.add(id);
  }

  @override
  Future<void> deleteBookmark(String id) async {
    deletes++;
    final target = ids;
    await writeGate?.future;
    if (writeFailure) throw StateError('private write error');
    target.remove(id);
  }
}

class ProbeBookmarks extends SupabaseBookmarkRepository {
  ProbeBookmarks(super.client);
  @override
  String? get userId => 'owner-a';
}

Future<void> flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('bounded batch transport uses one owner-filtered IN query; no recent-100 shortcut', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      httpClient: MockClient((r) async {
        requests.add(r);
        return http.Response(
          '[{"content_item_id":"old-saved"}]',
          200,
          headers: {'content-type': 'application/json'},
          request: r,
        );
      }),
    );
    addTearDown(client.dispose);
    final repo = ProbeBookmarks(client);
    expect(await repo.fetchBookmarkedIds(['old-saved', 'new-unsaved']), {
      'old-saved',
    });
    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
    final q = requests.single.url.queryParameters;
    expect(q['user_id'], 'eq.owner-a');
    expect(q['content_item_id'], contains('old-saved'));
    expect(q['select'], 'content_item_id');
    expect(q['limit'], '100');
    await expectLater(
      repo.fetchBookmarkedIds(List.generate(101, (i) => '$i')),
      throwsArgumentError,
    );
    expect(
      await SupabaseBookmarkRepository(null).fetchBookmarkedIds(['x']),
      isEmpty,
    );
    expect(requests, hasLength(1));
  });

  late BatchBookmarks repo;
  late StreamController<AuthStatus> auth;
  late ProviderContainer c;
  setUp(() async {
    repo = BatchBookmarks();
    auth = StreamController<AuthStatus>.broadcast();
    c = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => auth.stream),
        bookmarkRepositoryProvider.overrideWithValue(repo),
      ],
    );
    c.listen(authStateProvider, (_, _) {});
    auth.add(const AuthStatus('a'));
    await flush();
  });
  tearDown(() async {
    c.dispose();
    await auth.close();
  });
  ProviderSubscription<BookmarkState> watch(String id) =>
      c.listen(bookmarkStateProvider(id), (_, _) {});
  BookmarkState value(String id) => c.read(bookmarkStateProvider(id));
  Future<void> toggle(String id) =>
      c.read(bookmarkStateProvider(id).notifier).toggle();

  test('250 rows coalesce into 3 bounded reads; new pagination IDs only; detail shares state', () async {
    repo.ids.add('249');
    final subscriptions = [for (var i = 0; i < 250; i++) watch('$i')];
    await flush();
    expect(repo.batches.map((b) => b.length), [100, 100, 50]);
    expect(value('249').isSaved, isTrue);
    watch('249');
    watch('new');
    await flush();
    expect(repo.batches.last, ['new']);
    expect(repo.batches, hasLength(4));
    await toggle('1');
    expect(value('1').isSaved, isTrue);
    for (final sub in subscriptions) {
      sub.close();
    }
  });
  test('optimistic add/delete rollback, per-item double tap and other rows remain usable', () async {
    watch('x');
    watch('y');
    await flush();
    repo.writeGate = Completer<void>();
    repo.writeFailure = true;
    final operation = toggle('x');
    expect(value('x').isSaved, isTrue);
    expect(value('x').isMutating, isTrue);
    await toggle('x');
    expect(repo.adds, 1);
    final other = toggle('y');
    expect(repo.adds, 2);
    repo.writeGate!.complete();
    await Future.wait([operation, other]);
    expect(value('x').isSaved, isFalse);
    expect(value('x').message, isNot(contains('private')));
    repo.writeFailure = false;
    await toggle('x');
    repo.writeGate = Completer<void>();
    repo.writeFailure = true;
    final removal = toggle('x');
    expect(value('x').isSaved, isFalse);
    repo.writeGate!.complete();
    await removal;
    expect(value('x').isSaved, isTrue);
    repo.writeFailure = false;
    await toggle('x');
    expect(value('x').isSaved, isFalse);
  });
  test('read failure retry never interprets unknown as unsaved or performs a write', () async {
    repo.ids.add('x');
    repo.readFailure = true;
    watch('x');
    await flush();
    expect(value('x').phase, BookmarkPhase.failure);
    repo.readFailure = false;
    await toggle('x');
    await flush();
    expect(value('x').isSaved, isTrue);
    expect(repo.adds + repo.deletes, 0);
  });
  test('A to Guest to B drops cached and in-flight write completion', () async {
    watch('x');
    await flush();
    repo.writeGate = Completer<void>();
    final pending = toggle('x');
    auth.add(const AuthStatus(null));
    await flush();
    expect(value('x').isSaved, isFalse);
    repo.owner = 'b';
    auth.add(const AuthStatus('b'));
    await flush();
    repo.writeGate!.complete();
    await pending;
    expect(value('x').isSaved, isFalse);
    expect(repo.owners['a'], {'x'});
    expect(repo.ids, isEmpty);
  });
  test(
    'same-owner token refresh retains optimistic operation and avoids rereads',
    () async {
      watch('x');
      await flush();
      repo.writeGate = Completer<void>();
      final pending = toggle('x');
      auth.add(const AuthStatus('a', event: AuthChangeEvent.tokenRefreshed));
      await flush();
      expect(value('x').isSaved, isTrue);
      expect(value('x').isMutating, isTrue);
      expect(repo.batches, hasLength(1));
      await toggle('x');
      expect(repo.adds, 1);
      repo.writeGate!.complete();
      await pending;
      expect(value('x').phase, BookmarkPhase.saved);
    },
  );

  test('stale A read cannot overwrite B or guest', () async {
    repo.ids.add('x');
    repo.readGate = Completer<void>();
    watch('x');
    await flush();
    final old = repo.readGate!;
    repo.readGate = null;
    repo.owner = 'b';
    auth.add(const AuthStatus('b'));
    await flush();
    old.complete();
    await flush();
    expect(value('x').isSaved, isFalse);
    auth.add(const AuthStatus(null));
    await flush();
    final count = repo.batches.length;
    await toggle('x');
    expect(repo.batches.length, count);
    expect(repo.adds, 0);
  });
  test('in-flight write survives tile disposal/re-entry without duplicate; container disposal safe', () async {
    final sub = watch('x');
    await flush();
    repo.writeGate = Completer<void>();
    final pending = toggle('x');
    sub.close();
    await flush();
    watch('x');
    await flush();
    await toggle('x');
    expect(repo.adds, 1);
    expect(value('x').isSaved, isTrue);
    c.dispose();
    repo.writeGate!.complete();
    await pending;
    // ProviderContainer.dispose is idempotent; tearDown remains safe.
  });
}
