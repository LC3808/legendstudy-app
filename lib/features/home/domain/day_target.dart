class DayTarget {
  DayTarget({required DateTime date, required String label})
    : date = DateTime.utc(date.year, date.month, date.day),
      label = label.trim() {
    if (this.label.isEmpty || this.label.runes.length > 80) {
      throw const FormatException('D-Day label must contain 1..80 characters.');
    }
  }
  final DateTime date;
  final String label;
  String get formattedDate =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  int daysFrom(DateTime instant) =>
      date.difference(koreanCalendarDay(instant)).inDays;
  String description(DateTime instant) {
    final days = daysFrom(instant);
    final status = days < 0
        ? '지난 일정'
        : days == 0
        ? 'D-DAY'
        : 'D-$days';
    return '$status · $formattedDate';
  }
}

DateTime koreanCalendarDay(DateTime instant) {
  final korea = instant.toUtc().add(const Duration(hours: 9));
  return DateTime.utc(korea.year, korea.month, korea.day);
}
