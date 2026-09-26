import 'day_target.dart' show koreanCalendarDay;

/// App-side title limit for a D-Day event (code points). The Production column
/// still permits up to 80; new/edited titles are limited to this in the app.
const dayEventMaxTitle = 20;

/// Korean weekday for a calendar date. `DateTime.weekday`: Mon=1 .. Sun=7.
const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// The single canonical user-facing date format: `YYYY.MM.DD.(요일)`.
/// Weekday is derived from the date; it is never stored.
String formatEventDate(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final w = _weekdays[d.weekday - 1];
  return '${d.year}.${d.month.toString().padLeft(2, '0')}'
      '.${d.day.toString().padLeft(2, '0')}.($w)';
}

/// One D-Day event in the owner's collection. Reuses the existing KST
/// calendar-day and D-N semantics; adds an id (null for guest/unsaved) and a
/// primary flag so the collection can carry a user-chosen representative.
class DayEvent {
  DayEvent({
    this.id,
    required DateTime date,
    required String label,
    this.isPrimary = false,
  }) : date = DateTime.utc(date.year, date.month, date.day),
       label = label.trim() {
    if (this.label.isEmpty || this.label.runes.length > dayEventMaxTitle) {
      throw const FormatException('D-Day label must contain 1..20 characters.');
    }
  }

  final String? id;
  final DateTime date;
  final String label;
  final bool isPrimary;

  String get displayDate => formatEventDate(date);

  int daysFrom(DateTime instant) =>
      date.difference(koreanCalendarDay(instant)).inDays;

  /// D-N / D-DAY / 지난 일정 for the given instant.
  String dLabel(DateTime instant) {
    final days = daysFrom(instant);
    return days < 0
        ? '지난 일정'
        : days == 0
        ? 'D-DAY'
        : 'D-$days';
  }

  bool isUpcoming(DateTime instant) => daysFrom(instant) >= 0;

  DayEvent copyWith({String? id, DateTime? date, String? label, bool? isPrimary}) =>
      DayEvent(
        id: id ?? this.id,
        date: date ?? this.date,
        label: label ?? this.label,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  @override
  bool operator ==(Object other) =>
      other is DayEvent &&
      other.id == id &&
      other.date == date &&
      other.label == label &&
      other.isPrimary == isPrimary;

  @override
  int get hashCode => Object.hash(id, date, label, isPrimary);
}

/// Deterministic ordering for the collection: soonest date first, then a stable
/// tie-break by label then id, so the same events always render in the same order.
int compareEvents(DayEvent a, DayEvent b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  final byLabel = a.label.compareTo(b.label);
  if (byLabel != 0) return byLabel;
  return (a.id ?? '').compareTo(b.id ?? '');
}

/// The event shown in the Home representative card: the user-chosen primary if
/// present, else a deterministic fallback to the nearest upcoming event. This
/// is a display choice only and never writes to storage.
DayEvent? representativeEvent(List<DayEvent> events, DateTime instant) {
  for (final e in events) {
    if (e.isPrimary) return e;
  }
  final upcoming = [for (final e in events) if (e.isUpcoming(instant)) e]
    ..sort(compareEvents);
  return upcoming.isEmpty ? null : upcoming.first;
}

/// Non-primary upcoming events for the Home compact list, soonest first.
/// The representative is always excluded so it is never shown twice.
List<DayEvent> compactUpcoming(
  List<DayEvent> events,
  DateTime instant,
  DayEvent? representative,
) {
  final list = [
    for (final e in events)
      if (e.isUpcoming(instant) && !identical(e, representative)) e,
  ]..sort(compareEvents);
  return list;
}
