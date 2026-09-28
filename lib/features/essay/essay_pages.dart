import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/links/external_link.dart';
import '../../shared/widgets/shell_widgets.dart';
import 'essay_models.dart';
import 'essay_preview.dart';
import 'essay_controller.dart';

List<RouteBase> get essayRoutes => [
  GoRoute(
    path: 'essay',
    builder: (_, _) => const EssayHomePage(),
    routes: [
      GoRoute(
        path: 'write/:question',
        builder: (_, state) {
          final matches = essayPreviewQuestions.where(
            (q) => q.id == state.pathParameters['question'],
          );
          return matches.isEmpty
              ? Scaffold(
                  appBar: AppBar(title: const Text('논술 첨삭')),
                  body: const EmptyState('문항을 찾을 수 없어요. 이전 화면에서 다시 선택해 주세요.'),
                )
              : EssayWorkspacePage(question: matches.first);
        },
      ),
    ],
  ),
];

class EssayHomePage extends StatefulWidget {
  const EssayHomePage({super.key});
  @override
  State<EssayHomePage> createState() => _EssayHomePageState();
}

class _EssayHomePageState extends State<EssayHomePage> {
  String university = essayPreviewQuestions.first.university;
  String exam = essayPreviewQuestions.first.exam;
  @override
  Widget build(BuildContext context) {
    final questions = essayPreviewQuestions
        .where((q) => q.university == university && q.exam == exam)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('논술 첨삭')),
      body: ShellPage(
        children: [
          const AppHeader(
            title: 'Essay LAB',
            branded: true,
            subtitle: '읽고, 쓰고, 스스로 고쳐 쓰는 논술 학습',
          ),
          const _PreviewNotice(),
          const SectionHeader('대학 · 시험 선택'),
          DropdownButtonFormField<String>(
            initialValue: university,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '대학'),
            items: essayPreviewQuestions
                .map((q) => q.university)
                .toSet()
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            onChanged: (u) => setState(() {
              university = u!;
              exam = essayPreviewQuestions
                  .firstWhere((q) => q.university == u)
                  .exam;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(university),
            initialValue: exam,
            isExpanded: true,
            decoration: const InputDecoration(labelText: '학년도 · 시험 · 계열'),
            items: essayPreviewQuestions
                .where((q) => q.university == university)
                .map((q) => q.exam)
                .toSet()
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (e) => setState(() => exam = e!),
          ),
          const SectionHeader('문항 선택'),
          for (final q in questions) ...[
            const Divider(color: AppTokens.textPrimary),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(q.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${q.availability.label} · 표시 예시${q.minLength == null ? '' : ' · ${q.minLength}~${q.maxLength}자'}',
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/lab/essay/write/${q.id}'),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            '문제 읽기 → 직접 작성 → 첨삭 확인 → 다시 써보기',
            style: AppTokens.secondary,
          ),
        ],
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    color: AppTokens.primarySoft,
    child: const Text(
      '화면 미리보기 · 가상 문제와 결과입니다.\n실제 답안·개인정보를 입력하지 마세요. 저장은 이 화면에서만 유지되며 실제 첨삭·차감은 하지 않습니다.',
      style: AppTokens.caption,
    ),
  );
}

class EssayWorkspacePage extends StatefulWidget {
  const EssayWorkspacePage({
    required this.question,
    this.controller,
    super.key,
  });
  final EssayQuestion question;
  final EssayController? controller;
  @override
  State<EssayWorkspacePage> createState() => _EssayWorkspacePageState();
}

class _EssayWorkspacePageState extends State<EssayWorkspacePage> {
  late final EssayController c;
  late final TextEditingController editor;
  final problemScroll = ScrollController();
  final passageKeys = <GlobalKey>[];
  Timer? ticker;
  DateTime started = DateTime.now();
  bool problem = false, timed = false;
  @override
  void initState() {
    super.initState();
    c =
        widget.controller ??
        EssayController(PreviewEssayGateway(), initialBody: previewAnswer);
    editor = TextEditingController(text: c.body);
    passageKeys.addAll(widget.question.passages.map((_) => GlobalKey()));
    c.addListener(refresh);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ticker?.cancel();
    c.removeListener(refresh);
    if (widget.controller == null) c.dispose();
    editor.dispose();
    problemScroll.dispose();
    super.dispose();
  }

  String get timerText {
    final elapsed = DateTime.now().difference(started).inSeconds;
    final seconds = timed
        ? ((widget.question.examMinutes! * 60 - elapsed).clamp(0, 999999))
        : elapsed;
    return '${timed ? '남은' : '경과'} ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  bool get writing =>
      c.stage == EssayStage.writing || c.stage == EssayStage.revising;
  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.stage == EssayStage.revising ? '다시 써보기' : '논술 첨삭'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${q.university} · ${q.exam}', style: AppTokens.caption),
                const SizedBox(height: 4),
                Text(q.title, style: AppTokens.cardTitle),
                const SizedBox(height: 8),
                const Text(
                  '미리보기 · 이 화면을 나가면 작성 내용이 사라져요.',
                  style: AppTokens.caption,
                ),
                if (writing)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          '${c.body.runes.length}자 · 공백 포함',
                          style: AppTokens.cardTitle,
                        ),
                        Semantics(
                          label: '작성 시간',
                          child: Text(timerText, style: AppTokens.secondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTokens.textPrimary),
          Expanded(
            child: writing
                ? LayoutBuilder(
                    builder: (context, box) {
                      if (box.maxWidth >= 900 &&
                          MediaQuery.textScalerOf(context).scale(1) < 1.8) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 42, child: _questionPane()),
                            const VerticalDivider(
                              width: 1,
                              color: AppTokens.textPrimary,
                            ),
                            Expanded(flex: 58, child: _answerPane()),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  label: Text('문제'),
                                  icon: Icon(Icons.article_outlined),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('답안'),
                                  icon: Icon(Icons.edit_outlined),
                                ),
                              ],
                              selected: {problem},
                              onSelectionChanged: (v) =>
                                  setState(() => problem = v.first),
                            ),
                          ),
                          Expanded(
                            child: problem ? _questionPane() : _answerPane(),
                          ),
                        ],
                      );
                    },
                  )
                : _statusOrResult(),
          ),
        ],
      ),
    );
  }

  Widget _questionPane() {
    final q = widget.question;
    return SingleChildScrollView(
      controller: problemScroll,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '화면 검토용 창작 문제 · 실제 대학 기출이 아닙니다.',
            style: AppTokens.caption,
          ),
          const SectionHeader('문제'),
          SelectableText(q.prompt, style: AppTokens.body.copyWith(height: 1.8)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < q.passages.length; i++)
                ActionChip(
                  label: Text(q.passages[i].label),
                  onPressed: () {
                    final target = passageKeys[i].currentContext;
                    if (target != null) {
                      Scrollable.ensureVisible(
                        target,
                        duration: const Duration(milliseconds: 180),
                      );
                    }
                  },
                ),
            ],
          ),
          for (var i = 0; i < q.passages.length; i++)
            Column(
              key: passageKeys[i],
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader('제시문 ${q.passages[i].label}'),
                SelectableText(
                  q.passages[i].body,
                  style: AppTokens.body.copyWith(height: 1.9),
                ),
              ],
            ),
          if (q.figureUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.network(
                q.figureUrl.toString(),
                semanticLabel: '문항에 포함된 참고 도표',
                errorBuilder: (_, _, _) =>
                    const Text('도표를 불러오지 못했어요. 원문 자료를 확인해 주세요.'),
              ),
            ),
          const SectionHeader('작성 안내'),
          Text(
            q.minLength == null
                ? '분량 미확인'
                : '${q.minLength}~${q.maxLength}자 · 표시 예시',
          ),
          Text(
            q.examMinutes == null
                ? '시험시간 미확인'
                : '시험 전체 ${q.examMinutes}분 · 문항별 시간이 아닙니다.',
          ),
          const SectionHeader('평가 근거 · 출처'),
          Text('${q.origin.label} · 표시 예시', style: AppTokens.secondary),
          if (q.officialSource != null)
            ExternalLinkButton(
              uri: q.officialSource,
              label: '출처 · ${q.university} 입학처 / 원문 자료 보기',
            )
          else
            const Text('가상 자료이므로 연결할 공식 원문이 없습니다.', style: AppTokens.caption),
          if (q.resourceUrl != null)
            ExternalLinkButton(uri: q.resourceUrl, label: '원문 PDF 보기'),
        ],
      ),
    );
  }

  Widget _answerPane() => SingleChildScrollView(
    key: const ValueKey('answer-scroll'),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.question.examMinutes != null)
              TextButton(
                onPressed: () => setState(() {
                  timed = !timed;
                  started = DateTime.now();
                }),
                child: Text(timed ? '연습 모드로' : '실전 모드로'),
              ),
          ],
        ),
        if (timed)
          const Text(
            '시험 전체 시간 기준입니다. 앱을 잠시 떠나도 시간이 흐르며 자동 제출하지 않습니다.',
            style: AppTokens.caption,
          ),
        Semantics(
          liveRegion: true,
          child: Text(switch (c.draftStatus) {
            DraftStatus.saved => '저장됨 · 미리보기 세션',
            DraftStatus.saving => '저장 중...',
            DraftStatus.conflict => '다른 기기에서 더 최근에 수정한 내용이 있습니다.',
            DraftStatus.failed => '저장하지 못했어요. 입력한 내용은 그대로 있습니다.',
          }, style: AppTokens.caption),
        ),
        if (c.draftStatus == DraftStatus.failed)
          TextButton(onPressed: c.save, child: const Text('저장 다시 시도')),
        if (c.draftStatus == DraftStatus.conflict) ...[
          const Text(
            '내가 작성한 내용은 아래에 남아 있어요. 복사하거나 최신 내용과 비교한 뒤 선택해 주세요.',
            style: AppTokens.secondary,
          ),
          OutlinedButton(
            onPressed: _reviewConflict,
            child: const Text('최신 내용과 비교'),
          ),
        ],
        if (c.stage == EssayStage.revising) ...[
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('내 첫 답안'),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SelectableText(c.firstAnswer),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('이번에 확인할 것'),
            children: [
              for (final text in c.evaluation?.checklist ?? <String>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_box_outline_blank),
                  title: Text(text),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('essay-editor'),
          controller: editor,
          minLines: 12,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: AppTokens.body.copyWith(height: 1.9),
          onChanged: c.edit,
          decoration: const InputDecoration(
            labelText: '내 답안',
            alignLabelWithHint: true,
            hintText: '먼저 자신의 생각을 써 보세요.',
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '글자 수는 공백을 포함한 입력 기준입니다. 대학별 공식 계산 방식은 별도로 확인해야 해요.',
          style: AppTokens.caption,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed:
              c.body.trim().isEmpty ||
                  c.draftStatus == DraftStatus.conflict ||
                  !widget.question.availability.canEvaluate
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  c.submit();
                },
          child: const Text('제출하고 첨삭 화면 살펴보기'),
        ),
        const SizedBox(height: 8),
        const Text(
          '입력한 글을 평가하지 않습니다. 제출 후에는 미리 준비된 결과 예시가 표시됩니다.',
          style: AppTokens.caption,
        ),
        if (!widget.question.availability.canEvaluate)
          const Text('평가 자료가 준비되지 않아 문제만 확인할 수 있어요.'),
      ],
    ),
  );
  Future<void> _reviewConflict() async {
    final remote = await c.gateway.loadDraft();
    if (!mounted) return;
    final reload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('두 내용을 비교해 주세요'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('내가 작성한 내용'),
              SelectableText(c.body),
              const Divider(),
              const Text('최근 저장된 내용'),
              SelectableText(remote.body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('내 내용 유지'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('최신 내용 불러오기'),
          ),
        ],
      ),
    );
    if (reload == true && mounted) {
      await c.reloadDraft();
      if (mounted) editor.text = c.body;
    }
  }

  Widget _statusOrResult() {
    if (c.stage == EssayStage.processing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: const Text('첨삭 화면 예시를 준비하고 있어요.'),
              ),
              const Text(
                '중복으로 제출하지 않아도 됩니다. 실제 AI 호출은 없습니다.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (c.stage == EssayStage.failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.refresh),
              const SizedBox(height: 16),
              const Text('첨삭 화면을 준비하지 못했어요. 입력한 답안은 그대로 있습니다.'),
              const Text('미리보기에서는 회차권을 차감하지 않습니다.'),
              FilledButton(onPressed: c.submit, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    return EssayResultView(
      evaluation: c.evaluation!,
      question: widget.question,
      comparison: c.stage == EssayStage.comparison,
      onRewrite: () {
        c.rewrite();
        started = DateTime.now();
        setState(() => problem = false);
      },
    );
  }
}

String _levelLabel(int? level) => level != null && level >= 1 && level <= 5
    ? ['크게 보완 필요', '부족', '보완 필요', '대체로 충실', '매우 충실'][level - 1]
    : '판단이 어려워요';

String _levelStars(int? level) => level != null && level >= 1 && level <= 5
    ? '${'★' * level}${'☆' * (5 - level)}'
    : '판단 보류';

// Reading order remains title → status → stars when the trailing group wraps.
Widget _dimensionHeading(BuildContext context, String title, Widget trailing) =>
    LayoutBuilder(
      builder: (context, box) {
        final heading = Text(title, style: AppTokens.cardTitle);
        if (box.maxWidth < 600 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.8) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 8), trailing],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 20),
            trailing,
          ],
        );
      },
    );

Widget _diagnosis(String text) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const ExcludeSemantics(child: Text('▶', style: AppTokens.secondary)),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: AppTokens.body.copyWith(height: 1.6))),
  ],
);

class EssayLevel extends StatelessWidget {
  const EssayLevel(this.level, {super.key});
  final int? level;
  @override
  Widget build(BuildContext context) {
    final valid = level != null && level! >= 1 && level! <= 5;
    final label = _levelLabel(level);
    return Semantics(
      label: valid ? '5단계 중 $level단계, $label' : label,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 8,
          children: [
            Text(label, style: AppTokens.secondary),
            if (valid)
              Text(
                _levelStars(level),
                style: AppTokens.body.copyWith(color: AppTokens.primaryInk),
              ),
          ],
        ),
      ),
    );
  }
}

class EssayResultView extends StatefulWidget {
  const EssayResultView({
    required this.evaluation,
    required this.question,
    required this.comparison,
    required this.onRewrite,
    super.key,
  });
  final EssayEvaluation evaluation;
  final EssayQuestion question;
  final bool comparison;
  final VoidCallback onRewrite;
  @override
  State<EssayResultView> createState() => _EssayResultViewState();
}

class _EssayResultViewState extends State<EssayResultView> {
  bool example = false;
  @override
  void didUpdateWidget(covariant EssayResultView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evaluation != widget.evaluation) example = false;
  }

  Widget section(
    String title,
    List<String> content, {
    bool diagnostic = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(title),
      for (final line in content)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: diagnostic
              ? _diagnosis(line)
              : Text(line, style: AppTokens.body),
        ),
    ],
  );
  Future<void> openExample() async {
    if (!widget.comparison) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('먼저 직접 고쳐 써 볼까요?'),
          content: const Text('첨삭 내용을 반영해 직접 고쳐 쓴 뒤 예시 답안과 비교하면 더 도움이 됩니다.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('직접 다시 써보기'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('그래도 예시 답안 보기'),
            ),
          ],
        ),
      );
      if (!mounted || proceed == null) return;
      if (!proceed) {
        widget.onRewrite();
        return;
      }
    }
    setState(() => example = true);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.evaluation;
    return SingleChildScrollView(
      key: const ValueKey('result-scroll'),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PreviewNotice(),
              const SizedBox(height: 12),
              const Text(
                '아래 내용은 입력한 글의 평가가 아닌 별도로 준비한 표시 예시입니다.',
                style: AppTokens.caption,
              ),
              if (widget.comparison) ...[
                const SectionHeader('무엇이 달라졌나요?'),
                if (!e.comparable)
                  const Text('평가 조건이 달라 직접적인 향상으로 비교하기 어려워요.')
                else ...[
                  for (final entry in e.changes.entries)
                    section(entry.key, entry.value),
                  const SectionHeader('평가 항목 변화'),
                  for (final d in e.dimensions) ...[
                    _dimensionHeading(
                      context,
                      d.label,
                      Semantics(
                        label:
                            '${_levelLabel(d.previousLevel)}에서 ${_levelLabel(d.level)}',
                        child: ExcludeSemantics(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                _levelStars(d.previousLevel),
                                style: AppTokens.body,
                              ),
                              const Text('→'),
                              Text(_levelStars(d.level), style: AppTokens.body),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_levelLabel(d.previousLevel)} → ${_levelLabel(d.level)}',
                      style: AppTokens.secondary,
                    ),
                    const SizedBox(height: 8),
                    _diagnosis(d.explanation),
                    const SizedBox(height: 20),
                  ],
                ],
                const Divider(color: AppTokens.textPrimary),
              ],
              section('종합 평가', [e.summary], diagnostic: true),
              section('잘한 점', e.strengths, diagnostic: true),
              const SectionHeader('평가 항목별 진단'),
              const Text(
                '별은 평가 기준의 충족 정도를 설명하며, 대학의 공식 점수가 아닙니다.',
                style: AppTokens.caption,
              ),
              for (final d in e.dimensions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dimensionHeading(context, d.label, EssayLevel(d.level)),
                      if (d.officialWeight != null)
                        Text(
                          '대학 공식 배점 비중 ${d.officialWeight}% · 별 단계와 별개',
                          style: AppTokens.caption,
                        ),
                      const SizedBox(height: 8),
                      _diagnosis(d.explanation),
                      const Divider(),
                    ],
                  ),
                ),
              section('보완할 점', e.improvements, diagnostic: true),
              section('먼저 고쳐야 할 부분', e.priorities, diagnostic: true),
              section('다시 쓸 때 확인할 것', e.checklist, diagnostic: true),
              section('평가 근거', [
                '${widget.question.origin.label} · 표시 예시',
                '가상 제시문과 문제 요구를 바탕으로 구성한 화면 검토 자료입니다.',
              ]),
              if (widget.question.officialSource != null)
                ExternalLinkButton(
                  uri: widget.question.officialSource,
                  label: '대학 공식 자료 보기',
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onRewrite,
                child: const Text('다시 써보기'),
              ),
              if (e.includedRevision)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '첫 재첨삭은 추가 차감 없이 이용할 수 있어요.\n이 화면의 안내는 이용 권한 표시 예시입니다.',
                    style: AppTokens.caption,
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: example
                    ? () => setState(() => example = false)
                    : openExample,
                child: Text(example ? '예시 답안 접기' : '첨삭을 반영한 예시답안 보기'),
              ),
              if (example) ...[
                const SectionHeader('첨삭을 반영한 예시 답안 · AI 생성'),
                const Text(
                  'AI가 첨삭 내용을 반영해 만든 예시이며, 대학의 공식 답안이 아닙니다.\n실제 서비스에 표시할 안내 문구입니다. 현재 본문은 화면 검토용 창작 예시입니다.',
                  style: AppTokens.caption,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  e.example,
                  style: AppTokens.body.copyWith(height: 1.8),
                ),
                const SizedBox(height: 16),
                const Text(
                  '정답처럼 외우기보다는 자신의 답안을 다시 작성할 때 참고해 보세요.',
                  style: AppTokens.secondary,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
