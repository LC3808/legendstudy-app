import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/links/external_link.dart';
import '../../analytics/analytics_providers.dart';
import '../../analytics/analytics_guard.dart';
import '../../analytics/domain/analytics_events.dart';
import 'grade_cutoff.dart';

String cutoffGroup(GradeCutoff row) {
  final label = (row.data['subject_label'] as String? ?? '').replaceAll(
    ' ',
    '',
  );
  if (label.startsWith('국어')) return '국어';
  if (label.startsWith('수학')) return '수학';
  if (label == '영어' || label == '한국사') return '영어·한국사';
  if (['물리학', '화학', '생명과학', '지구과학'].any(label.startsWith)) {
    return '과학탐구';
  }
  if ([
    '경제',
    '동아시아사',
    '사회문화',
    '생활과윤리',
    '세계사',
    '세계지리',
    '윤리와사상',
    '정치와법',
    '한국지리',
  ].contains(label)) {
    return '사회탐구';
  }
  return '제2외국어·한문';
}

const cutoffGroups = ['국어', '수학', '영어·한국사', '과학탐구', '사회탐구', '제2외국어·한문'];

class GradeCutoffPanel extends ConsumerStatefulWidget {
  const GradeCutoffPanel({
    super.key,
    required this.contentItemId,
    required this.source,
    this.inline = false,
  });
  final String contentItemId, source;
  final bool inline;
  @override
  ConsumerState<GradeCutoffPanel> createState() => _GradeCutoffPanelState();
}

class _GradeCutoffPanelState extends ConsumerState<GradeCutoffPanel> {
  bool expanded = false;
  String? selected;
  void record(GradeCutoff row) =>
      ref.read(analyticsServiceProvider).logEventOnce(
        '${widget.source}:${widget.contentItemId}:${row.key}',
        AnalyticsEvents.gradeCutoffView,
        {
          AnalyticsParamKeys.examCode: widget.contentItemId,
          AnalyticsParamKeys.academicYear: row.year,
          AnalyticsParamKeys.subjectCode: row.key,
          AnalyticsParamKeys.platform: analyticsPlatform(),
          AnalyticsParamKeys.source: widget.source,
        },
      );
  @override
  Widget build(BuildContext context) {
    if (widget.inline) return content();
    return Card(
      child: ExpansionTile(
        title: const Text('등급컷 확인'),
        onExpansionChanged: (v) => setState(() => expanded = v),
        childrenPadding: const EdgeInsets.all(12),
        children: [if (expanded) content()],
      ),
    );
  }

  Widget content() => ref
      .watch(gradeCutoffsProvider(widget.contentItemId))
      .when(
        loading: () =>
            const LinearProgressIndicator(semanticsLabel: '등급컷 불러오는 중'),
        error: (_, _) => Column(
          children: [
            const Text('등급컷을 불러오지 못했어요. 자료와 PDF는 계속 이용할 수 있어요.'),
            TextButton(
              onPressed: () =>
                  ref.invalidate(gradeCutoffsProvider(widget.contentItemId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
        data: (rows) {
          if (rows.isEmpty) return const Text('확인된 등급컷 자료가 아직 없습니다.');
          final available = cutoffGroups
              .where((g) => rows.any((r) => cutoffGroup(r) == g))
              .toList();
          final group = available.contains(selected)
              ? selected!
              : available.first;
          final chosen = rows.where((r) => cutoffGroup(r) == group).toList();
          final subjects = <String, GradeCutoff>{
            for (final r in chosen) r.key: r,
          }.values.toList();
          final tables = <List<GradeCutoff>>[];
          final sections = group == '과학탐구'
              ? [
                  for (final level in [false, true])
                    subjects.where((r) {
                      final label = r.data['subject_label'] as String? ?? '';
                      return (label.endsWith('2') || label.endsWith('Ⅱ')) ==
                          level;
                    }).toList(),
                ]
              : [subjects];
          for (final section in sections) {
            for (var i = 0; i < section.length; i += 4) {
              tables.add(section.skip(i).take(4).toList());
            }
          }
          // All electives in a group are shown together; no implicit elective selection.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && (expanded || widget.inline)) {
              for (final r in subjects) {
                record(r);
              }
            }
          });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('${widget.contentItemId}:$group'),
                initialValue: group,
                isExpanded: true,
                decoration: const InputDecoration(labelText: '과목'),
                items: [
                  for (final g in available)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                onChanged: (v) => setState(() => selected = v),
              ),
              if (group == '영어·한국사')
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('절대평가 · 원점수'),
                ),
              for (final table in tables)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _ComparisonTable(subjects: table, rows: chosen),
                ),
              if (chosen.any((r) => r.historicalReference != null)) ...[
                const SizedBox(height: 20),
                Text(
                  '유사 시험 참고 원점수',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Text(
                  '같은 선택과목·등급의 이전 시험 범위입니다. '
                  '이 시험의 예상 등급컷이나 등급 판정 기준이 아닙니다.',
                ),
                for (final basis
                    in chosen
                        .map((r) => r.historicalReference?['basis'])
                        .whereType<String>()
                        .toSet())
                  Text('기준: $basis'),
                for (final table in tables)
                  _ComparisonTable(
                    subjects: table,
                    rows: chosen,
                    historical: true,
                  ),
              ],
              ExpansionTile(
                title: const Text('출처'),
                children: [
                  for (final url
                      in chosen
                          .map((r) => r.data['source_url'])
                          .whereType<String>()
                          .toSet())
                    ExternalLinkButton(
                      uri: Uri.tryParse(url),
                      label: '등급컷 원본 게시글',
                    ),
                  for (final url
                      in chosen
                          .expand(
                            (r) => [
                              r.data['raw_source_url'],
                              r.data['standard_source_url'],
                              r.data['estimated_raw_source_url'],
                              ...?r.historicalReference?['urls'] as List?,
                            ],
                          )
                          .whereType<String>()
                          .toSet())
                    ExternalLinkButton(
                      uri: Uri.tryParse(url),
                      label: '점수 기준 원본 자료',
                    ),
                ],
              ),
            ],
          );
        },
      );
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({
    required this.subjects,
    required this.rows,
    this.historical = false,
  });
  final List<GradeCutoff> subjects, rows;
  final bool historical;
  @override
  Widget build(BuildContext context) {
    final raw = {
      for (final s in subjects)
        s.key: rows.any((r) => r.key == s.key && r.hasRaw),
    };
    final indexed = {for (final r in rows) '${r.key}:${r.grade}': r};
    final grades = rows.map((r) => r.grade).toSet().toList()..sort();
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontSize: 14, height: 1.45);
    Widget cell(String text, {bool heading = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: heading ? style?.copyWith(fontWeight: FontWeight.w700) : style,
      ),
    );
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: c.maxWidth < 280 ? 280 : c.maxWidth,
          child: Table(
            columnWidths: {0: const FixedColumnWidth(42)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                children: [
                  cell('등급', heading: true),
                  for (final s in subjects)
                    cell(
                      '${(s.data['elective_label'] as String?)?.isNotEmpty == true ? s.data['elective_label'] : s.data['subject_label']}\n${historical
                          ? '참고 원점수'
                          : raw[s.key] == true
                          ? '원점수'
                          : '표준점수 / 추정 원점수'}',
                      heading: true,
                    ),
                ],
              ),
              for (final grade in grades)
                TableRow(
                  children: [
                    cell('$grade'),
                    for (final s in subjects)
                      cell(
                        historical
                            ? (indexed['${s.key}:$grade']?.historicalRaw ?? '—')
                            : raw[s.key] == true
                            ? (indexed['${s.key}:$grade']?.hasRaw == true
                                  ? indexed['${s.key}:$grade']!.score
                                  : '—')
                            : '${indexed['${s.key}:$grade']?.data['standard_score'] ?? '—'} / ${indexed['${s.key}:$grade']?.estimatedRaw ?? '—'}',
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Embedded in the existing study panel: selecting an exam opens its table here.
class GradeCutoffPicker extends ConsumerStatefulWidget {
  const GradeCutoffPicker({super.key});
  @override
  ConsumerState<GradeCutoffPicker> createState() => _GradeCutoffPickerState();
}

class _GradeCutoffPickerState extends ConsumerState<GradeCutoffPicker> {
  String? exam;
  @override
  Widget build(BuildContext context) => ref
      .watch(cutoffExamsProvider)
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => TextButton(
          onPressed: () => ref.invalidate(cutoffExamsProvider),
          child: const Text('시험 목록 다시 불러오기'),
        ),
        data: (rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rows.isEmpty) const Text('조회 가능한 시험이 없습니다.'),
            if (rows.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: exam,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: '시험 선택'),
                items: [
                  for (final r in rows)
                    DropdownMenuItem(
                      value: r['content_item_id'] as String,
                      child: Text(
                        '${r['academic_year']}학년도 ${r['exam_type'] == 'csat' ? '수능' : '${r['exam_month']}월 모의평가'}',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => exam = v),
              ),
            if (exam != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GradeCutoffPanel(
                  contentItemId: exam!,
                  source: 'study',
                  inline: true,
                ),
              ),
          ],
        ),
      );
}

class GradeCutoffBrowser extends StatelessWidget {
  const GradeCutoffBrowser({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('등급컷 확인')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: GradeCutoffPicker(),
    ),
  );
}
