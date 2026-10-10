import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/features/onboarding/device_intro.dart';
import 'package:legendstudy_app/features/onboarding/presentation/onboarding_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  bool saved = false, fail = false;
  setUp(() {
    saved = false;
    fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceIntroStore.channel, (call) async {
          if (call.method == 'introCompleted') return saved;
          if (fail) throw PlatformException(code: 'LOCAL_IO');
          saved = true;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceIntroStore.channel, null),
  );

  for (final skip in [true, false]) {
    testWidgets(
      'device intro ${skip ? 'skip' : 'finish'} persists before login choice',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/intro',
          routes: [
            GoRoute(path: '/intro', builder: (_, _) => const DeviceIntroPage()),
            GoRoute(
              path: '/auth',
              builder: (_, _) => const Scaffold(body: Text('LOGIN CHOICE')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [introRequiredAtBootProvider.overrideWithValue(true)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
        if (!skip) {
          for (var i = 0; i < 2; i++) {
            await tester.tap(find.text('다음'));
            await tester.pumpAndSettle();
          }
        }
        fail = true;
        await tester.tap(find.text(skip ? '건너뛰기' : '시작하기'));
        await tester.pumpAndSettle();
        expect(saved, false);
        expect(find.text('LOGIN CHOICE'), findsNothing);
        fail = false;
        await tester.tap(find.text(skip ? '건너뛰기' : '시작하기'));
        await tester.pumpAndSettle();
        expect(await DeviceIntroStore().completed(), true);
        expect(find.text('LOGIN CHOICE'), findsOneWidget);
        final restart = ProviderContainer(
          overrides: [
            introRequiredAtBootProvider.overrideWithValue(
              !await DeviceIntroStore().completed(),
            ),
          ],
        );
        expect(restart.read(deviceIntroProvider), false);
        restart.dispose();
      },
    );
  }
}
