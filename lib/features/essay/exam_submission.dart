import '../../core/config/app_config.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExamSubmissionRejected implements Exception {
  const ExamSubmissionRejected(this.code);
  final String code;
}

/// Shared WEB gateway, current user bearer only; no Worker/finance credential.
class ExamSubmissionGateway {
  ExamSubmissionGateway(this.client, this.owner);
  final SupabaseClient client;
  final String owner;
  Future<Map<String, dynamic>> request(Map<String, dynamic> payload) async {
    final origin = AppConfig.fromEnvironment().essayApiOrigin;
    final session = client.auth.currentSession;
    if (session == null || session.isExpired || session.user.id != owner) {
      throw StateError('LOGIN_REQUIRED');
    }
    final transport = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$origin/api/essay/exam'))
        ..followRedirects = false
        ..headers.addAll({
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode(payload);
      final response = await transport
          .send(request)
          .timeout(const Duration(seconds: 100));
      final bytes = await response.stream.toBytes().timeout(
        const Duration(seconds: 10),
      );
      if (bytes.length > 1048576) {
        throw const FormatException('RESPONSE_TOO_LARGE');
      }
      if (client.auth.currentUser?.id != owner) {
        throw StateError('ACCOUNT_CHANGED');
      }
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map) throw const FormatException('INVALID_RESPONSE');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 402 || response.statusCode == 422) {
          throw ExamSubmissionRejected(
            value['code'] as String? ?? 'SUBMISSION_REJECTED',
          );
        }
        throw StateError(value['code'] as String? ?? 'UNAVAILABLE');
      }
      return Map<String, dynamic>.from(value);
    } finally {
      transport.close();
    }
  }
}
