import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/credit_history.dart';

void main() {
  test('Korean date does not depend on device timezone or expose time', () {
    expect(creditDate('2027-01-23T14:59:59.999999Z'), '2027.01.23');
    expect(creditDate('2026-10-22T16:00:00Z'), '2026.10.23');
  });
  testWidgets('credit history distinguishes free, paid and missing expiry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditHistoryProvider.overrideWith(
            (ref) async => [
              {
                'created_at': '2026-10-23T05:39:20Z',
                'transaction_type': 'purchase',
                'balance_delta': 1,
                'reserved_delta': 0,
                'credit_grants': {'expires_at': '2027-01-23T14:59:59.999999Z'},
              },
              {
                'created_at': '2026-10-23T05:00:00Z',
                'transaction_type': 'signup_bonus',
                'balance_delta': 3,
                'reserved_delta': 0,
                'credit_grants': {'expires_at': null},
              },
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CreditHistory())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('구매 충전 · 크레딧 1개'), findsOneWidget);
    expect(find.textContaining('만료일 2027.01.23'), findsOneWidget);
    expect(find.textContaining('만료 없음'), findsOneWidget);
    expect(find.textContaining('14:59'), findsNothing);
  });
}
