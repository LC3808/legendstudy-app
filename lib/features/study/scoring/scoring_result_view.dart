import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'scoring_display_title.dart';
import 'scoring_models.dart';
import 'exam_title_banner.dart';
import 'practice_grade.dart';

/// Presentation only; the immutable score, answer and provenance stay intact.
class ScoringResultView extends StatelessWidget {
  const ScoringResultView({
    super.key,
    required this.attempt,
    required this.guest,
    this.sessionChanges,
    this.canReadResult,
  });
  final ScoringAttempt attempt;
  final bool guest;
  final Listenable? sessionChanges;
  final bool Function()? canReadResult;

  void openAnswers(BuildContext context, [int? number]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScoringAnswersPage(
          attempt: attempt,
          initialQuestion: number,
          sessionChanges: sessionChanges,
          canReadResult: canReadResult,
        ),
      ),
    );
  }

  Widget numbers(
    BuildContext context,
    String label,
    List<int> values,
    Color color,
  ) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTokens.sectionTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in values)
                Semantics(
                  label: '$label $n번, 답안 확인',
                  button: true,
                  child: ExcludeSemantics(
                    child: OutlinedButton(
                      key: ValueKey('review-jump-$n'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        minimumSize: const Size(56, 48),
                      ),
                      onPressed: () => openAnswers(context, n),
                      child: Text('$n번'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = attempt.result!;
    final referenceGrade = PracticeGrade.forAttempt(attempt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExamTitleBanner(title: attempt.title),
        if (attempt.subject?.trim().isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(attempt.subject!, style: AppTokens.body),
          ),
        const SizedBox(height: 20),
        Container(
          key: const Key('score-summary-banner'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FA),
            border: Border.all(color: AppTokens.info, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '원점수 ${score.rawScore}점, 만점 ${score.maxScore}점',
                child: ExcludeSemantics(
                  child: Text(
                    '${score.rawScore} / ${score.maxScore}점',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.info,
                    ),
                  ),
                ),
              ),
              if (score.hasGradeBasis && score.grade != null) ...[
                const SizedBox(height: 6),
                Text(score.gradeLabel, style: AppTokens.sectionTitle),
              ] else if (referenceGrade != null) ...[
                const SizedBox(height: 10),
                Text(
                  referenceGrade.label,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8E4600),
                  ),
                ),
                if (referenceGrade.estimated)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('유사 시험 원점수 기준', style: TextStyle(fontSize: 13)),
                  ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _ResultStat(
                    '정답',
                    '${score.correctCount} / ${score.answers.length}',
                    AppTokens.info,
                  ),
                  _ResultStat(
                    '오답',
                    '${score.wrong.length}',
                    AppTokens.dangerInk,
                  ),
                  _ResultStat(
                    '미응답',
                    '${score.unanswered.length}',
                    AppTokens.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => openAnswers(context),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('답안 확인'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTokens.textPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 52),
          ),
        ),
        numbers(context, '틀린 문제', score.wrong, AppTokens.dangerInk),
        numbers(context, '미응답 문제', score.unanswered, AppTokens.textSecondary),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class ScoringAnswersPage extends StatefulWidget {
  const ScoringAnswersPage({
    super.key,
    required this.attempt,
    this.initialQuestion,
    this.sessionChanges,
    this.canReadResult,
  });
  final ScoringAttempt attempt;
  final int? initialQuestion;
  final Listenable? sessionChanges;
  final bool Function()? canReadResult;
  @override
  State<ScoringAnswersPage> createState() => _ScoringAnswersPageState();
}

class _ScoringAnswersPageState extends State<ScoringAnswersPage> {
  final anchors = <int, GlobalKey>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = anchors[widget.initialQuestion]?.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.05);
    });
  }

  Widget page(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('답안 확인')),
    body: SafeArea(
      child: widget.canReadResult?.call() == false
          ? const Center(child: Text('이 계정의 결과를 확인할 수 없어요.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    scoringDisplayTitle(widget.attempt.title),
                    style: AppTokens.sectionTitle,
                  ),
                  if (widget.attempt.subject?.trim().isNotEmpty == true)
                    Text(widget.attempt.subject!, style: AppTokens.body),
                  const SizedBox(height: 16),
                  for (final review in widget.attempt.result!.answers)
                    Padding(
                      key: anchors.putIfAbsent(
                        review.number,
                        () => GlobalKey(),
                      ),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AnswerCard(review),
                    ),
                ],
              ),
            ),
    ),
  );

  @override
  Widget build(BuildContext context) => widget.sessionChanges == null
      ? page(context)
      : ListenableBuilder(
          listenable: widget.sessionChanges!,
          builder: (context, _) => page(context),
        );
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard(this.review);
  final AnswerReview review;
  @override
  Widget build(BuildContext context) {
    final a = review;
    final label = a.allCredit
        ? '전원 정답'
        : a.submitted == null
        ? '미응답'
        : a.isCorrect
        ? '정답'
        : '오답';
    final color = a.isCorrect
        ? AppTokens.info
        : a.submitted == null
        ? AppTokens.textSecondary
        : AppTokens.dangerInk;
    final own = a.submitted == null ? '미응답' : a.formatAnswer(a.submitted);
    return Semantics(
      label:
          '${a.number}번, 내 답 $own, 정답 ${a.correctLabel}, $label, 배점 ${a.points}점',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: a.isCorrect
                ? const Color(0xFFF3F7FC)
                : a.submitted == null
                ? Colors.white
                : const Color(0xFFFFF4F4),
            border: Border.all(color: color, width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${a.number}번 · $label',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _ResultStat('내 답', own, color),
                  _ResultStat('정답', a.correctLabel, AppTokens.info),
                  _ResultStat('배점', '${a.points}점', AppTokens.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
