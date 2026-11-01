import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/essay_beta_credit.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
  test('server configured allowance and exact end time', () {
    final v = EssayBetaCredit.parse({
      ...fixture(),
      'available': 2,
      'daily_limit': 2,
    })!;
    expect(v.available, 2);
    expect(v.dailyLimit, 2);
    expect(
      () => EssayBetaCredit.parse({...fixture(), 'available': 2}),
      throwsFormatException,
    );
    expect(betaPolicyText(v.endsAt!, v.dailyLimit), contains('매일 무료 첨삭 2회'));
    expect(
      betaEndDate(DateTime.parse('2026-11-10T12:30:00Z')),
      contains('21:30 KST'),
    );
  });
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
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(find.text('논술 LAB 베타 무료 이용 안내'), findsNothing);
    expect(find.text('오늘의 무료 첨삭을 모두 사용했습니다.'), findsOneWidget);
    expect(find.textContaining('내일 00:00 KST'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'start refreshes availability and hide only suppresses the modal',
    (tester) async {
      var reads = 0;
      Widget app() => ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('owner')),
          ),
          essayBetaCreditProvider.overrideWith((ref) async {
            reads++;
            return EssayBetaCredit.parse({
              ...fixture(),
              'available': 1,
              'expires_at': '2099-01-01T15:00:00Z',
              'ends_at': '2099-01-02T15:00:00Z',
            });
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EssayBetaCreditEntry(child: Text('workspace'))),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.text('베타 테스트 시작하기'));
      await tester.tap(find.text('베타 테스트 시작하기'));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('오늘의 무료 첨삭 · 1회 남음'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('오늘의 무료 첨삭 · 1회 남음'), findsOneWidget);
    },
  );
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
