import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

String _rawNonce() => base64UrlEncode(
  List<int>.generate(32, (_) => Random.secure().nextInt(256)),
);

/// Ephemeral exchange material. Never expose through UI state or logging.
class NativeIdentityToken {
  const NativeIdentityToken(this.token, this.nonce);
  final String token;
  final String? nonce;
}

class NativeAuthCancelled implements Exception {
  const NativeAuthCancelled();
}

abstract class NativeIdentityProvider {
  Future<NativeIdentityToken> google();
  Future<NativeIdentityToken> apple();
}

class DeviceIdentityProvider implements NativeIdentityProvider {
  DeviceIdentityProvider(this.config);
  final AppConfig config;
  // google_sign_in requires exactly one initialize per process. Its nonce is
  // initialization-scoped, not an argument to authenticate. Never reinitialize.
  static Future<void>? _googleInitialization;
  static String? _googleNonce;

  @override
  Future<NativeIdentityToken> google() async {
    if (config.googleServerClientId.isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            config.googleIosClientId.isEmpty)) {
      throw const AuthException(
        'Unavailable',
        code: 'oauth_provider_not_supported',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ready = await const MethodChannel('com.legendstudy.app/info')
          .invokeMethod<bool>('googleSchemeReady', config.googleIosClientId);
      if (ready != true) {
        throw const AuthException(
          'Unavailable',
          code: 'oauth_provider_not_supported',
        );
      }
    }
    if (_googleInitialization == null) {
      _googleNonce = _rawNonce();
      _googleInitialization = GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? config.googleIosClientId
            : null,
        serverClientId: config.googleServerClientId,
        nonce: sha256.convert(utf8.encode(_googleNonce!)).toString(),
      );
    }
    try {
      await _googleInitialization;
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const AuthException(
          'No identity token',
          code: 'session_not_found',
        );
      }
      return NativeIdentityToken(token, _googleNonce);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const NativeAuthCancelled();
      }
      // Do not forward SDK descriptions, which can carry platform diagnostics.
      throw const AuthException('Unavailable', code: 'unexpected_failure');
    }
  }

  @override
  Future<NativeIdentityToken> apple() async {
    final nonce = _rawNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: sha256.convert(utf8.encode(nonce)).toString(),
      );
      final token = credential.identityToken;
      if (token == null || token.isEmpty) {
        throw const AuthException(
          'No identity token',
          code: 'session_not_found',
        );
      }
      return NativeIdentityToken(token, nonce);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const NativeAuthCancelled();
      }
      throw const AuthException('Unavailable', code: 'unexpected_failure');
    }
  }
}
