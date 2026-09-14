import 'package:flutter/services.dart';

enum FocusCapability { ownedRule, manualAndroid, guideOnly, unsupported }

enum FocusPreference { ask, always, disabled }

enum FocusChoice { always, once, disabled, skip }

enum FocusResult { requested, denied, inactive, unsupported, failed }

class FocusStatus {
  const FocusStatus(this.capability, this.permission);
  final FocusCapability capability;
  final bool permission;
}

abstract interface class FocusService {
  Future<FocusStatus> status();
  Future<FocusPreference> readPreference();
  Future<void> writePreference(FocusPreference value);
  Future<void> requestPermission();
  Future<FocusResult> activateForStudy(String session);
  Future<void> reconcile(String? session);
}

class NativeFocusService implements FocusService {
  static const channel = MethodChannel('com.legendstudy.app/focus');
  @override
  Future<FocusStatus> status() async {
    final v = await channel.invokeMapMethod<String, dynamic>('status');
    return FocusStatus(
      FocusCapability.values.byName(v!['capability'] as String),
      v['permission'] == true,
    );
  }

  @override
  Future<FocusPreference> readPreference() async => FocusPreference.values
      .byName(await channel.invokeMethod<String>('readPreference') ?? 'ask');
  @override
  Future<void> writePreference(FocusPreference value) =>
      channel.invokeMethod<void>('writePreference', value.name);
  @override
  Future<void> requestPermission() =>
      channel.invokeMethod<void>('requestPermission');
  @override
  Future<FocusResult> activateForStudy(String session) async =>
      FocusResult.values.byName(
        await channel.invokeMethod<String>('activate', session) ?? 'failed',
      );
  @override
  Future<void> reconcile(String? session) =>
      channel.invokeMethod<void>('reconcile', session);
}
