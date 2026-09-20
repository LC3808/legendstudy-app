import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final data = await const MethodChannel(
    'com.legendstudy.app/info',
  ).invokeMapMethod<String, dynamic>('version');
  final version = data?['version'] as String?;
  final build = data?['build']?.toString();
  if (version == null || version.isEmpty || build == null || build.isEmpty) {
    throw const FormatException('Version unavailable');
  }
  return '$version ($build)';
});
