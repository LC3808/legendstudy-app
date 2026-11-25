/// Provenance and the student's visibility choice for an official admission
/// event. Hidden events deliberately have no D-Day projection to render.
class AdmissionDayEvent {
  const AdmissionDayEvent({
    required this.officialEventId,
    required this.title,
    required this.universityName,
    required this.eventType,
    required this.status,
    required this.revision,
    required this.canRestore,
    this.dayTargetId,
    this.date,
    this.eventTime,
    this.sourceUrl,
    this.sourceNote,
    this.unavailableReason,
  });

  final String officialEventId;
  final String? dayTargetId;
  final String title;
  final String universityName;
  final String eventType;
  final DateTime? date;
  final String? eventTime;
  final String status;
  final String? sourceUrl;
  final String? sourceNote;
  final int revision;
  final bool canRestore;
  final String? unavailableReason;

  bool get isActive => status == 'ACTIVE';
  bool get isDismissed => status == 'DISMISSED';

  String get typeLabel => switch (eventType.toUpperCase()) {
    'ESSAY' => '논술고사',
    'INTERVIEW' => '면접고사',
    'PRACTICAL' => '실기고사',
    'STAGE_RESULT' => '1단계 합격자 발표',
    'INITIAL_RESULT' => '최초 합격자 발표',
    'REGISTRATION_DEADLINE' => '등록 마감',
    _ => '공식 일정',
  };

  String get displayTitle => '$universityName $typeLabel';

  factory AdmissionDayEvent.fromJson(Map<String, dynamic> row) {
    String requiredText(String key) {
      final value = row[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Invalid admission event $key');
      }
      return value;
    }

    final status = requiredText('status');
    final revision = row['revision'];
    if (!const {'ACTIVE', 'DISMISSED', 'CANCELLED'}.contains(status) ||
        revision is! int ||
        revision < 1 ||
        row['can_restore'] is! bool) {
      throw const FormatException('Invalid admission event state');
    }
    final rawDate = row['event_date'];
    DateTime? date;
    if (rawDate != null) {
      if (rawDate is! String ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
        throw const FormatException('Invalid admission calendar date');
      }
      date = DateTime.tryParse(rawDate);
      if (date == null || date.toIso8601String().substring(0, 10) != rawDate) {
        throw const FormatException('Invalid admission calendar date');
      }
      date = DateTime.utc(date.year, date.month, date.day);
    }
    return AdmissionDayEvent(
      officialEventId: requiredText('official_event_id'),
      dayTargetId: row['day_target_id'] as String?,
      title: requiredText('title'),
      universityName: requiredText('university_name'),
      eventType: requiredText('event_type'),
      date: date,
      eventTime: row['event_time'] as String?,
      status: status,
      sourceUrl: row['source_url'] as String?,
      sourceNote: row['source_note'] as String?,
      revision: revision,
      canRestore: row['can_restore'] as bool,
      unavailableReason: row['unavailable_reason'] as String?,
    );
  }
}
