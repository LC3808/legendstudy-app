import 'dart:async';
import 'package:flutter/widgets.dart';
import 'focus_service.dart';

/// Device preference and owned-rule lifecycle, independent of timer accounting/Auth.
class StudyFocusController extends ChangeNotifier with WidgetsBindingObserver {
  StudyFocusController(this.service) {
    WidgetsBinding.instance.addObserver(this);
  }
  final FocusService service;
  FocusPreference preference = FocusPreference.ask;
  FocusCapability capability = FocusCapability.unsupported;
  bool busy = false, _alive = true, _resolved = false;
  String? message, _session, _awaitingPermission;
  Future<void> _queue = Future.value();
  static const timeout = Duration(seconds: 2);
  void _notify() {
    if (_alive) notifyListeners();
  }

  final Map<Timer, void Function()> _deadlines = {};
  Future<T> _bounded<T>(Future<T> value) {
    final result = Completer<T>();
    late Timer timer;
    void fail() {
      if (!result.isCompleted) {
        result.completeError(TimeoutException('Focus operation unavailable'));
      }
    }

    timer = Timer(timeout, () {
      _deadlines.remove(timer);
      fail();
    });
    _deadlines[timer] = fail;
    value.then(
      (v) {
        timer.cancel();
        _deadlines.remove(timer);
        if (!result.isCompleted) result.complete(v);
      },
      onError: (Object error, StackTrace stack) {
        timer.cancel();
        _deadlines.remove(timer);
        if (!result.isCompleted) result.completeError(error, stack);
      },
    );
    return result.future;
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _queue.then((_) async {
      if (_alive) await action();
    });
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> get settled => _queue;
  Future<void> load() async {
    try {
      final status = await _bounded(service.status());
      capability = status.capability;
      preference = await _bounded(service.readPreference());
    } catch (_) {
      capability = FocusCapability.unsupported;
    }
    _notify();
  }

  void observe({required String? session, required bool ready}) {
    if (!ready && !_resolved) return;
    if (ready) _resolved = true;
    final next = ready ? session : null;
    if (next == _session && _resolved && ready) {
      // Also reconcile once after cold start, before any new activation.
      if (_observed) return;
    }
    _observed = true;
    if (_session != null && _session != next) message = null;
    _session = next;
    if (_awaitingPermission != next) _awaitingPermission = null;
    unawaited(
      _serial(() async {
        try {
          await _bounded(service.reconcile(next));
        } catch (_) {
          message = '집중 설정에서 알림 상태를 확인해 주세요.';
          _notify();
        }
      }),
    );
  }

  bool _observed = false;
  Future<void> setPreference(FocusPreference value) async {
    try {
      await _bounded(service.writePreference(value));
      preference = value;
    } catch (_) {
      message = '집중 설정을 저장하지 못했어요. 다시 선택해 주세요.';
    }
    _notify();
  }

  Future<void> start({
    required Future<void> Function() startTimer,
    required String? Function() currentSession,
    required Future<FocusChoice> Function(FocusCapability) choose,
  }) async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    var choice = FocusChoice.skip;
    var explicitChoice = false;
    try {
      await load();
      if (capability != FocusCapability.unsupported &&
          preference != FocusPreference.disabled) {
        explicitChoice =
            preference != FocusPreference.always ||
            capability != FocusCapability.ownedRule;
        choice =
            preference == FocusPreference.always &&
                capability == FocusCapability.ownedRule
            ? FocusChoice.once
            : await choose(capability);
        if (choice == FocusChoice.always &&
            capability == FocusCapability.ownedRule) {
          await setPreference(FocusPreference.always);
        } else if (choice == FocusChoice.disabled) {
          await setPreference(FocusPreference.disabled);
        }
      }
    } catch (_) {
      choice = FocusChoice.skip;
    }
    try {
      // Commit the timer before leaving for OS settings; never await a permission return.
      await startTimer();
      final session = currentSession();
      if (session != null &&
          capability == FocusCapability.ownedRule &&
          (choice == FocusChoice.always || choice == FocusChoice.once)) {
        await _serial(() async {
          if (_session != session) return;
          try {
            final status = await _bounded(service.status());
            if (_session != session) return;
            if (!status.permission) {
              message = '타이머가 시작됐어요. 집중 모드 권한은 집중 설정에서 선택해 주세요.';
              if (explicitChoice) {
                _awaitingPermission = session;
                await _bounded(service.requestPermission());
              }
            } else {
              await _activate(session);
            }
          } catch (_) {
            _failed();
          }
        });
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _bounded(service.requestPermission());
    } catch (_) {
      message = '기기의 알림 권한 설정을 열지 못했어요.';
      _notify();
    }
  }

  void _failed() {
    message = '집중 모드를 적용하지 못했어요. 타이머는 정상적으로 시작됐어요.';
  }

  Future<void> _activate(String session) async {
    if (_session != session) return;
    final result = await _bounded(service.activateForStudy(session));
    if (_session != session) return;
    if (result == FocusResult.failed) _failed();
    if (result == FocusResult.denied) message = '집중 모드 권한이 필요해요. 타이머는 계속 진행돼요.';
    if (result == FocusResult.requested) {
      message = '집중 연동을 요청했어요. 기기의 알림 설정이 우선 적용돼요.';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_resolved) return;
    unawaited(
      _serial(() async {
        try {
          await _bounded(service.reconcile(_session));
          final session = _awaitingPermission;
          _awaitingPermission =
              null; // One return attempt; no repeated permission prompts.
          if (session != null && session == _session) {
            final status = await _bounded(service.status());
            if (status.permission) {
              await _activate(session);
            } else {
              message = null;
            }
          }
        } catch (_) {
          message = '집중 설정에서 알림 상태를 확인해 주세요.';
        }
        _notify();
      }),
    );
  }

  @override
  void dispose() {
    _alive = false;
    for (final entry in _deadlines.entries.toList()) {
      entry.key.cancel();
      entry.value();
    }
    _deadlines.clear();
    WidgetsBinding.instance.removeObserver(this);
    // Disposal/background is not session end. Persisted owned lease reconciles on restart.
    super.dispose();
  }
}
