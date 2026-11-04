// Opt-in isolated TEST read-only cross-platform learning persistence check.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_page.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('TEST persisted learning matches WEB read and native History', (
    tester,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.supabaseUrl, 'https://kpqbedylxlyntrrfybpn.supabase.co');
    final uri = Uri.parse(const String.fromEnvironment('SMOKE_CONFIG_URL'));
    expect(uri.host, '127.0.0.1');
    final data = jsonDecode((await http.get(uri)).body) as Map<String, dynamic>;
    final client = SupabaseClient(
      config.supabaseUrl,
      config.supabasePublishableKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    try {
      await client.auth.signInWithPassword(
        email: data['email'] as String,
        password: data['password'] as String,
      );
      final gateway = MathGateway(client, client.auth.currentUser!.id);
      for (final entry in data['cases'] as List) {
        final payload = Map<String, dynamic>.from(entry['payload'] as Map);
        final actual = await gateway.call(
          entry['rpc'] as String,
          'read',
          payload,
        );
        expect(
          actual['learning_completeness'],
          entry['expected']['learning_completeness'],
        );
        expect(
          actual['learning_comparison'],
          entry['expected']['learning_comparison'],
        );
        final history = await gateway.call(
          entry['rpc'] as String,
          'history',
          payload,
        );
        expect(history, entry['history']);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [supabaseClientProvider.overrideWithValue(client)],
            child: MaterialApp(
              home: MathCoachingPage(
                key: ValueKey(entry['name']),
                evaluationId: entry['evaluation_id'] as String,
                runId: payload['run_id'] as String?,
                questionId: payload['question_id'] as String?,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
        expect(find.byType(MathCoachingScreen), findsOneWidget);
        final screen = tester.widget<MathCoachingScreen>(
          find.byType(MathCoachingScreen),
        );
        expect(
          screen.snapshot.data['learning_completeness'],
          actual['learning_completeness'],
        );
        expect(find.textContaining('학습 완성도 ·'), findsWidgets);
        await binding.takeScreenshot('${entry['name']}-learning');
        await tester.tap(find.text('학습 기록').first);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 90),
        );
        expect(find.textContaining('학습 완성도 ·'), findsWidgets);
        await binding.takeScreenshot('${entry['name']}-history');
      }
    } finally {
      await client.dispose();
    }
  });
}
