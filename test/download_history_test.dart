import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/resources/data/download_history.dart';

void main() {
  test(
    'completed receipts stay owner-scoped, deduplicated and bounded',
    () async {
      final storage = <String, String>{};
      final history = DownloadHistory((key) async => storage[key], (
        key,
        value,
      ) async {
        storage[key] = value;
      });
      for (var i = 0; i < 105; i++) {
        await history.record(
          'a',
          DownloadReceipt('$i', 'exam', '$i.pdf', DateTime.utc(2026, 11, 13)),
        );
      }
      expect((await history.load('a')).length, 100);
      expect(await history.load('b'), isEmpty);
      await history.record(
        'a',
        DownloadReceipt('104', 'exam', 'retry.pdf', DateTime.utc(2026, 11, 14)),
      );
      expect((await history.load('a')).length, 100);
      expect((await history.load('a')).first.filename, 'retry.pdf');
      await history.clear('a');
      expect(await history.load('a'), isEmpty);
    },
  );
}
