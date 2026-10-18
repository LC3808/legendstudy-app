import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';

void main() {
  test('TEST catalog fails before network or token transmission', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('{}', 200);
    });
    await expectLater(
      SourceCatalog.load(
        config: const AppConfig(environment: 'test'),
        accessToken: 'synthetic-test-token',
        client: client,
      ),
      throwsA(isA<StateError>()),
    );
    expect(calls, 0);
    client.close();
  });
  test('Production gateway remains unchanged', () {
    expect(
      const AppConfig(environment: 'production').essayApiOrigin,
      'https://lab.legendstudy.com',
    );
  });
}
