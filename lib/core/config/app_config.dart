import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defines are public values embedded in the application, never server secrets.
class AppConfig {
  const AppConfig({
    this.environment = 'development',
    this.supabaseUrl = '',
    this.supabasePublishableKey = '',
    this.recoveryRedirectUrl = '',
    this.accountDeletionEnabled = false,
  });
  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    // Empty means "not configured": Supabase then uses the project Site URL.
    // The production recovery redirect is a pending Owner configuration, so no
    // URL is invented here. See wiki/auth-recovery.md.
    recoveryRedirectUrl: String.fromEnvironment('SUPABASE_RECOVERY_REDIRECT'),
    // Off until the delete-account function is reviewed and deployed. A build
    // without it tells the user the feature is not ready instead of failing
    // with a transport error.
    accountDeletionEnabled: bool.fromEnvironment('ACCOUNT_DELETION_ENABLED'),
  );
  final String environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Empty until the Owner registers a redirect URL in the Supabase dashboard.
  final String recoveryRedirectUrl;

  /// False until the deletion endpoint is deployed; see
  /// wiki/account-deletion-privacy.md.
  final bool accountDeletionEnabled;

  /// Null when unconfigured, so the SDK falls back to the project Site URL.
  String? get recoveryRedirectTo =>
      recoveryRedirectUrl.isEmpty ? null : recoveryRedirectUrl;

  List<String> get validationErrors {
    final errors = <String>[];
    final uri = Uri.tryParse(supabaseUrl);
    if (supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL 설정이 필요합니다.');
    } else if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'stlhijzpjfgwwdgunlsd.supabase.co' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      errors.add('LegendStudy 전용 HTTPS Supabase URL을 설정해 주세요.');
    }
    if (supabasePublishableKey.isEmpty) {
      errors.add('SUPABASE_PUBLISHABLE_KEY 설정이 필요합니다.');
    } else if (!RegExp(
      r'^sb_publishable_[A-Za-z0-9_-]+$',
    ).hasMatch(supabasePublishableKey)) {
      errors.add('공개 클라이언트용 publishable key를 설정해 주세요.');
    }
    return errors;
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
