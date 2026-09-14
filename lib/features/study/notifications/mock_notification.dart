import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../application/study_controller.dart';
import '../domain/study_models.dart';

abstract interface class MockNotificationService {
  Future<bool> request();
  Future<void> replace(String? session, int remainingMs);
}

class NativeMockNotificationService implements MockNotificationService {
  static const channel = MethodChannel('com.legendstudy.app/mock-notification');
  @override
  Future<bool> request() async =>
      await channel.invokeMethod<bool>('request') ?? false;
  @override
  Future<void> replace(String? session, int remainingMs) =>
      channel.invokeMethod<void>('replace', {
        'session': session,
        'remainingMs': remainingMs,
      });
}

/// Serial reconciliation prevents an older schedule from winning over cancellation.
/// Delivery is advisory; neither permission nor this observer drives timer state.
class MockNotificationController with WidgetsBindingObserver {
  MockNotificationController(this.study, this.service) {
    WidgetsBinding.instance.addObserver(this);
    study.addListener(observe);
    observe();
  }
  final StudyController study;
  final MockNotificationService service;
  String? _signature;
  int _generation = 0;
  bool _alive = true, _foreground = true;
  Future<void> _queue = Future.value();
  Future<void> get settled => _queue;
  void observe() {
    if (!study.ready && _signature == null) return;
    final d = study.draft;
    // A suspended app may reach timeUp before the OS delivers its inexact alert.
    // Keep that pending alert until foreground reconciliation, without starting Dart.
    if (!_foreground &&
        d?.frozenReason == 'planElapsed' &&
        _signature?.startsWith('${d!.id}:') == true) {
      return;
    }
    final active =
        d != null &&
        study.ready &&
        !study.recovery &&
        d.mock?.notify == true &&
        !d.frozen &&
        d.phase == TimerPhase.running;
    final signature = active ? '${d.id}:${d.openStart}' : 'none';
    if (_signature == signature) return;
    _signature = signature;
    final generation = ++_generation;
    _queue = _queue.then((_) async {
      if (!_alive || generation != _generation) return;
      try {
        await service.replace(
          active ? d.id : null,
          active ? study.remainingMs : 0,
        );
      } catch (_) {
        /* Timer remains authoritative if scheduling is unavailable. */
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) observe();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alive = false;
    study.removeListener(observe);
    // Background/provider disposal is not an end; retain a valid scheduled alert.
  }
}
