import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/links/external_link.dart';
import '../../analytics/analytics_providers.dart';
import '../../analytics/analytics_guard.dart';
import '../../analytics/domain/analytics_events.dart';
import 'grade_cutoff.dart';

class GradeCutoffPanel extends ConsumerStatefulWidget {
  const GradeCutoffPanel({
    super.key,
    required this.contentItemId,
    required this.source,
  });
  final String contentItemId, source;
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
  void didUpdateWidget(GradeCutoffPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentItemId != widget.contentItemId) selected = null;
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: const Text('등급컷 확인'),
      onExpansionChanged: (v) => setState(() => expanded = v),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        if (expanded)
          ref
              .watch(gradeCutoffsProvider(widget.contentItemId))
              .when(
                loading: () =>
                    const LinearProgressIndicator(semanticsLabel: '등급컷 불러오는 중'),
                error: (_, _) => Column(
                  children: [
                    const Text('등급컷을 불러오지 못했어요. 자료와 PDF는 계속 이용할 수 있어요.'),
                    TextButton(
                      onPressed: () => ref.invalidate(
                        gradeCutoffsProvider(widget.contentItemId),
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
                data: (rows) {
                  if (rows.isEmpty) return const Text('확인된 등급컷 자료가 아직 없습니다.');
                  final subjects = <String, GradeCutoff>{
                    for (final row in rows) row.key: row,
                  };
                  // Electives require explicit choice. Never choose the first elective silently.
                  final key = subjects.length == 1
                      ? subjects.keys.single
                      : selected;
                  final chosen = rows.where((r) => r.key == key).toList()
                    ..sort((a, b) => a.grade.compareTo(b.grade));
                  final scoreTypes = chosen
                      .where((r) => r.scoreType != '자료 없음')
                      .map((r) => r.scoreType)
                      .toSet();
                  if (chosen.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && expanded) record(chosen.first);
                    });
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('${widget.contentItemId}:$key'),
                        initialValue: key,
                        isExpanded: true,
                        itemHeight: null,
                        decoration: const InputDecoration(labelText: '과목·선택과목'),
                        hint: const Text('과목을 선택해 주세요'),
                        items: [
                          for (final r in subjects.values)
                            DropdownMenuItem(
                              value: r.key,
                              child: Text(r.label),
                            ),
                        ],
                        onChanged: (v) => setState(() => selected = v),
                      ),
                      if (chosen.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${scoreTypes.isEmpty ? '자료 없음' : scoreTypes.join(' · ')} 등급컷',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('원점수 우선 · 원점수가 없으면 표준점수로 표시합니다.'),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16,
                            horizontalMargin: 8,
                            columns: [
                              const DataColumn(label: Text('등급')),
                              DataColumn(
                                label: Text(
                                  scoreTypes.length == 1
                                      ? scoreTypes.first
                                      : '점수',
                                ),
                              ),
                              const DataColumn(label: Text('자료 상태')),
                            ],
                            rows: [
                              for (final r in chosen)
                                DataRow(
                                  cells: [
                                    DataCell(Text('${r.grade}등급')),
                                    DataCell(
                                      Text(
                                        scoreTypes.length == 1
                                            ? r.score
                                            : '${r.scoreType} ${r.score}',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        r.certainty.replaceFirst(
                                          '확정 여부 미제공',
                                          '확정 여부\n미제공',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (chosen.any(
                          (r) => r.hasRaw && r.data['standard_score'] != null,
                        )) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '표준점수 (보조 정보)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          for (final r in chosen.where(
                            (r) => r.data['standard_score'] != null,
                          ))
                            Text(
                              '${r.grade}등급: ${r.data['standard_score']} · ${GradeCutoff.certaintyLabel(r.data['standard_certainty'])}',
                            ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          '등급 경계는 해당 등급의 하한입니다. 범위는 원자료의 추정 범위입니다. 추정 원점수는 공식 확정 점수가 아닙니다.',
                        ),
                        if (chosen.length < 9)
                          const Text(
                            '원자료에서 확인된 등급만 표시합니다. 누락된 경계는 임의 계산하지 않습니다.',
                          ),
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
                                  ],
                                )
                                .whereType<String>()
                                .toSet())
                          ExternalLinkButton(
                            uri: Uri.tryParse(url),
                            label: '점수 기준 원본 자료',
                          ),
                        for (final entry in {
                          for (final r in chosen)
                            '${r.data['source_name']} · ${r.data['verified_at']?.toString().split('T').first ?? ''}',
                        })
                          Text(entry),
                      ],
                    ],
                  );
                },
              ),
      ],
    ),
  );
}

class GradeCutoffBrowser extends ConsumerStatefulWidget {
  const GradeCutoffBrowser({super.key});
  @override
  ConsumerState<GradeCutoffBrowser> createState() => _GradeCutoffBrowserState();
}

class _GradeCutoffBrowserState extends ConsumerState<GradeCutoffBrowser> {
  String? exam;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('평가원 모의평가·수능 등급컷')),
    body: ref
        .watch(cutoffExamsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(cutoffExamsProvider),
              child: const Text('시험 목록 다시 불러오기'),
            ),
          ),
          data: (rows) => ListView(
            padding: const EdgeInsets.all(16),
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
                GradeCutoffPanel(
                  key: ValueKey(exam),
                  contentItemId: exam!,
                  source: 'study',
                ),
            ],
          ),
        ),
  );
}
