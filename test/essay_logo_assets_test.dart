import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/university_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all existing official logos decode natively and light-background variants retain contrast', () async {
    expect(essayUniversityCatalog.length, 42);
    for (final u in essayUniversityCatalog) {
      final bytes = await File(u['logoAsset'] as String).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: u['name'] as String);
      frame.image.dispose();
      codec.dispose();
    }
    expect(
      essayUniversityCatalog.singleWhere(
        (u) => u['sourceUniversityId'] == 'hanyang',
      )['logoDark'],
      false,
    );
  });
}
