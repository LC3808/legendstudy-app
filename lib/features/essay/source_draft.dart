import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'essay_models.dart';
import 'essay_live_gateway.dart';

class SourceDraftGateway implements EssayGateway {
  SourceDraftGateway(String owner, String question, {this.remote})
    : key = '${hash(owner)}_${hash(question)}';
  static const channel = MethodChannel('com.legendstudy.app/essay-draft');
  static String hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();
  final String key;
  final SupabaseEssayGateway? remote;
  int? remoteRevision;
  String? remoteBody;
  bool syncConflict = false;
  String? syncNotice;
  Future<EssayDraft> openSharedDraft() async {
    var local = await loadDraft();
    if (remote == null) return local;
    try {
      final server = await remote!.open(loadResults: false);
      syncConflict = false;
      remoteRevision = server.revision;
      remoteBody = server.body;
      if (local.body.isEmpty && server.body.isNotEmpty) {
        local = await saveLocalDraft(server.body, local.revision);
      } else if (local.body.isNotEmpty &&
          server.body.isNotEmpty &&
          local.body != server.body) {
        syncConflict = true;
      }
      syncNotice = syncConflict
          ? '계정에 다른 답안이 있습니다. 현재 기기의 답안은 보존했습니다.'
          : local.body == server.body
          ? '계정의 답안과 연결됐습니다.'
          : '기기에 보관된 답안입니다. 계정에 저장해 주세요.';
    } on EssayClientError catch (error) {
      syncNotice = error.code == 'PT422'
          ? '이 문항은 계정 답안 저장이 아직 지원되지 않습니다. 답안은 기기에 보관됩니다.'
          : error.code == 'PT401'
          ? '로그인 상태를 다시 확인해 주세요. 기기의 답안은 유지됩니다.'
          : '계정 답안을 확인하지 못했어요. 기기의 답안은 유지됩니다.';
    } catch (_) {
      syncNotice = '계정 답안을 확인하지 못했어요. 기기의 답안은 유지됩니다.';
    }
    return local;
  }

  Future<void> sync(String body) async {
    if (remote == null) return;
    if (syncConflict || remoteRevision == null) {
      syncNotice ??= '계정 답안을 먼저 확인해 주세요. 기기의 답안은 유지됩니다.';
      return;
    }
    if (body.length > 20000) {
      syncNotice = '계정 저장은 20,000자까지 지원합니다. 전체 답안은 기기에 보관했습니다.';
      return;
    }
    try {
      final saved = await remote!.saveDraft(body, remoteRevision!);
      remoteRevision = saved.revision;
      remoteBody = saved.body;
      syncNotice = '계정에 저장했습니다. 다른 기기에서 이어 쓸 수 있습니다.';
    } on EssayConflict {
      syncConflict = true;
      syncNotice = '다른 기기에서 답안이 변경됐어요. 현재 답안을 보존했습니다.';
    } catch (_) {
      syncNotice = '계정 저장을 확인하지 못했어요. 기기의 답안은 유지됩니다.';
    }
  }

  static Future<void> purge(String owner) =>
      channel.invokeMethod('purge', hash(owner));
  Future<Uint8List?> loadImage() =>
      channel.invokeMethod<Uint8List>('readImage', key);
  Future<void> saveImage(Uint8List? bytes) =>
      channel.invokeMethod('writeImage', {'key': key, 'value': bytes});
  String get _imagesKey => '${key.split('_').first}_${hash('$key:images-v2')}';
  String _imageKey(String id) =>
      '${key.split('_').first}_${hash('$key:image:$id')}';
  int _imagesRevision = 0;
  Future<List<Uint8List>> loadImages() async {
    final raw = await channel.invokeMethod<String>('read', _imagesKey);
    if (raw == null) {
      final legacy = await loadImage();
      return legacy == null ? [] : [legacy];
    }
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    _imagesRevision = doc['revision'] as int;
    final ids = (jsonDecode(doc['body'] as String) as List).cast<String>();
    if (ids.length > 6) throw const FormatException('Too many images');
    final result = <Uint8List>[];
    for (final id in ids) {
      final bytes = await channel.invokeMethod<Uint8List>(
        'readImage',
        _imageKey(id),
      );
      if (bytes == null || sha256.convert(bytes).toString() != id) {
        throw const FormatException('Image draft incomplete');
      }
      result.add(bytes);
    }
    return result;
  }

  Future<void> saveImages(List<Uint8List> images) async {
    if (images.length > 6 || images.any((b) => b.length > 20971520)) {
      throw const FormatException('Image limit');
    }
    final ids = <String>[];
    for (final bytes in images) {
      final id = sha256.convert(bytes).toString();
      ids.add(id);
      await channel.invokeMethod('writeImage', {
        'key': _imageKey(id),
        'value': bytes,
      });
    }
    // Atomic manifest is committed last. Failed writes leave the previous draft intact.
    // Old content-addressed pages remain private and are removed by existing owner purge.
    await channel.invokeMethod('write', {
      'key': _imagesKey,
      'expected': _imagesRevision,
      'value': jsonEncode({
        'body': jsonEncode(ids),
        'revision': _imagesRevision + 1,
      }),
    });
    _imagesRevision++;
  }

  @override
  Future<EssayDraft> loadDraft() async {
    final raw = await channel.invokeMethod<String>('read', key);
    if (raw == null) return const EssayDraft('', 0);
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    return EssayDraft(doc['body'] as String, doc['revision'] as int);
  }

  @override
  Future<EssayDraft> saveDraft(String body, int expectedRevision) async {
    final saved = await saveLocalDraft(body, expectedRevision);
    await sync(body);
    return saved;
  }

  Future<EssayDraft> saveLocalDraft(String body, int expectedRevision) async {
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
