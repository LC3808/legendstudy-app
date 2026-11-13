import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Device-local completion receipts, not file handles or cloud bookmarks.
class DownloadReceipt {
  const DownloadReceipt(
    this.resourceId,
    this.slug,
    this.filename,
    this.savedAt,
  );
  final String resourceId, slug, filename;
  final DateTime savedAt;
  Map<String, Object> toJson() => {
    'resource_id': resourceId,
    'slug': slug,
    'filename': filename,
    'saved_at': savedAt.toUtc().toIso8601String(),
  };
  factory DownloadReceipt.fromJson(Map<String, dynamic> json) =>
      DownloadReceipt(
        json['resource_id'] as String,
        json['slug'] as String,
        json['filename'] as String,
        DateTime.parse(json['saved_at'] as String),
      );
}

class DownloadHistory {
  DownloadHistory(this.read, this.write);
  final Future<String?> Function(String) read;
  final Future<void> Function(String, String) write;
  Future<List<DownloadReceipt>> load(String owner) async {
    final raw = await read('downloads.v1.$owner');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map(
          (j) => DownloadReceipt.fromJson(Map<String, dynamic>.from(j as Map)),
        )
        .toList();
  }

  Future<void> record(String owner, DownloadReceipt receipt) async {
    final rows = await load(owner);
    // A recent-file list: repeated downloads refresh only this file's receipt.
    final next = [
      receipt,
      ...rows.where((r) => r.resourceId != receipt.resourceId),
    ].take(100).map((r) => r.toJson()).toList();
    await write('downloads.v1.$owner', jsonEncode(next));
  }

  Future<void> clear(String owner) => write('downloads.v1.$owner', '[]');
}

final downloadHistoryProvider = Provider<DownloadHistory>((ref) {
  final prefs = SharedPreferencesAsync();
  return DownloadHistory(prefs.getString, prefs.setString);
});
final downloadedMaterialsProvider =
    FutureProvider.autoDispose<List<DownloadReceipt>>((ref) async {
      final auth = ref.watch(authStateProvider);
      if (auth.isLoading || auth.hasError || auth.value?.userId == null) {
        return [];
      }
      return ref.read(downloadHistoryProvider).load(auth.value!.userId!);
    }, retry: (_, _) => null);
