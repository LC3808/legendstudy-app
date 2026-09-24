import 'package:flutter/material.dart';

import '../scoring/scoring_repository.dart';

/// Presentation hierarchy only; all options retain their actual occurrence/key.
class OfficialMockSelector extends StatefulWidget {
  const OfficialMockSelector({
    super.key,
    required this.papers,
    required this.busy,
    required this.onExam,
    required this.onPaper,
    required this.selectedPaper,
  });
  final List<ScoringPaper> papers;
  final bool busy;
  final int? selectedPaper;
  final Future<void> Function(String) onExam;
  final Future<void> Function(int?) onPaper;
  @override
  State<OfficialMockSelector> createState() => _OfficialMockSelectorState();
}

class _OfficialMockSelectorState extends State<OfficialMockSelector> {
  int? year, grade, month;
  String? exam, group;
  Future<void> reset(void Function() edit) async {
    if (widget.busy) return;
    setState(edit);
    await widget.onExam('timer-only');
  }

  Widget picker<T>(
    String key,
    String label,
    T? value,
    List<(T, String)> options,
    void Function(T) changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$key-$value'),
      initialValue: value,
      isExpanded: true,
      isDense: true,
      itemHeight: null,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: [
        for (final o in options)
          DropdownMenuItem(
            value: o.$1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Align(alignment: Alignment.centerLeft, child: Text(o.$2)),
            ),
          ),
      ],
      onChanged: widget.busy
          ? null
          : (v) {
              if (v != null) changed(v);
            },
    ),
  );
  List<int> values(
    Iterable<ScoringPaper> rows,
    int? Function(ScoringPaper) field,
  ) =>
      rows.map((p) => field(p) ?? 0).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
  @override
  Widget build(BuildContext context) {
    final rows = widget.papers;
    final years = values(rows, (p) => p.year);
    final yr = rows.where((p) => (p.year ?? 0) == year);
    final gr = yr.where((p) => (p.grade ?? 0) == grade);
    final mr = gr.where((p) => (p.month ?? 0) == month).toList();
    final exams = mr.map((p) => p.examIdentity).toSet();
    final subjectRows = rows.indexed
        .where((p) => p.$2.examIdentity == exam)
        .toList();
    final groups = [
      '국어',
      '수학',
      '영어',
      '한국사',
      '탐구',
      '기타',
    ].where((g) => subjectRows.any((p) => p.$2.group == g)).toList();
    final options = subjectRows.where((p) => p.$2.group == group).toList();
    Future<void> selectExam(String id) async {
      setState(() {
        exam = id;
        group = null;
      });
      await widget.onExam(id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        picker(
          'official-year',
          '연도',
          year,
          [for (final v in years) (v, v == 0 ? '연도 정보 없음' : '$v년')],
          (v) => reset(() {
            year = v;
            grade = month = null;
            exam = group = null;
          }),
        ),
        if (year != null)
          picker(
            'official-grade',
            '학년',
            grade,
            [
              for (final v in values(yr, (p) => p.grade))
                (v, v == 0 ? '학년 정보 없음' : '고$v'),
            ],
            (v) => reset(() {
              grade = v;
              month = null;
              exam = group = null;
            }),
          ),
        if (grade != null)
          picker(
            'official-month',
            '월',
            month,
            [
              for (final v in values(gr, (p) => p.month))
                (v, v == 0 ? '월 정보 없음' : '$v월'),
            ],
            (v) async {
              await reset(() {
                month = v;
                exam = group = null;
              });
              final ids = gr
                  .where((p) => (p.month ?? 0) == v)
                  .map((p) => p.examIdentity)
                  .toSet();
              if (mounted && ids.length == 1) await selectExam(ids.single);
            },
          ),
        if (month != null && exams.length > 1)
          picker('official-exam', '시험 구분', exam, [
            for (final id in exams)
              (id, mr.firstWhere((p) => p.examIdentity == id).title),
          ], selectExam),
        if (exam != null) ...[
          Text(rows.firstWhere((p) => p.examIdentity == exam).title),
          const SizedBox(height: 8),
          const Text('과목'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final g in groups)
                ChoiceChip(
                  label: Text(g),
                  selected: group == g,
                  onSelected: widget.busy
                      ? null
                      : (_) async {
                          setState(() => group = g);
                          await widget.onExam(exam!);
                          final choices = subjectRows
                              .where((p) => p.$2.group == g)
                              .toList();
                          if (mounted && choices.length == 1) {
                            await widget.onPaper(choices.single.$1);
                          }
                        },
                ),
            ],
          ),
          if (options.length > 1)
            picker(
              'official-subject-$exam-$group',
              '세부 과목 · 선택과목',
              widget.selectedPaper,
              [
                for (final o in options)
                  (
                    o.$1,
                    '${o.$2.subjectLabel} · ${o.$2.availability.paperVariant}',
                  ),
              ],
              widget.onPaper,
            ),
          if (options.length == 1)
            Text(
              '${options.single.$2.subjectLabel} · ${options.single.$2.availability.paperVariant}',
            ),
        ],
      ],
    );
  }
}
