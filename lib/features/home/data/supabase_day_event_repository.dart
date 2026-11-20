import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/day_event.dart';
import '../domain/day_event_repository.dart';
import '../domain/admission_day_event.dart';

/// Confirmed-write storage for the owner's D-Day collection on `day_targets`.
/// RLS restricts every row to `owner_id = auth.uid()`; this class also asserts
/// ownership on decode as defense in depth.
class SupabaseDayEventRepository
    implements DayEventRepository, AdmissionDayEventRepository {
  SupabaseDayEventRepository(this.client);
  final SupabaseClient? client;
  final Map<String, String> _pendingActions = {};
  Map<String, AdmissionDayEvent> _admissionsByTarget = {};

  static const _projection = 'id,owner_id,title,event_date,is_primary';

  String get _owner =>
      client?.auth.currentUser?.id ?? (throw const SignedOutException());

  String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DayEvent _decode(Map<String, dynamic> row, String owner) {
    if (row['owner_id'] != owner) {
      throw const FormatException('Unexpected event owner');
    }
    final id = row['id'], date = row['event_date'], title = row['title'];
    if (id is! String ||
        title is! String ||
        date is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw const FormatException('Invalid event row');
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) throw const FormatException('Invalid calendar date');
    // The app title limit is 15; a legacy backfilled row may hold up to 80.
    // Clamp on load so an existing longer title still displays (and re-saves
    // within the limit on edit) rather than breaking the whole fetch.
    final runes = title.trim().runes.toList();
    final safeLabel = runes.length > dayEventMaxTitle
        ? String.fromCharCodes(runes.take(dayEventMaxTitle))
        : title;
    final event = DayEvent(
      id: id,
      date: parsed,
      label: safeLabel,
      isPrimary: row['is_primary'] == true,
    );
    if (_iso(event.date) != date) {
      throw const FormatException('Invalid event row');
    }
    return event;
  }

  @override
  Future<List<DayEvent>> fetchEvents() async {
    return (await fetchAdmissionSnapshot()).events;
  }

  bool _missingRpc(PostgrestException error) =>
      error.code == 'PGRST202' || error.code == '42883';

  void _requireSameOwner(String owner) {
    if (client?.auth.currentUser?.id != owner) {
      throw const SignedOutException();
    }
  }

  @override
  Future<AdmissionDayEventSnapshot> fetchAdmissionSnapshot() async {
    if (client?.auth.currentUser == null) {
      _admissionsByTarget = {};
      return const AdmissionDayEventSnapshot(events: [], admissions: []);
    }
    final owner = _owner;
    var available = true;
    var admissions = <AdmissionDayEvent>[];
    try {
      final result = await client!.rpc<dynamic>('my_admission_day_events');
      _requireSameOwner(owner);
      if (result is! Map || result['events'] is! List) {
        throw const FormatException('Invalid admission event response');
      }
      admissions = [
        for (final row in result['events'] as List)
          AdmissionDayEvent.fromJson(Map<String, dynamic>.from(row as Map)),
      ];
    } on PostgrestException catch (error) {
      // During rollout, the existing manual collection remains usable. An
      // authorization/transport failure must not masquerade as no auto events.
      if (!_missingRpc(error)) rethrow;
      available = false;
    }
    _requireSameOwner(owner);
    final rows = await client!
        .from('day_targets')
        .select(_projection)
        .eq('owner_id', owner);
    _requireSameOwner(owner);
    final byTarget = <String, AdmissionDayEvent>{};
    final officialIds = <String>{};
    for (final event in admissions) {
      if (!officialIds.add(event.officialEventId)) {
        throw const FormatException('Duplicate admission event');
      }
      final target = event.dayTargetId;
      if (target != null && byTarget.containsKey(target)) {
        throw const FormatException('Duplicate admission projection');
      }
      if (target != null) byTarget[target] = event;
    }
    final events = <DayEvent>[];
    for (final row in rows) {
      final event = _decode(row, owner);
      final admission = byTarget[event.id];
      if (admission != null && !admission.isActive) continue;
      events.add(event.copyWith(admission: admission));
    }
    _admissionsByTarget = byTarget;
    return AdmissionDayEventSnapshot(
      events: events..sort(compareEvents),
      admissions: List.unmodifiable(admissions),
      syncAvailable: available,
    );
  }

  Future<void> _clearPrimary(String owner) async {
    await client!
        .from('day_targets')
        .update({'is_primary': false})
        .eq('owner_id', owner)
        .eq('is_primary', true);
  }

  @override
  Future<DayEvent> addEvent(
    DateTime date,
    String label, {
    bool primary = false,
  }) async {
    final owner = _owner;
    final event = DayEvent(date: date, label: label, isPrimary: primary);
    if (date.year < 1 || date.year > 9999) {
      throw const FormatException('Unsupported date');
    }
    // Clear any existing primary first so the single-primary index never trips.
    if (primary) await _clearPrimary(owner);
    final row = await client!
        .from('day_targets')
        .insert({
          'owner_id': owner,
          'title': event.label,
          'event_date': _iso(event.date),
          'is_primary': primary,
        })
        .select(_projection)
        .single();
    return _decode(row, owner);
  }

  @override
  Future<DayEvent> updateEvent(String id, DateTime date, String label) async {
    final owner = _owner;
    if (_admissionsByTarget.containsKey(id)) {
      throw const FormatException('Official admission dates cannot be edited');
    }
    final event = DayEvent(id: id, date: date, label: label);
    final row = await client!
        .from('day_targets')
        .update({'title': event.label, 'event_date': _iso(event.date)})
        .eq('id', id)
        .eq('owner_id', owner)
        .select(_projection)
        .single();
    return _decode(row, owner);
  }

  @override
  Future<void> deleteEvent(String id) async {
    final owner = _owner;
    final admission = _admissionsByTarget[id];
    if (admission != null) {
      await changeAdmissionVisibility(admission, restore: false);
      return;
    }
    await client!
        .from('day_targets')
        .delete()
        .eq('id', id)
        .eq('owner_id', owner);
  }

  @override
  Future<void> changeAdmissionVisibility(
    AdmissionDayEvent event, {
    required bool restore,
  }) async {
    final owner = _owner;
    final action = restore ? 'restore' : 'dismiss';
    final command = '$owner/${event.officialEventId}/$action/${event.revision}';
    // Retain the key on an ambiguous network failure so retry is the same
    // operation. The server still checks ownership and expected revision.
    final requestKey = _pendingActions.putIfAbsent(command, _newRequestKey);
    await client!.rpc<dynamic>(
      'my_admission_day_event_action',
      params: {
        'p_event_id': event.officialEventId,
        'p_action': action,
        'p_expected_revision': event.revision,
        'p_request_key': requestKey,
      },
    );
    _pendingActions.remove(command);
    _requireSameOwner(owner);
  }

  String _newRequestKey() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  Future<void> setPrimary(String id) async {
    final owner = _owner;
    try {
      await client!.rpc<dynamic>(
        'my_set_primary_day_target',
        params: {'p_id': id},
      );
      _requireSameOwner(owner);
      return;
    } on PostgrestException catch (error) {
      if (!_missingRpc(error) || _admissionsByTarget.containsKey(id)) rethrow;
    }
    // Compatibility with the pre-install manual D-Day backend only.
    await _clearPrimary(owner);
    final rows = await client!
        .from('day_targets')
        .update({'is_primary': true})
        .eq('id', id)
        .eq('owner_id', owner)
        .select('id');
    if (rows.length != 1) {
      throw const FormatException('Primary change not confirmed');
    }
  }
}
