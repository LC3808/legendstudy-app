import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/essay_beta_credit.dart';

void main() {
  Map<String, dynamic> fixture() => {
    'version': 'essay-beta-credit-v2',
    'active': true,
    'available': 1,
    'status': 'active',
    'ends_at': '2026-11-10T15:00:00Z',
    'campaign_id': 'fixture',
    'policy_version': 'daily-v2',
    'notice_seen': false,
    'expires_at': '2026-10-27T15:00:00Z',
  };
  testWidgets('first entry policy once and exhausted banner', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('owner')),
          ),
          essayBetaCreditProvider.overrideWith(
            (ref) async => EssayBetaCredit.parse({
              ...fixture(),
              'available': 0,
              'expires_at': '2099-01-01T15:00:00Z',
              'ends_at': '2099-01-02T15:00:00Z',
            }),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EssayBetaCreditEntry(child: Text('workspace'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('논술 LAB 베타 무료 이용 안내'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('논술 LAB 베타 무료 이용 안내'), findsNothing);
    expect(find.text('오늘의 무료 첨삭을 모두 사용했습니다.'), findsOneWidget);
    expect(find.textContaining('내일 00:00 KST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('final day never promises another free day', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          essayBetaCreditProvider.overrideWith(
            (ref) async => EssayBetaCredit.parse({
              ...fixture(),
              'available': 0,
              'notice_seen': true,
              'expires_at': '2099-01-01T15:00:00Z',
              'ends_at': '2099-01-01T15:00:00Z',
            }),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EssayBetaCreditEntry(child: Text('workspace'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('오늘의 무료 첨삭을 모두 사용했습니다.'), findsOneWidget);
    expect(find.textContaining('내일 00:00'), findsNothing);
  });
  testWidgets('ended banner has no policy modal', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          essayBetaCreditProvider.overrideWith(
            (ref) async => EssayBetaCredit(0, DateTime(2026), ended: true),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EssayBetaCreditEntry(child: Text('workspace'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('베타 무료 첨삭 제공이 종료되었습니다.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
  test('uses server balance and absolute KST midnight timestamp', () {
    final value = EssayBetaCredit.parse(fixture())!;
    expect(value.available, 1);
    expect(value.expiresAt, DateTime.utc(2026, 10, 27, 15));
  });
  test('inactive campaign has no beta balance', () {
    expect(
      EssayBetaCredit.parse({
        'version': 'essay-beta-credit-v2',
        'active': false,
        'status': 'inactive',
      }),
      isNull,
    );
  });
  test('ended campaign remains visible and inclusive Nov 10 is correct', () {
    final value = EssayBetaCredit.parse({
      'version': 'essay-beta-credit-v2',
      'active': false,
      'status': 'ended',
      'ends_at': '2026-11-10T15:00:00Z',
    })!;
    expect(value.ended, true);
    expect(betaEndDate(value.endsAt!), '2026년 11월 10일');
    expect(betaPolicyText(value.endsAt!), contains('최대 14일'));
    expect(betaPolicyText(value.endsAt!), contains('베타 종료 전까지 1회'));
  });
  test('invalid balance and expiry never displayed', () {
    for (final count in [-1, 2, 3, 1.5, '1']) {
      expect(
        () => EssayBetaCredit.parse({...fixture(), 'available': count}),
        throwsFormatException,
      );
    }
    expect(
      () => EssayBetaCredit.parse({...fixture(), 'expires_at': 'invalid'}),
      throwsFormatException,
    );
    expect(
      () => EssayBetaCredit.parse({...fixture(), 'version': 'other'}),
      throwsFormatException,
    );
  });
}
