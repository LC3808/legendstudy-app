import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';
import 'package:legendstudy_app/features/essay/essay_live_gateway.dart';

import 'essay_live_gateway_test.dart' show FakeEssayStore;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final disk = <String, String>{};
  setUp(() {
    disk.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
          if (call.method == 'read') return disk[call.arguments];
          if (call.method == 'write') {
            final a = call.arguments as Map;
            disk[a['key'] as String] = a['value'] as String;
          }
          return null;
        });
  });
  SourceDraftGateway subject(FakeEssayStore store) => SourceDraftGateway(
    'owner',
    'source:question',
    remote: SupabaseEssayGateway(store, questionId: 'q', writesEnabled: true),
  );
  test(
    'server draft restores locally without loading results or billing',
    () async {
      final store = FakeEssayStore();
      final draft = subject(store);
      expect((await draft.openSharedDraft()).body, '답안');
      expect((await draft.loadDraft()).body, '답안');
      await draft.saveDraft('수정', 1);
      expect(store.calls, ['essay_open_session', 'essay_save_draft']);
      expect(draft.syncNotice, contains('다른 기기'));
    },
  );
  test(
    'nonempty local conflict retains both bodies and performs no remote save',
    () async {
      final store = FakeEssayStore();
      final draft = subject(store);
      disk[draft.key] = jsonEncode({'body': 'local', 'revision': 1});
      expect((await draft.openSharedDraft()).body, 'local');
      expect(draft.remoteBody, '답안');
      expect(draft.syncConflict, true);
      await draft.saveDraft('local modified', 1);
      expect(store.calls, ['essay_open_session']);
      expect((await draft.loadDraft()).body, 'local modified');
    },
  );
  test(
    'connection error and long local answers preserve local content',
    () async {
      final store = FakeEssayStore();
      final draft = subject(store);
      await draft.openSharedDraft();
      final body = 'x' * 20001;
      await draft.saveDraft(body, 1);
      expect((await draft.loadDraft()).body, body);
      expect(store.calls, ['essay_open_session']);
      store.handler = (_, _) async => throw Exception('offline');
      await draft.saveDraft('offline answer', 2);
      expect((await draft.loadDraft()).body, 'offline answer');
      expect(draft.syncNotice, contains('유지'));
    },
  );
}
