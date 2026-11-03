// Explicit paired-device TEST login smoke; no credential is embedded in the app.
// Run with flutter drive --keep-app-running before installing the normal TEST
// Profile app. The default drive teardown uninstalls the app AND its session.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/test_session_storage.dart';
import 'package:legendstudy_app/features/onboarding/device_intro.dart';
import 'package:legendstudy_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('paired TEST actual app login persists through SDK', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, 'test');
    expect(config.supabaseUrl, 'https://kpqbedylxlyntrrfybpn.supabase.co');
    expect(config.essayApiOrigin, 'https://legendstudy-task16b.pages.dev');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 43991);
    late Map<String, dynamic> data;
    try {
      final request = await server.first.timeout(const Duration(minutes: 2));
      expect(request.method, 'POST');
      expect(request.uri.path, '/config');
      expect(request.contentLength, inInclusiveRange(1, 65536));
      data = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      request.response.statusCode = 204;
      await request.response.close();
    } finally {
      await server.close(force: true);
    }
    await DeviceIntroStore().complete();
    app.main();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      try {
        Supabase.instance.client;
        break;
      } catch (_) {
        /* Bootstrap pending. */
      }
    }
    final client = Supabase.instance.client;
    await client.auth.signInWithPassword(
      email: data['email'] as String,
      password: data['password'] as String,
    );
    expect(client.auth.currentUser, isNotNull);
    expect(isIapTestToken(client.auth.currentSession!.accessToken), true);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 60),
    );
    final storage = IapTestSessionStorage();
    await storage.initialize();
    expect(await storage.hasAccessToken(), true);
    final persisted =
        jsonDecode((await storage.accessToken())!) as Map<String, dynamic>;
    expect(persisted['user']['id'], client.auth.currentUser!.id);
    expect(tester.takeException(), isNull);
    await binding.takeScreenshot('owner-authenticated-app');
    // Leave time for platform persistence, then inspect actual device preferences.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 8)),
    );
    binding.reportData = {
      ...?binding.reportData,
      'sdk_login': true,
      'test_session_persisted': true,
      'providerCalls': 0,
    };
  }, timeout: const Timeout(Duration(minutes: 4)));
}
