import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/resources/data/pdf_download.dart';

void main() {
  const id = '11111111-1111-4111-8111-111111111111';
  final bytes = Uint8List.fromList(
    '%PDF-1.4\nsynthetic fixture\n%%EOF'.codeUnits,
  );
  Map<String, Object> allowed() => {
    'state': 'ALLOWED',
    'filename': '2026_고3_9월_국어_문제지.pdf',
    'sha256': sha256.convert(bytes).toString(),
  };
  Map<String, Object> response() => {
    'resource_id': id,
    'status': 'resolved',
    'policy': allowed(),
    'target':
        'https://blog.kakaocdn.net/dna/abc/def/file.pdf?credential=test&signature=test&expires=${DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600}',
  };
  test('unknown, missing, unsafe name and digest fail closed', () {
    for (final value in [
      null,
      <String, Object?>{},
      {'state': 'ALLOWED'},
      {...allowed(), 'filename': '../test.pdf'},
      {...allowed(), 'sha256': 'bad'},
      {'state': 'OFFICIAL_LINK', 'official_url': 'javascript:bad'},
    ]) {
      expect(PdfDownloadPolicy.parse(value).state, 'PENDING');
    }
    expect(PdfDownloadPolicy.parse({'state': 'VIEW_ONLY'}).state, 'VIEW_ONLY');
    expect(
      PdfDownloadPolicy.parse({
        'state': 'OFFICIAL_LINK',
        'official_url': 'https://www.kice.re.kr/',
      }).state,
      'OFFICIAL_LINK',
    );
  });
  test('success only after native save completion, bytes and Korean filename preserved', () async {
    final saved = Completer<bool>();
    final service = PdfDownloadService(
      (_) async => response(),
      (_) async => bytes,
      (b, n) {
        expect(b, bytes);
        expect(n, allowed()['filename']);
        return saved.future;
      },
    );
    var completed = false;
    final future = service.download(id).then((v) {
      completed = true;
      return v;
    });
    await Future<void>.delayed(Duration.zero);
    expect(completed, false);
    saved.complete(true);
    expect(await future, true);
  });
  test('server denial and wrong resource never load or save', () async {
    for (final value in [
      {'status': 'denied'},
      {...response(), 'resource_id': 'wrong'},
      {
        ...response(),
        'policy': {'state': 'PENDING'},
      },
    ]) {
      final service = PdfDownloadService(
        (_) async => value,
        (_) async => throw StateError('must not load'),
        (_, _) async => throw StateError('must not save'),
      );
      await expectLater(service.download(id), throwsStateError);
    }
  });
  test('HTML and changed source bytes blocked before save', () async {
    for (final b in [
      Uint8List.fromList('<html>'.codeUnits),
      Uint8List.fromList('%PDF-changed'.codeUnits),
    ]) {
      var saved = false;
      final service = PdfDownloadService(
        (_) async => response(),
        (_) async => b,
        (_, _) async {
          saved = true;
          return true;
        },
      );
      await expectLater(service.download(id), throwsStateError);
      expect(saved, false);
    }
  });
  test('native cancellation is not success', () async {
    final service = PdfDownloadService(
      (_) async => response(),
      (_) async => bytes,
      (_, _) async => false,
    );
    expect(await service.download(id), false);
  });
  test('cancel before fetch does not save', () async {
    final service = PdfDownloadService(
      (_) async => response(),
      (_) async => throw StateError('must not load'),
      (_, _) async => true,
    );
    expect(await service.download(id, cancelled: () => true), false);
  });
  test('network failure and retry fetch fresh authorization', () async {
    var attempts = 0, authorizations = 0;
    final service = PdfDownloadService(
      (_) async {
        authorizations++;
        return response();
      },
      (_) async {
        if (attempts++ == 0) throw StateError('offline');
        return bytes;
      },
      (_, _) async => true,
    );
    await expectLater(service.download(id), throwsStateError);
    expect(await service.download(id), true);
    expect(authorizations, 2);
  });
  test('storage/access failure releases guard for retry', () async {
    var attempts = 0;
    final service = PdfDownloadService(
      (_) async => response(),
      (_) async => bytes,
      (_, _) async {
        if (attempts++ == 0) throw StateError('disk full');
        return true;
      },
    );
    await expectLater(service.download(id), throwsStateError);
    expect(await service.download(id), true);
  });
  test('concurrent saves blocked', () async {
    final completion = Completer<bool>();
    final service = PdfDownloadService(
      (_) async => response(),
      (_) async => bytes,
      (_, _) => completion.future,
    );
    final first = service.download(id);
    await expectLater(service.download(id), throwsStateError);
    completion.complete(true);
    expect(await first, true);
  });
}
