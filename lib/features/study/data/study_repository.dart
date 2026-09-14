import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../domain/study_models.dart';

class StudyHistoryLimit implements Exception {
  const StudyHistoryLimit();
}

class StudyStorageError implements Exception {
  const StudyStorageError();
}

abstract interface class StudyRepository {
  String get owner;
  Future<List<StudyRecord>> fetchWindow(int nowMs);
  Future<void> insertCompleted(StudyRecord record);
  Future<void> deleteOwn(String id);
}

/// Request-scoped identity/token: later SDK account switches cannot reassign a draft.
class SupabaseStudyRepository implements StudyRepository {
  SupabaseStudyRepository._(
    this.owner,
    this._token,
    this.config,
    this.httpClient,
  );
  factory SupabaseStudyRepository.bind(
    SupabaseClient? client,
    AppConfig config,
    http.Client transport,
  ) {
    final session = client?.auth.currentSession;
    if (session == null || config.validationErrors.isNotEmpty) {
      throw const StudyStorageError();
    }
    return SupabaseStudyRepository._(
      session.user.id,
      session.accessToken,
      config,
      transport,
    );
  }
  @override
  final String owner;
  final String _token;
  final AppConfig config;
  final http.Client httpClient;
  static const projection =
      'id,user_id,mode,title,subject,planned_duration_seconds,started_at,ended_at,active_segments,duration_seconds,created_at';
  Future<List<Map<String, dynamic>>> _request(
    String method,
    Map<String, String> query, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '${config.supabaseUrl.replaceFirst(RegExp(r'/$'), '')}/rest/v1/study_sessions',
    ).replace(queryParameters: query);
    final request = http.Request(method, uri)..followRedirects = false;
    request.headers.addAll({
      'apikey': config.supabasePublishableKey,
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
      'Prefer': method == 'POST'
          ? 'resolution=ignore-duplicates,return=representation'
          : 'return=representation',
    });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await httpClient.send(request).timeout(const Duration(seconds: 20)),
    ).timeout(const Duration(seconds: 20));
    if (![200, 201, 206].contains(response.statusCode)) {
      throw const StudyStorageError();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const StudyStorageError();
    return decoded.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  StudyRecord _decode(Map<String, dynamic> row) {
    if (row['user_id'] != owner) throw const StudyStorageError();
    final record = StudyRecord.fromJson({...row, 'synced': true});
    if (row['duration_seconds'] != record.activeMs ~/ 1000) {
      throw const StudyStorageError();
    }
    return record;
  }

  @override
  Future<List<StudyRecord>> fetchWindow(int nowMs) async {
    final start = dayStartMs(
      koreanDay(nowMs).subtract(const Duration(days: 6)),
    );
    final end = dayStartMs(koreanDay(nowMs).add(const Duration(days: 1)));
    String iso(int ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
    final result = <StudyRecord>[];
    String? cursorStarted, cursorId;
    while (true) {
      final query = {
        'select': projection,
        'user_id': 'eq.$owner',
        'order': 'started_at.desc,id.desc',
        'and':
            '(started_at.gte.${iso(start - studyMaxSpan)},started_at.lt.${iso(end)},ended_at.gt.${iso(start)})',
        'limit': result.length == 2000 ? '1' : '100',
      };
      if (cursorStarted != null) {
        query['or'] =
            '(started_at.lt.$cursorStarted,and(started_at.eq.$cursorStarted,id.lt.$cursorId))';
      }
      final rows = await _request('GET', query);
      if (result.length == 2000) {
        if (rows.isNotEmpty) throw const StudyHistoryLimit();
        break;
      }
      if (rows.length > 100) throw const StudyStorageError();
      for (final row in rows) {
        final decoded = _decode(row);
        if (result.any((r) => r.id == decoded.id)) {
          throw const StudyStorageError();
        }
        result.add(decoded);
      }
      if (rows.length < 100) break;
      // Preserve PostgreSQL microseconds in pagination, even though aggregates use ms.
      cursorStarted = DateTime.parse(
        rows.last['started_at'] as String,
      ).toUtc().toIso8601String();
      cursorId = result.last.id;
    }
    return result;
  }

  @override
  Future<void> insertCompleted(StudyRecord record) async {
    record.validate();
    await _request('POST', {'on_conflict': 'id'}, body: record.payload());
    // Verify identical row on both first insertion and ambiguous/duplicate retry.
    final rows = await _request('GET', {
      'select': projection,
      'id': 'eq.${record.id}',
      'user_id': 'eq.$owner',
    });
    if (rows.length != 1 ||
        jsonEncode(_decode(rows.single).payload()) !=
            jsonEncode(record.payload())) {
      throw const StudyStorageError();
    }
  }

  @override
  Future<void> deleteOwn(String id) async {
    await _request('DELETE', {'id': 'eq.$id', 'user_id': 'eq.$owner'});
  }
}
