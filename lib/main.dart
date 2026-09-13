import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/legendstudy_app.dart';
import 'core/config/app_config.dart';
import 'core/supabase/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  SupabaseClient? client;
  String? issue;
  if (config.validationErrors.isEmpty) {
    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabasePublishableKey,
        debug: false,
      );
      client = Supabase.instance.client;
    } catch (_) {
      // Never expose SDK exceptions which may contain credentials or URLs.
      issue = '서버 연결을 초기화하지 못했습니다. 설정과 네트워크를 확인한 뒤 앱을 다시 실행해 주세요.';
    }
  } else {
    issue = config.validationErrors.join('\n');
  }
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
        backendIssueProvider.overrideWithValue(issue),
      ],
      child: const LegendStudyApp(),
    ),
  );
}
