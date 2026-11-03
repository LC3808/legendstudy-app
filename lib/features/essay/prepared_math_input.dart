import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A confirmed Math input, bound to the local answer that produced it. The
/// existing Essay exam parent owns evaluation, billing and mixed History.
class PreparedMathInput {
  PreparedMathInput({
    required this.attemptId,
    required this.confirmedRunId,
    required this.body,
    required List<String> imageHashes,
  }) : imageHashes = List.unmodifiable(imageHashes);

  final String attemptId, confirmedRunId, body;
  final List<String> imageHashes;

  bool matches(String currentBody, List<Uint8List> images) =>
      body == currentBody &&
      images.length == imageHashes.length &&
      images.indexed.every(
        (entry) => sha256.convert(entry.$2).toString() == imageHashes[entry.$1],
      );

  Map<String, String> get reference => {
    'attemptId': attemptId,
    'confirmedRunId': confirmedRunId,
  };
}

bool isMathInputReference(Object? value) {
  if (value is! Map || value.length != 2) return false;
  final uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  return [
    'attemptId',
    'confirmedRunId',
  ].every((key) => value[key] is String && uuid.hasMatch(value[key] as String));
}
