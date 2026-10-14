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
  const SourceCatalogPage({super.key, this.catalog, this.rewriteRun});
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
    final owner = auth.value?.userId ?? 'guest';
    return _SourceSelection(
      key: ValueKey(owner),
      owner: owner,
      catalog: catalog,
      rewriteRun: rewriteRun,
      loadCatalog: () => SourceCatalog.load(
        accessToken: ref
            .read(supabaseClientProvider)
            ?.auth
            .currentSession
            ?.accessToken,
      ),
    );
  }
}

class _SourceSelection extends StatefulWidget {
  const _SourceSelection({
    super.key,
    required this.owner,
    required this.loadCatalog,
    this.catalog,
    this.rewriteRun,
  });
  final Map<String, dynamic>? rewriteRun;
  final String owner;
  final Future<SourceCatalog> Function() loadCatalog;
  final Future<SourceCatalog>? catalog;
  @override
  State<_SourceSelection> createState() => _SourceSelectionState();
}

class _SourceSelectionState extends State<_SourceSelection> {
  late Future<SourceCatalog> data = widget.catalog ?? widget.loadCatalog();
  final included = <String, Set<String>>{};
  String? university, year, kind, track, examKey;
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(university == null ? '논술 LAB' : '논술 첨삭 시작'),
      actions: [
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
              onPressed: () => setState(() => data = widget.loadCatalog()),
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
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CreditBalanceCard(compact: true),
              for (final u in c.universities)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (u['logo'] is String)
                          Image.network(
                            'https://lab.legendstudy.com${u['logo']}',
                            height: 48,
                            width: 140,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.school_outlined),
                          ),
                        Text(
                          u['name'] as String,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(
                            () =>
                                university = u['sourceUniversityId'] as String,
                          ),
                          child: const Text('첨삭 시작하기'),
                        ),
                      ],
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
        final years = rows.map((e) => '${e['year']}').toSet().toList()
          ..sort((a, b) => b.compareTo(a));
        final y = year ?? (years.length == 1 ? years.first : null);
        final yr = rows.where((e) => '${e['year']}' == y).toList();
        final kinds = yr.map((e) => e['kind'] as String).toSet().toList();
        final k = kind ?? (kinds.length == 1 ? kinds.first : null);
        final kr = yr.where((e) => e['kind'] == k).toList();
        final tracks = kr.map((e) => e['track'] as String).toSet().toList();
        final t = track ?? (tracks.length == 1 ? tracks.first : null);
        final exams = kr.where((e) => e['track'] == t).toList();
        final selected =
            examKey ??
            (exams.length == 1 ? exams.first['key'] as String : null);
        final matches = exams.where((e) => e['key'] == selected);
        final exam = matches.isEmpty ? null : matches.single;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CreditBalanceCard(compact: true),
            if (widget.rewriteRun == null)
              TextButton(
                onPressed: () => setState(() {
                  university = null;
                  year = kind = track = examKey = null;
                }),
                child: const Text('대학 목록'),
              ),
            if (widget.rewriteRun != null)
              const Text('다시 써보기 · 최초 제출 문항을 유지합니다.'),
            if (rows.isEmpty) const Text('이 대학의 시험 자료를 준비하고 있어요.'),
            choice(
              '대학',
              uni,
              c.universities
                  .map((u) => u['sourceUniversityId'] as String)
                  .toList(),
              (v) => setState(() {
                university = v;
                year = kind = track = examKey = null;
              }),
              labels: {
                for (final u in c.universities)
                  u['sourceUniversityId'] as String: u['name'] as String,
              },
            ),
            choice(
              '학년도',
              y,
              years,
              (v) => setState(() {
                year = v;
                kind = track = examKey = null;
              }),
            ),
            choice(
              '시험 유형',
              k,
              kinds,
              (v) => setState(() {
                kind = v;
                track = examKey = null;
              }),
              labels: const {'mock': '모의논술', 'admission': '수시 논술'},
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
              if (RegExp('인문|언어|사회|경제|경영|상경').hasMatch(t ?? ''))
                const Text(
                  '최초 첨삭은 시험의 선택 문항 묶음당 1 Credit입니다. 14일 이내 같은 문항 집합의 재첨삭 1회가 포함됩니다.',
                ),
              if (widget.rewriteRun == null &&
                  RegExp('인문|언어|사회|경제|경영|상경').hasMatch(t ?? ''))
                OutlinedButton(
                  onPressed: () => setState(
                    () => included[exam['key'] as String] =
                        (exam['questions'] as List)
                            .cast<Map<String, dynamic>>()
                            .map((q) => q['key'] as String)
                            .toSet(),
                  ),
                  child: const Text('전체 문항 선택'),
                ),
              for (final q
                  in (exam['questions'] as List).cast<Map<String, dynamic>>())
                ListTile(
                  title: Text(q['label'] as String),
                  subtitle: q['lengthLabel'] == null
                      ? null
                      : Text(q['lengthLabel'] as String),
                  leading: RegExp('인문|언어|사회|경제|경영|상경').hasMatch(t ?? '')
                      ? Checkbox(
                          value:
                              included[exam['key']]?.contains(q['key']) ??
                              false,
                          semanticLabel: '${q['label']} 첨삭 선택',
                          onChanged: widget.rewriteRun != null
                              ? null
                              : (v) => setState(() {
                                  final selected = included.putIfAbsent(
                                    exam['key'] as String,
                                    () => {},
                                  );
                                  if (v == true) {
                                    selected.add(q['key'] as String);
                                  } else {
                                    selected.remove(q['key']);
                                  }
                                }),
                        )
                      : null,
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _SourceWriter(
                        owner: widget.owner,
                        question: q,
                        exam: exam,
                        rewriteRun: widget.rewriteRun,
                        officialUrl:
                            c.universities
                                    .where(
                                      (u) => u['sourceUniversityId'] == uni,
                                    )
                                    .first['officialSourceUrl']
                                as String?,
                      ),
                    ),
                  ),
                ),
              _ExamSubmit(
                key: ValueKey('${widget.owner}:${exam['key']}'),
                owner: widget.owner,
                exam: exam,
                included: included[exam['key']] ?? {},
                rewriteRun: widget.rewriteRun,
              ),
            ],
          ],
        );
      },
    ),
  );
}

class _SourceWriter extends ConsumerStatefulWidget {
  const _SourceWriter({
    this.rewriteRun,
    required this.owner,
    required this.question,
    required this.exam,
    this.officialUrl,
  });
  final Map<String, dynamic>? rewriteRun;
  final String owner;
  final String? officialUrl;
  final Map<String, dynamic> question, exam;
  @override
  ConsumerState<_SourceWriter> createState() => _SourceWriterState();
}

class _SourceWriterState extends ConsumerState<_SourceWriter> {
  List<Uint8List> photo = [];
  bool imageReady = false, imageSaving = false, imageDirty = false;
  String? photoNotice;
  late final draft = SourceDraftGateway(
    widget.owner,
    widget.question['key'] as String,
    remote:
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
          photoNotice = '사진을 이 기기에 저장했습니다.';
        });
      }
    } catch (_) {
      if (mounted) setState(() => photoNotice = '사진을 저장하지 못했어요. 원본을 보관해 주세요.');
    } finally {
      if (mounted) setState(() => imageSaving = false);
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
  bool problem = false, showOptionalImage = false, syncBusy = false;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final g = draft;
      final d = await g.openSharedDraft();
      final image = await g.loadImages();
      if (mounted) {
        photo = image;
        imageReady = true;
      }
      if (!mounted) return;
      controller = EssayController(g, initialBody: d.body)
        ..revision = d.revision;
      editor.text = d.body;
      final previous = (widget.rewriteRun?['answers'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((a) => a['questionId'] == widget.question['dbQuestionId'])
          .firstOrNull;
      if (d.body.isEmpty && previous?['body'] is String) {
        editor.text = previous!['body'] as String;
        controller!.edit(editor.text);
      }
      controller!.addListener(refresh);
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => error = '저장된 답안을 불러오지 못했어요.');
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

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
    return PopScope(
      canPop:
          (c == null || !c.dirty) && !imageSaving && !imageDirty && !syncBusy,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.question['label'] as String)),
        body: c == null
            ? Center(child: Text(error ?? '답안을 불러오고 있어요.'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('문제 보기')),
                      ButtonSegment(value: false, label: Text('답안 작성')),
                    ],
                    selected: {problem},
                    onSelectionChanged: (v) =>
                        setState(() => problem = v.first),
                  ),
                  const SizedBox(height: 20),
                  if (pdf != null)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_full),
                      label: const Text('문제 보기'),
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text('문제 보기'),
                              leading: IconButton(
                                tooltip: '닫기',
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
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
                  if (problem) ...[
                    Text('${widget.exam['year']}학년도 · ${widget.exam['track']}'),
                    const Text('대학 공식 기출자료에서 문제와 제시문을 확인하세요.'),
                    if (widget.officialUrl != null)
                      ExternalLinkButton(
                        uri: Uri.tryParse(widget.officialUrl!),
                        label: '공식 자료 확인 ↗',
                      ),
                    if (widget.question['sourceLocator'] != null)
                      Text(widget.question['sourceLocator'] as String),
                  ] else ...[
                    if (widget.question['inputMode'] == 'image' ||
                        photo.isNotEmpty ||
                        showOptionalImage) ...[
                      AnswerImagesInput(
                        values: photo,
                        enabled: imageReady && !imageSaving,
                        onChanged: savePhoto,
                      ),
                      if (photoNotice != null) Text(photoNotice!),
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
                        title: const Text('최초 답안 참고'),
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
                    TextField(
                      controller: editor,
                      enabled: !syncBusy,
                      minLines: widget.question['inputMode'] == 'image'
                          ? 3
                          : 12,
                      maxLines: null,
                      maxLength: 30000,
                      onChanged: c.edit,
                      decoration: InputDecoration(
                        labelText: widget.question['inputMode'] == 'image'
                            ? '추가 설명 (선택)'
                            : '내 답안',
                        alignLabelWithHint: true,
                      ),
                    ),
                    Text(switch (c.draftStatus) {
                      DraftStatus.saved => draft.syncNotice ?? '이 기기에 저장했습니다.',
                      DraftStatus.saving => '저장 중…',
                      DraftStatus.failed => '저장하지 못했어요. 답안을 복사해 보관해 주세요.',
                      DraftStatus.conflict => '저장된 답안이 변경됐어요. 작성 내용을 복사해 주세요.',
                    }),
                    if (draft.syncNotice != null) Text(draft.syncNotice!),
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
                    if (c.dirty)
                      TextButton(
                        onPressed: c.save,
                        child: const Text('저장 다시 시도'),
                      ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
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
                          rewriteRun: widget.rewriteRun,
                        ),
                      );
                    },
                    child: const Text('답안 확인 · 첨삭 요청'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ExamSubmit extends ConsumerStatefulWidget {
  const _ExamSubmit({
    super.key,
    this.rewriteRun,
    required this.owner,
    required this.exam,
    required this.included,
  });
  final Map<String, dynamic>? rewriteRun;
  final String owner;
  final Map<String, dynamic> exam;
  final Set<String> included;
  @override
  ConsumerState<_ExamSubmit> createState() => _ExamSubmitState();
}

class _ExamSubmitState extends ConsumerState<_ExamSubmit> {
  bool ready = false, busy = false, polling = false, eligibilityLoaded = false;
  String notice = '';
  String? parentId;
  String? submittedRun;
  Timer? statusPoll;
  int polls = 0;
  @override
  void dispose() {
    statusPoll?.cancel();
    super.dispose();
  }

  Future<void> pollStatus() async {
    if (polling) return;
    statusPoll?.cancel();
    final client = ref.read(supabaseClientProvider);
    if (client == null || submittedRun == null || !mounted) return;
    polling = true;
    try {
      final rows = await SharedEssayHistory(
        client,
        widget.owner,
      ).examRuns(submittedRun);
      if (!mounted || rows.length != 1) return;
      final state = rows.single['state'];
      setState(
        () => notice = switch (state) {
          'completed' => '첨삭이 완료됐어요. 저장된 결과를 확인하세요.',
          'failed' => '첨삭을 완료하지 못했어요. 기록에서 처리 상태를 확인해 주세요.',
          _ => '첨삭 중입니다. 화면을 닫아도 제출 기록은 유지됩니다.',
        },
      );
      if (state == 'completed' || state == 'failed') {
        ref.invalidate(sharedEssayHistoryProvider(widget.owner));
        ref.invalidate(creditBalanceProvider);
        return;
      }
    } catch (_) {
      if (mounted) setState(() => notice = '처리 상태를 확인하지 못했어요. 제출 기록은 보존됩니다.');
    } finally {
      polling = false;
    }
    if (mounted && ++polls < 100) {
      statusPoll = Timer(const Duration(seconds: 3), pollStatus);
    }
  }

  List<Map<String, dynamic>> rewrites = [];
  SourceDraftGateway get pending => SourceDraftGateway(
    widget.owner,
    'exam-request:${widget.exam['key']}:${parentId ?? 'initial'}',
  );
  @override
  void initState() {
    super.initState();
    parentId = widget.rewriteRun?['id'] as String?;
    unawaited(check());
  }

  ExamSubmissionGateway? gateway() {
    final client = ref.read(supabaseClientProvider);
    return client == null ? null : ExamSubmissionGateway(client, widget.owner);
  }

  Future<void> check() async {
    try {
      final result = await gateway()?.request({
        'action': 'availability',
        'examId': widget.exam['dbExamId'],
      });
      if (mounted) setState(() => ready = result?['ready'] == true);
    } catch (_) {
      // Availability failure leaves execution closed, but must not hide eligibility.
    }
    try {
      final client = ref.read(supabaseClientProvider);
      if (client != null) {
        final rows = await SharedEssayHistory(client, widget.owner).examRuns();
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
    if (busy || !ready) return;
    setState(() => busy = true);
    try {
      final selected = (widget.exam['questions'] as List)
          .cast<Map<String, dynamic>>()
          .where((q) => widget.included.contains(q['key']))
          .toList();
      if (selected.isEmpty) throw StateError('답안을 제출할 문항을 선택해 주세요.');
      final answers = <Map<String, dynamic>>[];
      for (final q in selected) {
        final store = SourceDraftGateway(widget.owner, q['key'] as String);
        final draft = await store.loadDraft();
        final images = await store.loadImages();
        if (q['dbQuestionId'] == null ||
            draft.body.trim().isEmpty ||
            images.isNotEmpty ||
            q['inputMode'] == 'image') {
          throw StateError(
            '선택한 문항의 텍스트 답안을 확인해 주세요. 사진 포함 답안은 아직 이 시험에서 제출할 수 없습니다.',
          );
        }
        answers.add({
          'questionId': q['dbQuestionId'],
          'body': draft.body,
          'revision': draft.revision,
        });
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('제출할 답안 확인'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentId == null
                      ? '선택한 ${answers.length}개 문항 · 최초 첨삭 1 Credit'
                      : '동일 문항 집합 · 무료 재첨삭 자격은 서버에서 확인합니다.',
                ),
                for (var i = 0; i < answers.length; i++) ...[
                  Text(selected[i]['label'] as String),
                  Text(answers[i]['body'] as String),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 작성'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('첨삭 요청'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final fingerprint = jsonEncode({
        'parentId': parentId,
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
      final key = prior?['key'] as String? ?? newEssayUuid();
      if (prior == null) {
        await pending.saveLocalDraft(
          jsonEncode({'fingerprint': fingerprint, 'key': key}),
          saved.revision,
        );
      }
      final result = await gateway()?.request({
        'action': 'submit',
        'examId': widget.exam['dbExamId'],
        'key': key,
        'parentId': parentId,
        'answers': answers,
      });
      if (result?['runId'] == null) {
        throw StateError('제출 상태를 확인하지 못했어요. 같은 답안으로 다시 확인해 주세요.');
      }
      if (mounted) {
        setState(() {
          submittedRun = result!['runId'] as String;
          notice = '답안을 제출했어요. 처리 상태를 확인합니다.';
        });
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
              ? (error.code == 'INSUFFICIENT_CREDIT'
                    ? '첨삭권이 부족합니다.'
                    : '제출 조건을 확인해 주세요.')
              : error is StateError
              ? error.message.toString()
              : '연결을 확인하지 못했어요. 답안과 제출 정보는 보존됩니다.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.rewriteRun == null && rewrites.isNotEmpty)
        DropdownButtonFormField<String>(
          initialValue: parentId ?? '',
          decoration: const InputDecoration(labelText: '제출 방식'),
          items: [
            const DropdownMenuItem(value: '', child: Text('새 첨삭 · 1 Credit')),
            for (final r in rewrites)
              DropdownMenuItem(
                value: r['id'] as String,
                child: Text(
                  '무료 재첨삭 · ${r['created_at'].toString().substring(0, 10)}',
                ),
              ),
          ],
          onChanged: busy || submittedRun != null
              ? null
              : (v) => setState(() {
                  parentId = v == '' ? null : v;
                  notice = '';
                }),
        ),
      const CreditBalanceCard(compact: true),
      if (parentId != null)
        const Text('최초 제출과 동일한 문항을 선택하고 답안을 수정해 주세요. 재첨삭 가능 여부는 서버에서 확인합니다.'),
      if (!ready) const Text('현재 첨삭 실행은 비공개 검증 중입니다. 답안 작성과 저장은 계속할 수 있어요.'),
      FilledButton(
        onPressed:
            ready &&
                submittedRun == null &&
                !busy &&
                (parentId == null || rewrites.any((r) => r['id'] == parentId))
            ? submit
            : null,
        child: Text(
          busy
              ? '처리 중…'
              : ready
              ? '답안 제출'
              : '첨삭 실행 대기',
        ),
      ),
      if (parentId != null &&
          eligibilityLoaded &&
          !rewrites.any((r) => r['id'] == parentId))
        const Text('현재 무료 재첨삭 자격이 없습니다. 작성한 답안은 보존됩니다.'),
      if (parentId != null && !eligibilityLoaded)
        const Text('재첨삭 자격을 아직 확인하지 못했어요. 답안은 계속 작성할 수 있습니다.'),
      if (notice.isNotEmpty) Text(notice),
      if (submittedRun != null)
        TextButton(onPressed: pollStatus, child: const Text('처리 상태 새로고침')),
      if (notice.isNotEmpty)
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SharedEssayHistoryPage(),
            ),
          ),
          child: const Text('나의 첨삭 기록'),
        ),
    ],
  );
}

/// Review the existing per-question drafts before using the same exam submission API.
class ExamAnswerReview extends StatefulWidget {
  const ExamAnswerReview({
    super.key,
    required this.owner,
    required this.exam,
    required this.currentQuestion,
    this.rewriteRun,
  });
  final String owner, currentQuestion;
  final Map<String, dynamic> exam;
  final Map<String, dynamic>? rewriteRun;
  @override
  State<ExamAnswerReview> createState() => _ExamAnswerReviewState();
}

class _ExamAnswerReviewState extends State<ExamAnswerReview> {
  late final Set<String> selected = widget.rewriteRun == null
      ? {widget.currentQuestion}
      : (widget.exam['questions'] as List)
            .cast<Map<String, dynamic>>()
            .where(
              (q) => (widget.rewriteRun!['question_ids'] as List).contains(
                q['dbQuestionId'],
              ),
            )
            .map((q) => q['key'] as String)
            .toSet();
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('답안 확인', style: Theme.of(context).textTheme.titleLarge),
          for (final q
              in (widget.exam['questions'] as List)
                  .cast<Map<String, dynamic>>())
            CheckboxListTile(
              title: Text(q['label'] as String),
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
          _ExamSubmit(
            owner: widget.owner,
            exam: widget.exam,
            included: selected,
            rewriteRun: widget.rewriteRun,
          ),
        ],
      ),
    ),
  );
}
