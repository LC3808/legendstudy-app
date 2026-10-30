import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defines are public values embedded in the application, never server secrets.
class AppConfig {
  const AppConfig({
    this.environment = 'development',
    this.supabaseUrl = '',
    this.supabasePublishableKey = '',
    this.recoveryRedirectUrl = '',
    this.signupRedirectUrl = '',
    this.googleServerClientId = '',
    this.googleIosClientId = '',
    this.accountDeletionEnabled = false,
    this.privacyUrl = '',
    this.termsUrl = '',
    this.refundUrl = '',
    this.googleOAuthEnabled = false,
    this.appleOAuthEnabled = false,
    this.kakaoOAuthEnabled = false,
    this.analyticsEnabled = false,
  });
  factory AppConfig.fromEnvironment() => const AppConfig(
    environment: String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    // Empty means "not configured": Supabase then uses the project Site URL.
    // The production recovery redirect is a pending Owner configuration, so no
    // URL is invented here. See wiki/auth-recovery.md.
    recoveryRedirectUrl: String.fromEnvironment('SUPABASE_RECOVERY_REDIRECT'),
    signupRedirectUrl: String.fromEnvironment('SUPABASE_SIGNUP_REDIRECT'),
    googleServerClientId: String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
    googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    // Off until the delete-account function is reviewed and deployed. A build
    // without it tells the user the feature is not ready instead of failing
    // with a transport error.
    accountDeletionEnabled: bool.fromEnvironment('ACCOUNT_DELETION_ENABLED'),
    privacyUrl: String.fromEnvironment(
      'PRIVACY_POLICY_URL',
      defaultValue: 'https://lab.legendstudy.com/privacy/',
    ),
    termsUrl: String.fromEnvironment(
      'TERMS_URL',
      defaultValue: 'https://lab.legendstudy.com/terms/',
    ),
    refundUrl: String.fromEnvironment(
      'REFUND_URL',
      defaultValue: 'https://lab.legendstudy.com/refund/',
    ),
    googleOAuthEnabled: bool.fromEnvironment('GOOGLE_OAUTH_ENABLED'),
    appleOAuthEnabled: bool.fromEnvironment('APPLE_OAUTH_ENABLED'),
    kakaoOAuthEnabled: bool.fromEnvironment('KAKAO_OAUTH_ENABLED'),
    // Off until the Owner connects a Firebase project and adds the native
    // config files. A build without it uses the no-op analytics service and
    // ships normally; see wiki/analytics-v1-implementation-20261030.md.
    analyticsEnabled: bool.fromEnvironment('ANALYTICS_ENABLED'),
  );
  final String privacyUrl, termsUrl, refundUrl;
  final bool googleOAuthEnabled, appleOAuthEnabled, kakaoOAuthEnabled;

  /// Behavioural analytics (GA4/Firebase). Gated so the app ships without a
  /// Firebase project; GA4 carries behaviour events only, never official DB
  /// facts (credit/revenue/completion stay in PostgreSQL).
  final bool analyticsEnabled;
  // No TEST Cloudflare essay gateway is configured in this candidate. Fail closed rather
  // than sending a TEST session to Production; Supabase reads use their client.
  String get essayApiOrigin {
    if (environment == 'test') {
      throw StateError('TEST_ESSAY_BACKEND_UNCONFIGURED');
    }
    return 'https://lab.legendstudy.com';
  }

  final String environment;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Empty until the Owner registers a redirect URL in the Supabase dashboard.
  final String recoveryRedirectUrl;

  /// Optional Owner-registered email verification redirect; empty uses Site URL.
  final String signupRedirectUrl;
  // Public OAuth identifiers only; never client secrets.
  final String googleServerClientId;
  final String googleIosClientId;
  String? get signupRedirectTo =>
      signupRedirectUrl.isEmpty ? null : signupRedirectUrl;

  /// False until the deletion endpoint is deployed; see
  /// wiki/account-deletion-privacy.md.
  final bool accountDeletionEnabled;

  /// Null when unconfigured, so the SDK falls back to the project Site URL.
  String? get recoveryRedirectTo =>
      recoveryRedirectUrl.isEmpty ? null : recoveryRedirectUrl;

  /// Production is always the sole allowed Supabase host. An explicit TEST
  /// build must use the isolated TEST project. All other environments retain
  /// the existing Production-only host policy. See wiki/iap-billing-preparation-2026-10-09.md.
  static const _prodSupabaseHost = 'stlhijzpjfgwwdgunlsd.supabase.co';
  static const _testSupabaseHost = 'kpqbedylxlyntrrfybpn.supabase.co';
  bool _supabaseHostAllowed(String host) => environment == 'test'
      ? host == _testSupabaseHost
      : host == _prodSupabaseHost;

  List<String> get validationErrors {
    final errors = <String>[];
    final uri = Uri.tryParse(supabaseUrl);
    if (supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL 설정이 필요합니다.');
    } else if (uri == null ||
        uri.scheme != 'https' ||
        !_supabaseHostAllowed(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      errors.add('레전드스터디+ 전용 HTTPS Supabase URL을 설정해 주세요.');
    }
    if (supabasePublishableKey.isEmpty) {
      errors.add('SUPABASE_PUBLISHABLE_KEY 설정이 필요합니다.');
    } else if (!RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$')
        .hasMatch(supabasePublishableKey)) {
      errors.add('공개 클라이언트용 publishable key를 설정해 주세요.');
    }
    return errors;
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
