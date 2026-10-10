import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Install-local presentation state, independent of Auth and server profile data.
class DeviceIntroStore {
  static const channel = MethodChannel('com.legendstudy.app/info');
  Future<bool> completed() async =>
      await channel.invokeMethod<bool>('introCompleted') ?? false;
  Future<void> complete() => channel.invokeMethod<void>('completeIntro');
}

final deviceIntroStoreProvider = Provider((ref) => DeviceIntroStore());
final introRequiredAtBootProvider = Provider<bool>((ref) => false);
final deviceIntroProvider = NotifierProvider<DeviceIntroState, bool>(
  DeviceIntroState.new,
);

class DeviceIntroState extends Notifier<bool> {
  @override
  bool build() => ref.read(introRequiredAtBootProvider);
  Future<void> complete() async {
    await ref.read(deviceIntroStoreProvider).complete();
    if (ref.mounted) state = false;
  }
}
