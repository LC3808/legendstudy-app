import 'dart:async';
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
  const SourceCatalogPage({super.key, this.catalog});
  final Future<SourceCatalog>? catalog;
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
  });
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
      onChanged: options.isEmpty ? null : change,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('대학 · 시험 선택'),
      actions: [
        IconButton(
          tooltip: '나의 첨삭 기록',
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
              if (RegExp('인문|언어|사회|경제|경영|상경').hasMatch(t ?? ''))
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
                          onChanged: (v) => setState(() {
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
              const FilledButton(onPressed: null, child: Text('첨삭 준비 중')),
            ],
          ],
        );
      },
    ),
  );
}

class _SourceWriter extends ConsumerStatefulWidget {
  const _SourceWriter({
    required this.owner,
    required this.question,
    required this.exam,
    this.officialUrl,
  });
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
                                            .from('essay-student-questions')
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
                      DraftStatus.saved => '이 기기에 저장했습니다. 다른 기기와 동기화되지 않습니다.',
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
                  const FilledButton(onPressed: null, child: Text('첨삭 준비 중')),
                ],
              ),
      ),
    );
  }
}
