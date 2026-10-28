import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/answer_ocr.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'observed text preserved without correction, paragraph gaps retained',
    () {
      expect(
        assembleOcrLines([
          {'text': '학생 123 + ABC', 'top': 0.1, 'height': 0.05},
          {'text': '다음 줄.', 'top': 0.16, 'height': 0.05},
          {'text': '다음 문단', 'top': 0.4, 'height': 0.05},
        ]),
        '학생 123 + ABC\n다음 줄.\n\n다음 문단',
      );
    },
  );
  test(
    'native OCR receives only photo, preserves text and propagates failure',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(AnswerOcrEngine.channel, (call) async {
        expect(call.method, 'recognize');
        expect((call.arguments as Map).keys, ['bytes']);
        return {
          'lines': [
            {'text': '원문 오류도 그대로 12%'},
          ],
        };
      });
      expect(
        await AnswerOcrEngine().recognize(Uint8List.fromList([1])),
        '원문 오류도 그대로 12%',
      );
      messenger.setMockMethodCallHandler(AnswerOcrEngine.channel, (call) async {
        throw PlatformException(code: 'OCR_FAILED');
      });
      await expectLater(
        AnswerOcrEngine().recognize(Uint8List.fromList([1])),
        throwsA(isA<PlatformException>()),
      );
      messenger.setMockMethodCallHandler(AnswerOcrEngine.channel, null);
    },
  );
  for (final replace in [true, false]) {
    testWidgets(
      'OCR preview edits require explicit ${replace ? 'replace' : 'merge'} confirmation',
      (tester) async {
        OcrTextSelection? applied;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('owner')),
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      applied = await Navigator.push<OcrTextSelection>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnswerOcrPage(
                            owner: 'owner',
                            hasAnswer: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '학생이 확인한 원문 123%');
        expect(applied, isNull);
        final button = find.text(replace ? '기존 답안 교체하기' : '기존 답안 뒤에 합치기');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(applied?.text, '학생이 확인한 원문 123%');
        expect(applied?.replace, replace);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
