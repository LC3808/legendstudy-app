import '../../core/config/app_information.dart';

const officialIosStoreUrl = 'https://apps.apple.com/us/app/레전드스터디/id6820826957';
const officialAndroidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.legendstudy.app';

/// Server publication verification is independent of a candidate/build number.
class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.platform,
    required this.latest,
    required this.storeUrl,
    required this.releaseNotes,
    this.minimum,
    this.requiredApproved = false,
  });
  final String platform;
  final AppInstalledVersion latest;
  final AppInstalledVersion? minimum;
  final Uri storeUrl;
  final String releaseNotes;
  final bool requiredApproved;
  String get key => '$platform:${latest.key}';

  static AppUpdatePolicy? parse(
    Object? value, {
    required String platform,
    required DateTime now,
  }) {
    if (value == null) return null;
    if (value is! Map ||
        value['version'] != 'app-update-policy-v1' ||
        value['platform'] != platform ||
        value['enabled'] != true ||
        value['store_release_verified'] != true) {
      return null;
    }
    final verifiedAt = DateTime.tryParse(
      value['verified_at']?.toString() ?? '',
    );
    final store = Uri.tryParse(value['store_url']?.toString() ?? '');
    final expected = switch (platform) {
      'ios' => Uri.parse(officialIosStoreUrl),
      'android' => Uri.parse(officialAndroidStoreUrl),
      _ => null,
    };
    if (verifiedAt == null ||
        verifiedAt.isAfter(now) ||
        expected == null ||
        store != expected) {
      return null;
    }
    try {
      final latest = AppInstalledVersion.parse(
        value['latest_version'],
        value['latest_build'],
      );
      final type = value['update_type'] ?? 'OPTIONAL';
      if (type != 'OPTIONAL' && type != 'REQUIRED') return null;
      AppInstalledVersion? minimum;
      if (value['minimum_supported_version'] != null ||
          value['minimum_supported_build'] != null) {
        minimum = AppInstalledVersion.parse(
          value['minimum_supported_version'],
          value['minimum_supported_build'],
        );
        if (minimum.compareTo(latest) > 0) return null;
      }
      final notes = value['release_notes'];
      if (notes != null && (notes is! String || notes.length > 2000)) {
        return null;
      }
      return AppUpdatePolicy(
        platform: platform,
        latest: latest,
        minimum: minimum,
        storeUrl: store!,
        releaseNotes: (notes as String?)?.trim() ?? '',
        requiredApproved:
            type == 'REQUIRED' &&
            minimum != null &&
            value['required_approved'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  AppUpdatePrompt? forInstalled(AppInstalledVersion installed) {
    if (installed.compareTo(latest) >= 0) return null;
    return AppUpdatePrompt(
      this,
      required: requiredApproved && installed.compareTo(minimum!) < 0,
    );
  }
}

class AppUpdatePrompt {
  const AppUpdatePrompt(this.policy, {required this.required});
  final AppUpdatePolicy policy;
  final bool required;
}
