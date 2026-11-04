import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_page.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_mobile_preview.dart';

// This widget test exercises gateway lifetime; SDK Auth is covered separately.
class _UnusedClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected SDK access');
}

class _Gateway extends MathGateway {
  _Gateway(SupabaseClient client) : super(client, 'owner');
  final image = Completer<Uint8List>();
  bool disposed = false;
  int reads = 0;
  bool held = false;
  bool failInput = false;
  @override
  Future<Map<String, dynamic>> call(
    String fn,
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (action == 'read_input') {
      expect(payload['attempt_id'], 'original-attempt');
      if (failInput) throw StateError('network');
      return {
        'attempt': {
          'attempt_id': 'original-attempt',
          'input_kind': 'TYPED',
          'typed_answer': 'original submitted answer',
        },
        'input_state': 'INPUT_FROZEN',
      };
    }
    if (action == 'history') return {'attempts': <Object>[]};
    final data = mathMobilePreviewSnapshot();
    if (held) {
      data['attempt_id'] = 'original-attempt';
      data['tasks'] = <Object>[];
      data['strengths'] = <Object>[];
      data['diagnosis'] = '판정 보류';
    }
    for (final task in data['tasks'] as List) {
      (task as Map)['source_regions'] = [
        {
          'artifact_id': 'stored-photo',
          'x': 0,
          'y': 0,
          'width': 0.5,
          'height': 0.5,
        },
      ];
    }
    return data;
  }

  @override
  Future<Uint8List> readEvidence(String artifact) async {
    expect(artifact, 'stored-photo');
    reads++;
    final bytes = await image.future;
    if (disposed) throw StateError('closed during History read');
    return bytes;
  }

  @override
  void close() {
    disposed = true;
    super.close();
  }
}

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'held original retains submission independently; input failure=$fails',
      (tester) async {
        final gateway = _Gateway(_UnusedClient())
          ..held = true
          ..failInput = fails;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('owner')),
              ),
              mathGatewayProvider('owner').overrideWith((ref) => gateway),
            ],
            child: const MaterialApp(
              home: MathCoachingPage(evaluationId: 'preview-only'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final screen = tester.widget<MathCoachingScreen>(
          find.byType(MathCoachingScreen),
        );
        expect(screen.snapshot.diagnosis, '판정 보류');
        expect(screen.snapshot.tasks, isEmpty);
        expect(
          screen.submittedAnswer,
          fails ? isNull : 'original submitted answer',
        );
        expect(screen.submissionReadFailed, fails);
        expect(gateway.reads, 0);
      },
    );
  }
  testWidgets(
    'History loads shared original once and keeps gateway alive until route closes',
    (tester) async {
      final client = _UnusedClient();
      final gateway = _Gateway(client);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('owner')),
            ),
            mathGatewayProvider('owner').overrideWith((ref) {
              ref.onDispose(gateway.close);
              return gateway;
            }),
          ],
          child: const MaterialApp(
            home: MathCoachingPage(evaluationId: 'preview-only'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(gateway.reads, 1);
      expect(gateway.disposed, false);
      final bytes = Uint8List.fromList([1, 2, 3]);
      gateway.image.complete(bytes);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MathCoachingScreen>(find.byType(MathCoachingScreen))
            .sources['stored-photo'],
        bytes,
      );
      expect(gateway.reads, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(gateway.disposed, true);
    },
  );
}
