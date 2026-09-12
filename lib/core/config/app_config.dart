import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compile-time public settings only. Values embedded in an app are not secrets.
class AppConfig {
  const AppConfig({this.environment = 'development'});

  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'development'),
  );

  final String environment;
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
