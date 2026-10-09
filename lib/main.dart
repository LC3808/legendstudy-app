import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/legendstudy_app.dart';
import 'core/config/app_config.dart';
import 'core/supabase/supabase_providers.dart';
import 'features/auth/identity_diagnostic.dart';
import 'features/brand/brand_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppBootstrap(config: AppConfig.fromEnvironment()));
}

/// Render the existing brand immediately; mount providers/router only after
/// persisted authentication initialization finishes. No guest/new-user flash.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({required this.config, super.key});
  final AppConfig config;
  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  final processStart = DateTime.now();
  late final Future<Widget> initialized = _initialize(widget.config);
  Future<Widget> _initialize(AppConfig config) async {
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
    startIdentityDiagnostic(client);
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
        backendIssueProvider.overrideWithValue(issue),
      ],
      child: const LegendStudyApp(),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: initialized,
    builder: (context, snapshot) => BrandGate(
      processStart: processStart,
      ready: snapshot.hasData,
      child: snapshot.data ?? const SizedBox.expand(),
    ),
  );
}
