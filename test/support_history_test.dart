import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/feedback/presentation/feedback_history.dart';

void main() {
  testWidgets('owner reply screen displays original and persisted answer', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportDetailProvider(('APP', 'fixture')).overrideWith(
            (ref) async => {
              'title': '원본 문의',
              'body': '원본 내용',
              'status': 'ANSWERED',
              'replies': [
                {
                  'reply_id': 'r',
                  'body': '관리자 합성 답변',
                  'created_at': '2026-11-04T01:00:00Z',
                },
              ],
            },
          ),
        ],
        child: const MaterialApp(
          home: SupportReplyPage(source: 'APP', id: 'fixture'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('원본 내용'), findsOneWidget);
    expect(find.text('관리자 합성 답변'), findsOneWidget);
    expect(find.text('답변 완료'), findsOneWidget);
  });
  testWidgets('read failure is not an empty successful history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportDetailProvider(('APP', 'fixture'))
              .overrideWith((ref) async => throw Exception('denied')),
        ],
        child: const MaterialApp(
          home: SupportReplyPage(source: 'APP', id: 'fixture'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('답변을 불러오지 못했어요. 다시 시도'), findsOneWidget);
    expect(find.text('아직 답변이 없습니다.'), findsNothing);
  });
}
