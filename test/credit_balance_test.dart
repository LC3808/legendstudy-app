import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/features/credits/credit_balance.dart';

void main() {
  test('APP consumes the same credit-v1 snapshots as LAB 5/4/4/3', () {
    for (final paid in [5, 4, 4, 3]) {
      final balance = CreditBalance.fromJson({
        'dto_version': 'credit-v1',
        'spendable': paid,
        'paid': paid,
        'free': 0,
        'other': 0,
        'next_expiry': null,
      });
      expect(balance.spendable, paid);
    }
  });
  test('inconsistent summary fails closed', () {
    expect(
      () => CreditBalance.fromJson({
        'dto_version': 'credit-v1',
        'spendable': 7,
        'paid': 5,
        'free': 0,
        'other': 0,
        'next_expiry': null,
      }),
      throwsFormatException,
    );
  });
  testWidgets('shared canonical quantities render and guest has no balance', (tester) async {
    final value = CreditBalance.fromJson({'dto_version':'credit-v1','spendable':8,'paid':5,'free':3,'other':0,'next_expiry':null});
    await tester.pumpWidget(ProviderScope(overrides:[creditBalanceProvider.overrideWith((ref) async => value)], child: const MaterialApp(home: Scaffold(body: CreditBalanceCard()))));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능 8 Credits'), findsOneWidget);
    expect(find.text('구매 5 · 가입 무료 3 · 기타 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(ProviderScope(overrides:[creditBalanceProvider.overrideWith((ref) async => null)], child: const MaterialApp(home: Scaffold(body: CreditBalanceCard()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('사용 가능'), findsNothing);
  });
}
