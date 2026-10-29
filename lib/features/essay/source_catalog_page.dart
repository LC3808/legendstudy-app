import 'result_disclosure.dart';
import 'exam_presentation.dart';
import 'exam_session_status.dart';
import 'exam_session_store.dart';
import 'exam_rewrite.dart';
import 'exam_draft_actions.dart';
import 'answer_sections.dart';

import 'package:flutter/cupertino.dart';

import 'answer_ocr.dart';
import '../credits/essay_credit_source.dart';
import 'service_availability.dart';
import 'math_gateway.dart';
import 'math_exam_session.dart';
import '../../core/theme/app_theme.dart';
import '../credits/credit_balance.dart';

import 'dart:async';
import 'dart:convert';

import 'exam_submission.dart';
import 'shared_history_page.dart';
import 'shared_history.dart';

import 'dart:typed_data';

import 'answer_image.dart';
import 'question_pdf.dart';

import '../../core/links/external_link.dart';
import '../../shared/widgets/shell_widgets.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'source_catalog.dart';
import 'source_draft.dart';
import 'essay_live_gateway.dart';
import 'essay_controller.dart';
import 'essay_models.dart';

class SourceCatalogPage extends ConsumerWidget {
  const SourceCatalogPage({
    super.key,
    this.catalog,
    this.rewriteRun,
    this.rewriteOwner,
  });
  final String? rewriteOwner;
  final Future<SourceCatalog>? catalog;
  final Map<String, dynamic>? rewriteRun;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.hasError) {
      return const Scaffold(
        body: Center(child: Text('로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.')),
      );
    }
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Keep the Hero balance cached while selecting an exam, so returning
    // does not replace its content with a shorter loading state.
    ref.watch(creditBalanceProvider);
    final owner = auth.value?.userId ?? 'guest';
    // Keep card admission/height stable across university navigation.
    ref.watch(publicServiceUniversitiesProvider(owner));
    if (rewriteRun != null && rewriteOwner != owner) {
      return const Scaffold(
        body: Center(child: Text('계정이 변경됐어요. 본인의 첨삭 기록에서 다시 열어 주세요.')),
      );
    }
    return _SourceSelection(
      key: ValueKey(owner),
      owner: owner,
      catalog: catalog,
      rewriteRun: rewriteRun,
      loadCatalog: (university) async {
        Future<SourceCatalog> load(String? university) => SourceCatalog.load(
          university: university,
          browse: (id) async {
            final client = ref.read(supabaseClientProvider);
            if (client == null) throw StateError('Catalog unavailable');
            return client.rpc(
              'essay_browse_catalog',
              params: {'p_university': id},
            );
          },
          accessToken: ref
              .read(supabaseClientProvider)
              ?.auth
              .currentSession
              ?.accessToken,
        );
        if (rewriteRun == null) return load(university);
        final restored = await SourceCatalog.forHistory(rewriteRun!, load);
        for (final exam in restored.exams) {
          for (final q
              in (exam['questions'] as List).cast<Map<String, dynamic>>()) {
            if (ref.read(authStateProvider).value?.userId != owner) {
              throw StateError('ACCOUNT_CHANGED');
            }
            await recoverIncludedEssayDraft(
              owner,
              exam['key'] as String,
              q['key'] as String,
              rewriteRun!,
            );
          }
        }
        return restored;
      },
    );
  }
}

class _SourceSelection extends ConsumerStatefulWidget {
  const _SourceSelection({
    super.key,
    required this.owner,
    required this.loadCatalog,
    this.catalog,
    this.rewriteRun,
    this.initialUniversity,
    this.selectionMemory,
  });
  final Map<String, _SelectionSnapshot>? selectionMemory;
  final String? initialUniversity;
  final Map<String, dynamic>? rewriteRun;
  final String owner;
  final Future<SourceCatalog> Function(String?) loadCatalog;
  final Future<SourceCatalog>? catalog;
  @override
  ConsumerState<_SourceSelection> createState() => _SourceSelectionState();
}

class _SelectionSnapshot {
  _SelectionSnapshot(
    this.year,
    this.kind,
    this.track,
    this.examKey,
    this.included,
  );
  final String? year, kind, track, examKey;
  final Map<String, Set<String>> included;
}

class _SourceSelectionState extends ConsumerState<_SourceSelection> {
  late Future<SourceCatalog> data =
      widget.catalog ?? widget.loadCatalog(university);
  final included = <String, Set<String>>{};
  late final selectionMemory =
      widget.selectionMemory ?? <String, _SelectionSnapshot>{};
  bool pushingUniversity = false;
  late String? university = widget.initialUniversity;
  String? year, kind, track, examKey;
  final catalogScroll = ScrollController();
  double catalogOffset = 0;
  @override
  void initState() {
    super.initState();
    restoreSelection();
  }

  void saveSelection() {
    if (university != null) {
      selectionMemory[university!] = _SelectionSnapshot(
        year,
        kind,
        track,
        examKey,
        {
          for (final e in included.entries) e.key: {...e.value},
        },
      );
    }
  }

  void restoreSelection() {
    final saved = selectionMemory[university];
    year = saved?.year;
    kind = saved?.kind;
    track = saved?.track;
    examKey = saved?.examKey;
    included.clear();
    if (saved != null) {
      included.addAll({
        for (final e in saved.included.entries) e.key: {...e.value},
      });
    }
  }

  void selectUniversity(String id) {
    if (pushingUniversity) return;
    if (university == null) {
      final page = _SourceSelection(
        owner: widget.owner,
        catalog: widget.catalog,
        loadCatalog: widget.loadCatalog,
        initialUniversity: id,
        selectionMemory: selectionMemory,
      );
      pushingUniversity = true;
      Navigator.of(context)
          .push<void>(
            Theme.of(context).platform == TargetPlatform.iOS
                ? CupertinoPageRoute(builder: (_) => page)
                : MaterialPageRoute(builder: (_) => page),
          )
          .whenComplete(() => pushingUniversity = false);
      return;
    }
    saveSelection();
    setState(() {
      university = id;
      restoreSelection();
      if (widget.catalog == null) data = widget.loadCatalog(id);
    });
  }

  void backToCatalog() {
    if (widget.initialUniversity != null) {
      saveSelection();
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      university = null;
      year = kind = track = examKey = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (catalogScroll.hasClients) {
        catalogScroll.jumpTo(
          catalogOffset.clamp(0, catalogScroll.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    saveSelection();
    catalogScroll.dispose();
    super.dispose();
  }

  Widget choice(
    String label,
    String? value,
    List<String> options,
    void Function(String?) change, {
    Map<String, String>? labels,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label:$value:${options.join()}'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final x in options)
          DropdownMenuItem(value: x, child: Text(labels?[x] ?? x)),
      ],
      onChanged: options.isEmpty || widget.rewriteRun != null ? null : change,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading ||
        auth.hasError ||
        (auth.value?.userId ?? 'guest') != widget.owner) {
      return const Scaffold(body: Center(child: Text('로그인 상태를 확인해 주세요.')));
    }
    return buildSelection(context);
  }

  Widget buildSelection(BuildContext context) => PopScope(
    canPop:
        university == null ||
        widget.rewriteRun != null ||
        widget.initialUniversity != null,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) {
        saveSelection();
      } else {
        backToCatalog();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(university == null ? '논술 LAB' : '시험 선택'),
        leading: university != null && widget.rewriteRun == null
            ? IconButton(
                tooltip: '대학 목록',
                icon: const Icon(Icons.arrow_back),
                onPressed: backToCatalog,
              )
            : null,
        actions: [
          if (university != null)
            TextButton.icon(
              label: const Text('나의 첨삭 기록'),
              icon: const Icon(Icons.history),
              onPressed: () => context.push('/lab/essay/history'),
            ),
        ],
      ),
      body: FutureBuilder<SourceCatalog>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => data = widget.loadCatalog(university)),
                child: const Text('문항을 불러오지 못했어요. 다시 확인'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snapshot.data!;
          if (widget.rewriteRun != null && university == null) {
            final matched = c.exams
                .where((e) => e['dbExamId'] == widget.rewriteRun!['exam_id'])
                .firstOrNull;
            if (matched == null) {
              return const Center(
                child: Text('이 시험의 작성 자료를 확인하지 못했어요. 기존 첨삭 기록은 보존됩니다.'),
              );
            }
            university = matched['sourceUniversityId'] as String;
            year = '${matched['year']}';
            kind = matched['kind'] as String;
            track = matched['track'] as String;
            examKey = matched['key'] as String;
            included[examKey!] = (matched['questions'] as List)
                .cast<Map<String, dynamic>>()
                .where(
                  (q) => (widget.rewriteRun!['question_ids'] as List).contains(
                    q['dbQuestionId'],
                  ),
                )
                .map((q) => q['key'] as String)
                .toSet();
          }
          if (university == null) {
            final service = ref.watch(
              publicServiceUniversitiesProvider(widget.owner),
            );
            final ready = service.isLoading || service.hasError
                ? <String>{}
                : service.asData?.value ?? <String>{};
            return ListView(
              key: const PageStorageKey('essay-university-list'),
              controller: catalogScroll,
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Builder(
                          builder: (context) {
                            TextButton menu(String label, String route) =>
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTokens.space8,
                                    ),
                                    minimumSize: const Size(0, 44),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppTokens.textPrimary,
                                  ),
                                  onPressed: () => context.push(route),
                                  child: Text(label),
                                );
                            final history = menu(
                              '나의 첨삭 기록 ›',
                              '/lab/essay/history',
                            );
                            final lab = menu('나의 논술랩 ›', '/lab/essay/growth');
                            final balance = ref
                                .watch(creditBalanceProvider)
                                .value;
                            // 서버 잔액만 사용하고 조회 전에는 임의 숫자를 보이지 않는다.
                            final Widget credit = balance == null
                                ? const SizedBox.shrink()
                                : Text(
                                    '현재 크레딧 ${balance.spendable}개',
                                    style: AppTokens.secondary.copyWith(
                                      color: AppTokens.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                            // 세 항목을 한 줄로: 왼쪽 메뉴 그룹 + 오른쪽 현재 크레딧.
                            // 아주 큰 글자 배율에서는 접근성을 위해 2행 세로 배치로
                            // 떨어뜨리고, 그 외 모바일 폭에서는 FittedBox로 균일
                            // 축소해 가로 넘침·글자 잘림을 방지한다.
                            return MediaQuery.textScalerOf(context).scale(14) >
                                    22
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      history,
                                      lab,
                                      const SizedBox(height: AppTokens.space8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: credit,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [history, lab],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTokens.space8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: credit,
                                      ),
                                    ],
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (service.isLoading) const Text('서비스 확인 중'),
                if (service.hasError)
                  TextButton(
                    onPressed: () => ref.invalidate(
                      publicServiceUniversitiesProvider(widget.owner),
                    ),
                    child: const Text('일시적으로 확인할 수 없습니다 · 다시 시도'),
                  ),
                for (final u in orderedServiceUniversities(c, ready))
                  Card(
                    child: InkWell(
                      onTap: ready.contains(u['universityId'])
                          ? () {
                              catalogOffset = catalogScroll.offset;
                              selectUniversity(
                                u['sourceUniversityId'] as String,
                              );
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 100,
                              height: 52,
                              padding: EdgeInsets.all(
                                const {
                                      'skku',
                                      'uos',
                                    }.contains(u['sourceUniversityId'])
                                    ? 0
                                    : 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: u['logoAsset'] is String
                                  ? Image.asset(
                                      u['logoAsset'] as String,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) =>
                                          const SizedBox.shrink(),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u['name'] as String,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (ready.contains(u['universityId']))
                              const Icon(
                                Icons.chevron_right,
                                color: AppTokens.textPrimary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
          final uni = university;
          final rows = c.exams
              .where((e) => e['sourceUniversityId'] == uni)
              .toList();
          final periods =
              rows.map((e) => "${e['year']}:${e['kind']}").toSet().toList()
                ..sort((a, b) {
                  final yearOrder = b
                      .split(':')
                      .first
                      .compareTo(a.split(':').first);
                  return yearOrder != 0 ? yearOrder : a.compareTo(b);
                });
          final period = year != null && kind != null
              ? '$year:$kind'
              : (periods.length == 1 ? periods.single : null);
          final kr = rows
              .where((e) => "${e['year']}:${e['kind']}" == period)
              .toList();
          final tracks = kr.map((e) => e['track'] as String).toSet().toList();
          final t = track ?? (tracks.length == 1 ? tracks.first : null);
          final exams = kr.where((e) => e['track'] == t).toList();
          final selected =
              examKey ??
              (exams.length == 1 ? exams.first['key'] as String : null);
          final matches = exams.where((e) => e['key'] == selected);
          final exam = matches.isEmpty ? null : matches.single;
          final questions = (exam?['questions'] as List? ?? [])
              .cast<Map<String, dynamic>>()
              .where(
                (q) =>
                    widget.rewriteRun == null ||
                    (widget.rewriteRun!['question_ids'] as List).contains(
                      q['dbQuestionId'],
                    ),
              )
              .toList();
          final selection = exam == null
              ? <String>{}
              : included.putIfAbsent(
                  exam['key'] as String,
                  () => questions.length == 1
                      ? {questions.single['key'] as String}
                      : <String>{},
                );
          final reviewDraftAvailable =
              selection.isNotEmpty &&
              questions
                  .where((q) => selection.contains(q['key']))
                  .every(
                    (q) =>
                        QuestionPdfAsset.parse(
                          q['studentPdf'],
                          q['dbQuestionId'] as String? ?? '',
                        ) !=
                        null,
                  );
          final ownedHistory =
              widget.rewriteRun != null &&
              exam?['historyRunId'] == widget.rewriteRun!['id'];
          final writingBlocked =
              !ownedHistory &&
              (isUniversityServicePreparing(uni) ||
                  (exam?['verification'] == 'REVIEW_REQUIRED' &&
                      !reviewDraftAvailable));
          // 첨삭 공개 보류(준비 중) 판정은 대학·계열 이름이나 inputMode(browse 투영에
          // 없어 누락됨)가 아니라, 서버의 서비스 가능 시험 집합(service-status)을
          // 기준으로 한다. 들어갈 수 있는(대학 보류·REVIEW_REQUIRED 아님) 시험인데
          // 서비스 가능 집합에 없으면 아직 첨삭이 공개되지 않은 것이므로, 문항 선택·
          // 작성 전에 준비 중 안내를 표시한다. 집합을 아직 받지 못했으면(로딩/오류)
          // 거짓양성을 피하려 표시하지 않는다. 안내는 비차단 정보이므로 공개된 TEXT
          // 문항의 작성·제출을 막지 않는다.
          final serviceExams = ref.watch(serviceExamIdsProvider(widget.owner));
          final feedbackPreparing =
              exam != null &&
              !writingBlocked &&
              exam['dbExamId'] is String &&
              serviceExams.hasValue &&
              !serviceExams.value!.contains(exam['dbExamId']);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.rewriteRun != null)
                const Text('다시 써보기 · 최초 제출 문항을 유지합니다.'),
              if (c.browseUnavailable)
                const Text('등록 자료 조회를 준비하고 있습니다. 현재 목록은 기존 공개 자료입니다.'),
              if (rows.isEmpty) const Text('이 대학의 시험 자료를 준비하고 있어요.'),
              choice(
                '대학',
                uni,
                c.universities
                    .map((u) => u['sourceUniversityId'] as String)
                    .toList(),
                (v) {
                  if (v != null) selectUniversity(v);
                },
                labels: {
                  for (final u in c.universities)
                    u['sourceUniversityId'] as String: u['name'] as String,
                },
              ),
              choice(
                '학년도·시험',
                period,
                periods,
                (v) => setState(() {
                  year = v?.split(':').first;
                  kind = v?.split(':').last;
                  track = examKey = null;
                }),
                labels: {
                  for (final p in periods)
                    p: '${p.split(':').first}학년도 ${p.endsWith(':mock') ? '모의논술' : '수시논술'}',
                },
              ),
              choice(
                '계열',
                t,
                tracks,
                (v) => setState(() {
                  track = v;
                  examKey = null;
                }),
              ),
              if (exams.length > 1)
                choice(
                  '캠퍼스 · 회차',
                  selected,
                  exams.map((e) => e['key'] as String).toList(),
                  (v) => setState(() => examKey = v),
                  labels: {
                    for (final e in exams)
                      e['key'] as String: [
                        e['campus'],
                        e['session'],
                      ].whereType<String>().join(' · '),
                  },
                ),
              if (exam != null) ...[
                Text(essayServiceAreaLabel(exam)),
                if (feedbackPreparing) const _ServicePreparingNotice(),
                if (isUniversityServicePreparing(uni) ||
                    exam['verification'] == 'REVIEW_REQUIRED')
                  for (final u in c.universities.where(
                    (u) => u['sourceUniversityId'] == uni,
                  ))
                    if (u['officialSourceUrl'] is String)
                      ExternalLinkButton(
                        uri: Uri.tryParse(u['officialSourceUrl'] as String),
                        label: '공식 입학처 자료 확인 ↗',
                      ),
                const Text('문항 선택'),
                for (final q in questions)
                  CheckboxListTile(
                    title: Text(q['label'] as String),
                    secondary: _BrowseQuestionPdfButton(question: q),
                    subtitle: q['lengthLabel'] == null
                        ? null
                        : Text(q['lengthLabel'] as String),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppTokens.textPrimary,
                    checkColor: Colors.white,
                    value: selection.contains(q['key']),
                    onChanged: widget.rewriteRun != null
                        ? null
                        : (checked) => setState(() {
                            if (checked == true) {
                              selection.add(q['key'] as String);
                            } else {
                              selection.remove(q['key']);
                            }
                          }),
                  ),
                Text('선택한 문항 ${selection.length}개'),
                if (writingBlocked || selection.isEmpty)
                  FilledButton(
                    onPressed: null,
                    child: Text(
                      !ownedHistory && isUniversityServicePreparing(uni)
                          ? '서비스 준비중'
                          : selection.isEmpty
                          ? '문제 선택'
                          : '첨삭 서비스 준비 중',
                    ),
                  )
                else
                  ExamDraftActions(
                    key: ValueKey(
                      '${widget.owner}:${exam['key']}:${(selection.toList()..sort()).join(',')}',
                    ),
                    owner: widget.owner,
                    rewriteRun: widget.rewriteRun,
                    questions: questions
                        .where((q) => selection.contains(q['key']))
                        .toList(),
                    onWrite: () async {
                      final u = c.universities.firstWhere(
                        (u) => u['sourceUniversityId'] == uni,
                      );
                      await Navigator.of(
                        context,
                        rootNavigator: true,
                      ).push<void>(
                        MaterialPageRoute(
                          builder: (_) => _SelectedAnswerWriter(
                            owner: widget.owner,
                            questions: questions
                                .where((q) => selection.contains(q['key']))
                                .toList(),
                            exam: {...exam, 'universityName': u['name']},
                            universityName: u['name'] as String?,
                            rewriteRun: widget.rewriteRun,
                            officialUrl: u['officialSourceUrl'] as String?,
                          ),
                        ),
                      );
                    },
                    onReview: () async {
                      final u = c.universities.firstWhere(
                        (u) => u['sourceUniversityId'] == uni,
                      );
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ExamAnswerReview(
                          owner: widget.owner,
                          exam: {...exam, 'universityName': u['name']},
                          currentQuestion: selection.first,
                          selectedQuestions: {...selection},
                          rewriteRun: widget.rewriteRun,
                        ),
                      );
                    },
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

// Keep each selected question's existing writer and Draft alive when switching.
class _SelectedAnswerWriter extends StatefulWidget {
  const _SelectedAnswerWriter({
    required this.owner,
    required this.questions,
    required this.exam,
    this.universityName,
    this.officialUrl,
    this.rewriteRun,
  });
  final String owner;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> exam;
  final String? universityName, officialUrl;
  final Map<String, dynamic>? rewriteRun;
  @override
  State<_SelectedAnswerWriter> createState() => _SelectedAnswerWriterState();
}

class _SelectedAnswerWriterState extends State<_SelectedAnswerWriter> {
  // The single expanded question (0 = 문제 1 on entry); -1 = all collapsed.
  int current = 0;
  final Map<String, bool> written = {};

  String get _examMeta => essayExamTitle(widget.exam);

  @override
  Widget build(BuildContext context) {
    if (widget.rewriteRun == null &&
        isUniversityServicePreparing(widget.exam['sourceUniversityId'])) {
      return Scaffold(
        appBar: AppBar(title: const Text('자료 조회')),
        body: Column(
          children: [
            const FilledButton(onPressed: null, child: Text('서비스 준비중')),
            if (widget.officialUrl != null)
              ExternalLinkButton(
                uri: Uri.tryParse(widget.officialUrl!),
                label: '공식 입학처 자료 확인 ↗',
              ),
          ],
        ),
      );
    }
    final questions = widget.questions;
    return Scaffold(
      appBar: AppBar(title: Text(widget.universityName ?? '답안 작성')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space20,
            AppTokens.space16,
            AppTokens.space20,
            AppTokens.space24,
          ),
          children: [
            if (_examMeta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space12),
                child: Text(
                  _examMeta,
                  style: AppTokens.secondary.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
            for (var i = 0; i < questions.length; i++)
              _AccordionItem(
                key: ValueKey('panel-${questions[i]['key']}'),
                title: questions[i]['label'] as String,
                expanded: current == i,
                written: written[questions[i]['key'] as String] ?? false,
                // One panel open at a time; tapping the open one collapses it.
                onTap: () => setState(() => current = current == i ? -1 : i),
                child: _SourceWriter(
                  key: ValueKey(questions[i]['key']),
                  owner: widget.owner,
                  question: questions[i],
                  exam: widget.exam,
                  universityName: widget.universityName,
                  officialUrl: widget.officialUrl,
                  rewriteRun: widget.rewriteRun,
                  selectedQuestions: questions,
                  onContentChanged: (has) {
                    if (mounted) {
                      setState(
                        () => written[questions[i]['key'] as String] = has,
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One accordion question: a touchable header (문항 번호 + concise completion
/// mark) over a body that stays mounted — so each question's answer, drafts and
/// photos are preserved while switching — and is only shown while expanded.
class _AccordionItem extends StatelessWidget {
  const _AccordionItem({
    super.key,
    required this.title,
    required this.expanded,
    required this.written,
    required this.onTap,
    required this.child,
  });
  final String title;
  final bool expanded, written;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
              if (written) ...[
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppTokens.success,
                ),
                const SizedBox(width: AppTokens.space8),
              ],
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: AppTokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
      Offstage(
        offstage: !expanded,
        child: TickerMode(enabled: expanded, child: child),
      ),
      const Divider(height: 1),
    ],
  );
}

String essayWritingDraftKey(String question, Map<String, dynamic>? run) =>
    run == null
    ? question
    : '$question:${run['_additional'] == true ? 'additional' : 'rewrite'}:${run['id']}';

/// Calm red "service preparing" banner shown above the answer area when a
/// photo/math (수리·자연논술) question's feedback is not yet published. Keeps the
/// existing navy/grey system; red is reserved for this held-service notice.
class _ServicePreparingNotice extends StatelessWidget {
  const _ServicePreparingNotice();
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '첨삭 서비스 준비 중 안내',
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppTokens.space8),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEE),
        border: Border.all(color: AppTokens.danger),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, size: 18, color: AppTokens.dangerInk),
              SizedBox(width: AppTokens.space8),
              Expanded(
                child: Text(
                  '첨삭 서비스 준비 중',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.dangerInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space8),
          Text(
            '선택한 시험의 첨삭 공개 상태를 준비하고 있습니다. '
            '첨삭 서비스는 준비가 완료되면 제공됩니다.',
            style: AppTokens.body.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    ),
  );
}

class _SourceWriter extends ConsumerStatefulWidget {
  const _SourceWriter({
    super.key,
    required this.selectedQuestions,
    this.onContentChanged,
    this.rewriteRun,
    required this.owner,
    required this.question,
    required this.exam,
    this.officialUrl,
    this.universityName,
  });
  final Map<String, dynamic>? rewriteRun;
  final String owner;
  final String? officialUrl, universityName;
  final Map<String, dynamic> question, exam;
  final List<Map<String, dynamic>> selectedQuestions;

  /// Reports whether this question now has written content (text or photo), so
  /// the accordion header can show a concise completion mark. Content-presence
  /// only; never the saved/submitted state.
  final ValueChanged<bool>? onContentChanged;
  @override
  ConsumerState<_SourceWriter> createState() => _SourceWriterState();
}

class _SourceWriterState extends ConsumerState<_SourceWriter> {
  List<Uint8List> photo = [];
  bool imageReady = false, imageSaving = false, imageDirty = false;
  String? photoNotice;
  // Manual "임시저장" feedback, kept separate from the passive auto-save state so
  // a "저장됨" message never shows before the student presses the button, and is
  // cleared as soon as the answer is edited again.
  bool manualSaving = false;
  String? manualSaveNotice;
  late final draft = SourceDraftGateway(
    widget.owner,
    essayWritingDraftKey(widget.question['key'] as String, widget.rewriteRun),
    remote:
        widget.rewriteRun == null &&
            widget.exam['verification'] != 'REVIEW_REQUIRED' &&
            widget.owner != 'guest' &&
            widget.question['dbQuestionId'] is String &&
            widget.question['accountDraftReady'] != false &&
            ref.read(supabaseClientProvider) != null
        ? SupabaseEssayGateway(
            SupabaseEssayStore(ref.read(supabaseClientProvider)!),
            questionId: widget.question['dbQuestionId'] as String,
            writesEnabled: true,
          )
        : null,
  );
  Future<void> savePhoto(List<Uint8List> bytes) async {
    setState(() {
      photo = bytes;
      imageSaving = true;
      imageDirty = true;
    });
    try {
      await draft.saveImages(bytes);
      if (mounted) {
        setState(() {
          imageDirty = false;
          photoNotice = '사진: 이 기기에 임시 저장됨';
        });
      }
    } catch (_) {
      if (mounted) setState(() => photoNotice = '사진을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => imageSaving = false);
      _notifyContent();
    }
  }

  /// Explicit button save (text draft + any dirty photo). Reports its own
  /// success/failure feedback below the button; the underlying auto-save and
  /// save/restore contracts are unchanged.
  Future<void> saveManually() async {
    final ctrl = controller;
    if (ctrl == null || manualSaving || syncBusy) return;
    setState(() {
      manualSaving = true;
      manualSaveNotice = null;
    });
    try {
      await ctrl.save();
      if (imageDirty && !imageSaving) await savePhoto(photo);
      if (!mounted) return;
      final saved = ctrl.draftStatus == DraftStatus.saved;
      setState(() {
        manualSaveNotice = !saved
            ? '저장하지 못했어요. 다시 시도해 주세요.'
            : (draft.remote != null &&
                  !draft.syncConflict &&
                  draft.remoteBody == ctrl.body)
            ? '계정에 임시 저장됨'
            : '이 기기에 임시 저장됨';
      });
    } catch (_) {
      if (mounted) {
        setState(() => manualSaveNotice = '저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => manualSaving = false);
    }
  }

  late final pdfPosition = SourceDraftGateway(
    widget.owner,
    'pdf:${widget.question['key']}:${widget.question['studentPdf']}',
  );
  int pdfRevision = 0;
  Future<void> pdfWrite = Future<void>.value();
  Future<int?> restorePdfPage() async {
    final d = await pdfPosition.loadDraft();
    pdfRevision = d.revision;
    return int.tryParse(d.body);
  }

  Future<void> savePdfPage(int page) {
    pdfWrite = pdfWrite.catchError((Object _) {}).then((_) async {
      final d = await pdfPosition.saveLocalDraft('$page', pdfRevision);
      pdfRevision = d.revision;
    });
    return pdfWrite;
  }

  EssayController? controller;
  final editor = TextEditingController();
  String? error;
  bool showOptionalImage = false, syncBusy = false;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final g = draft;
      var d = await g.openSharedDraft();
      var image = await g.loadImages();
      if (widget.rewriteRun != null &&
          d.revision == 0 &&
          d.body.isEmpty &&
          image.isEmpty) {
        final old = SourceDraftGateway(
          widget.owner,
          widget.question['key'] as String,
        );
        final legacy = await old.loadDraft();
        final oldImages = await old.loadImages();
        // Preserve unfinished edits; seed only a brand-new draft from owned history.
        final body = legacy.body.isNotEmpty && legacy.body != previousAnswer
            ? legacy.body
            : previousAnswer;
        d = await g.saveLocalDraft(body, d.revision);
        if (oldImages.isNotEmpty) {
          await g.saveImages(oldImages);
          image = oldImages;
        }
      }
      if (mounted) {
        photo = image;
        imageReady = true;
      }
      if (!mounted) return;
      controller = EssayController(g, initialBody: d.body)
        ..revision = d.revision;
      editor.text = d.body;
      controller!.addListener(refresh);
      setState(() {});
      _notifyContent();
    } catch (_) {
      if (mounted) setState(() => error = '저장된 답안을 불러오지 못했어요.');
    }
  }

  String get previousAnswer =>
      (widget.rewriteRun?['answers'] as List? ?? [])
              .cast<Map<String, dynamic>>()
              .where((a) => a['questionId'] == widget.question['dbQuestionId'])
              .firstOrNull?['body']
          as String? ??
      '';
  Future<void> importOcr() async {
    final original = editor.text;
    final selection = await Navigator.of(context).push<OcrTextSelection>(
      MaterialPageRoute(
        builder: (_) =>
            AnswerOcrPage(hasAnswer: original.isNotEmpty, owner: widget.owner),
      ),
    );
    if (!mounted ||
        selection == null ||
        controller == null ||
        ref.read(authStateProvider).value?.userId != widget.owner) {
      return;
    }
    if (editor.text != original) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답안이 변경되어 자동 적용하지 않았어요. 다시 확인해 주세요.')),
      );
      return;
    }
    final value = selection.replace || original.isEmpty
        ? selection.text
        : '$original\n\n${selection.text}';
    if (value.length > 30000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('합친 답안이 30,000자를 넘어 적용하지 않았어요.')),
      );
      return;
    }
    editor.text = value;
    controller!.edit(value);
    _notifyContent();
    await controller!.save();
  }

  Future<void> importPrevious() async {
    if (editor.text.isNotEmpty) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('작성 중인 답안을 바꿀까요?'),
          content: const Text('현재 글을 이전 제출 답안으로 교체합니다. 첨부 사진은 유지됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('불러오기'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    editor.text = previousAnswer;
    controller!.edit(editor.text);
    await controller!.save();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void _notifyContent() => widget.onContentChanged?.call(
    editor.text.trim().isNotEmpty || photo.isNotEmpty,
  );

  @override
  void dispose() {
    controller?.removeListener(refresh);
    controller?.dispose();
    editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.hasError ||
        auth.isLoading ||
        (auth.value?.userId ?? 'guest') != widget.owner) {
      return const Scaffold(
        body: Center(child: Text('계정이 변경됐어요. 문항을 다시 열어 주세요.')),
      );
    }
    final c = controller;
    final pdf = QuestionPdfAsset.parse(
      widget.question['studentPdf'],
      widget.question['dbQuestionId'] as String? ?? '',
    );
    final positionKey = 'essay-pdf:${widget.owner}:${pdf?.id}:${pdf?.hash}';
    // The 수리·자연논술 준비 중 안내는 시험·계열 선택 화면(답안 작성 진입 전)에서
    // 노출한다. 작성 화면 내부에서는 중복 표시하지 않는다.
    // Embedded body for the accordion: no Scaffold/AppBar and no 문항 드롭다운
    // (the accordion header carries the question number and switching). The
    // exam/university meta is shown once above the accordion. Each panel keeps
    // its own PopScope so an unsaved answer still blocks a back-gesture.
    return PopScope(
      canPop:
          (c == null || !c.dirty) && !imageSaving && !imageDirty && !syncBusy,
      child: c == null
          ? Padding(
              padding: const EdgeInsets.all(AppTokens.space20),
              child: Text(error ?? '답안을 불러오고 있어요.'),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space16,
                AppTokens.space4,
                AppTokens.space16,
                AppTokens.space16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pdf != null)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_full),
                      label: const Text('문제 보기'),
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).push<void>(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('문제 보기'),
                                  leading: IconButton(
                                    tooltip: '닫기',
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ),
                                body: SafeArea(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) =>
                                        EssayQuestionPdf(
                                          height: constraints.maxHeight,
                                          key: ValueKey(positionKey),
                                          asset: pdf,
                                          load: () async {
                                            final client = ref.read(
                                              supabaseClientProvider,
                                            );
                                            if (client == null ||
                                                client.auth.currentUser?.id !=
                                                    widget.owner) {
                                              throw StateError('로그인 필요');
                                            }
                                            return client.storage
                                                .from(pdf.bucket)
                                                .download('${pdf.id}.pdf');
                                          },
                                          restorePage: restorePdfPage,
                                          savePage: savePdfPage,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                  if (pdf == null && widget.officialUrl != null)
                    ExternalLinkButton(
                      uri: Uri.tryParse(widget.officialUrl!),
                      label: '공식 입학처 자료 확인 ↗',
                    ),
                  ...[
                    if (widget.question['inputMode'] == 'image' ||
                        photo.isNotEmpty ||
                        showOptionalImage) ...[
                      Theme(
                        data: Theme.of(context).copyWith(
                          outlinedButtonTheme: OutlinedButtonThemeData(
                            style: Theme.of(context).outlinedButtonTheme.style
                                ?.copyWith(
                                  side: const WidgetStatePropertyAll(
                                    BorderSide(color: AppTokens.textPrimary),
                                  ),
                                ),
                          ),
                        ),
                        child: AnswerImagesInput(
                          values: photo,
                          enabled: imageReady && !imageSaving,
                          onChanged: savePhoto,
                        ),
                      ),
                      if (imageSaving)
                        const Text('사진 저장 중')
                      else if (photoNotice != null)
                        Text(photoNotice!),
                      if (imageDirty && !imageSaving)
                        TextButton(
                          onPressed: () => savePhoto(photo),
                          child: const Text('사진 저장 다시 시도'),
                        ),
                    ],
                    if (widget.question['inputMode'] != 'image' &&
                        photo.isEmpty &&
                        !showOptionalImage)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => showOptionalImage = true),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('수식·도표 이미지 첨부'),
                      ),
                    if (widget.rewriteRun != null)
                      ExpansionTile(
                        title: const Text('이전 답안 보기'),
                        children: [
                          for (final a
                              in (widget.rewriteRun!['answers'] as List)
                                  .cast<Map<String, dynamic>>()
                                  .where(
                                    (a) =>
                                        a['questionId'] ==
                                        widget.question['dbQuestionId'],
                                  ))
                            SelectableText(a['body'] as String),
                        ],
                      ),
                    if (widget.rewriteRun != null)
                      TextButton(
                        onPressed: syncBusy || previousAnswer.isEmpty
                            ? null
                            : importPrevious,
                        child: const Text('이전 답안 불러오기'),
                      ),
                    if (widget.question['inputMode'] != 'image')
                      TextButton.icon(
                        onPressed: syncBusy ? null : importOcr,
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('사진으로 답안 입력'),
                      ),
                    if (essayAnswerSections(
                      widget.exam['dbExamId'] as String?,
                      widget.question['dbQuestionId'] as String?,
                    ).isNotEmpty)
                      SectionedAnswerInput(
                        controller: editor,
                        labels: essayAnswerSections(
                          widget.exam['dbExamId'] as String?,
                          widget.question['dbQuestionId'] as String?,
                        ),
                        enabled: !syncBusy,
                        onChanged: (value) {
                          c.edit(value);
                          _notifyContent();
                          if (manualSaveNotice != null) {
                            setState(() => manualSaveNotice = null);
                          }
                        },
                      )
                    else
                      TextField(
                        controller: editor,
                        enabled: !syncBusy,
                        minLines: widget.question['inputMode'] == 'image'
                            ? 3
                            : 12,
                        maxLines: null,
                        maxLength: 30000,
                        onChanged: (value) {
                          c.edit(value);
                          _notifyContent();
                          // Editing invalidates the previous manual-save result.
                          if (manualSaveNotice != null) {
                            setState(() => manualSaveNotice = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: widget.question['inputMode'] == 'image'
                              ? '추가 설명 (선택)'
                              : '내 답안',
                          alignLabelWithHint: true,
                        ),
                      ),
                    // 버튼이 먼저, 상태 메시지는 버튼 아래. 기본 회색 테두리,
                    // 누르는 동안 네이비 채움. 누르기 전에는 '저장됨'을 표시하지 않는다.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: manualSaving
                          ? FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTokens.textPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                              ),
                              onPressed: null,
                              icon: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              label: const Text('저장 중…'),
                            )
                          : OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTokens.textPrimary,
                                side: const BorderSide(
                                  color: AppTokens.majorSurfaceBorder,
                                ),
                                minimumSize: const Size(0, 44),
                              ),
                              onPressed:
                                  syncBusy ||
                                      c.draftStatus == DraftStatus.saving
                                  ? null
                                  : saveManually,
                              icon: const Icon(
                                Icons.save_outlined,
                                size: AppTokens.iconDense,
                              ),
                              label: const Text('임시저장'),
                            ),
                    ),
                    Builder(
                      builder: (_) {
                        final status = manualSaving
                            ? '저장 중…'
                            : manualSaveNotice ??
                                  (c.draftStatus == DraftStatus.conflict
                                      ? '저장된 답안이 변경됐어요. 작성 내용을 복사해 주세요.'
                                      : c.draftStatus == DraftStatus.failed
                                      ? '저장하지 못했어요. 다시 시도해 주세요.'
                                      : null);
                        if (status == null) return const SizedBox.shrink();
                        final success =
                            !manualSaving &&
                            (manualSaveNotice?.contains('저장됨') ?? false);
                        final problem =
                            status.contains('못') || status.contains('변경됐어요');
                        return Padding(
                          padding: const EdgeInsets.only(top: AppTokens.space4),
                          child: Row(
                            children: [
                              if (success) ...[
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppTokens.success,
                                ),
                                const SizedBox(width: AppTokens.space4),
                              ],
                              Flexible(
                                child: Text(
                                  status,
                                  style: AppTokens.caption.copyWith(
                                    color: problem
                                        ? AppTokens.dangerInk
                                        : AppTokens.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (draft.syncNotice != null &&
                        (draft.syncConflict || draft.remoteBody != c.body))
                      Text(draft.syncNotice!),
                    const Text('아직 첨삭 요청 전입니다.'),
                    if (draft.remote != null)
                      TextButton(
                        onPressed: syncBusy
                            ? null
                            : () async {
                                setState(() => syncBusy = true);
                                try {
                                  await c.save();
                                  if (c.dirty) return;
                                  await draft.openSharedDraft();
                                  await c.reloadDraft();
                                  editor.text = c.body;
                                  if (!mounted || !context.mounted) return;
                                  if (draft.syncConflict &&
                                      draft.remoteBody != null) {
                                    await showDialog<void>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('계정에 저장된 답안'),
                                        content: SingleChildScrollView(
                                          child: SelectionArea(
                                            child: Text(draft.remoteBody!),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('닫기'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    await draft.sync(editor.text);
                                  }
                                } finally {
                                  if (mounted) setState(() => syncBusy = false);
                                }
                              },
                        child: const Text('계정 답안 확인·저장'),
                      ),
                  ],
                  ...[
                    const SizedBox(height: 20),

                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTokens.textPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: () async {
                        await c.save();
                        if (!context.mounted ||
                            c.dirty ||
                            imageSaving ||
                            imageDirty) {
                          return;
                        }
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => ExamAnswerReview(
                            owner: widget.owner,
                            exam: widget.exam,
                            currentQuestion: widget.question['key'] as String,
                            selectedQuestions: widget.selectedQuestions
                                .map((q) => q['key'] as String)
                                .toSet(),
                            rewriteRun: widget.rewriteRun,
                          ),
                        );
                      },
                      child: Text(
                        widget.exam['verification'] == 'REVIEW_REQUIRED'
                            ? '답안 확인'
                            : '답안 확인 · 첨삭 요청',
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class ExamSubmissionPanel extends ConsumerStatefulWidget {
  const ExamSubmissionPanel({
    super.key,
    this.rewriteRun,
    required this.owner,
    required this.exam,
    required this.included,
    this.onEdit,
    this.onSubmittedChanged,
  });
  final Map<String, dynamic>? rewriteRun;
  final String owner;
  final Map<String, dynamic> exam;
  final Set<String> included;

  /// Return to the writer to edit answers (shown beside 첨삭 요청).
  final VoidCallback? onEdit;

  /// Fires when a run becomes in-flight (or clears) so the review sheet can
  /// switch to a progress-only view instead of keeping the answer-confirm UI.
  final ValueChanged<bool>? onSubmittedChanged;
  @override
  ConsumerState<ExamSubmissionPanel> createState() =>
      ExamSubmissionPanelState();
}

class ExamSubmissionPanelState extends ConsumerState<ExamSubmissionPanel>
    with WidgetsBindingObserver {
  bool serverReady = false,
      busy = false,
      polling = false,
      eligibilityLoaded = false,
      foreground = true;
  Set<String> admittedQuestions = {};
  bool get ready {
    if (!serverReady || widget.included.isEmpty) return false;
    if (widget.exam['verification'] != 'REVIEW_REQUIRED' &&
        widget.exam['evaluationReady'] != false) {
      return true;
    }
    final questions = (widget.exam['questions'] as List)
        .cast<Map<String, dynamic>>();
    return widget.included.every(
      (key) => questions.any(
        (q) =>
            q['key'] == key &&
            q['dbQuestionId'] is String &&
            admittedQuestions.contains(q['dbQuestionId']),
      ),
    );
  }

  String notice = '';
  String? parentId;
  String? get previousPaidId => widget.rewriteRun?['_additional'] == true
      ? (widget.rewriteRun!['parent_id'] as String? ??
            widget.rewriteRun!['id'] as String)
      : null;
  String? submittedRun;
  String? submittedRequestKey;
  String? runState;
  bool resultOpened = false;
  Map<String, dynamic>? completedRun;
  Map<String, dynamic>? observedRun;
  Map<String, String> questionStates = {};
  bool confirmedRunState = false;
  ExamSessionStatus? sessionStatus;
  bool retrying = false;
  Timer? statusPoll;
  final submissionWait = Stopwatch();
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    statusPoll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause status polling while backgrounded; resume (an immediate check) on
    // return. The server evaluation keeps running regardless.
    final resumed = state == AppLifecycleState.resumed;
    foreground = resumed;
    if (!resumed) {
      statusPoll?.cancel();
    } else if (runState == 'completed' && !resultOpened) {
      resultOpened = true;
      unawaited(openCompletedResult());
    } else if (submittedRun != null &&
        runState != 'completed' &&
        runState != 'failed') {
      unawaited(pollStatus());
    }
  }

  bool get runPending =>
      submittedRun != null && runState != 'completed' && runState != 'failed';

  Future<void> pollStatus({
    bool manual = false,
    bool afterRetry = false,
  }) async {
    if (polling) return;
    statusPoll?.cancel();
    final client = ref.read(supabaseClientProvider);
    if (client == null || submittedRun == null || !mounted) return;
    setState(() => polling = true);
    final before = jsonEncode([runState, questionStates]);
    bool detailFailed = false;
    try {
      final rows = await SharedEssayHistory(
        client,
        widget.owner,
      ).examRuns(submittedRun);
      if (!mounted) return;
      if (rows.length != 1) throw StateError('Submission history pending');
      try {
        final store = ref.read(examSessionStoreProvider(widget.owner));
        final detail = await (afterRetry
            ? store.refreshAfterRetry(submittedRun!)
            : store.refresh(submittedRun!));
        if (!mounted) return;
        sessionStatus = detail;
        questionStates = detail.questions;
      } catch (_) {
        detailFailed = true;
        sessionStatus =
            null; // Failed refresh must never leave retry permission stale.
      }

      if (!mounted) return;
      observedRun = rows.single;
      final state = rows.single['state'];
      runState = state as String?;
      confirmedRunState = true;
      setState(
        () => notice = switch (state) {
          'completed' => '첨삭이 완료됐어요. 저장된 결과를 확인하세요.',
          'failed' => '첨삭을 완료하지 못했어요. 기록에서 처리 상태를 확인해 주세요.',
          // Progress view shows the fixed "잠시 쉬어가세요" guidance instead of a
          // per-poll notice, so no rotating or fabricated progress text here.
          _ =>
            manual
                ? detailFailed
                      ? '문항별 상태를 확인하지 못했어요. 다시 확인해 주세요.'
                      : before == jsonEncode([runState, questionStates])
                      ? '아직 처리 상태에 변화가 없습니다.'
                      : '최신 처리 상태를 확인했어요.'
                : notice == '아직 처리 상태에 변화가 없습니다.' &&
                      before != jsonEncode([runState, questionStates])
                ? '처리 상태가 업데이트됐어요.'
                : notice,
        },
      );
      if (state == 'failed' && submittedRequestKey != null) {
        // Only a server-confirmed terminal failure permits a new request key.
        // Preserve answers and never retry an unknown or in-flight evaluation.
        final saved = await pending.loadDraft();
        final stored = saved.body.isEmpty
            ? null
            : jsonDecode(saved.body) as Map<String, dynamic>;
        if (stored?['key'] == submittedRequestKey) {
          await pending.saveLocalDraft('', saved.revision);
        }
      }
      if (state == 'completed') {
        completedRun = rows.single;
        if (foreground && !resultOpened) {
          resultOpened = true;
          unawaited(openCompletedResult());
        }
      }
      if (state == 'completed' || state == 'failed') {
        ref.invalidate(sharedEssayHistoryProvider(widget.owner));
        ref.invalidate(creditBalanceProvider);
        return;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          sessionStatus = null;
          notice = '처리 상태를 확인하지 못했어요. 제출 기록은 보존됩니다.';
        });
      }
    } finally {
      if (mounted) setState(() => polling = false);
    }
    // Keep checking while the screen is active and the run is still pending —
    // no fixed 100s give-up — but back the interval off so a long evaluation is
    // not polled at high frequency. Background pause/resume is handled in
    // didChangeAppLifecycleState.
    if (mounted && foreground && runPending) {
      final elapsed = submissionWait.elapsed;
      final interval = elapsed < const Duration(seconds: 30)
          ? const Duration(seconds: 3)
          : elapsed < const Duration(minutes: 2)
          ? const Duration(seconds: 10)
          : const Duration(seconds: 30);
      statusPoll = Timer(interval, pollStatus);
    }
  }

  Future<void> retryFailedQuestions() async {
    if (retrying ||
        polling ||
        sessionStatus?.canRetry != true ||
        submittedRun == null) {
      return;
    }
    setState(() => retrying = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final api = gateway();
      if (client == null || api == null) throw StateError('로그인 상태를 확인해 주세요.');
      await retryExistingExam(
        client: client,
        gateway: api,
        owner: widget.owner,
        run: submittedRun!,
        exam: widget.exam['dbExamId'] as String,
      );
      if (!mounted) return;
      setState(() => notice = '실패 문항 재처리가 접수됐어요. 완료된 문항은 보존됩니다.');
      await pollStatus(afterRetry: true);
    } catch (error) {
      if (mounted) {
        setState(
          () => notice =
              error is StateError &&
                  !RegExp(r'^[A-Z_]+$').hasMatch(error.message.toString())
              ? error.message.toString()
              : '재처리 접수를 확인하지 못했어요. 상태를 새로고침해 주세요. 기존 답안과 결과는 보존됩니다.',
        );
      }
    } finally {
      if (mounted) setState(() => retrying = false);
    }
  }

  List<Map<String, dynamic>> rewrites = [];
  bool get eligibleRewrite {
    final row = rewrites.where((r) => r['id'] == parentId).firstOrNull;
    if (row == null || row['question_ids'] is! List) return false;
    final original = (row['question_ids'] as List).toSet();
    final selected = (widget.exam['questions'] as List)
        .cast<Map<String, dynamic>>()
        .where((q) => widget.included.contains(q['key']))
        .map((q) => q['dbQuestionId'])
        .toSet();
    return original.length == selected.length && original.containsAll(selected);
  }

  SourceDraftGateway get pending => SourceDraftGateway(
    widget.owner,
    'exam-request:${widget.exam['key']}:${previousPaidId == null ? parentId ?? 'initial' : 'additional:$previousPaidId'}',
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    parentId = previousPaidId == null
        ? (widget.rewriteRun?['parent_id'] as String? ??
              widget.rewriteRun?['id'] as String?)
        : null;
    unawaited(check());
    unawaited(restoreInFlightRun());
  }

  /// Re-attach to an evaluation that is still running when the student reopens
  /// this screen, using the runId persisted alongside the submission key. Never
  /// creates a new request or resubmits — it only resumes status polling.
  Future<void> restoreInFlightRun() async {
    try {
      final saved = await pending.loadDraft();
      if (saved.body.isEmpty || !mounted) return;
      final stored = jsonDecode(saved.body) as Map<String, dynamic>;
      var runId = stored['runId'] as String?;
      if (runId == null && stored['key'] is String) {
        final client = ref.read(supabaseClientProvider);
        if (client == null) return;
        runId = await recoverExamRequest(
          client,
          widget.owner,
          key: stored['key'] as String,
          exam: widget.exam['dbExamId'] as String,
          parent: parentId,
          previousPaid: previousPaidId,
        );
        if (runId == null) return;
        await pending.saveLocalDraft(
          jsonEncode({...stored, 'runId': runId}),
          saved.revision,
        );
      }
      if (runId == null || !mounted) return;
      setState(() {
        submittedRun = runId;
        submittedRequestKey = stored['key'] as String?;
        runState = 'processing';
        notice = '';
      });
      widget.onSubmittedChanged?.call(true);
      submissionWait
        ..reset()
        ..start();
      await pollStatus();
    } catch (_) {
      /* No resumable run; leave the form ready. */
    }
  }

  ExamSubmissionGateway? gateway() {
    return ref.read(examSubmissionGatewayProvider(widget.owner));
  }

  Future<void> check() async {
    try {
      final result = await ref.read(
        examAvailabilityProvider((
          owner: widget.owner,
          examId: widget.exam['dbExamId'] as String,
        )).future,
      );
      if (mounted) {
        setState(() {
          serverReady = result['ready'] == true;
          admittedQuestions = (result['questionIds'] as List? ?? [])
              .whereType<String>()
              .toSet();
        });
      }
    } catch (_) {
      // Availability failure leaves execution closed, but must not hide eligibility.
    }
    try {
      final client = ref.read(supabaseClientProvider);
      if (client != null) {
        final rows = await SharedEssayHistory(
          client,
          widget.owner,
        ).examRuns(parentId);
        if (mounted) setState(() => eligibilityLoaded = true);
        if (mounted) {
          setState(
            () => rewrites = rows
                .where(
                  (r) =>
                      r['exam_id'] == widget.exam['dbExamId'] &&
                      r['free_rewrite_available'] == true,
                )
                .toList(),
          );
        }
      }
    } catch (_) {
      /* Existing public HOLD remains closed. */
    }
  }

  Future<void> submit() async {
    if ((widget.rewriteRun == null &&
            isUniversityServicePreparing(widget.exam['sourceUniversityId'])) ||
        busy ||
        !ready) {
      return;
    }
    setState(() => busy = true);
    try {
      // An earlier lost response is resolved read-only BEFORE checking whether
      // its parent is still eligible. An accepted child consumes eligibility.
      final unresolved = await pending.loadDraft();
      if (unresolved.body.isNotEmpty) {
        final old = jsonDecode(unresolved.body) as Map<String, dynamic>;
        final client = ref.read(supabaseClientProvider);
        if (client == null) throw StateError('로그인 상태를 확인해 주세요.');
        final recovered =
            old['runId'] as String? ??
            await recoverExamRequest(
              client,
              widget.owner,
              key: old['key'] as String,
              exam: widget.exam['dbExamId'] as String,
              parent: parentId,
              previousPaid: previousPaidId,
            );
        if (recovered != null) {
          await pending.saveLocalDraft(
            jsonEncode({...old, 'runId': recovered}),
            unresolved.revision,
          );
          await restoreInFlightRun();
          return;
        }
        // Confirmed absent: only the existing key and exact payload may replay.
      }
      final selected = (widget.exam['questions'] as List)
          .cast<Map<String, dynamic>>()
          .where((q) => widget.included.contains(q['key']))
          .toList();
      if (selected.isEmpty) throw StateError('답안을 제출할 문항을 선택해 주세요.');
      var answers = <Map<String, dynamic>>[];
      for (final q in selected) {
        final store = SourceDraftGateway(
          widget.owner,
          essayWritingDraftKey(q['key'] as String, widget.rewriteRun),
        );
        final draft = await store.loadDraft();
        final images = await store.loadImages();
        if (draft.body.trim().isEmpty && images.isEmpty) {
          throw StateError(
            '${q['label']}: 답안이 비어 있어요. 답안을 작성하거나 제출 선택에서 제외해 주세요.',
          );
        }
        if (q['dbQuestionId'] == null ||
            draft.body.trim().isEmpty ||
            images.isNotEmpty ||
            q['inputMode'] == 'image') {
          throw StateError(
            '선택한 문항의 텍스트 답안을 확인해 주세요. 사진 포함 답안은 아직 이 시험에서 제출할 수 없습니다.',
          );
        }
        final missing = missingAnswerSections(
          draft.body,
          essayAnswerSections(
            widget.exam['dbExamId'] as String?,
            q['dbQuestionId'] as String?,
          ),
        );
        if (missing.isNotEmpty) {
          throw StateError('${missing.join(', ')} 답안을 작성해 주세요.');
        }
        answers.add({
          'questionId': q['dbQuestionId'],
          'body': draft.body,
          'revision': draft.revision,
        });
      }
      if (parentId != null) {
        final client = ref.read(supabaseClientProvider);
        if (client == null) throw StateError('로그인 상태를 확인해 주세요.');
        // Resolve this exact parent; a latest-50 list cannot authorize an old run.
        final parents = await SharedEssayHistory(
          client,
          widget.owner,
        ).examRuns(parentId);
        if (parents.length != 1 ||
            parents.single['exam_id'] != widget.exam['dbExamId'] ||
            parents.single['free_rewrite_available'] != true) {
          throw StateError(
            '무료 재첨삭 기간이 지났거나 이미 사용한 기록입니다. 추가 첨삭은 결과 화면에서 선택해 주세요. 답안은 보존됩니다.',
          );
        }
        answers = examRewriteAnswers(answers, parents.single);
      }
      final fingerprint = jsonEncode({
        'parentId': parentId,
        if (previousPaidId != null) 'previousPaidRunId': previousPaidId,
        'examId': widget.exam['dbExamId'],
        'answers': answers,
      });
      final saved = await pending.loadDraft();
      final prior = saved.body.isEmpty
          ? null
          : jsonDecode(saved.body) as Map<String, dynamic>;
      if (prior != null && prior['fingerprint'] != fingerprint) {
        throw StateError('이전 제출의 처리 상태를 첨삭 기록에서 먼저 확인해 주세요.');
      }
      EssayCreditSource? creditSource;
      if (prior == null) {
        final quote = await gateway()?.request({
          'action': 'quote',
          'examId': widget.exam['dbExamId'],
          'questionIds': answers.map((a) => a['questionId']).toList(),
          'parentId': parentId,
          if (previousPaidId != null) 'previousPaidRunId': previousPaidId,
        });
        if (quote?['version'] != 'essay-exam-quote-v1' ||
            quote?['credits'] != (parentId == null ? 1 : 0)) {
          throw StateError('사용 크레딧을 확인하지 못했어요. 답안은 보존됩니다.');
        }
        if (quote!.containsKey('credit_source')) {
          creditSource = EssayCreditSource.parse(
            quote['credit_source'],
            quote['credits'] as int,
          );
        }
        if (!mounted) return;
        // Minimal confirmation: what is submitted + the server-confirmed Credit
        // source in one line. Pressing 첨삭 시작 is the student's consent to that
        // source; the server still re-checks the grant and fence on submit.
        final creditLine = (quote['credits'] as int) == 0
            ? '추가 Credit이 사용되지 않아요'
            : creditSource?.usageLabel;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(
              AppTokens.space24,
              AppTokens.space24,
              AppTokens.space24,
              AppTokens.space12,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space24,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              AppTokens.space16,
              AppTokens.space12,
              AppTokens.space16,
              AppTokens.space16,
            ),
            title: const Text(
              '첨삭을 시작할까요?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note,
                      size: 20,
                      color: AppTokens.textTertiary,
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Text(
                      '작성 문항: ${answers.length}개',
                      style: AppTokens.body.copyWith(
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (creditLine != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                          color: AppTokens.textTertiary,
                        ),
                        const SizedBox(width: AppTokens.space8),
                        Flexible(
                          child: Text(
                            creditLine,
                            style: AppTokens.body.copyWith(
                              color: AppTokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTokens.textSecondary,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('돌아가기'),
              ),
              const SizedBox(width: AppTokens.space8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.textPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(96, 48),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('첨삭 시작'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final key = prior?['key'] as String? ?? newEssayUuid();
      if (prior == null) {
        await pending.saveLocalDraft(
          jsonEncode({
            'fingerprint': fingerprint,
            'key': key,
            if (creditSource != null) 'expectedGrant': creditSource.grantId,
          }),
          saved.revision,
        );
      }
      submissionWait
        ..reset()
        ..start();
      final result = await gateway()?.request({
        'action': 'submit',
        'examId': widget.exam['dbExamId'],
        'key': key,
        if (prior?.containsKey('expectedGrant') == true)
          'expectedGrant': prior!['expectedGrant']
        else if (creditSource != null)
          'expectedGrant': creditSource.grantId,
        'parentId': parentId,
        if (previousPaidId != null) 'previousPaidRunId': previousPaidId,
        'answers': answers,
      });
      if (result?['runId'] == null) {
        throw StateError('제출 상태를 확인하지 못했어요. 같은 답안으로 다시 확인해 주세요.');
      }
      {
        final runId = result!['runId'] as String;
        // Persist the runId beside the submission key so reopening this screen
        // resumes polling the same run instead of losing it.
        final saved = await pending.loadDraft();
        if (saved.body.isNotEmpty) {
          final stored = jsonDecode(saved.body) as Map<String, dynamic>;
          await pending.saveLocalDraft(
            jsonEncode({...stored, 'runId': runId}),
            saved.revision,
          );
        }
        if (!mounted) return;
        setState(() {
          submittedRun = runId;
          submittedRequestKey = key;
          runState = 'processing';
          notice = '';
        });
        widget.onSubmittedChanged?.call(true);
        unawaited(pollStatus());
      }
    } catch (error) {
      if (error is ExamSubmissionRejected) {
        final saved = await pending.loadDraft();
        await pending.saveLocalDraft('', saved.revision);
      }
      if (mounted) {
        setState(
          () => notice = error is ExamSubmissionRejected
              ? ([
                      'CREDIT_SOURCE_CHANGED',
                      'CREDIT_SOURCE_CONFIRMATION_REQUIRED',
                    ].contains(error.code)
                    ? '사용할 Credit 출처가 변경됐습니다. 답안은 보존됩니다. 다시 요청하여 출처를 확인해 주세요.'
                    : error.code == 'INSUFFICIENT_CREDIT'
                    ? '크레딧이 부족합니다.'
                    : error.code == 'QUOTE_UNAVAILABLE'
                    ? '서버에서 재첨삭 조건을 확인하지 못했어요. 답안은 보존됩니다. 기록에서 이용 가능 여부를 다시 확인해 주세요.'
                    : error.code == 'ADDITIONAL_CYCLE_UNAVAILABLE'
                    ? '추가 첨삭은 현재 이용할 수 없어요. 답안은 보존됩니다. 첨삭 결과에서 재첨삭 가능 여부를 확인해 주세요.'
                    : '서버에서 제출을 승인하지 않았어요. 답안은 보존됩니다. 잠시 후 다시 확인해 주세요.')
              : error is StateError
              ? RegExp(r'^[A-Z_]+$').hasMatch(error.message.toString())
                    ? '요청 상태를 확인하지 못했어요. 로그인과 연결 상태를 확인해 주세요.'
                    : error.message.toString()
              : '연결을 확인하지 못했어요. 답안과 제출 정보는 보존됩니다.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> openCompletedResult() async {
    final row = completedRun;
    if (!mounted || row == null) return;
    final ids = (row['question_ids'] as List).cast<String>().toSet();
    final questions = (widget.exam['questions'] as List)
        .cast<Map<String, dynamic>>()
        .map((q) => q['dbQuestionId'])
        .whereType<String>()
        .where(ids.contains)
        .toList();
    if (questions.isEmpty) questions.addAll(ids);
    if (questions.isEmpty) return;
    final record = SharedEssayRecord(
      id: row['id'] as String,
      math: false,
      exam: true,
      examData: {...row, 'questions': widget.exam['questions']},
      at: DateTime.parse(row['created_at'] as String),
      rewrite: row['parent_id'] != null,
      evaluations: [
        for (final q in questions)
          {'id': '${row['id']}/$q', 'state': 'COMPLETED'},
      ],
    );
    await openSharedEssayResult(
      context,
      ref,
      widget.owner,
      record,
      record.evaluations.first,
    );
  }

  Future<void> openAvailableQuestionResults() async {
    final row = observedRun;
    if (row == null || !mounted) return;
    final choices = (widget.exam['questions'] as List)
        .cast<Map<String, dynamic>>()
        .where((q) => questionStates[q['dbQuestionId']] == 'completed')
        .toList();
    if (choices.isEmpty) return;
    final id = choices.length == 1
        ? choices.single['dbQuestionId'] as String
        : await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final q in choices)
                    ListTile(
                      title: Text('${q['label']} · 완료된 결과 보기'),
                      onTap: () =>
                          Navigator.pop(context, q['dbQuestionId'] as String),
                    ),
                ],
              ),
            ),
          );
    if (!mounted || id == null) return;
    final record = SharedEssayRecord(
      id: row['id'] as String,
      math: false,
      exam: true,
      examData: {...row, 'questions': widget.exam['questions']},
      at: DateTime.parse(row['created_at'] as String),
      rewrite: row['parent_id'] != null,
      evaluations: [
        {'id': '${row['id']}/$id', 'state': 'COMPLETED'},
      ],
    );
    await openSharedEssayResult(
      context,
      ref,
      widget.owner,
      record,
      record.evaluations.single,
    );
  }

  void _openHistory() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SharedEssayHistoryPage()),
  );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading || auth.hasError || auth.value?.userId != widget.owner) {
      return const SizedBox.shrink();
    }
    if (submittedRun case final run?) {
      ref.listen(
        examSessionObservationProvider((owner: widget.owner, run: run)),
        (_, next) {
          final observed = next.value;
          if (mounted && observed != null && submittedRun == run) {
            setState(() {
              sessionStatus = observed;
              questionStates = observed.questions;
            });
          }
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: submittedRun == null ? _preSubmit() : _progress(context),
    );
  }

  // Pre-submit: choose 제출 방식, confirm 문항 수, request 첨삭.
  List<Widget> _preSubmit() => [
    if (widget.rewriteRun == null && rewrites.isNotEmpty)
      DropdownButtonFormField<String>(
        initialValue: parentId ?? '',
        decoration: const InputDecoration(labelText: '제출 방식'),
        items: [
          const DropdownMenuItem(value: '', child: Text('최초 첨삭')),
          for (final r in rewrites)
            DropdownMenuItem(
              value: r['id'] as String,
              child: Text(
                '무료 재첨삭 · ${r['created_at'].toString().substring(0, 10)}',
              ),
            ),
        ],
        onChanged: busy
            ? null
            : (v) => setState(() {
                parentId = v == '' ? null : v;
                notice = '';
              }),
      ),
    if (parentId != null)
      const Text('최초 제출과 동일한 문항을 선택하고 답안을 수정해 주세요. 재첨삭 가능 여부는 서버에서 확인합니다.'),
    const Divider(color: AppTokens.majorSurfaceBorder, height: 16),
    Text('제출 문항: ${widget.included.length}개'),
    if (parentId != null && eligibleRewrite)
      const Text('무료 재첨삭 · 추가 Credit 없음'),
    if (!ready) const Text('현재 이 문항은 첨삭을 이용할 수 없어요. 답안 작성과 저장은 계속할 수 있어요.'),
    // [답안 수정] [첨삭 요청] 나란히 배치.
    Row(
      children: [
        if (widget.onEdit != null) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.textPrimary,
                side: const BorderSide(color: AppTokens.majorSurfaceBorder),
                minimumSize: const Size(0, 48),
              ),
              onPressed: busy ? null : widget.onEdit,
              child: const Text('답안 수정'),
            ),
          ),
          const SizedBox(width: AppTokens.space12),
        ],
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.textPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            onPressed: ready && !busy && (parentId == null || eligibleRewrite)
                ? submit
                : null,
            child: Text(
              busy
                  ? '처리 중…'
                  : ready
                  ? '첨삭 요청'
                  : '첨삭 서비스 준비 중',
            ),
          ),
        ),
      ],
    ),
    if (parentId != null && eligibilityLoaded && !eligibleRewrite)
      const Text('현재 무료 재첨삭 자격이 없습니다. 작성한 답안은 보존됩니다.'),
    if (parentId != null && !eligibilityLoaded)
      const Text('재첨삭 자격을 아직 확인하지 못했어요. 답안은 계속 작성할 수 있습니다.'),
    if (notice.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: AppTokens.space8),
        child: Text(notice),
      ),
  ];

  // Post-submit progress: the status is the primary information. Real server
  // state only — no fabricated percentage or ETA.
  List<Widget> _progress(BuildContext context) {
    final questionFailure =
        runState != 'completed' &&
        questionStates.values.contains('failed') &&
        !questionStates.values.contains('processing');
    final failed = runState == 'failed' || questionFailure;
    final completed = runState == 'completed';
    final included = (widget.exam['questions'] as List)
        .cast<Map<String, dynamic>>()
        .where((q) => widget.included.contains(q['key']));
    return [
      const SizedBox(height: AppTokens.space8),
      Text(
        failed
            ? questionFailure
                  ? '일부 문항의 첨삭이 완료되지 않았어요.'
                  : '첨삭을 완료하지 못했어요'
            : completed
            ? '첨삭이 완료됐어요'
            : '첨삭을 진행하고 있어요',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTokens.textPrimary,
        ),
      ),
      if (!failed) ...[
        const SizedBox(height: AppTokens.space8),
        Text(
          completed ? '저장된 결과를 확인할 수 있어요.' : '잠시 쉬어가세요 ☕',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTokens.textPrimary,
          ),
        ),
        if (!completed) ...[
          const SizedBox(height: AppTokens.space8),
          ProcessingGuidance(
            active:
                runState == 'processing' ||
                questionStates.values.contains('processing'),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space16),
          child: StepProgressBar(
            steps: const ['제출 완료', '첨삭 중', '결과 준비'],
            showActivity:
                !completed &&
                (runState == 'processing' ||
                    questionStates.values.contains('processing')),
            activeIndex: completed
                ? 2
                : ((confirmedRunState && runState == 'processing') ||
                      questionStates.values.any(
                        (s) => s == 'processing' || s == 'completed',
                      ))
                ? 1
                : 0,
            done: completed,
          ),
        ),
      ],
      const SizedBox(height: AppTokens.space8),
      // 문제별 진행 상태 (구분선으로 구분).
      for (final q in included) ...[
        const Divider(height: 1, color: AppTokens.majorSurfaceBorder),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
          child: Row(
            children: [
              Expanded(
                child: Text(q['label'] as String, style: AppTokens.body),
              ),
              Text(
                completed
                    ? '완료'
                    : essayQuestionStatus(questionStates[q['dbQuestionId']]),
                style: AppTokens.caption.copyWith(
                  color: questionStates[q['dbQuestionId']] == 'failed'
                      ? AppTokens.dangerInk
                      : AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
      const Divider(height: 1, color: AppTokens.majorSurfaceBorder),
      const SizedBox(height: AppTokens.space12),
      if (failed)
        Text(
          notice.isEmpty
              ? sessionStatus?.retryExplanation ??
                    '상태를 새로고침해 재처리 가능 여부를 확인해 주세요. 완료 문항은 보존됩니다.'
              : notice,
          style: AppTokens.body.copyWith(color: AppTokens.dangerInk),
        ),
      if (completed)
        Text(
          notice.isEmpty ? '저장된 결과를 확인하세요.' : notice,
          style: AppTokens.body.copyWith(color: AppTokens.textSecondary),
        ),
      if (!failed && !completed) ...[
        if (notice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.space4),
            child: Text(
              notice,
              style: AppTokens.caption.copyWith(color: AppTokens.dangerInk),
            ),
          ),
      ],
      if (!completed && questionStates.values.contains('completed'))
        const Text(
          bool.fromEnvironment('ESSAY_OBSERVATION_V1_ENABLED')
              ? '완료된 문항의 결과를 먼저 확인할 수 있어요.'
              : '완료된 결과는 보존되며, 전체 문항의 처리가 끝나면 조회할 수 있어요.',
          style: TextStyle(fontSize: 13, color: AppTokens.textSecondary),
        ),
      const SizedBox(height: AppTokens.space4),
      if (!failed && !completed)
        Text(
          '화면을 닫아도 첨삭은 계속 진행됩니다.',
          style: AppTokens.caption.copyWith(color: AppTokens.textTertiary),
        ),
      const SizedBox(height: AppTokens.space12),
      Wrap(
        spacing: AppTokens.space8,
        runSpacing: AppTokens.space8,
        children: [
          OutlinedButton.icon(
            onPressed: polling || retrying
                ? null
                : () => pollStatus(manual: true),
            icon: const Icon(Icons.refresh, size: AppTokens.iconDense),
            label: const Text('처리 상태 새로고침'),
          ),
          if (questionStates.values.contains('failed'))
            FilledButton(
              onPressed: retrying || polling || sessionStatus?.canRetry != true
                  ? null
                  : retryFailedQuestions,
              child: Text(
                sessionStatus?.canRetry == true
                    ? '실패한 문항 다시 처리 · 0 Credit'
                    : '실패한 문항 다시 처리',
              ),
            ),
          if (!completed && questionStates.values.contains('completed'))
            OutlinedButton(
              onPressed:
                  const bool.fromEnvironment('ESSAY_OBSERVATION_V1_ENABLED')
                  ? openAvailableQuestionResults
                  : null,
              child: const Text('완료된 결과 보기'),
            ),
          if (completed)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.textPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: openCompletedResult,
              child: const Text('완료된 결과 보기'),
            ),
          TextButton(onPressed: _openHistory, child: const Text('나의 첨삭 기록')),
        ],
      ),
    ];
  }
}

/// Review the existing per-question drafts before using the same exam submission API.
class ExamAnswerReview extends ConsumerStatefulWidget {
  const ExamAnswerReview({
    super.key,
    required this.owner,
    required this.exam,
    required this.currentQuestion,
    this.selectedQuestions,
    this.rewriteRun,
  });
  final String owner, currentQuestion;
  final Set<String>? selectedQuestions;
  final Map<String, dynamic> exam;
  final Map<String, dynamic>? rewriteRun;
  @override
  ConsumerState<ExamAnswerReview> createState() => _ExamAnswerReviewState();
}

class _ExamAnswerReviewState extends ConsumerState<ExamAnswerReview> {
  late final Set<String> selected = widget.rewriteRun == null
      ? {
          ...?widget.selectedQuestions,
          if (widget.selectedQuestions == null) widget.currentQuestion,
        }
      : (widget.exam['questions'] as List)
            .cast<Map<String, dynamic>>()
            .where(
              (q) => (widget.rewriteRun!['question_ids'] as List).contains(
                q['dbQuestionId'],
              ),
            )
            .map((q) => q['key'] as String)
            .toSet();
  Future<List<String>> missingAnswers() async {
    final missing = <String>[];
    for (final q
        in (widget.exam['questions'] as List).cast<Map<String, dynamic>>()) {
      if (!selected.contains(q['key'])) continue;
      final store = SourceDraftGateway(
        widget.owner,
        essayWritingDraftKey(q['key'] as String, widget.rewriteRun),
      );
      final draft = await store.loadDraft();
      final images = await store.loadImages();
      if (draft.body.trim().isEmpty && images.isEmpty) {
        missing.add(q['label'] as String);
      } else {
        missing.addAll(
          missingAnswerSections(
            draft.body,
            essayAnswerSections(
              widget.exam['dbExamId'] as String?,
              q['dbQuestionId'] as String?,
            ),
          ),
        );
      }
    }
    return missing;
  }

  // Once a run is in flight the sheet switches to a progress-only view (the
  // submit router renders the progress); the answer-confirm UI is hidden so the
  // exam name, 답안 수정 and the checklist are not stacked under the progress.
  bool submitting = false;

  String get _examMeta => essayExamTitle(widget.exam);

  @override
  Widget build(BuildContext context) {
    final admission = widget.exam['dbExamId'] is String
        ? ref
              .watch(
                examAvailabilityProvider((
                  owner: widget.owner,
                  examId: widget.exam['dbExamId'] as String,
                )),
              )
              .asData
              ?.value
        : null;
    final questions = (widget.exam['questions'] as List)
        .cast<Map<String, dynamic>>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!submitting) ...[
              // 시험명은 한 번만: 대학명 + 한 줄 요약.
              Text('답안 확인', style: Theme.of(context).textTheme.titleLarge),
              if (widget.exam['universityName'] != null) ...[
                const SizedBox(height: AppTokens.space8),
                Text(
                  widget.exam['universityName'] as String,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              if (_examMeta.isNotEmpty)
                Text(
                  _examMeta,
                  style: AppTokens.secondary.copyWith(
                    color: AppTokens.textSecondary,
                  ),
                ),
              const Divider(color: AppTokens.majorSurfaceBorder, height: 16),
              for (final (i, q) in questions.indexed) ...[
                if (i > 0)
                  const Divider(color: AppTokens.majorSurfaceBorder, height: 1),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(q['label'] as String),
                  subtitle:
                      essayQuestionAvailability(
                        widget.exam,
                        q,
                        admission,
                      ).isEmpty
                      ? null
                      : Text(
                          essayQuestionAvailability(widget.exam, q, admission),
                        ),
                  value: selected.contains(q['key']),
                  onChanged: widget.rewriteRun != null
                      ? null
                      : (v) => setState(() {
                          if (v == true) {
                            selected.add(q['key'] as String);
                          } else {
                            selected.remove(q['key']);
                          }
                        }),
                ),
              ],
              FutureBuilder<List<String>>(
                future: missingAnswers(),
                builder: (context, snapshot) => snapshot.hasError
                    ? const Text('답안 저장 상태를 확인하지 못했어요. 다시 확인해 주세요.')
                    : (snapshot.data ?? []).isEmpty
                    ? const SizedBox.shrink()
                    : Text(
                        '${snapshot.data!.join(', ')}: 답안이 비어 있어요. 작성하거나 제출 선택에서 제외해 주세요.',
                      ),
              ),
              const SizedBox(height: AppTokens.space8),
            ],
            // [답안 수정]은 제출 라우터가 [첨삭 요청]과 나란히 렌더한다.
            _RoundSubmitRouter(
              owner: widget.owner,
              exam: widget.exam,
              included: selected,
              rewriteRun: widget.rewriteRun,
              onEdit: () => Navigator.pop(context),
              onSubmittedChanged: (value) {
                if (mounted) setState(() => submitting = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only entry independent of answer submission/readiness. Same native viewer
/// and authenticated Storage transport as the existing answer writer.
class _BrowseQuestionPdfButton extends ConsumerWidget {
  const _BrowseQuestionPdfButton({required this.question});
  final Map<String, dynamic> question;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = QuestionPdfAsset.parse(
      question['studentPdf'],
      question['dbQuestionId'] as String? ?? '',
    );
    if (asset == null) return const Text('문제 자료 준비 중');
    return OutlinedButton(
      onPressed: () async {
        final client = ref.read(supabaseClientProvider);
        final owner = client?.auth.currentUser?.id;
        if (owner == null) {
          await context.push('/auth', extra: true);
          return;
        }
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('${question['label']} · 문제 보기')),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => EssayQuestionPdf(
                    key: ValueKey('${question['dbQuestionId']}:${asset.hash}'),
                    asset: asset,
                    height: constraints.maxHeight,
                    load: () async {
                      if (client!.auth.currentUser?.id != owner) {
                        throw StateError('로그인이 필요합니다.');
                      }
                      final bytes = await client.storage
                          .from(asset.bucket)
                          .download('${asset.id}.pdf');
                      if (client.auth.currentUser?.id != owner) {
                        throw StateError('로그인이 필요합니다.');
                      }
                      return bytes;
                    },
                    restorePage: () async => null,
                    savePage: (_) async {},
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: const Text('문제 보기'),
    );
  }
}

class _RoundSubmitRouter extends ConsumerWidget {
  const _RoundSubmitRouter({
    required this.owner,
    required this.exam,
    required this.included,
    this.rewriteRun,
    this.onEdit,
    this.onSubmittedChanged,
  });
  final String owner;
  final Map<String, dynamic> exam;
  final Set<String> included;
  final Map<String, dynamic>? rewriteRun;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onSubmittedChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admission = exam['dbExamId'] is String
        ? ref
              .watch(
                examAvailabilityProvider((
                  owner: owner,
                  examId: exam['dbExamId'] as String,
                )),
              )
              .asData
              ?.value
        : null;
    final catalog = ref.watch(mathCatalogProvider(owner));
    final leaves = <String, String>{
      for (final row in catalog.value ?? <Map<String, dynamic>>[])
        if (row['essay_exam_id'] == exam['dbExamId'] &&
            row['essay_question_id'] is String &&
            row['leaf_id'] is String)
          row['essay_question_id'] as String: row['leaf_id'] as String,
    };
    final selected = (exam['questions'] as List)
        .cast<Map<String, dynamic>>()
        .where((q) => included.contains(q['key']))
        .toList();
    final area = essayServiceArea(exam);
    final mathSelected = selected
        .where(
          (q) =>
              leaves.containsKey(q['dbQuestionId']) ||
              (admission?['mathQuestions'] is Map &&
                  (admission!['mathQuestions'] as Map).containsKey(
                    q['dbQuestionId'],
                  )) ||
              q['inputMode'] == 'image',
        )
        .toList();
    Widget unavailable(String message) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message),
        if (onEdit != null)
          OutlinedButton(onPressed: onEdit, child: const Text('답안 수정')),
      ],
    );
    if (area == EssayServiceArea.science) {
      return unavailable('자연·공학·이학·의예논술 첨삭은 베타 공개 보류 중입니다. 작성한 답안은 유지됩니다.');
    }
    if (area == null && mathSelected.isNotEmpty) {
      return unavailable('시험 정보를 확인하기 전에는 이 수리 문항을 제출할 수 없어요. 작성한 답안은 보존됩니다.');
    }
    if (mathSelected.isNotEmpty && mathSelected.length != selected.length) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('글쓰기 문항과 수리 문항을 함께 제출하는 기능을 준비 중이에요. 작성한 답안은 보존됩니다.'),
          const Text('일부 문항만 제출하려면 답안 확인에서 직접 선택하고 사용 Credit을 확인해 주세요.'),
          if (onEdit != null)
            OutlinedButton(onPressed: onEdit, child: const Text('답안 수정')),
        ],
      );
    }
    if (mathSelected.isNotEmpty &&
        !selected.every((q) => leaves.containsKey(q['dbQuestionId']))) {
      return unavailable('현재 이 수리 문항은 첨삭을 이용할 수 없어요. 작성한 답안은 보존됩니다.');
    }
    if (selected.isNotEmpty &&
        selected.every((q) => leaves.containsKey(q['dbQuestionId']))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onEdit != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTokens.textPrimary,
                  side: const BorderSide(color: AppTokens.majorSurfaceBorder),
                ),
                onPressed: onEdit,
                child: const Text('답안 수정'),
              ),
            ),
          MathExamSession(
            key: ValueKey(
              '$owner/${exam['dbExamId']}/${(included.toList()..sort()).join(',')}',
            ),
            owner: owner,
            exam: exam,
            selected: included,
            leaves: leaves,
          ),
        ],
      );
    }
    return ExamSubmissionPanel(
      owner: owner,
      exam: exam,
      included: included,
      rewriteRun: rewriteRun,
      onEdit: onEdit,
      onSubmittedChanged: onSubmittedChanged,
    );
  }
}

List<Map<String, dynamic>> orderedServiceUniversities(
  SourceCatalog catalog,
  Set<String> admitted,
) {
  final active = admitted;
  final indexed = catalog.universities.indexed.toList();
  indexed.sort((a, b) {
    final priority =
        (active.contains(b.$2['universityId']) ? 1 : 0) -
        (active.contains(a.$2['universityId']) ? 1 : 0);
    return priority != 0 ? priority : a.$1.compareTo(b.$1);
  });
  return indexed.map((e) => e.$2).toList();
}
