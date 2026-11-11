import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/supabase/supabase_providers.dart';
import '../personal/domain/personal_models.dart';

bool canManageApplications(UserProfile? p) =>
    p?.academicStatus == 'retaker' ||
    (p?.academicStatus == 'student' && p?.gradeLevel == 3);
const applicationStates = {
  'planned': '지원 예정',
  'submitted': '지원 완료',
  'stage_pass': '1단계 합격',
  'accepted': '최초합격',
  'additional_acceptance': '추가합격',
  'rejected': '불합격',
  'registered': '등록',
  'not_registered': '미등록',
};
String eventLabel(String kind) =>
    applicationStates[kind] ??
    (kind == 'created'
        ? '지원 내역 생성'
        : kind == 'details_changed'
        ? '지원 정보 변경'
        : '알 수 없는 상태');

class ApplicationRecord {
  ApplicationRecord(this.data) {
    for (final key in [
      'id',
      'university_id',
      'university_name_snapshot',
      'intended_division',
      'admission_type',
      'admission_name',
    ]) {
      if (data[key] is! String) {
        throw const FormatException('Invalid application');
      }
    }
    if (data['admission_year'] is! int || data['revision'] is! int) {
      throw const FormatException('Invalid application');
    }
    final event = data['latest_event'];
    if (event != null && (event is! Map || event['kind'] is! String)) {
      throw const FormatException('Invalid event');
    }
  }
  final Map<String, dynamic> data;
  String get id => data['id'] as String;
  String get university => data['university_name_snapshot'] as String;
  String get division => data['intended_division'] as String;
  String get type => data['admission_type'] as String;
  String get track => data['admission_name'] as String;
  int get year => data['admission_year'] as int;
  int get revision => data['revision'] as int;
  String get status => data['latest_event'] == null
      ? '진행·결과 미입력'
      : eventLabel(data['latest_event']['kind'] as String);
}

/// Keep a key across uncertain network failures, change it only when input changes.
class ApplicationRequestKey {
  String? _signature, _key;
  String forInput(Object value) {
    final signature = jsonEncode(value);
    if (_signature != signature) {
      _signature = signature;
      _key = const Uuid().v4();
    }
    return _key!;
  }
}

typedef ApplicationRpc = Future<Object?> Function(
  String name,
  Map<String, dynamic> params,
);

class ApplicationRepository {
  ApplicationRepository(this.rpc, this.currentOwner, this.owner);
  final ApplicationRpc rpc;
  final String? Function() currentOwner;
  final String owner;
  void checkOwner() {
    if (currentOwner() != owner) throw const AuthException('Account changed');
  }

  Future<Object?> call(String name, Map<String, dynamic> params) async {
    checkOwner();
    final result = await rpc(name, params);
    checkOwner();
    return result;
  }

  Future<List<Map<String, dynamic>>> pages(
    String name,
    String version,
    int size, {
    String? id,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0; offset < 10000; offset += size) {
      final raw = await call(name, {
        'p_offset': offset,
        if (id != null) 'p_id': id,
      });
      if (raw is! Map ||
          raw['version'] != version ||
          raw['has_more'] is! bool ||
          raw['items'] is! List) {
        throw const FormatException('Invalid application response');
      }
      final items = (raw['items'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      if (items.length > size || (raw['has_more'] == true && items.isEmpty)) {
        throw const FormatException('Invalid page');
      }
      rows.addAll(items);
      if (raw['has_more'] == false) return rows;
    }
    throw const FormatException('Page limit exceeded');
  }

  Future<List<ApplicationRecord>> list() async => (await pages(
    'my_applications',
    'applications-v1',
    25,
  )).map(ApplicationRecord.new).toList();
  Future<List<Map<String, dynamic>>> history(String id) =>
      pages('my_application_events', 'application-events-v1', 100, id: id);
  Future<String> save(Map<String, dynamic> input, String key) async =>
      (await call('my_application_save', {...input, 'p_request_key': key}))
          as String;
  Future<void> event(
    String id,
    String kind,
    String? supersedes,
    String key,
  ) async {
    if (!applicationStates.containsKey(kind)) {
      throw const FormatException('Unsupported state');
    }
    await call('my_application_event', {
      'p_id': id,
      'p_kind': kind,
      'p_occurred_at': null,
      'p_supersedes': supersedes,
      'p_request_key': key,
    });
  }

  Future<void> delete(String id) async {
    await call('my_application_delete', {'p_id': id});
  }
}

String applicationError(Object error) {
  if (error is PostgrestException) {
    if (error.code == '23505') return '동일한 지원 내역이 이미 있어요. 목록을 확인해 주세요.';
    if (error.code == '40001') return '다른 화면에서 변경됐어요. 목록을 새로고침한 뒤 다시 열어 주세요.';
  }
  return '처리하지 못했어요. 입력값을 유지했으니 다시 시도해 주세요.';
}

final applicationRepositoryProvider = Provider<ApplicationRepository?>((ref) {
  final auth = ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  final owner = auth.asData?.value.userId;
  if (auth.isLoading || auth.hasError || client == null || owner == null) {
    return null;
  }
  return ApplicationRepository(
    (n, p) async => await client.rpc(n, params: p),
    () => client.auth.currentUser?.id,
    owner,
  );
});
final applicationsProvider = FutureProvider<List<ApplicationRecord>>((
  ref,
) async {
  final repo = ref.watch(applicationRepositoryProvider);
  return repo == null ? [] : repo.list();
});
