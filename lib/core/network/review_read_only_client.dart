import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Review builds only. Unknown operations fail closed before transport.
const reviewReadOnly = bool.fromEnvironment('REVIEW_READ_ONLY');

http.Client reviewHttpClient() =>
    reviewReadOnly ? ReviewReadOnlyClient(http.Client()) : http.Client();

class ReviewWriteBlocked implements Exception {
  const ReviewWriteBlocked();
  @override
  String toString() => 'REVIEW_READ_ONLY_BLOCKED';
}

class ReviewReadOnlyClient extends http.BaseClient {
  ReviewReadOnlyClient(this.inner);
  final http.Client inner;
  static const production = 'stlhijzpjfgwwdgunlsd.supabase.co';
  static const readRpcs = {
    'credit_summary',
    'essay_exam_history',
    'essay_evaluation_status',
    'my_applications',
    'user_notifications_list',
    'user_notifications_unread_count',
    'is_feedback_admin',
    'fetch_own_mock_attempt',
  };

  static bool allows(http.BaseRequest request) {
    final u = request.url;
    final read = request.method == 'GET' || request.method == 'HEAD';
    if (u.scheme != 'https') return false;
    if (u.host.endsWith('.supabase.co') && u.host != production) return false;
    if (u.host == production) {
      if (u.path.startsWith('/functions/')) return false;
      if (u.path.startsWith('/auth/')) {
        // Existing email login/refresh only; no signup, identity linking or OAuth.
        return (read && u.path == '/auth/v1/user') ||
            (request.method == 'POST' &&
                u.path == '/auth/v1/token' &&
                {
                  'password',
                  'refresh_token',
                }.contains(u.queryParameters['grant_type']));
      }
      if (u.path.startsWith('/rest/v1/rpc/')) {
        return readRpcs.contains(u.path.substring('/rest/v1/rpc/'.length));
      }
      return read &&
          (u.path.startsWith('/rest/v1/') ||
              u.path.startsWith('/storage/v1/object/'));
    }
    if (u.host == 'lab.legendstudy.com' && u.path.startsWith('/api/')) {
      return read && u.path == '/api/essay/catalog';
    }
    return read; // Static public resources; never POST to external services.
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!allows(request)) {
      // Deliberately no URL/query/body/headers: they can contain credentials.
      debugPrint('REVIEW_READ_ONLY_BLOCKED');
      throw const ReviewWriteBlocked();
    }
    // A permitted endpoint must not redirect to an unreviewed operation.
    request.followRedirects = false;
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
