import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/test_session_storage.dart';
import 'package:legendstudy_app/features/billing/purchase_verification.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

String jwt(String issuer) =>
    'e30.${base64Url.encode(utf8.encode(jsonEncode({'iss': issuer}))).replaceAll('=', '')}.signature';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'explicit TEST cannot target Production; production cannot target TEST',
    () {
      for (final env in ['test', 'production', 'development']) {
        for (final host in ['kpqbedylxlyntrrfybpn', 'stlhijzpjfgwwdgunlsd']) {
          final config = AppConfig(
            environment: env,
            supabaseUrl: 'https://$host.supabase.co',
            supabasePublishableKey: 'sb_publishable_fixture',
          );
          expect(
            config.validationErrors.isEmpty,
            (env == 'test') == (host == 'kpqbedylxlyntrrfybpn'),
          );
        }
      }
    },
  );
  test(
    'TEST restoration rejects foreign/malformed token and preserves Production',
    () async {
      const prodKey = 'sb-stlhijzpjfgwwdgunlsd-auth-token';
      const testKey = 'sb-kpqbedylxlyntrrfybpn-auth-token';
      for (final token in [
        jwt('https://stlhijzpjfgwwdgunlsd.supabase.co/auth/v1'),
        'broken',
        null,
      ]) {
        SharedPreferences.setMockInitialValues({
          prodKey: 'untouched',
          testKey: jsonEncode({'access_token': token}),
        });
        final storage = IapTestSessionStorage();
        await storage.initialize();
        expect(await storage.accessToken(), isNull);
        expect(
          (await SharedPreferences.getInstance()).getString(prodKey),
          'untouched',
        );
      }
    },
  );
  test('valid TEST issuer restores unchanged', () async {
    final token = jwt(iapTestIssuer);
    final saved = jsonEncode({'access_token': token});
    SharedPreferences.setMockInitialValues({
      'sb-kpqbedylxlyntrrfybpn-auth-token': saved,
    });
    final storage = IapTestSessionStorage();
    await storage.initialize();
    expect(await storage.accessToken(), saved);
    expect(isIapTestToken(token), isTrue);
  });
  test('TEST verifier without TEST session sends no network request', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://kpqbedylxlyntrrfybpn.supabase.co',
      'fixture',
      httpClient: MockClient((r) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final verifier = SupabaseFunctionPurchaseVerifier(
      client,
      testSessionOnly: true,
    );
    final outcome = await verifier.verify(
      const IapVerificationRequest(
        platform: 'google',
        productId: 'com.legendstudy.essay.credit1',
        transactionId: 'fixture',
        verificationData: 'fixture',
      ),
    );
    expect(outcome.status, VerificationStatus.pending);
    expect(calls, 0);
    await client.dispose();
  });
  test(
    'TEST verifier forwards TEST JWT but blocks a foreign session',
    () async {
      for (final issuer in [
        iapTestIssuer,
        'https://stlhijzpjfgwwdgunlsd.supabase.co/auth/v1',
      ]) {
        final token = jwt(issuer);
        final verificationRequests = <http.Request>[];
        final client = SupabaseClient(
          'https://kpqbedylxlyntrrfybpn.supabase.co',
          'fixture',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((r) async {
            if (r.url.path.contains('/auth/v1/token')) {
              return http.Response(
                jsonEncode({
                  'access_token': token,
                  'refresh_token': 'fixture',
                  'token_type': 'bearer',
                  'expires_in': 3600,
                  'user': {
                    'id': 'fixture-user',
                    'aud': 'authenticated',
                    'created_at': '2026-10-15T00:00:00Z',
                    'app_metadata': <String, dynamic>{},
                    'user_metadata': <String, dynamic>{},
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            verificationRequests.add(r);
            return http.Response(
              '{"status":"pending"}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        await client.auth.signInWithPassword(
          email: 'fixture@example.invalid',
          password: 'fixture',
        );
        final result =
            await SupabaseFunctionPurchaseVerifier(
              client,
              testSessionOnly: true,
            ).verify(
              const IapVerificationRequest(
                platform: 'google',
                productId: 'com.legendstudy.essay.credit1',
                transactionId: 'fixture',
                verificationData: 'fixture',
              ),
            );
        expect(result.status, VerificationStatus.pending);
        expect(verificationRequests.length, issuer == iapTestIssuer ? 1 : 0);
        if (verificationRequests.isNotEmpty) {
          expect(
            verificationRequests.single.url.host,
            'kpqbedylxlyntrrfybpn.supabase.co',
          );
          expect(
            verificationRequests.single.headers['Authorization'],
            'Bearer $token',
          );
        }
        await client.dispose();
      }
    },
  );
}
