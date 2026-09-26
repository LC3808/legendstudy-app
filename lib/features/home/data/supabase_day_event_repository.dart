import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/day_event.dart';
import '../domain/day_event_repository.dart';

/// Confirmed-write storage for the owner's D-Day collection on `day_targets`.
/// RLS restricts every row to `owner_id = auth.uid()`; this class also asserts
/// ownership on decode as defense in depth.
class SupabaseDayEventRepository implements DayEventRepository {
  SupabaseDayEventRepository(this.client);
  final SupabaseClient? client;

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
    // The app title limit is 20; a legacy backfilled row may hold up to 80.
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
    if (client?.auth.currentUser == null) return const [];
    final owner = _owner;
    final rows = await client!
        .from('day_targets')
        .select(_projection)
        .eq('owner_id', owner);
    return [for (final row in rows) _decode(row, owner)]..sort(compareEvents);
  }

  Future<void> _clearPrimary(String owner) async {
    await client!
        .from('day_targets')
        .update({'is_primary': false})
        .eq('owner_id', owner)
        .eq('is_primary', true);
  }

  @override
  Future<DayEvent> addEvent(DateTime date, String label,
      {bool primary = false}) async {
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
    await client!.from('day_targets').delete().eq('id', id).eq('owner_id', owner);
  }

  @override
  Future<void> setPrimary(String id) async {
    final owner = _owner;
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
