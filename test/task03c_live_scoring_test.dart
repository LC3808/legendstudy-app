// Explicit opt-in: public production reads and local guest grading only.
// No login, server submissions, Study writes or persistent app storage.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';

void main() {
  test(
    'TASK03C live public app repository and guest grading',
    () async {
      final priorOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = priorOverrides);
      final config = AppConfig.fromEnvironment();
      expect(
        Uri.parse(config.supabaseUrl).host,
        'stlhijzpjfgwwdgunlsd.supabase.co',
      );
      final client = http.Client();
      addTearDown(client.close);
      final repo = SupabaseScoringRepository(config, client);
      final papers = await repo.availablePapers();
      expect(papers.length, 443);
      expect(
        papers.map((p) => p.availability.examSubjectId).toSet().length,
        396,
      );
      expect(papers.map((p) => p.examIdentity).toSet().length, 17);
      final data = jsonDecode(
        File('data/mock_expansion/task03b/load_data.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final keys = (data['answer_key_versions'] as List)
          .cast<Map<String, dynamic>>();
      final questions = (data['exam_questions'] as List)
          .cast<Map<String, dynamic>>();
      final chosen = <String>{};
      for (final p in papers) {
        final key = keys.singleWhere(
          (k) => k['id'] == p.availability.answerKeyVersionId,
        );
        final qs =
            questions
                .where((q) => q['answer_key_version_id'] == key['id'])
                .toList()
              ..sort(
                (a, b) => (a['question_number'] as int).compareTo(
                  b['question_number'] as int,
                ),
              );
        final categories = <String>[
          if (qs.any((q) => q['answer_type'] == 'numeric')) 'numeric',
          if (qs.any((q) => q['all_credit'] == true)) 'all_credit',
          if (qs.any((q) => (q['accepted_answers'] as List).length > 1))
            'multiple',
          if (qs.every((q) => q['answer_type'] == 'multiple_choice')) 'mcq',
        ];
        if (categories.every(chosen.contains)) continue;
        chosen.addAll(categories);
        final draft = await repo.prepare(p.availability);
        final mandatory = qs
            .where((q) => q['all_credit'] == true)
            .fold<int>(0, (n, q) => n + (q['points'] as int));
        for (final mode in ['perfect', 'wrong', 'blank']) {
          final answers = <int?>[
            for (final q in qs)
              mode == 'blank' || (mode == 'perfect' && q['all_credit'] == true)
                  ? null
                  : mode == 'perfect'
                  ? (q['accepted_answers'] as List).first as int
                  : List.generate(
                      q['answer_type'] == 'numeric' ? 1000 : 5,
                      (i) => q['answer_type'] == 'numeric' ? i : i + 1,
                    ).firstWhere(
                      (n) => !(q['accepted_answers'] as List).contains(n),
                    ),
          ];
          final result = await repo.submit(
            ScoringAttempt(
              id: 'public-read-only-probe',
              title: 'TASK03C guest verification',
              draft: AnswerDraft(draft.availability, draft.questions, answers),
            ),
          );
          expect(
            result.rawScore,
            mode == 'perfect' ? key['max_score'] : mandatory,
          );
          expect(result.grade, isNull);
          expect(result.gradeLabel, '등급 산출 불가');
          expect(result.answers.length, qs.length);
        }
      }
      expect(chosen, containsAll(['numeric', 'all_credit', 'mcq']));
      // Opt-in verification marker, never invoked in application code.
      // ignore: avoid_print
      print(
        'TASK03C PASS live repository: ${papers.length} papers, guest categories $chosen',
      );
    },
    skip: !const bool.fromEnvironment('TASK03C_LIVE_READS'),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
