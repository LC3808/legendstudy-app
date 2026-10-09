import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/billing/billing_providers.dart';
import 'package:legendstudy_app/features/billing/iap_controller.dart';
import 'package:legendstudy_app/features/billing/purchase_verification.dart';
import 'package:legendstudy_app/features/billing/presentation/credit_purchase_page.dart';

class _Verifier implements PurchaseVerifier {
  @override
  Future<VerificationOutcome> verify(IapVerificationRequest request) async =>
      const VerificationOutcome(VerificationStatus.pending);
}

class _Controller extends IapController {
  _Controller(String id)
    : super(verifier: _Verifier(), onBalanceChanged: () {}, accountId: id);
  int starts = 0;
  bool closed = false;
  @override
  Future<void> init() async {
    starts++;
  }

  @override
  void dispose() {
    closed = true;
    super.dispose();
  }
}

void main() {
  testWidgets(
    'purchase page keeps listener alive and replaces it on account switch',
    (tester) async {
      final auth = StreamController<AuthStatus>();
      addTearDown(auth.close);
      final created = <_Controller>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => auth.stream),
            iapControllerProvider.overrideWith((ref) {
              final value = ref.watch(authStateProvider);
              final id = value.value?.userId;
              if (value.isLoading || id == null) return null;
              final c = _Controller(id);
              created.add(c);
              ref.onDispose(c.dispose);
              return c;
            }),
          ],
          child: const MaterialApp(home: CreditPurchasePage()),
        ),
      );
      auth.add(const AuthStatus('A'));
      await tester.pumpAndSettle();
      expect(created.single.starts, 1);
      expect(created.single.closed, false);
      auth.add(const AuthStatus('B'));
      await tester.pumpAndSettle();
      expect(created.first.closed, true);
      expect(created.last.accountId, 'B');
      expect(created.last.starts, 1);
      auth.add(const AuthStatus(null));
      await tester.pumpAndSettle();
      expect(created.last.closed, true);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
