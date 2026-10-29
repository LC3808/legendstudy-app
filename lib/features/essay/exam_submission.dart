import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/network/review_read_only_client.dart';
import '../../core/config/app_config.dart';

import 'dart:convert';

import 'source_draft.dart';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExamSubmissionRejected implements Exception {
  const ExamSubmissionRejected(this.code);
  final String code;
}

/// Shared WEB gateway, current user bearer only; no Worker/finance credential.
class ExamSubmissionGateway {
  ExamSubmissionGateway(
    this.client,
    this.owner, {
    this.transportOverride,
    this.diagnostic,
  });
  final http.Client? transportOverride;
  final Future<void> Function(Map<String, dynamic>)? diagnostic;
  Future<void> record(
    Map<String, dynamic> payload,
    String phase, {
    int? status,
    String? code,
  }) async {
    final event = <String, dynamic>{
      'version': 'exam-network-observation-v1',
      'at': DateTime.now().toUtc().toIso8601String(),
      'action': payload['action'],
      'examId': payload['examId'],
      'key': payload['key'],
      'parentId': payload['parentId'],
      'previousPaidRunId': payload['previousPaidRunId'],
      'phase': phase,
      'http_status': status,
      'code': code != null && RegExp(r'^[A-Z_0-9]{1,80}$').hasMatch(code)
          ? code
          : null,
    };
    try {
      if (diagnostic != null) {
        await diagnostic!(event);
        return;
      }
      if (client.auth.currentUser?.id != owner) return;
      final store = SourceDraftGateway(
        owner,
        'exam-network:${payload['examId']}:${payload['action']}',
      );
      final old = await store.loadDraft();
      await store.saveLocalDraft(jsonEncode(event), old.revision);
    } catch (_) {
      /* Diagnostics never changes submission acknowledgement. */
    }
  }

  final SupabaseClient client;
  final String owner;
  Future<Map<String, dynamic>> request(Map<String, dynamic> payload) async {
    final origin = AppConfig.fromEnvironment().essayApiOrigin;
    final session = client.auth.currentSession;
    if (session == null || session.isExpired || session.user.id != owner) {
      throw StateError('LOGIN_REQUIRED');
    }
    final transport = transportOverride ?? reviewHttpClient();
    int? responseStatus;
    String? responseCode;
    try {
      final request = http.Request('POST', Uri.parse('$origin/api/essay/exam'))
        ..followRedirects = false
        ..headers.addAll({
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode(payload);
      await record(payload, 'sending');
      final response = await transport
          .send(request)
          .timeout(const Duration(seconds: 100));
      responseStatus = response.statusCode;
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
      responseCode = value['code'] is String ? value['code'] as String : null;
      await record(
        payload,
        'response',
        status: response.statusCode,
        code: value['code'] is String ? value['code'] as String : null,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 402 ||
            response.statusCode == 422 ||
            (response.statusCode == 409 &&
                [
                  'CREDIT_SOURCE_CHANGED',
                  'CREDIT_SOURCE_CONFIRMATION_REQUIRED',
                ].contains(value['code']))) {
          throw ExamSubmissionRejected(
            value['code'] as String? ?? 'SUBMISSION_REJECTED',
          );
        }
        throw StateError(value['code'] as String? ?? 'UNAVAILABLE');
      }
      return Map<String, dynamic>.from(value);
    } catch (error) {
      if (error is! ExamSubmissionRejected) {
        await record(
          payload,
          'unconfirmed',
          status: responseStatus,
          // Keep the server's symbolic failure while retaining the pending key.
          // A received 503/409 must not be overwritten by a generic diagnostic.
          code: responseCode ?? 'REQUEST_UNCONFIRMED',
        );
      }
      rethrow;
    } finally {
      if (transportOverride == null) transport.close();
    }
  }
}

final examSubmissionGatewayProvider =
    Provider.family<ExamSubmissionGateway?, String>((ref, owner) {
      final client = ref.watch(supabaseClientProvider);
      return client == null ? null : ExamSubmissionGateway(client, owner);
    });

/// Read-only admission check shared by review and submission; reserves no Credit.
final examAvailabilityProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String owner, String examId})>((
      ref,
      scope,
    ) async {
      final gateway = ref.watch(examSubmissionGatewayProvider(scope.owner));
      if (gateway == null) return {};
      return gateway.request({
        'action': 'availability',
        'examId': scope.examId,
      });
    });

/// Owner-scoped lookup only. Missing rollout never falls back to a new key.
Future<String?> recoverExamRequest(
  SupabaseClient client,
  String owner, {
  required String key,
  required String exam,
  required String? parent,
  String? previousPaid,
}) async {
  if (client.auth.currentUser?.id != owner ||
      client.auth.currentSession?.isExpired != false) {
    throw StateError('ACCOUNT_CHANGED');
  }
  final dynamic raw;
  try {
    raw = await client
        .rpc<dynamic>(
          'essay_exam_request_status',
          params: {'p_key': key, 'p_exam': exam},
        )
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    throw StateError('이전 요청이 접수됐는지 확인할 수 없어 다시 제출하지 않았어요. 답안은 보존됩니다.');
  }
  if (client.auth.currentUser?.id != owner) throw StateError('ACCOUNT_CHANGED');
  if (raw is! Map ||
      raw['version'] != 'exam-request-status-v1' ||
      raw['found'] is! bool) {
    throw const FormatException('REQUEST_STATUS_INVALID');
  }
  if (raw['found'] == false) return null;
  if (raw['exam_id'] != exam ||
      raw['parent_id'] != parent ||
      raw['previous_paid_run_id'] != previousPaid ||
      raw['run_id'] is! String) {
    throw const FormatException('REQUEST_STATUS_IDENTITY');
  }
  return raw['run_id'] as String;
}
