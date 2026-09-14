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
    if (doc['version'] != 1 || doc['owners'] is! Map) {
      throw const FormatException('Unsupported study storage');
    }
    return doc;
  }

  @override
  Future<void> write(Map<String, dynamic> document) =>
      studyChannel.invokeMethod<void>('write', jsonEncode(document));
}
