import 'day_event.dart';

/// Owner-scoped D-Day event collection. All operations act only on the
/// authenticated user's own events (enforced again by RLS in the database).
abstract interface class DayEventRepository {
  Future<List<DayEvent>> fetchEvents();

  /// Add one event. When [primary] is true it becomes the sole representative.
  Future<DayEvent> addEvent(DateTime date, String label, {bool primary = false});

  Future<DayEvent> updateEvent(String id, DateTime date, String label);

  /// Delete one event. Deleting the primary leaves no persisted primary; the
  /// Home display falls back to the nearest upcoming event (no automatic write).
  Future<void> deleteEvent(String id);

  /// Make [id] the sole primary, clearing any previous primary first.
  Future<void> setPrimary(String id);
}
