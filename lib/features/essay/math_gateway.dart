import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';

const mathOrigin = 'https://lab.legendstudy.com';
String mathRequestId() {
  final b = List.generate(16, (_) => Random.secure().nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final s = b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

/// Existing WEB RPCs and allowlisted worker gateway. No worker key or client billing.
class MathGateway {
  MathGateway(this.client, this.owner, {http.Client? transport})
    : transport = transport ?? http.Client();
  final SupabaseClient client;
  final String owner;
  final http.Client transport;
  bool _closed = false;
  void close() {
    _closed = true;
    transport.close();
  }

  void checkOwner() {
    if (_closed ||
        client.auth.currentUser?.id != owner ||
        client.auth.currentSession?.isExpired != false) {
      throw StateError('ACCOUNT_CHANGED');
    }
  }

  Future<bool> available() async {
    checkOwner();
    final request =
        http.Request('GET', Uri.parse('$mathOrigin/api/essay/availability'))
          ..followRedirects = false
          ..headers['Authorization'] =
              'Bearer ${client.auth.currentSession!.accessToken}';
    final response = await transport
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 25));
    checkOwner();
    if (response.statusCode != 200) throw StateError('UNAVAILABLE');
    final value = jsonDecode(response.body);
    if (value is! Map ||
        value['version'] != 'essay-web-v1' ||
        value['types'] is! Map) {
      throw const FormatException('INVALID_RESPONSE');
    }
    return value['types']['math'] == true;
  }

  Future<List<Map<String, dynamic>>> catalog() async {
    checkOwner();
    if (!await available()) return [];
    final data = await client.rpc<dynamic>(
      'math_catalog',
      params: {'p_limit': 20},
    );
    checkOwner();
    if (data is! List) throw const FormatException('INVALID_RESPONSE');
    return data.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  }

  Future<Map<String, dynamic>> call(
    String fn,
    String action,
    Map<String, dynamic> payload,
  ) async {
    checkOwner();
    if (!['math_input', 'math_learning'].contains(fn)) {
      throw ArgumentError('RPC');
    }
    final dto = fn == 'math_input' ? 'math-input-v1' : 'math-learning-v1';
    final value = await client
        .rpc<dynamic>(
          fn,
          params: {
            'p_request': {
              'dto_version': dto,
              'action': action,
              'payload': payload,
            },
          },
        )
        .timeout(const Duration(seconds: 25));
    checkOwner();
    if (value is! Map ||
        value['dto_version'] != dto ||
        value['action'] != action ||
        value['result'] is! Map) {
      throw const FormatException('INVALID_RESPONSE');
    }
    return Map<String, dynamic>.from(value['result'] as Map);
  }

  Future<void> evaluate(String id) async {
    checkOwner();
    final request =
        http.Request('POST', Uri.parse('$mathOrigin/api/math/evaluate'))
          ..followRedirects = false
          ..headers.addAll({
            'Authorization':
                'Bearer ${client.auth.currentSession!.accessToken}',
            'Origin': mathOrigin,
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({'evaluation_id': id});
    final response = await transport
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 60));
    checkOwner();
    // Ambiguous failure is recovered by reading this SAME evaluation, never a new charge.
    if (response.statusCode != 200) throw StateError('CHECK_EVALUATION_STATUS');
  }
}

final mathGatewayProvider = Provider.autoDispose.family<MathGateway?, String>((
  ref,
  owner,
) {
  final auth = ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  if (auth.isLoading ||
      auth.hasError ||
      auth.value?.userId != owner ||
      client == null) {
    return null;
  }
  final gateway = MathGateway(client, owner);
  ref.onDispose(gateway.close);
  return gateway;
});
final mathCatalogProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, owner) async {
      final gateway = ref.watch(mathGatewayProvider(owner));
      return gateway == null ? [] : gateway.catalog();
    });
