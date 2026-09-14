import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../domain/study_models.dart';
import '../scoring/scoring_models.dart';
import '../scoring/scoring_repository.dart';
import '../data/study_local.dart';
import '../data/study_repository.dart';

class StudyController extends ChangeNotifier with WidgetsBindingObserver {
  StudyController(
    this.clock,
    this.store,
    this.repository, {
    this.ticking = true,
    this.scoringRepository,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }
  final StudyClock clock;
  final StudyLocalStore store;
  final StudyRepository Function() repository;
  final bool ticking;
  final ScoringRepository Function()? scoringRepository;
  AnswerDraft? scoringSetup;
  List<ScoringAttempt> attempts = [];
  bool scoringBusy = false;
  bool get guest => _identity == null;
  bool ready = false,
      busy = false,
      historyError = false,
      historyLimit = false,
      authReady = false;
  String? message;
  bool historyStale = false;
  SavePhase savePhase = SavePhase.idle;
  TimerPhase get phase => recovery
      ? TimerPhase.recoveryRequired
      : busy
      ? TimerPhase.ending
      : draft?.phase ?? TimerPhase.idle;
  StudyDraft? draft;
  bool mockSelected = false;
  bool _mockSubmitting = false;
  int get viewGeneration => _epoch;
  MockSetup? mockSetup;
  StudyRecord? lastMock;
  MockPhase get mockPhase => draft?.mock != null
      ? _mockSubmitting
            ? MockPhase.submitting
            : draft!.frozen
            ? MockPhase.timeUp
            : draft!.phase == TimerPhase.running
            ? MockPhase.running
            : MockPhase.paused
      : lastMock != null
      ? MockPhase.completed
      : mockSetup == null
      ? MockPhase.setup
      : MockPhase.ready;
  int get remainingMs =>
      ((draft?.mock ?? mockSetup)?.plannedSeconds ?? 0) * 1000 - elapsedMs;
  String? get focusSession =>
      recovery || draft?.frozen == true ? null : draft?.id;
  bool selectMock(bool value) {
    if (draft != null || busy) {
      message = '현재 세션을 종료하거나 취소한 뒤 모드를 변경해 주세요.';
      _notify();
      return false;
    }
    mockSelected = value;
    message = null;
    _notify();
    return true;
  }

  void configureMock(MockSetup? setup) {
    if (draft != null || busy) return;
    setup?.validate();
    mockSetup = setup;
    lastMock = null;
    _notify();
  }

  List<StudyRecord> records = [];
  bool recovery = false;
  int nowMs = DateTime.now().millisecondsSinceEpoch,
      offset = 0,
      lastCompletedMs = 0;
  String? _identity;
  String _owner = 'guest';
  int _epoch = 0;
  bool _alive = true, _loaded = false, _tickInFlight = false;
  final Set<String> _syncing = {};
  Map<String, dynamic> _doc = {'version': 3, 'owners': <String, dynamic>{}};
  Future<void> _queue = Future.value();
  Timer? _timer;
  int get elapsedMs => draft?.activeMs(offset) ?? 0;
  List<int> get week =>
      studyWeek(records, nowMs, draft: recovery ? null : draft, offset: offset);
  bool get summaryComplete => ready && !historyError && !historyLimit;
  bool get canResume =>
      draft != null &&
      draft!.segments.length < studyMaxSegments &&
      !draft!.frozen;
  String get storageLabel => switch (savePhase) {
    SavePhase.local => '이 기기에 저장됨',
    SavePhase.saved => '저장됨',
    SavePhase.pendingSync => '동기화 대기',
    SavePhase.saving => '저장 중',
    SavePhase.error => '기기 저장을 완료하지 못했어요.',
    SavePhase.idle => '',
  };
  String get summary {
    if (!ready) return '공부 기록을 불러오는 중이에요.';
    if (historyLimit) return '기록이 많아 전체 합계를 표시할 수 없어요.';
    if (historyError) return '전체 공부시간을 확인하지 못했어요.';
    final prefix = historyStale ? '최근 확인한 기록 기준: ' : '';
    return week.last == 0
        ? '$prefix오늘 공부 기록이 아직 없어요.'
        : '$prefix오늘 ${studyDuration(week.last)} 공부했어요.';
  }

  void _notify() {
    if (!_alive) return;
    if (ticking && draft != null && !recovery && !draft!.frozen) {
      _timer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(tick()),
      );
    } else {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) async {
      if (_alive) await action();
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> get settled => _queue;
  void retryLocal() => identity(_identity, resolved: authReady);
  Map<String, dynamic> _space(String owner) =>
      Map<String, dynamic>.from((_doc['owners'] as Map)[owner] as Map? ?? {});
  List<StudyRecord> _local(String owner) =>
      ((_space(owner)['records'] as List?) ?? [])
          .map((r) => StudyRecord.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
  Future<void> _write(
    String owner,
    StudyDraft? d,
    List<StudyRecord> rows, {
    List<ScoringAttempt>? scores,
  }) async {
    final copy = jsonDecode(jsonEncode(_doc)) as Map<String, dynamic>;
    copy['version'] = 3;
    (copy['owners'] as Map)[owner] = {
      ..._space(owner),
      if (scores != null) 'attempts': scores.map((a) => a.toJson()).toList(),
      'draft': d?.toJson(),
      'records': rows.map((r) => r.toJson()).toList(),
    };
    await store.write(copy);
    _doc = copy;
  }

  void identity(String? user, {required bool resolved}) {
    authReady = resolved;
    if (!resolved) {
      _notify();
      return;
    }
    if (ready && _identity == user) return;
    if (!_loaded || _identity != user || !ready) {
      final previousOwner = _owner;
      final previousDraft = draft;
      final previousOffset = offset;
      final changedOwner = previousOwner != (user ?? 'guest');
      final e = ++_epoch;
      _identity = user;
      _owner = user ?? 'guest';
      ready = false;
      records = [];
      draft = null;
      offset = 0;
      recovery = false;
      busy = false;
      historyError = user != null;
      historyStale = false;
      historyLimit = false;
      savePhase = SavePhase.idle;
      message = null;
      lastCompletedMs = 0;
      lastMock = null;
      scoringSetup = null;
      attempts = [];
      scoringBusy = false;
      mockSetup = null;
      _mockSubmitting = false;
      _notify();
      unawaited(
        _serial(() async {
          try {
            if (!_loaded) {
              _doc = await store.read();
              if (![1, 2, 3].contains(_doc['version']) ||
                  _doc['owners'] is! Map) {
                throw const FormatException('Unsupported local study state');
              }
              // Validate every owner before atomically upgrading; never discard old outbox.
              for (final owner in (_doc['owners'] as Map).keys.cast<String>()) {
                final raw = _space(owner)['draft'];
                if (raw != null) {
                  StudyDraft.fromJson(Map<String, dynamic>.from(raw as Map));
                }
                _local(owner);
                _scores(owner);
              }
              if (_doc['version'] != 3) {
                final upgraded = {..._doc, 'version': 3};
                await store.write(upgraded);
                _doc = upgraded;
              }
              _loaded = true;
            }
            final now = await clock.read();
            final previousRaw = _space(previousOwner)['draft'];
            final leavingDraft =
                previousDraft ??
                (changedOwner && previousRaw != null
                    ? StudyDraft.fromJson(
                        Map<String, dynamic>.from(previousRaw as Map),
                      )
                    : null);
            if (changedOwner && leavingDraft != null) {
              // Finalize only into the original namespace. Never upload guest work on login.
              final end = leavingDraft.continuous(now)
                  ? leavingDraft.offset(now)
                  : (previousDraft == null
                        ? leavingDraft.checkpoint
                        : previousOffset);
              if (leavingDraft.mock != null) {
                await _write(
                  previousOwner,
                  leavingDraft.freeze(
                    end,
                    leavingDraft.activeMs(end) >=
                            leavingDraft.mock!.plannedSeconds * 1000
                        ? 'planElapsed'
                        : end >= studyMaxSpan
                        ? 'wallLimit'
                        : 'accountChanged',
                  ),
                  _local(previousOwner),
                );
              } else {
                final row = leavingDraft.finish(end);
                final rows = _local(previousOwner);
                if (row != null && !rows.any((r) => r.id == row.id)) {
                  rows.add(row);
                }
                await _write(previousOwner, null, rows);
              }
            }
            if (e != _epoch) return;
            nowMs = now.utcMs;
            records = _local(_owner);
            attempts = _scores(_owner);
            final raw = _space(_owner)['draft'];
            draft = raw == null
                ? null
                : StudyDraft.fromJson(Map<String, dynamic>.from(raw as Map));
            if (draft != null) {
              recovery = !draft!.frozen && !draft!.continuous(now);
              mockSelected = draft!.mock != null;
              offset = recovery ? draft!.checkpoint : draft!.offset(now);
            }
            ready = true;
            savePhase = records.any((r) => !r.synced) && _identity != null
                ? SavePhase.pendingSync
                : SavePhase.idle;
            _notify();
            if (draft != null && !recovery) {
              if (draft!.mock != null &&
                  draft!.exhausted(offset) &&
                  !draft!.frozen) {
                await _freezeMock();
              } else if (draft!.mock == null && offset >= studyMaxSpan) {
                await _finish();
              }
            }
            unawaited(sync());
          } catch (_) {
            if (e == _epoch) {
              message = '기기 기록을 읽지 못했어요. 다시 시도해 주세요.';
              savePhase = SavePhase.error;
              _notify();
            }
          }
        }),
      );
    }
  }

  Future<void> tick() async {
    if (!ready || _tickInFlight || !_alive) return;
    _tickInFlight = true;
    final e = _epoch;
    try {
      final now = await clock.read();
      if (e != _epoch || !_alive) return;
      final oldDay = koreanDay(nowMs);
      nowMs = now.utcMs;
      final d = draft;
      if (d != null && !recovery && !d.frozen) {
        if (!d.continuous(now)) {
          recovery = true;
          offset = d.checkpoint;
        } else {
          offset = d.offset(now);
        }
        if (!recovery && d.mock != null && d.exhausted(offset)) {
          await _command((_) async {
            if (draft == d) await _freezeMock();
          });
        } else if (!recovery && offset >= studyMaxSpan) {
          await end(automatic: true);
        } else if (!recovery && offset - d.checkpoint >= 30000) {
          await _serial(() async {
            if (e != _epoch || draft != d) return;
            final updated = d.at(offset);
            await _write(_owner, updated, _local(_owner));
            if (e == _epoch) draft = updated;
          });
        }
      }
      if (oldDay != koreanDay(nowMs)) unawaited(sync());
      _notify();
    } catch (_) {
      if (e == _epoch) {
        message = '기기 기록을 확인하지 못했어요.';
        _notify();
      }
    } finally {
      _tickInFlight = false;
    }
  }

  Future<void> _command(Future<void> Function(ClockReading) action) async {
    if (!ready || (!authReady && draft == null) || busy || recovery) return;
    busy = true;
    message = null;
    _notify();
    final e = _epoch;
    try {
      await _serial(() async {
        final now = await clock.read();
        if (e == _epoch) await action(now);
      });
    } catch (_) {
      if (e == _epoch) {
        message = '기기 저장을 완료하지 못했어요. 다시 시도해 주세요.';
        savePhase = SavePhase.error;
      }
    } finally {
      if (e == _epoch) {
        busy = false;
        _mockSubmitting = false;
        _notify();
      }
    }
  }

  Future<void> startMock() async {
    final setup = mockSetup;
    if (setup == null) return;
    setup.validate();
    await _start(setup);
  }

  Future<void> start() => _start(null);
  Future<void> _start(MockSetup? mock) => _command((now) async {
    if (draft != null) return;
    final d = StudyDraft.start(
      now,
      mock: mock,
      answers: mock == null ? null : scoringSetup,
    );
    final e = _epoch;
    final owner = _owner;
    await _write(owner, d, _local(owner));
    if (e != _epoch) return;
    draft = d;
    mockSelected = mock != null;
    lastMock = null;
    offset = 0;
    nowMs = now.utcMs;
    lastCompletedMs = 0;
    savePhase = SavePhase.idle;
    // Future focus integration runs after durable start; no permission dependency here.
  });
  Future<void> pause() => _command((now) async {
    if (draft?.phase != TimerPhase.running || draft!.frozen) return;
    await _transition(now, TimerPhase.paused);
  });
  Future<void> resume() => _command((now) async {
    if (draft?.phase != TimerPhase.paused || !canResume) return;
    await _transition(now, TimerPhase.running);
  });
  Future<void> _transition(ClockReading now, TimerPhase next) async {
    final d = draft!;
    if (!d.continuous(now)) {
      recovery = true;
      offset = d.checkpoint;
      return;
    }
    offset = d.offset(now);
    nowMs = now.utcMs;
    if (d.mock != null && d.exhausted(offset)) {
      await _freezeMock();
      return;
    }
    if (offset >= studyMaxSpan) {
      await _finish();
      return;
    }
    final updated = d.at(offset, next: next);
    final e = _epoch;
    await _write(_owner, updated, _local(_owner));
    if (e == _epoch) draft = updated;
  }

  Future<void> end({bool automatic = false}) => _command((now) async {
    if (draft == null) return;
    if (!draft!.frozen && !draft!.continuous(now)) {
      recovery = true;
      offset = draft!.checkpoint;
      return;
    }
    offset = draft!.offset(now);
    nowMs = now.utcMs;
    if (draft!.mock != null) {
      if (automatic) {
        await _freezeMock();
        return;
      }
      _mockSubmitting = true;
      await _freezeMock(reason: 'submit');
    }
    await _finish();
    if (automatic) message = '24시간이 지나 자동으로 종료했어요.';
  });
  Future<void> _freezeMock({String? reason}) async {
    final d = draft;
    if (d == null || d.mock == null || d.frozen) return;
    final e = _epoch;
    final frozen = d.freeze(
      offset,
      reason ??
          (d.activeMs(offset) >= d.mock!.plannedSeconds * 1000
              ? 'planElapsed'
              : 'wallLimit'),
    );
    // Freeze memory too on disk failure, so retry cannot add extra active time.
    draft = frozen;
    offset = frozen.checkpoint;
    _notify();
    await _write(_owner, frozen, _local(_owner));
    if (e != _epoch) return;
  }

  Future<void> discardMock() => _command((_) async {
    if (draft?.mock != null) await _finish(discard: true);
  });
  Future<void> _finish({bool discard = false}) async {
    final d = draft;
    if (d == null) return;
    final owner = _owner, e = _epoch;
    final row = discard ? null : d.finish(offset);
    final rows = _local(owner);
    if (row != null && !rows.any((r) => r.id == row.id)) rows.add(row);
    final scores = _scores(owner);
    if (!discard && d.answers != null) {
      scores.add(
        ScoringAttempt(
          id: newStudyId(),
          title: d.mock!.title,
          subject: d.mock!.subject,
          completedAt: DateTime.fromMillisecondsSinceEpoch(
            d.startedMs + d.boundedOffset(offset),
            isUtc: true,
          ),
          draft: d.answers!,
          studyId: row?.id,
        ),
      );
    }
    await _write(owner, null, rows, scores: scores);
    if (e != _epoch) return;
    draft = null;
    attempts = scores;
    scoringSetup = null;
    recovery = false;
    lastCompletedMs = row?.activeMs ?? 0;
    lastMock = row?.mode == 'mock_exam' ? row : null;
    records = _merge(rows, records);
    savePhase = row == null
        ? SavePhase.idle
        : _identity == null
        ? SavePhase.local
        : SavePhase.pendingSync;
    if (row == null && !discard) message = '기록할 공부시간이 너무 짧아요.';
    unawaited(sync());
  }

  Future<void> recover({required bool keep}) async {
    if (!recovery || busy) return;
    busy = true;
    final e = _epoch;
    try {
      await _serial(() async {
        if (e != _epoch) return;
        if (keep && draft?.mock != null) {
          await _freezeMock(reason: 'recovery');
          recovery = false;
        } else {
          await _finish(discard: !keep);
        }
      });
    } catch (_) {
      if (e == _epoch) {
        message = '기기 저장을 완료하지 못했어요.';
        savePhase = SavePhase.error;
      }
    } finally {
      if (e == _epoch) {
        busy = false;
        _mockSubmitting = false;
        _notify();
      }
    }
  }

  List<StudyRecord> _merge(List<StudyRecord> local, List<StudyRecord> remote) =>
      {
        for (final r in remote) r.id: r,
        for (final r in local) r.id: r,
      }.values.toList();
  Future<void> sync() async {
    if (!ready || !authReady || !_alive) return;
    final owner = _owner, e = _epoch;
    if (!_syncing.add(owner)) return;
    try {
      if (_identity == null) {
        await _syncScores(owner, e);
        return;
      }
      final repo = repository();
      if (repo.owner != owner) throw const StudyStorageError();
      final pending = _local(owner).where((r) => !r.synced).toList();
      for (final row in pending) {
        if (e != _epoch || !_alive) return;
        await repo.insertCompleted(row);
        await _serial(() async {
          final rows = _local(
            owner,
          ).map((r) => r.id == row.id ? r.acknowledged() : r).toList();
          final raw = _space(owner)['draft'];
          await _write(
            owner,
            raw == null
                ? null
                : StudyDraft.fromJson(Map<String, dynamic>.from(raw as Map)),
            rows,
          );
        });
      }
      await _syncScores(owner, e);
      final fetched = await repo.fetchWindow(nowMs);
      if (e != _epoch || !_alive) return;
      records = _merge(_local(owner), fetched);
      historyError = false;
      historyStale = false;
      historyLimit = false;
      savePhase = _local(owner).any((r) => !r.synced)
          ? SavePhase.pendingSync
          : records.isEmpty
          ? SavePhase.idle
          : SavePhase.saved;
    } on StudyHistoryLimit {
      if (e == _epoch) {
        historyLimit = true;
        historyError = false;
      }
    } catch (_) {
      if (e == _epoch) {
        historyStale = true;
        savePhase = _local(owner).any((r) => !r.synced)
            ? SavePhase.pendingSync
            : savePhase;
      }
    } finally {
      _syncing.remove(owner);
      if (e == _epoch) _notify();
    }
  }

  List<ScoringAttempt> _scores(String owner) =>
      ((_space(owner)['attempts'] as List?) ?? [])
          .map(
            (a) => ScoringAttempt.fromJson(Map<String, dynamic>.from(a as Map)),
          )
          .toList();

  Future<void> configureScoring(MockScoringAvailability? a) async {
    if (draft != null || busy) return;
    final e = _epoch;
    if (a == null) {
      scoringSetup = null;
      _notify();
      return;
    }
    final repo = scoringRepository?.call();
    if (repo == null) return;
    final prepared = await repo.prepare(a);
    if (e == _epoch && draft == null) {
      scoringSetup = prepared;
      _notify();
    }
  }

  Future<void> selectAnswer(int number, int? choice) => _command((now) async {
    final d = draft;
    if (d?.answers == null || d!.frozen || d.phase != TimerPhase.running) {
      return;
    }
    if (!d.continuous(now)) {
      recovery = true;
      return;
    }
    offset = d.offset(now);
    if (d.exhausted(offset)) {
      await _freezeMock();
      return;
    }
    final next = d.at(offset).withAnswers(d.answers!.select(number, choice));
    final e = _epoch;
    await _write(_owner, next, _local(_owner));
    if (e == _epoch) draft = next;
  });

  Future<void> _syncScores(String owner, int e) async {
    if (scoringRepository == null || e != _epoch || !_alive) return;
    final repo = scoringRepository!();
    if ((repo.owner ?? 'guest') != owner) return;
    scoringBusy = true;
    _notify();
    try {
      for (final attempt in _scores(
        owner,
      ).where((a) => a.outcome == ScoringOutcome.pending)) {
        if (e != _epoch || !_alive) return;
        if (repo.owner != null &&
            attempt.studyId != null &&
            !_local(owner).any((r) => r.id == attempt.studyId && r.synced)) {
          return;
        }
        ScoringAttempt updated;
        try {
          updated = attempt.completed(await repo.submit(attempt));
        } on ScoringStale {
          updated = attempt.stale();
        } catch (_) {
          if (e == _epoch) message = '채점하지 못했어요. 답안은 보관되어 있어요. 다시 시도해 주세요.';
          return;
        }
        if (e != _epoch || !_alive) return;
        await _serial(() async {
          if (e != _epoch) return;
          final scores = _scores(
            owner,
          ).map((a) => a.id == updated.id ? updated : a).toList();
          final raw = _space(owner)['draft'];
          await _write(
            owner,
            raw == null
                ? null
                : StudyDraft.fromJson(Map<String, dynamic>.from(raw as Map)),
            _local(owner),
            scores: scores,
          );
          if (e == _epoch) attempts = scores;
        });
      }
    } finally {
      if (e == _epoch) {
        scoringBusy = false;
        _notify();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(tick().then((_) => sync()));
    } else {
      unawaited(tick());
    }
  }

  @override
  void dispose() {
    _alive = false;
    _epoch++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
