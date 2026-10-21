import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/essay/answer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_workspace_page.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    String requested,
    bool enabled, {
    MathGateway? gateway,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (gateway != null)
            mathGatewayProvider('fixture').overrideWithValue(gateway),
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('fixture')),
          ),
          mathCatalogProvider('fixture').overrideWith(
            (ref) async => [
              {
                'leaf_id': 'first',
                'label': '다른 문항',
                'statement': '첫 문항',
                'problem_statement': '합성',
                'response_format': 'FULL_SOLUTION',
              },
              {
                'leaf_id': 'selected',
                'label': '선택한 문항',
                'statement': '선택 내용',
                'problem_statement': '합성',
                'response_format': 'FULL_SOLUTION',
              },
            ],
          ),
          mathEvaluationAvailableProvider('fixture')
              .overrideWith((ref) async => enabled),
        ],
        child: MaterialApp(home: MathWorkspacePage(requestedLeafId: requested)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unavailable pinned question never falls back to another leaf', (
    tester,
  ) async {
    await mount(tester, 'missing', true);
    expect(find.text('선택한 문항은 아직 수리논술 첨삭이 준비되지 않았습니다.'), findsOneWidget);
    expect(find.text('첫 문항'), findsNothing);
    final submit = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '첨삭 진행'),
    );
    expect(submit.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('authorized selection retains server evaluation HOLD', (
    tester,
  ) async {
    await mount(tester, 'selected', false);
    expect(find.text('선택 내용'), findsOneWidget);
    expect(find.text('첫 문항'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '첨삭 진행'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'six ordered pages retry only failed upload and keep attempt and artifacts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 10000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final fake = _UploadGateway();
      await mount(tester, 'selected', true, gateway: fake);
      final pixel = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
      );
      final pages = List.generate(6, (_) => Uint8List.fromList(pixel));
      await tester
          .widget<AnswerImagesInput>(find.byType(AnswerImagesInput))
          .onChanged(pages);
      await tester.pumpAndSettle();
      // Existing picker hides at six; the last page can move without rewriting bytes.
      final input = tester.widget<AnswerImagesInput>(
        find.byType(AnswerImagesInput),
      );
      expect(input.values.length, 6);
      expect(input.allowReorder, isTrue);
      final move = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '사진 2 앞으로 이동'),
      );
      move.onPressed!();
      await tester.pumpAndSettle();
      expect(
        identical(
          tester
              .widget<AnswerImagesInput>(find.byType(AnswerImagesInput))
              .values[0],
          pages[1],
        ),
        isTrue,
      );
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '첨삭 진행'))
          .onPressed!();
      await tester.pumpAndSettle();
      expect(fake.uploads, ['artifact-1', 'artifact-2']);
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '같은 요청 다시 확인'),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(fake.creates, 1);
      expect(fake.positions, [1, 2, 3, 4, 5, 6]);
      expect(fake.uploads, [
        'artifact-1',
        'artifact-2',
        'artifact-2',
        'artifact-3',
        'artifact-4',
        'artifact-5',
        'artifact-6',
      ]);
      expect(identical(fake.firstPage, pages[1]), isTrue);
      expect(fake.extracts, 1);
      expect(
        tester
            .widget<AnswerImagesInput>(find.byType(AnswerImagesInput))
            .enabled,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _UploadGateway extends MathGateway {
  _UploadGateway() : super(_UnusedClient(), 'fixture');
  int creates = 0, extracts = 0;
  bool fail = true;
  Uint8List? firstPage;
  final positions = <int>[];
  final uploads = <String>[];
  @override
  Future<bool> available({bool browsing = false}) async => true;
  @override
  Future<Map<String, dynamic>> call(
    String fn,
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (action == 'create_attempt') {
      creates++;
      return {'attempt_id': 'attempt'};
    }
    if (action == 'register_evidence') {
      final position = (payload['metadata'] as Map)['position'] as int;
      positions.add(position);
      return {'artifact_id': 'artifact-$position'};
    }
    if (action == 'read_input') {
      return {
        'can_request_evaluation': false,
        'candidate': extracts > 0 ? 'candidate' : null,
        'candidate_regions': <Map<String, dynamic>>[],
      };
    }
    throw StateError('Unexpected call: $action');
  }

  @override
  Future<void> uploadEvidence(String artifact, Uint8List bytes) async {
    uploads.add(artifact);
    if (artifact == 'artifact-1') firstPage = bytes;
    if (artifact == 'artifact-2' && fail) {
      fail = false;
      throw StateError('synthetic network interruption');
    }
  }

  @override
  Future<void> extract(String attempt) async {
    extracts++;
  }
}

class _UnusedClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No real transport allowed');
}
