import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import 'ephemeral_pdf_loader.dart';
import 'trusted_resolver_client.dart';

class PdfDownloadPolicy {
  const PdfDownloadPolicy(
    this.state, {
    this.filename,
    this.digest,
    this.official,
  });
  final String state;
  final String? filename, digest;
  final Uri? official;
  static const pending = PdfDownloadPolicy('PENDING');
  static PdfDownloadPolicy parse(Object? value) {
    if (value is! Map<String, Object?>) return pending;
    final state = value['state'];
    final filename = value['filename'];
    final digest = value['sha256'];
    final official = value['official_url'];
    if (state == 'ALLOWED' &&
        filename is String &&
        RegExp(r'^[a-zA-Z0-9가-힣_() .-]{1,150}\.pdf$').hasMatch(filename) &&
        digest is String &&
        RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
      return PdfDownloadPolicy('ALLOWED', filename: filename, digest: digest);
    }
    if (state == 'OFFICIAL_LINK' && official is String) {
      final uri = Uri.tryParse(official);
      if (uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          !uri.hasFragment) {
        return PdfDownloadPolicy('OFFICIAL_LINK', official: uri);
      }
    }
    return state == 'VIEW_ONLY'
        ? const PdfDownloadPolicy('VIEW_ONLY')
        : pending;
  }
}

final pdfDownloadPolicyProvider = FutureProvider.autoDispose
    .family<PdfDownloadPolicy, String>((ref, id) async {
      try {
        final client = ref.watch(supabaseClientProvider);
        if (client == null) return PdfDownloadPolicy.pending;
        return PdfDownloadPolicy.parse(
          await client
              .rpc<Object?>(
                'resource_download_policy',
                params: {'p_resource_id': id},
              )
              .timeout(const Duration(seconds: 3)),
        );
      } catch (_) {
        return PdfDownloadPolicy.pending;
      }
    }, retry: (_, _) => null);

typedef SavePdf = Future<bool> Function(Uint8List bytes, String name);
final pdfDownloadServiceProvider = Provider<PdfDownloadService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PdfDownloadService(
    (id) async => client == null
        ? null
        : (await client.functions.invoke(
            'resource-download',
            body: {'resource_id': id},
          )).data,
    loadEphemeralPdf,
    (bytes, name) async =>
        await const MethodChannel('com.legendstudy.app/pdf-download')
            .invokeMethod<bool>('save', {'bytes': bytes, 'name': name}) ??
        false,
  );
});

/// Fresh server authorization on every attempt; never persists signed URLs.
class PdfDownloadService {
  PdfDownloadService(this.authorize, this.load, this.save);
  final Future<Object?> Function(String) authorize;
  final Future<Uint8List> Function(Uri) load;
  final SavePdf save;
  bool _busy = false;
  Future<bool> download(String id, {bool Function()? cancelled}) async {
    if (_busy) throw StateError('busy');
    _busy = true;
    try {
      final reply = await authorize(id).timeout(const Duration(seconds: 30));
      if (reply is! Map<String, Object?> ||
          reply['resource_id'] != id ||
          reply['status'] != 'resolved') {
        throw StateError('denied');
      }
      final policy = PdfDownloadPolicy.parse(reply['policy']);
      final uri = reply['target'] is String
          ? safeResolvedPdf(reply['target'] as String)
          : null;
      if (policy.state != 'ALLOWED' || uri == null) throw StateError('denied');
      if (cancelled?.call() == true) return false;
      final bytes = await load(uri);
      if (cancelled?.call() == true) return false;
      if (bytes.length > 32 * 1024 * 1024 ||
          bytes.length < 5 ||
          String.fromCharCodes(bytes.take(5)) != '%PDF-' ||
          sha256.convert(bytes).toString() != policy.digest) {
        throw StateError('invalid_pdf');
      }
      return await save(bytes, policy.filename!);
    } finally {
      _busy = false;
    }
  }
}
