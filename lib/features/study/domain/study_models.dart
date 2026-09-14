import 'dart:math';
import '../scoring/scoring_models.dart';

const studyMaxSpan = 86400000;
const studyMaxSegments = 256;

enum TimerPhase { idle, running, paused, ending, recoveryRequired }

enum MockPhase { setup, ready, running, paused, timeUp, submitting, completed }

class MockSetup {
  const MockSetup(
    this.title,
    this.subject,
    this.plannedSeconds, {
    this.notify = false,
  });
  final String title;
  final String? subject;
  final int plannedSeconds;
  final bool notify;
  static const presets = {'국어': 80, '수학': 100, '영어': 70, '탐구': 30};
  void validate() {
    if (title.isEmpty ||
        title != title.trim() ||
        title.runes.length > 80 ||
        (subject != null &&
            (subject!.isEmpty ||
                subject != subject!.trim() ||
                subject!.runes.length > 40)) ||
        plannedSeconds < 60 ||
        plannedSeconds > 43200) {
      throw const FormatException('Invalid mock setup');
    }
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'planned': plannedSeconds,
    'notify': notify,
  };
  factory MockSetup.fromJson(Map<String, dynamic> j) {
    final setup = MockSetup(
      j['title'] as String,
      j['subject'] as String?,
      j['planned'] as int,
      notify: j['notify'] == true,
    );
    setup.validate();
    return setup;
  }
}

enum SavePhase { idle, saving, local, saved, pendingSync, error }

class ClockReading {
  const ClockReading(this.utcMs, this.elapsedMs, this.boot);
  final int utcMs, elapsedMs;
  final String boot;
}

class ActiveSegment {
  const ActiveSegment(this.start, this.end);
  final int start, end;
  List<int> toJson() => [start, end];
}

class StudyRecord {
  StudyRecord({
    required this.id,
    required this.startedMs,
    required this.endedMs,
    required List<ActiveSegment> segments,
    this.mode = 'study',
    this.title,
    this.subject,
    this.plannedSeconds,
    this.synced = false,
  }) : segments = List.unmodifiable(segments) {
    validate();
  }
  final String id, mode;
  final int startedMs, endedMs;
  final List<ActiveSegment> segments;
  final String? title, subject;
  final int? plannedSeconds;
  final bool synced;
  int get activeMs => segments.fold(0, (n, s) => n + s.end - s.start);
  void validate() {
    if (endedMs < startedMs ||
        endedMs - startedMs > studyMaxSpan ||
        segments.length > studyMaxSegments ||
        activeMs < 1000 ||
        !['study', 'mock_exam'].contains(mode)) {
      throw const FormatException('Invalid study record');
    }
    var last = 0;
    for (final s in segments) {
      if (s.start < last || s.end <= s.start || s.end > endedMs - startedMs) {
        throw const FormatException('Invalid active interval');
      }
      last = s.end;
    }
    for (final (value, limit) in [(title, 80), (subject, 40)]) {
      if (value != null &&
          (value.trim() != value ||
              value.isEmpty ||
              value.runes.length > limit)) {
        throw const FormatException('Invalid study label');
      }
    }
    if ((mode == 'study' && plannedSeconds != null) ||
        (mode == 'mock_exam' &&
            (title == null ||
                plannedSeconds == null ||
                plannedSeconds! < 60 ||
                plannedSeconds! > 43200 ||
                activeMs > plannedSeconds! * 1000))) {
      throw const FormatException('Invalid study mode');
    }
  }

  Map<String, dynamic> payload() => {
    'id': id,
    'mode': mode,
    'title': title,
    'subject': subject,
    'planned_duration_seconds': plannedSeconds,
    'started_at': DateTime.fromMillisecondsSinceEpoch(
      startedMs,
      isUtc: true,
    ).toIso8601String(),
    'ended_at': DateTime.fromMillisecondsSinceEpoch(
      endedMs,
      isUtc: true,
    ).toIso8601String(),
    'active_segments': segments.map((s) => s.toJson()).toList(),
  };
  Map<String, dynamic> toJson() => {...payload(), 'synced': synced};
  factory StudyRecord.fromJson(Map<String, dynamic> json) => StudyRecord(
    id: json['id'] as String,
    mode: json['mode'] as String,
    startedMs: DateTime.parse(
      json['started_at'] as String,
    ).millisecondsSinceEpoch,
    endedMs: DateTime.parse(json['ended_at'] as String).millisecondsSinceEpoch,
    title: json['title'] as String?,
    subject: json['subject'] as String?,
    plannedSeconds: json['planned_duration_seconds'] as int?,
    synced: json['synced'] == true,
    segments: (json['active_segments'] as List)
        .map((s) => ActiveSegment(s[0] as int, s[1] as int))
        .toList(),
  );
  StudyRecord acknowledged() =>
      StudyRecord.fromJson({...toJson(), 'synced': true});
}

class StudyDraft {
  StudyDraft({
    required this.id,
    required this.startedMs,
    required this.anchorElapsed,
    required this.boot,
    required this.phase,
    required this.checkpoint,
    required this.segments,
    this.openStart,
    this.mock,
    this.frozenReason,
    this.answers,
  });
  final AnswerDraft? answers;
  final String id, boot;
  final int startedMs, anchorElapsed, checkpoint;
  final TimerPhase phase;
  final List<ActiveSegment> segments;
  final int? openStart;
  final MockSetup? mock;
  final String? frozenReason;
  bool get frozen => frozenReason != null;
  int boundedOffset(int value) {
    if (frozen) return checkpoint;
    var end = value.clamp(0, studyMaxSpan);
    if (mock != null && openStart != null) {
      final used = segments.fold(0, (n, s) => n + s.end - s.start);
      end = min(end, openStart! + max(0, mock!.plannedSeconds * 1000 - used));
    }
    return end;
  }

  bool exhausted(int value) =>
      mock != null &&
      (value >= studyMaxSpan || activeMs(value) >= mock!.plannedSeconds * 1000);
  StudyDraft freeze(int value, String reason) {
    if (frozen) return this;
    final end = boundedOffset(value);
    return StudyDraft(
      id: id,
      startedMs: startedMs,
      anchorElapsed: anchorElapsed,
      boot: boot,
      phase: TimerPhase.paused,
      checkpoint: end,
      segments: activeAt(end),
      mock: mock,
      answers: answers,
      frozenReason: reason,
    );
  }

  factory StudyDraft.start(
    ClockReading now, {
    MockSetup? mock,
    AnswerDraft? answers,
  }) => StudyDraft(
    mock: mock,
    answers: answers,
    id: newStudyId(),
    startedMs: now.utcMs,
    anchorElapsed: now.elapsedMs,
    boot: now.boot,
    phase: TimerPhase.running,
    checkpoint: 0,
    segments: const [],
    openStart: 0,
  );
  bool continuous(ClockReading now) =>
      boot.isNotEmpty &&
      boot == now.boot &&
      now.elapsedMs >= anchorElapsed + checkpoint &&
      ((now.utcMs - startedMs) - (now.elapsedMs - anchorElapsed)).abs() < 5000;
  int offset(ClockReading now) => boundedOffset(now.elapsedMs - anchorElapsed);
  List<ActiveSegment> activeAt(int offset) => [
    ...segments,
    if (openStart != null && boundedOffset(offset) > openStart!)
      ActiveSegment(openStart!, boundedOffset(offset)),
  ];
  int activeMs(int offset) =>
      activeAt(offset).fold(0, (n, s) => n + s.end - s.start);
  StudyDraft at(int offset, {TimerPhase? next}) {
    if (frozen) return this;
    offset = boundedOffset(offset);
    final target = next ?? phase;
    final closing = phase == TimerPhase.running && target != TimerPhase.running;
    return StudyDraft(
      mock: mock,
      answers: answers,
      id: id,
      startedMs: startedMs,
      anchorElapsed: anchorElapsed,
      boot: boot,
      checkpoint: offset,
      phase: target,
      segments: closing ? activeAt(offset) : segments,
      openStart: target == TimerPhase.running ? (openStart ?? offset) : null,
    );
  }

  StudyDraft withAnswers(AnswerDraft value) =>
      StudyDraft.fromJson({...toJson(), 'answers': value.toJson()});

  StudyRecord? finish(int offset) => activeMs(offset) < 1000
      ? null
      : StudyRecord(
          id: id,
          startedMs: startedMs,
          endedMs: startedMs + boundedOffset(offset),
          mode: mock == null ? 'study' : 'mock_exam',
          title: mock?.title,
          subject: mock?.subject,
          plannedSeconds: mock?.plannedSeconds,
          segments: activeAt(offset),
        );
  Map<String, dynamic> toJson() => {
    'id': id,
    'answers': answers?.toJson(),
    'mock': mock?.toJson(),
    'frozen': frozenReason,
    'started': startedMs,
    'anchor': anchorElapsed,
    'boot': boot,
    'phase': phase.name,
    'checkpoint': checkpoint,
    'open': openStart,
    'segments': segments.map((s) => s.toJson()).toList(),
  };
  factory StudyDraft.fromJson(Map<String, dynamic> j) {
    final d = StudyDraft(
      answers: j['answers'] == null
          ? null
          : AnswerDraft.fromJson(
              Map<String, dynamic>.from(j['answers'] as Map),
            ),
      mock: j['mock'] == null
          ? null
          : MockSetup.fromJson(Map<String, dynamic>.from(j['mock'] as Map)),
      frozenReason: j['frozen'] as String?,
      id: j['id'] as String,
      startedMs: j['started'] as int,
      anchorElapsed: j['anchor'] as int,
      boot: j['boot'] as String,
      phase: TimerPhase.values.byName(j['phase'] as String),
      checkpoint: j['checkpoint'] as int,
      openStart: j['open'] as int?,
      segments: (j['segments'] as List)
          .map((s) => ActiveSegment(s[0] as int, s[1] as int))
          .toList(),
    );
    if (d.answers != null && d.mock == null) {
      throw const FormatException('Scoring requires mock');
    }
    if (![TimerPhase.running, TimerPhase.paused].contains(d.phase) ||
        d.checkpoint < 0 ||
        d.checkpoint > studyMaxSpan ||
        d.anchorElapsed < 0 ||
        d.segments.length + (d.openStart == null ? 0 : 1) > studyMaxSegments ||
        (d.phase == TimerPhase.running) != (d.openStart != null)) {
      throw const FormatException('Invalid draft');
    }
    if (d.frozen &&
        (d.mock == null ||
            d.phase != TimerPhase.paused ||
            ![
              'planElapsed',
              'wallLimit',
              'accountChanged',
              'recovery',
              'submit',
            ].contains(d.frozenReason))) {
      throw const FormatException('Invalid frozen draft');
    }
    var last = 0;
    for (final s in d.segments) {
      if (s.start < last || s.end <= s.start || s.end > d.checkpoint) {
        throw const FormatException('Invalid draft interval');
      }
      last = s.end;
    }
    if (d.openStart != null &&
        (d.openStart! < last || d.openStart! > d.checkpoint)) {
      throw const FormatException('Invalid draft start');
    }
    if (d.mock != null &&
        d.segments.fold(0, (n, s) => n + s.end - s.start) +
                (d.openStart == null ? 0 : d.checkpoint - d.openStart!) >
            d.mock!.plannedSeconds * 1000) {
      throw const FormatException('Invalid mock duration');
    }
    return d;
  }
}

String newStudyId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

DateTime koreanDay(int utcMs) {
  final k = DateTime.fromMillisecondsSinceEpoch(
    utcMs,
    isUtc: true,
  ).add(const Duration(hours: 9));
  return DateTime.utc(k.year, k.month, k.day);
}

int dayStartMs(DateTime day) =>
    day.subtract(const Duration(hours: 9)).millisecondsSinceEpoch;

/// Union absolute intervals before splitting KST days. Current draft is a local overlay.
List<int> studyWeek(
  List<StudyRecord> records,
  int nowMs, {
  StudyDraft? draft,
  int? offset,
}) {
  final days = List<int>.filled(7, 0);
  final first = koreanDay(nowMs).subtract(const Duration(days: 6));
  final intervals = <ActiveSegment>[];
  for (final record in {for (final r in records) r.id: r}.values) {
    intervals.addAll(
      record.segments.map(
        (s) =>
            ActiveSegment(record.startedMs + s.start, record.startedMs + s.end),
      ),
    );
  }
  if (draft != null &&
      offset != null &&
      !records.any((r) => r.id == draft.id)) {
    intervals.addAll(
      draft
          .activeAt(offset)
          .map(
            (s) => ActiveSegment(
              draft.startedMs + s.start,
              draft.startedMs + s.end,
            ),
          ),
    );
  }
  intervals.sort((a, b) => a.start.compareTo(b.start));
  final union = <ActiveSegment>[];
  for (final s in intervals) {
    if (union.isEmpty || s.start > union.last.end) {
      union.add(s);
    } else {
      final last = union.removeLast();
      union.add(ActiveSegment(last.start, max(last.end, s.end)));
    }
  }
  for (var i = 0; i < 7; i++) {
    final start = dayStartMs(first.add(Duration(days: i))),
        end = start + studyMaxSpan;
    for (final s in union) {
      days[i] += max(0, min(end, s.end) - max(start, s.start));
    }
  }
  return days;
}

String studyDuration(int ms) {
  final mins = ms ~/ 60000;
  if (mins == 0) return ms > 0 ? '1분 미만' : '0분';
  return mins < 60 ? '$mins분' : '${mins ~/ 60}시간 ${mins % 60}분';
}

String timerDigits(int ms) {
  final seconds = ms ~/ 1000;
  return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
