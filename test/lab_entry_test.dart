import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/core/links/service_links.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/lab/lab_page.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:legendstudy_app/shared/widgets/legendstudy_lab_entry.dart';

import 'core_ux_test.dart' as preview;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

Future<void> Function(String)? nativeCapture;

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  test('LAB permits only canonical HTTPS root, without auth or tracking', () {
    final uri = legendStudyLabEntryUri(legendStudyLabUrl)!;
    expect(uri.toString(), 'https://lab.legendstudy.com');
    expect(uri.scheme, 'https');
    expect(uri.host, 'lab.legendstudy.com');
    expect(uri.hasQuery || uri.hasFragment, isFalse);
    for (final invalid in [
      'http://lab.legendstudy.com',
      'https://lab.legendstudy.com/lab/',
      'https://lab.legendstudy.com.evil.test',
      'https://preview.pages.dev',
      'https://lab.legendstudy.com?token=test',
      'https://user@lab.legendstudy.com',
      'https://lab.legendstudy.com#session',
      'http://localhost',
    ]) {
      expect(legendStudyLabEntryUri(invalid), isNull);
    }
  });
  for (final home in [true, false]) {
    for (final authenticated in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final name =
            'lab-${home ? 'home' : 'lab'}-${authenticated ? 'account' : 'guest'}-${scale.toInt()}x';
        testWidgets('$name 360x640 accessible external entry', (tester) async {
          if (nativeCapture == null) {
            tester.view.physicalSize = const Size(360, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
          }
          final opened = <Uri>[];
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith(
                  (ref) => Stream.value(
                    AuthStatus(authenticated ? 'test-account' : null),
                  ),
                ),
                currentAccountEmailProvider.overrideWithValue(
                  'student@example.test',
                ),
                homeRecentContentProvider.overrideWith((ref) async => []),
                studyControllerProvider.overrideWith(
                  (ref) => StudyController(
                    TestClock(),
                    TestStore(),
                    () => TestRepo('test-account'),
                  ),
                ),
                externalOpenerProvider.overrideWithValue((uri) async {
                  opened.add(uri);
                  return true;
                }),
              ],
              child: preview.app(
                home ? const HomePage() : const LabPage(),
                scale: scale,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (home) {
            expect(find.byType(LegendStudyLabEntry), findsNothing);
            expect(opened, isEmpty);
            await tester.pumpWidget(const SizedBox());
            return;
          }
          expect(find.byType(LegendStudyLabEntry), findsOneWidget);
          await tester.ensureVisible(find.byType(LegendStudyLabEntry));
          await tester.pumpAndSettle();
          expect(
            tester.getSize(find.widgetWithText(TextButton, 'LAB 살펴보기')).height,
            greaterThanOrEqualTo(48),
          );
          await preview.capture(tester, name);
          await nativeCapture?.call(name);
          await tester.tap(find.text('LAB 살펴보기'));
          await tester.pumpAndSettle();
          expect(opened.map((u) => u.toString()), [legendStudyLabUrl]);
          expect(find.byType(home ? HomePage : LabPage), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
  testWidgets(
    'LAB busy prevents duplicate; safe failure allows retry and return',
    (tester) async {
      final pending = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            externalOpenerProvider.overrideWithValue((uri) {
              calls++;
              if (calls == 1) return pending.future;
              if (calls == 2) throw StateError('private platform error');
              return Future.value(true);
            }),
          ],
          child: preview.app(const LegendStudyLabEntry()),
        ),
      );
      await tester.tap(find.text('LAB 살펴보기'));
      await tester.tap(find.text('LAB 살펴보기'));
      await tester.pump();
      expect(calls, 1);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('외부 링크를 열지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      await tester.tap(find.text('LAB 살펴보기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('private platform'), findsNothing);
      expect(find.text('외부 링크를 열지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      await tester.tap(find.text('LAB 살펴보기'));
      await tester.pumpAndSettle();
      expect(calls, 3);
      expect(find.text('외부 링크를 열지 못했어요. 다시 시도해 주세요.'), findsNothing);
    },
  );
}
