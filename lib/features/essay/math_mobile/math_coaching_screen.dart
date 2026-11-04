import 'learning_completeness.dart';
import 'math_answer_evidence.dart';

import 'dart:typed_data';

import 'math_recognition_panel.dart';

import 'package:flutter/material.dart';

import '../math_text.dart';
import 'academic_purple.dart';
import 'coaching_contract.dart';

class MathCoachingScreen extends StatefulWidget {
  const MathCoachingScreen({
    required this.snapshot,
    required this.request,
    required this.onRewrite,
    this.embedded = false,
    this.sources = const {},
    super.key,
  });
  final CoachingSnapshot snapshot;
  final MathCoachingRequest request;
  final Future<void> Function(bool paid) onRewrite;
  final bool embedded;
  final Map<String, Uint8List> sources;
  @override
  State<MathCoachingScreen> createState() => _MathCoachingScreenState();
}

class _MathCoachingScreenState extends State<MathCoachingScreen> {
  late CoachingSnapshot snapshot = widget.snapshot;
  bool busy = false;
  String? error;
  Future<void> rewrite() async {
    if (!snapshot.free && !snapshot.paid) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수정 답안을 작성할까요?'),
        content: Text(
          snapshot.free
              ? '무료 재첨삭 1회를 이용합니다. 기간과 자격은 제출 시 서버에서 다시 확인합니다.'
              : '새 첨삭에 이용권 1개를 사용합니다. 제출 전 서버에서 이용 조건을 확인합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('수정 답안 작성'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onRewrite(!snapshot.free);
    } catch (_) {
      if (mounted) {
        setState(() => error = '수정 답안을 열지 못했어요. 기존 기록은 보존됩니다. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reveal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 풀이를 공개할까요?'),
        content: const Text(
          '최종 정답과 완성 풀이가 표시되며 공개 요청이 학습 기록에 저장됩니다. 먼저 직접 수정해 보세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('조금 더 풀어볼게요'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('정답·해설 공개'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.request('reveal', {
        'evaluation_id': snapshot.id,
      });
      final next = CoachingSnapshot(result);
      if (!next.disclosed) throw StateError('DISCLOSURE_NOT_RECORDED');
      if (mounted) {
        setState(() => snapshot = next);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MathSolutionPage(solution: object(next.data['full_solution'])),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => error = '공개 기록을 확인하지 못했습니다. 다시 요청해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AcademicPurple.ink,
      ),
    ),
  );
  Widget result() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      MathCard(
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: AcademicPurple.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이번 답안의 종합 진단',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AcademicPurple.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              snapshot.diagnosis,
              style: const TextStyle(
                fontSize: 18,
                height: 1.65,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '공식 배점과 연결되지 않은 점수는 표시하지 않습니다.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AcademicPurple.secondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      LearningCompletenessCard(
        value: snapshot.data['learning_completeness'],
        evaluationId: snapshot.id,
      ),
      heading('잘한 점'),
      if (objects(snapshot.data['strengths']).isEmpty)
        const MathCard(child: Text('검증된 강점 근거가 아직 제공되지 않았습니다.')),
      for (final strength in objects(snapshot.data['strengths']))
        MathCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AcademicPurple.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      strength['title'] as String? ?? '풀이 과정의 강점',
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(strength['description'] as String? ?? ''),
              if (strength['student_formula'] is String &&
                  (strength['student_formula'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                MathContentSection(
                  label: '학생 답안 근거',
                  child: MathAnswerEvidence(
                    strength['student_formula'] as String,
                  ),
                ),
              ],
            ],
          ),
        ),
      const SizedBox(height: 8),
      heading('우선 개선할 부분'),
      if (snapshot.tasks.isEmpty)
        const MathCard(child: Text('현재 답안에서 우선 개선할 부분이 확인되지 않았습니다.')),
      for (final (index, task) in snapshot.tasks.indexed)
        MathCard(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MathTaskPage(
                  task: task,
                  sources: widget.sources,
                  concepts: snapshot.concepts,
                  request: widget.request,
                  evaluationId: snapshot.id,
                  onRewrite: rewrite,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AcademicPurple.emphasis,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AcademicPurple.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task['title'] as String? ?? '풀이 단계 점검',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AcademicPurple.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(task['importance'] as String? ?? '확인 필요'),
                      backgroundColor: AcademicPurple.soft,
                    ),
                    Chip(label: Text('풀이 ${task['position'] ?? '—'}단계')),
                  ],
                ),
                if (task['student_formula'] is String &&
                    (task['student_formula'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: MathFormulaSurface(
                      child: MathStudentText(task['student_formula'] as String),
                    ),
                  ),
                const SizedBox(height: 16),
                MathContentSection(
                  label: '수정 방향',
                  child: Text(
                    task['direction'] as String? ?? '사용한 조건과 계산을 확인하세요.',
                  ),
                ),
              ],
            ),
          ),
        ),
      if ((snapshot.data['remaining_task_count'] as num? ?? 0) > 0)
        Text(
          '추가 과제 ${snapshot.data['remaining_task_count']}개는 상세 공개 후 확인할 수 있습니다.',
        ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: busy || (!snapshot.free && !snapshot.paid) ? null : rewrite,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('수정 답안 작성하기'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          snapshot.chargeLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AcademicPurple.secondary),
        ),
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : reveal,
        icon: const Icon(Icons.lock_open_outlined),
        label: const Text('전체 풀이 및 해설 보기'),
      ),
      if (error != null)
        Text(error!, style: const TextStyle(color: AcademicPurple.error)),
    ],
  );
  @override
  Widget build(BuildContext context) => MathMobileTheme(
    child: DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          toolbarHeight: 76 * MediaQuery.textScalerOf(context).scale(1),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                snapshot.data['university'] as String? ?? '논술 LAB',
                style: const TextStyle(
                  fontSize: 13,
                  color: AcademicPurple.secondary,
                ),
              ),
              Text(
                snapshot.data['exam_label'] as String? ?? '수리논술 첨삭 결과',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '첨삭 결과'),
              Tab(text: '기본 개념 확인'),
              Tab(text: '학습 기록'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            result(),
            MathConceptList(concepts: snapshot.concepts),
            MathCoachingHistory(snapshot: snapshot, request: widget.request),
          ],
        ),
      ),
    ),
  );
}

class MathConceptList extends StatelessWidget {
  const MathConceptList({required this.concepts, super.key});
  final List<Map<String, dynamic>> concepts;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        '지금 필요한 개념만 확인해 보세요.',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        '문제의 최종 정답은 공개하지 않습니다.',
        style: TextStyle(color: AcademicPurple.secondary),
      ),
      const SizedBox(height: 20),
      if (concepts.isEmpty)
        const MathCard(child: Text('현재 문항과 연결된 검수 개념이 없습니다.')),
      for (final c in concepts)
        MathCard(
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text(
              c['name'] as String? ?? '개념 확인',
              style: const TextStyle(
                fontSize: 18,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  MathContentSection(
                    label: '핵심 공식',
                    child: MathFormulaSurface(
                      child: MathText('\\[${c['formula'] ?? ''}\\]'),
                    ),
                  ),
                  const Divider(),
                  for (final field in const [
                    ('설명', 'description'),
                    ('적용 조건', 'condition'),
                    ('주의할 점', 'caution'),
                    ('현재 문항과의 관계', 'relation'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: MathContentSection(
                        label: field.$1,
                        child: MathText('${c[field.$2] ?? '근거 미제공'}'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

class MathTaskPage extends StatefulWidget {
  const MathTaskPage({
    required this.task,
    required this.concepts,
    required this.request,
    required this.evaluationId,
    required this.onRewrite,
    this.sources = const {},
    super.key,
  });
  final Map<String, Uint8List> sources;
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> concepts;
  final MathCoachingRequest request;
  final String evaluationId;
  final Future<void> Function() onRewrite;
  @override
  State<MathTaskPage> createState() => _MathTaskPageState();
}

class _MathTaskPageState extends State<MathTaskPage> {
  final hints = <int, String>{};
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => MathMobileTheme(
    child: Scaffold(
      appBar: AppBar(title: const Text('개선 과제')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.task['title'] as String? ?? '풀이 단계 점검',
            style: const TextStyle(
              fontSize: 24,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          MathCard(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오류 위치 · 풀이 ${widget.task['position'] ?? '—'}단계',
                  style: const TextStyle(
                    color: AcademicPurple.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                for (final region in objects(widget.task['source_regions']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SizedBox(
                      height: 240,
                      child: MathSourceRegion(
                        region: region,
                        bytes: widget.sources['${region['artifact_id']}'],
                      ),
                    ),
                  ),
                MathContentSection(
                  label: '학생이 작성한 수식',
                  child: MathStudentText(
                    widget.task['student_formula'] as String? ?? '',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.task['source_note'] as String? ??
                      '원본 사진은 답안 인식 확인 화면에서 대조할 수 있습니다.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AcademicPurple.secondary,
                  ),
                ),
              ],
            ),
          ),
          MathCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MathContentSection(
                  label: '점검할 내용',
                  child: MathText(widget.task['description'] as String? ?? ''),
                ),
                if ((widget.task['direction'] as String? ?? '').isNotEmpty) ...[
                  const Divider(),
                  MathContentSection(
                    label: '수정 방향',
                    child: MathText(widget.task['direction'] as String),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('단계별 힌트', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final level in [1, 2])
            if (level == 1 || hints.containsKey(1))
              MathCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      level == 1 ? '1단계 · 개념·조건 점검' : '2단계 · 해결 방향',
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.45,
                        color: AcademicPurple.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (hints.containsKey(level))
                      MathText(hints[level]!)
                    else
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                setState(() => busy = true);
                                try {
                                  final result = await widget.request('hint', {
                                    'evaluation_id': widget.evaluationId,
                                    'task_id': widget.task['id'],
                                    'level': level,
                                  });
                                  if (result['body'] is! String) {
                                    throw const FormatException('HINT');
                                  }
                                  if (mounted) {
                                    setState(
                                      () => hints[level] =
                                          result['body'] as String,
                                    );
                                  }
                                } catch (_) {
                                  if (mounted) {
                                    setState(
                                      () =>
                                          error = '힌트를 확인하지 못했습니다. 다시 요청해 주세요.',
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        child: Text(level == 1 ? '개념 힌트 보기' : '해결 방향 보기'),
                      ),
                  ],
                ),
              ),
          if (error != null)
            Text(error!, style: const TextStyle(color: AcademicPurple.error)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MathMobileTheme(
                  child: Scaffold(
                    appBar: AppBar(title: const Text('기본 개념 확인')),
                    body: MathConceptList(concepts: widget.concepts),
                  ),
                ),
              ),
            ),
            child: const Text('관련 기본 개념 확인'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : widget.onRewrite,
            child: const Text('직접 풀이 수정하기'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class MathSolutionPage extends StatelessWidget {
  const MathSolutionPage({required this.solution, super.key});
  final Map<String, dynamic> solution;
  @override
  Widget build(BuildContext context) => MathMobileTheme(
    child: Scaffold(
      appBar: AppBar(title: const Text('전체 풀이 및 해설')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final reference in objects(solution['references']))
            MathCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reference['origin'] == 'OFFICIAL'
                        ? '공식 예시답안'
                        : reference['origin'] == 'VERIFIED_INTERNAL'
                        ? '검수된 참고 풀이'
                        : 'AI 생성 해설 · 검수되지 않음',
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      color: AcademicPurple.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (reference['relationship'] ==
                      'SUPPLEMENTAL_AFTER_ASSESSMENT') ...[
                    const Text('추가 연결 공식 자료 · 평가 당시 참고자료와 구분'),
                    const SizedBox(height: 8),
                  ],
                  if (reference['source_locator'] is String) ...[
                    Text(reference['source_locator'] as String),
                    const SizedBox(height: 8),
                  ],
                  MathStudentText(reference['body'] as String? ?? ''),
                ],
              ),
            ),
          if (object(solution['generated_solution'])['body'] is String &&
              (object(solution['generated_solution'])['body'] as String)
                  .trim()
                  .isNotEmpty)
            MathCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 생성 참고 해설 · 공식 예시답안 아님',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  MathStudentText(
                    object(solution['generated_solution'])['body'] as String,
                  ),
                ],
              ),
            ),
          if (objects(solution['references']).isEmpty)
            const MathCard(
              child: Text(
                '공식·검수 전체 풀이가 연결되지 않았습니다. 아래는 저장된 단계 분석이며 완성된 모범답안으로 간주하지 않습니다.',
              ),
            ),
          for (final step in objects(solution['steps']))
            MathCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '풀이 ${step['position']}단계',
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      color: AcademicPurple.dark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MathFormulaSurface(
                    child: MathStudentText(
                      step['representation'] as String? ?? '',
                    ),
                  ),
                  const SizedBox(height: 20),
                  MathContentSection(
                    label: '단계 설명',
                    child: MathText(step['explanation'] as String? ?? ''),
                  ),
                ],
              ),
            ),
          for (final path in objects(solution['paths']))
            MathCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '대안 풀이 검토',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MathText(
                    path['explanation'] as String? ??
                        path['reason'] as String? ??
                        '저장된 설명이 없습니다.',
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class MathCoachingHistory extends StatefulWidget {
  const MathCoachingHistory({
    required this.snapshot,
    required this.request,
    super.key,
  });
  final CoachingSnapshot snapshot;
  final MathCoachingRequest request;
  @override
  State<MathCoachingHistory> createState() => _MathCoachingHistoryState();
}

class _MathCoachingHistoryState extends State<MathCoachingHistory> {
  late final future = widget.request('history', {
    'evaluation_id': widget.snapshot.id,
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: future,
    builder: (context, state) {
      if (state.hasError) {
        return const Center(child: Text('학습 기록을 불러오지 못했습니다.'));
      }
      if (!state.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final rows = objects(state.data!['attempts']);
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '같은 문제, 이어지는 성장',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty) const Text('연결된 학습 기록이 없습니다.'),
          for (final row in rows)
            MathCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['resolve_kind'] == 'INITIAL' ? '최초 첨삭' : '수정 답안 첨삭',
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${row['completed_at'] ?? row['created_at'] ?? '시각 미확인'}',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AcademicPurple.secondary,
                    ),
                  ),
                  const Divider(),
                  MathContentSection(
                    label: '첨삭 상태',
                    child: Text('${row['evaluation_state'] ?? '확인 중'}'),
                  ),
                  const SizedBox(height: 20),
                  MathContentSection(
                    label: '힌트 사용',
                    child: Text('${row['exposed_hint_levels'] ?? <int>[]}'),
                  ),
                  const SizedBox(height: 20),
                  MathContentSection(
                    label: '해설 공개 상태',
                    child: Text(
                      row['solution_revealed'] == true
                          ? '전체 해설 공개됨'
                          : '전체 해설 비공개',
                    ),
                  ),
                  const SizedBox(height: 20),
                  MathContentSection(
                    label: '이용권',
                    child: Text(row['credit_label'] as String? ?? '이용권 내역 미제공'),
                  ),
                  const Divider(),
                  MathContentSection(
                    label: '학습 안내',
                    child: Text(
                      row['progress_label'] as String? ??
                          '개선 과제 해결 여부는 저장된 비교 결과에서 확인합니다.',
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}
