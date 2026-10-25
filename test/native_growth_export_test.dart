import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/credits/credit_expiry.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/growth_bars.dart';
import 'package:legendstudy_app/features/essay/growth_share.dart';
import 'package:legendstudy_app/features/essay/result_pdf.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('fonts/Pretendard-SemiBold.otf'))).load();
  });
  test(
    'expiry counts remaining spendable quantity, never original grant amount',
    () {
      expect(
        expiryQuantities(
          [
            {'id': 'paid', 'origin': 'purchase'},
            {'id': 'free', 'origin': 'signup_bonus'},
          ],
          [
            {'grant_id': 'paid', 'balance_delta': 3, 'reserved_delta': 0},
            {'grant_id': 'paid', 'balance_delta': -1, 'reserved_delta': 0},
            {'grant_id': 'paid', 'balance_delta': 0, 'reserved_delta': 1},
            {'grant_id': 'free', 'balance_delta': 1, 'reserved_delta': 0},
          ],
        ),
        {'구매 크레딧': 1, '무료 크레딧': 1},
      );
    },
  );
  testWidgets(
    'native bars preserve exact criterion names and export PNG/PDF locally',
    (t) async {
      final fixture = jsonDecode(
        File('test/fixtures/evaluation-display-v1.json').readAsStringSync(),
      ) as Map;
      final pair = (fixture['math'] as List).first;
      final before = mathEvaluationReport(pair['before']),
          after = mathEvaluationReport(pair['after']);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GrowthBars(before: before, after: after),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      for (final c in after.rubric) {
        expect(find.textContaining(c.name), findsWidgets);
      }
      await t.runAsync(() async {
        final png = await growthPng(
          completed: 2,
          rewrites: 1,
          report: after,
          before: before,
        );
        expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        final pdf = await evaluationPdf(after);
        expect(ascii.decode(pdf.take(8).toList()), '%PDF-1.4');
        await File('/tmp/legendstudy-growth-test.png').writeAsBytes(png);
        await File('/tmp/legendstudy-result-test.pdf').writeAsBytes(pdf);
      });
    },
  );
}
