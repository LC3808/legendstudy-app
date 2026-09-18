import 'dart:convert';
import 'package:flutter/services.dart';
import '../domain/study_models.dart';

abstract interface class StudyClock {
  Future<ClockReading> read();
}

abstract interface class StudyLocalStore {
  Future<Map<String, dynamic>> read();
  Future<void> write(Map<String, dynamic> document);
}

const studyChannel = MethodChannel('com.legendstudy.app/study');

/// Removes one owner's local study space, for account deletion.
///
/// Drafts, records and scoring attempts live on the device under an owner key,
/// so a server-side account deletion would otherwise leave that person's work
/// readable on this phone. Other owners and the rest of the document are left
/// exactly as they were, and an owner with nothing stored is a no-op.
Future<void> purgeStudyOwner(StudyLocalStore store, String userId) async {
  final document = await store.read();
  final owners = document['owners'];
  if (owners is! Map || !owners.containsKey(userId)) return;
  owners.remove(userId);
  await store.write(document);
}

class NativeStudyClock implements StudyClock {
  @override
  Future<ClockReading> read() async {
    final value = await studyChannel.invokeMapMethod<String, dynamic>('clock');
    return ClockReading(
      value!['utcMs'] as int,
      value['elapsedMs'] as int,
      value['boot'] as String,
    );
  }
}

/// A single native atomic file replacement commits draft + outbox together.
/// All writes are serialized by the controller; no fallback to volatile memory.
class NativeStudyLocalStore implements StudyLocalStore {
  @override
  Future<Map<String, dynamic>> read() async {
    final raw = await studyChannel.invokeMethod<String>('read');
    if (raw == null) return {'version': 1, 'owners': <String, dynamic>{}};
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    if (![1, 2, 3].contains(doc['version']) || doc['owners'] is! Map) {
      throw const FormatException('Unsupported study storage');
    }
    return doc;
  }

  @override
  Future<void> write(Map<String, dynamic> document) =>
      studyChannel.invokeMethod<void>('write', jsonEncode(document));
}
