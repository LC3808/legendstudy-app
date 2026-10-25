import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/credit_history.dart';
import 'package:legendstudy_app/features/credits/credit_balance.dart';

void main() {
  test('Korean date does not depend on device timezone or expose time', () {
    expect(creditDate('2027-01-23T14:59:59.999999Z'), '2027.01.23');
    expect(creditDate('2026-10-22T16:00:00Z'), '2026.10.23');
  });
  Map<String, dynamic> row(String type, int amount, {String? decision}) => {
    'created_at': '2026-10-23T05:00:00Z',
    'transaction_type': type,
    'balance_delta': amount,
    'decision_id': decision,
    'credit_grants': {'expires_at': null},
  };
  test(
    'projection hides holds and combines grant postings without changing facts',
    () {
      final rows = [
        row('reserve', 0, decision: 'a'),
        row('consume', -1, decision: 'a'),
        row('consume', -2, decision: 'a'),
        row('release', 0, decision: 'b'),
        row('refund', 1, decision: 'a'),
        row('adjustment', -1),
        row('purchase', 3),
      ];
      final visible = userCreditHistory(rows);
      expect(visible.length, 4);
      expect(
        visible.singleWhere(
          (r) => r['transaction_type'] == 'consume',
        )['balance_delta'],
        -3,
      );
      expect(rows[1]['balance_delta'], -1);
      expect(rows.length, 7);
      expect(
        userCreditHistory([row('reserve', 0), row('release', 0)]),
        isEmpty,
      );
      expect(
        userCreditHistory([row('consume', -1), row('consume', -1)]).length,
        2,
      );
    },
  );
  testWidgets(
    'one finalized charge appears; holds never resemble a second deduction',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            creditHistoryProvider.overrideWith(
              (ref) async => [
                row('reserve', 0, decision: 'a'),
                row('consume', -1, decision: 'a'),
                row('release', 0, decision: 'b'),
                row('refund', 1),
                row('adjustment', -1),
              ],
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CreditHistory())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('논술 첨삭 · -1 크레딧'), findsOneWidget);
      expect(find.textContaining('사용 대기'), findsNothing);
      expect(find.text('환불 · +1 크레딧'), findsOneWidget);
      expect(find.text('크레딧 회수 · -1 크레딧'), findsOneWidget);
    },
  );
  testWidgets(
    'pending hold is hidden while the canonical available balance stays reduced',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            creditHistoryProvider.overrideWith(
              (ref) async => [row('reserve', 0, decision: 'pending')],
            ),
            creditBalanceProvider.overrideWith(
              (ref) async => CreditBalance.fromJson({
                'dto_version': 'credit-v1',
                'spendable': 4,
                'paid': 4,
                'free': 0,
                'other': 0,
                'next_expiry': null,
              }),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CreditBalanceCard(),
                  Expanded(child: CreditHistory()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('사용 가능 4 Credits'), findsOneWidget);
      expect(find.text('크레딧 내역이 없어요.'), findsOneWidget);
      expect(find.textContaining('사용 대기'), findsNothing);
    },
  );
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
    expect(find.text('크레딧 구매 · +1 크레딧'), findsOneWidget);
    expect(find.textContaining('만료일 2027.01.23'), findsOneWidget);
    expect(find.textContaining('만료 없음'), findsOneWidget);
    expect(find.textContaining('14:59'), findsNothing);
  });
}
