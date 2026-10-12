import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'essay_models.dart';

class SourceDraftGateway implements EssayGateway {
  SourceDraftGateway(String owner, String question)
    : key = '${hash(owner)}_${hash(question)}';
  static const channel = MethodChannel('com.legendstudy.app/essay-draft');
  static String hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();
  final String key;
  static Future<void> purge(String owner) =>
      channel.invokeMethod('purge', hash(owner));
  Future<Uint8List?> loadImage() =>
      channel.invokeMethod<Uint8List>('readImage', key);
  Future<void> saveImage(Uint8List? bytes) =>
      channel.invokeMethod('writeImage', {'key': key, 'value': bytes});
  @override
  Future<EssayDraft> loadDraft() async {
    final raw = await channel.invokeMethod<String>('read', key);
    if (raw == null) return const EssayDraft('', 0);
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    return EssayDraft(doc['body'] as String, doc['revision'] as int);
  }

  @override
  Future<EssayDraft> saveDraft(String body, int expectedRevision) async {
    if (body.length > 30000) throw const FormatException('Answer too long');
    final old = await loadDraft();
    if (old.revision != expectedRevision) throw EssayConflict();
    final next = EssayDraft(body, expectedRevision + 1);
    await channel.invokeMethod('write', {
      'key': key,
      'expected': expectedRevision,
      'value': jsonEncode({'body': body, 'revision': next.revision}),
    });
    return next;
  }

  @override
  Future<String> submit(
    String body,
    int expectedRevision,
    String requestKey,
  ) async => throw StateError('EXAM_CONTRACT_NOT_READY');
  @override
  Future<EssayEvaluation> requestEvaluation(String attemptId) async =>
      throw StateError('EXAM_CONTRACT_NOT_READY');
}
