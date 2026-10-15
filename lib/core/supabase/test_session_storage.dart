import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

const iapTestIssuer = 'https://kpqbedylxlyntrrfybpn.supabase.co/auth/v1';

/// Routing guard only, not JWT signature verification. The TEST server still
/// authenticates the token. Never log tokens or modify Production storage.
bool isIapTestToken(String? token) {
  try {
    final parts = token!.split('.');
    if (parts.length != 3) return false;
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return claims is Map && claims['iss'] == iapTestIssuer;
  } catch (_) {
    return false;
  }
}

/// Retains the SDK's existing TEST-specific key; filters before SDK restoration.
/// Rejected records are ignored, not deleted. Production's key is never opened.
class IapTestSessionStorage extends SharedPreferencesLocalStorage {
  IapTestSessionStorage()
    : super(persistSessionKey: 'sb-kpqbedylxlyntrrfybpn-auth-token');

  @override
  Future<String?> accessToken() async {
    final saved = await super.accessToken();
    try {
      final data = jsonDecode(saved!);
      return data is Map && isIapTestToken(data['access_token'] as String?)
          ? saved
          : null;
    } catch (_) {
      return null;
    }
  }
}
