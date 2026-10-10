import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/legendstudy_app.dart';
import 'core/config/app_config.dart';
import 'core/supabase/supabase_providers.dart';
import 'features/auth/identity_diagnostic.dart';
import 'features/brand/brand_frame.dart';
import 'features/onboarding/device_intro.dart';

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
  late Future<Widget> initialized = _initialize(widget.config);
  late final connection = _connect(widget.config);

  Future<({SupabaseClient? client, String? issue})> _connect(
    AppConfig config,
  ) async {
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
    return (client: client, issue: issue);
  }

  Future<Widget> _initialize(AppConfig config) async {
    final introStore = DeviceIntroStore();
    bool introDone;
    SupabaseClient? client;
    String? issue;
    try {
      introDone = await introStore.completed();
      final backend = await connection;
      client = backend.client;
      issue = backend.issue;
      if (!introDone && client?.auth.currentUser != null) {
        await introStore.complete();
        introDone = true;
      }
    } catch (_) {
      // Local I/O failure is not evidence of a fresh installation.
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => setState(() {
                initialized = _initialize(widget.config);
              }),
              child: const Text('앱 시작 정보를 불러오지 못했어요. 다시 시도'),
            ),
          ),
        ),
      );
    }
    return ProviderScope(
      overrides: [
        introRequiredAtBootProvider.overrideWithValue(!introDone),
        deviceIntroStoreProvider.overrideWithValue(introStore),
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
