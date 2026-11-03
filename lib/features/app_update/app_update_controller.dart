import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_information.dart';
import '../../core/supabase/supabase_providers.dart';
import 'app_update_policy.dart';

abstract interface class AppUpdateRepository {
  Future<Object?> load(String platform);
}

abstract interface class AppUpdatePreferenceStore {
  Future<DateTime?> deferredAt(String key);
  Future<void> defer(String key, DateTime at);
}

class LocalAppUpdatePreferences implements AppUpdatePreferenceStore {
  String _key(String key) => 'legendstudy.app-update.later.v1:$key';
  @override
  Future<DateTime?> deferredAt(String key) async {
    final value = (await SharedPreferences.getInstance()).getInt(_key(key));
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  @override
  Future<void> defer(String key, DateTime at) async {
    await (await SharedPreferences.getInstance()).setInt(
      _key(key),
      at.millisecondsSinceEpoch,
    );
  }
}

class CallbackAppUpdateRepository implements AppUpdateRepository {
  const CallbackAppUpdateRepository(this.read);
  final Future<Object?> Function(String platform) read;
  @override
  Future<Object?> load(String platform) => read(platform);
}

/// Fail-open, install-local coordinator. It neither alters Auth nor writes DB.
class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required this.platform,
    required this.installed,
    required this.repository,
    required this.preferences,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 3),
  }) : clock = clock ?? DateTime.now;
  final String? platform;
  final Future<AppInstalledVersion> Function() installed;
  final AppUpdateRepository repository;
  final AppUpdatePreferenceStore preferences;
  final DateTime Function() clock;
  final Duration timeout;
  AppUpdatePrompt? prompt;
  Future<void>? _checking;
  Timer? _deadline;
  Completer<AppUpdatePrompt?>? _pendingRead;
  bool _disposed = false;
  final Map<String, DateTime> _deferred = {};
  final Set<String> _opened = {};

  Future<void> check() {
    if (_disposed) return Future.value();
    return _checking ??= _check().whenComplete(() => _checking = null);
  }

  Future<void> _check() async {
    final pending = Completer<AppUpdatePrompt?>();
    _pendingRead = pending;
    void complete(AppUpdatePrompt? value) {
      if (!pending.isCompleted) pending.complete(value);
    }

    // Own the deadline so widget/provider disposal never leaves a live timer.
    final deadline = Timer(timeout, () => complete(null));
    _deadline = deadline;
    unawaited(
      _read().then<void>(
        complete,
        onError: (Object error, StackTrace stack) {
          // Missing policy/RPC, offline and malformed data never lock the app.
          complete(null);
        },
      ),
    );
    final result = await pending.future;
    deadline.cancel();
    if (identical(_pendingRead, pending)) {
      _pendingRead = null;
      _deadline = null;
    }
    if (!_disposed) {
      prompt = result;
      notifyListeners();
    }
  }

  Future<AppUpdatePrompt?> _read() async {
    if (platform != 'ios' && platform != 'android') return null;
    final version = await installed();
    final policy = AppUpdatePolicy.parse(
      await repository.load(platform!),
      platform: platform!,
      now: clock(),
    );
    final next = policy?.forInstalled(version);
    if (next == null || next.required) return next;
    if (_opened.contains(policy!.key)) return null;
    final storedDeferred = await preferences.deferredAt(policy.key);
    // Local actions can occur while the persistence read is in flight.
    if (_opened.contains(policy.key)) return null;
    final deferred = _deferred[policy.key] ?? storedDeferred;
    if (deferred != null) {
      final elapsed = clock().difference(deferred);
      if (!elapsed.isNegative && elapsed < const Duration(hours: 24)) {
        return null;
      }
    }
    return next;
  }

  Future<void> later() async {
    final current = prompt;
    if (current == null || current.required) return;
    final now = clock();
    _deferred[current.policy.key] = now;
    prompt = null;
    notifyListeners();
    try {
      await preferences.defer(current.policy.key, now);
    } catch (_) {
      // This process still remembers dismissal when local persistence fails.
    }
  }

  void openedStore([AppUpdatePrompt? openedPrompt]) {
    if (_disposed) return;
    final current = openedPrompt ?? prompt;
    if (current == null || current.required) return;
    _opened.add(current.policy.key);
    if (prompt?.policy.key == current.policy.key && prompt?.required == false) {
      prompt = null;
      notifyListeners();
    }
  }

  void cancelPendingCheck() {
    _deadline?.cancel();
    _deadline = null;
    final pending = _pendingRead;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  @override
  void dispose() {
    _disposed = true;
    cancelPendingCheck();
    super.dispose();
  }
}

final appUpdatePlatformProvider = Provider<String?>(
  (ref) => kIsWeb
      ? null
      : switch (defaultTargetPlatform) {
          TargetPlatform.iOS => 'ios',
          TargetPlatform.android => 'android',
          _ => null,
        },
);
final appUpdatePreferencesProvider = Provider<AppUpdatePreferenceStore>(
  (ref) => LocalAppUpdatePreferences(),
);
final appUpdateRepositoryProvider = Provider<AppUpdateRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CallbackAppUpdateRepository(
    (platform) async => client == null
        ? null
        : await client.rpc(
            'app_update_policy',
            params: {'p_platform': platform},
          ),
  );
});
final appUpdateControllerProvider = Provider<AppUpdateController>((ref) {
  final controller = AppUpdateController(
    platform: ref.watch(appUpdatePlatformProvider),
    installed: () => ref.read(installedAppVersionProvider.future),
    repository: ref.watch(appUpdateRepositoryProvider),
    preferences: ref.watch(appUpdatePreferencesProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
