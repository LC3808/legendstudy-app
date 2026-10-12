import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const body =
      '{"version":"essay-source-registry-v1","universities":[],"exams":[]}';
  test('private query uses bearer; public fallback carries no token', () async {
    final calls = <http.Request>[];
    final client = MockClient((request) async {
      calls.add(request);
      return http.Response(body, request.method == 'POST' ? 503 : 200);
    });
    await SourceCatalog.load(accessToken: 'fixture', client: client);
    expect(calls.map((r) => r.method), ['POST', 'GET']);
    expect(calls.first.headers['authorization'], 'Bearer fixture');
    expect(calls.last.headers.containsKey('authorization'), false);
    calls.clear();
    await SourceCatalog.load(client: client);
    expect(calls.single.method, 'GET');
  });
  test(
    'ordered image draft survives failed manifest and preserves legacy',
    () async {
      final json = <String, String>{};
      final images = <String, Uint8List>{};
      var fail = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
            final a = call.arguments;
            if (call.method == 'read') return json[a];
            if (call.method == 'readImage') return images[a];
            final args = a as Map;
            if (call.method == 'writeImage') {
              images[args['key']] = args['value'];
              return null;
            }
            if (fail) throw PlatformException(code: 'IO');
            final old = json[args['key']];
            expect(
              args['expected'],
              old == null ? 0 : jsonDecode(old)['revision'],
            );
            json[args['key']] = args['value'];
            return null;
          });
      final gateway = SourceDraftGateway('a', 'q');
      final first = Uint8List.fromList([1, 2]),
          second = Uint8List.fromList([3, 4]);
      images[gateway.key] = first;
      expect((await gateway.loadImages()).single, first);
      await gateway.saveImages([first, second]);
      expect(await SourceDraftGateway('a', 'q').loadImages(), [first, second]);
      expect(await SourceDraftGateway('b', 'q').loadImages(), isEmpty);
      fail = true;
      await expectLater(
        gateway.saveImages([second]),
        throwsA(isA<PlatformException>()),
      );
      expect(await SourceDraftGateway('a', 'q').loadImages(), [first, second]);
      fail = false;
      await gateway.saveImages([second]);
      expect(await SourceDraftGateway('a', 'q').loadImages(), [second]);
      await gateway.saveImages([]);
      expect(await SourceDraftGateway('a', 'q').loadImages(), isEmpty);
    },
  );
}
