import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/content_resource.dart';

typedef ResolverInvoke = Future<Object?> Function(Map<String, Object> body);
final trustedResolverProvider = Provider<TrustedResolverClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TrustedResolverClient((body) async {
    if (client == null) return null;
    return (await client.functions.invoke(
      'resource-resolver',
      body: body,
    )).data;
  });
});

/// Transient delivery only: never serialize this result into personal history.
class TrustedResolverClient {
  const TrustedResolverClient(this.invoke);
  final ResolverInvoke invoke;
  Future<Uri?> resolve(String resourceId) async {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(resourceId)) {
      return null;
    }
    try {
      final result = await invoke({'resource_id': resourceId})
          .timeout(const Duration(seconds: 25));
      if (result is! Map ||
          result['status'] != 'resolved' ||
          result['kind'] != 'pdf' ||
          result['resource_id'] != resourceId ||
          result['target'] is! String) {
        return null;
      }
      return safeResolvedPdf(result['target'] as String);
    } catch (_) {
      return null; // Never expose transport exceptions containing signed targets.
    }
  }
}

Uri? safeResolvedPdf(String value) {
  final uri = publicWebUri(
    value,
  ); // Existing Safe Open boundary, then stricter delivery checks.
  if (uri == null ||
      value.contains(r'\') ||
      uri.scheme != 'https' ||
      uri.host != 'blog.kakaocdn.net' ||
      uri.port != 443 ||
      uri.hasFragment ||
      !RegExp(r'^/dna/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/').hasMatch(uri.path)) {
    return null;
  }
  for (final key in ['credential', 'signature', 'expires']) {
    final values = uri.queryParametersAll[key];
    if (values == null || values.length != 1 || values.single.isEmpty) {
      return null;
    }
  }
  final expiry = int.tryParse(uri.queryParameters['expires'] ?? '');
  if (expiry == null ||
      expiry * 1000 <= DateTime.now().millisecondsSinceEpoch + 5000) {
    return null;
  }
  return uri;
}

bool resolverCapable(ContentResource resource) {
  if (resource.linkKind != 'unknown' ||
      !{
        'question',
        'answer',
        'explanation',
        'answer_explanation',
      }.contains(resource.resourceType)) {
    return false;
  }
  final extension = resource.fileExtension?.toLowerCase().replaceFirst('.', '');
  final mime = resource.mimeType?.split(';').first.trim().toLowerCase();
  if (extension != null && extension.isNotEmpty && extension != 'pdf') {
    return false;
  }
  if (mime != null &&
      mime.isNotEmpty &&
      mime != 'application/pdf' &&
      mime != 'application/octet-stream') {
    return false;
  }
  final uri = publicWebUri(resource.sourceUrl);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'blog.kakaocdn.net' &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      RegExp(r'^/dna/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/').hasMatch(uri.path);
}
