import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:http/http.dart' as http;

import 'trusted_resolver_client.dart';

final ephemeralPdfLoaderProvider = Provider<Future<Uint8List> Function(Uri)>(
  (ref) => loadEphemeralPdf,
);

/// No disk cache, redirects, cookies or persisted URL. Bytes live only in the viewer.
Future<Uint8List> loadEphemeralPdf(Uri uri, {http.Client? transport}) async {
  if (safeResolvedPdf(uri.toString()) == null) throw StateError('자료를 열 수 없어요.');
  final client = transport ?? http.Client();
  Future<Uint8List> download() async {
    final request = http.Request('GET', uri)..followRedirects = false;
    final response = await client.send(request);
    const maxBytes = 32 * 1024 * 1024;
    if (response.statusCode != 200 ||
        (response.contentLength ?? 0) > maxBytes) {
      throw StateError('자료를 열 수 없어요.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxBytes) {
        throw StateError('자료를 열 수 없어요.');
      }
      bytes.add(chunk);
    }
    final result = bytes.takeBytes();
    if (result.length < 5 || String.fromCharCodes(result.take(5)) != '%PDF-') {
      throw StateError('자료를 열 수 없어요.');
    }
    return result;
  }

  try {
    return await download().timeout(const Duration(seconds: 30));
  } catch (_) {
    throw StateError('자료를 열 수 없어요.');
  } finally {
    client.close();
  }
}
