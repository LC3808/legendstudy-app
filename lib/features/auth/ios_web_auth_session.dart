import 'package:flutter/services.dart';

import 'native_auth.dart';

/// iOS owns presentation and callback interception; Supabase owns OAuth/PKCE.
class IosWebAuthSession {
  const IosWebAuthSession();
  static const _channel = MethodChannel('com.legendstudy.app/web-auth');

  Future<Uri> authenticate(String url) async {
    try {
      final callback = await _channel.invokeMethod<String>('authenticate', url);
      if (callback == null) throw const FormatException('Missing callback');
      return Uri.parse(callback);
    } on PlatformException catch (error) {
      if (error.code == 'AUTH_CANCELLED') throw const NativeAuthCancelled();
      rethrow;
    }
  }
}
