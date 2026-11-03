import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Numeric public version plus the native build, shared with MY and feedback.
class AppInstalledVersion implements Comparable<AppInstalledVersion> {
  const AppInstalledVersion._(this.version, this.build, this.parts);
  final String version;
  final int build;
  final List<int> parts;
  String get key => '${parts.join('.')}+$build';
  static AppInstalledVersion parse(Object? version, Object? build) {
    if (version is! String ||
        !RegExp(r'^\d{1,7}(?:\.\d{1,7}){1,3}$').hasMatch(version) ||
        (build is! int && build is! String) ||
        !RegExp(r'^\d{1,10}$').hasMatch(build.toString())) {
      throw const FormatException('Version unavailable');
    }
    final number = int.tryParse(build.toString());
    if (number == null || number < 0 || number > 2147483647) {
      throw const FormatException('Version unavailable');
    }
    final parts = version.split('.').map(int.parse).toList();
    while (parts.length < 4) {
      parts.add(0);
    }
    return AppInstalledVersion._(version, number, List.unmodifiable(parts));
  }

  @override
  int compareTo(AppInstalledVersion other) {
    for (var i = 0; i < parts.length; i++) {
      final comparison = parts[i].compareTo(other.parts[i]);
      if (comparison != 0) return comparison;
    }
    return build.compareTo(other.build);
  }
}

final installedAppVersionProvider = FutureProvider<AppInstalledVersion>((
  ref,
) async {
  final data = await const MethodChannel('com.legendstudy.app/info')
      .invokeMapMethod<String, dynamic>('version');
  return AppInstalledVersion.parse(data?['version'], data?['build']);
}, retry: (_, _) => null);

final appVersionProvider = FutureProvider<String>((ref) async {
  final version = await ref.watch(installedAppVersionProvider.future);
  return '${version.version} (${version.build})';
}, retry: (_, _) => null);
