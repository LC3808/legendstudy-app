import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/links/external_link.dart';
import '../../shared/widgets/shell_widgets.dart';
import 'essay_live_gateway.dart';
import '../credits/credit_balance.dart';
import 'essay_live_controller.dart';
import 'essay_models.dart';
import 'essay_pages.dart';

const essayLiveWritesEnabled = bool.fromEnvironment(
  'ESSAY_LIVE_WRITES_ENABLED',
);
const essayEvaluationRequestsEnabled = bool.fromEnvironment(
  'ESSAY_EVALUATION_REQUESTS_ENABLED',
);

class EssayLiveHome extends ConsumerStatefulWidget {
  const EssayLiveHome({super.key});
  @override
  ConsumerState<EssayLiveHome> createState() => _EssayLiveHomeState();
}

class _EssayLiveHomeState extends ConsumerState<EssayLiveHome> {
  late final Future<List<Map<String, dynamic>>> questions;
  String? university, exam;
  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);
    questions = client == null
        ? Future.value([])
        : client
              .from('essay_questions')
              .select(
                'id,label,essay_exam_id,essay_exams(exam_name,admission_year,universities(name))',
              )
              .eq('is_published', true);
  }

  String uni(Map<String, dynamic> q) =>
      ((q['essay_exams'] as Map)['universities'] as Map)['name'] as String;
  String examLabel(Map<String, dynamic> q) {
    final e = q['essay_exams'] as Map;
    return '${e['admission_year']} ${e['exam_name']}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Essay LAB')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: questions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState('문항을 불러오지 못했어요. 잠시 후 다시 확인해 주세요.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return const EmptyState('공식 문항 자료를 준비하고 있어요. 준비된 문항부터 안내할게요.');
        }
        final universities = rows.map(uni).toSet();
        final selected = university ?? universities.first;
        final exams = rows.where((q) => uni(q) == selected).toList();
        final selectedExam = exam ?? exams.first['essay_exam_id'] as String;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!essayLiveWritesEnabled)
              const Text('실제 답안 저장과 첨삭 연결을 준비하고 있어요.'),
            const SectionHeader('대학 · 시험 선택'),
            DropdownButtonFormField<String>(
              initialValue: selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '대학'),
              items: [
                for (final u in universities)
                  DropdownMenuItem(value: u, child: Text(u)),
              ],
              onChanged: (v) => setState(() {
                university = v;
                exam = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(selected),
              initialValue: selectedExam,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '학년도 · 시험'),
              items: [
                for (final id
                    in exams.map((q) => q['essay_exam_id'] as String).toSet())
                  DropdownMenuItem(
                    value: id,
                    child: Text(
                      examLabel(
                        exams.firstWhere((q) => q['essay_exam_id'] == id),
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => exam = v),
            ),
            const SectionHeader('문항 선택'),
            for (final q in exams.where(
              (q) => q['essay_exam_id'] == selectedExam,
            ))
              ListTile(
                title: Text(q['label'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/lab/essay/write/${q['id']}'),
              ),
          ],
        );
      },
    ),
  );
}

class EssayLiveWorkspace extends ConsumerStatefulWidget {
  const EssayLiveWorkspace({required this.questionId, super.key});
  final String questionId;
  @override
  ConsumerState<EssayLiveWorkspace> createState() => _EssayLiveWorkspaceState();
}

class _EssayLiveWorkspaceState extends ConsumerState<EssayLiveWorkspace> {
  EssayLiveController? controller;
  EssayQuestion? question;
  String? error;
  bool loading = false;
  StreamSubscription<dynamic>? auth;
  int epoch = 0;
  String? identity;
  SupabaseEssayGateway? activeGateway;
  @override
  void initState() {
    super.initState();
    final client = ref.read(supabaseClientProvider);
    identity = client?.auth.currentUser?.id;
    if (client != null) {
      auth = client.auth.onAuthStateChange.listen((event) {
        final next = client.auth.currentUser?.id;
        if (next != identity) {
          identity = next;
          activeGateway?.revoke();
          epoch++;
          controller?.dispose();
          controller = null;
          question = null;
          if (mounted) {
            setState(() {
              loading = false;
              error = '계정이 변경됐어요. 학습 기록을 다시 열어 주세요.';
            });
          }
        }
      });
    }
    unawaited(load());
  }

  Future<void> load() async {
    final generation = ++epoch;
    controller?.dispose();
    controller = null;
    activeGateway?.revoke();
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() => error = '서버 연결을 준비하고 있어요.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    SupabaseEssayGateway? gateway;
    try {
      final store = SupabaseEssayStore(client);
      gateway = SupabaseEssayGateway(
        store,
        questionId: widget.questionId,
        writesEnabled: essayLiveWritesEnabled,
        evaluationsEnabled: essayEvaluationRequestsEnabled,
      );
      activeGateway = gateway;
      final rows = await store.rows('essay_questions', {
        'id': widget.questionId,
        'is_published': true,
      });
      if (rows.length != 1) throw const EssayClientError('PT404');
      final q = rows.single;
      final exams = await store.rows('essay_exams', {
        'id': q['essay_exam_id'] as String,
      });
      final exam = exams.single;
      final universities = await store.rows('universities', {
        'id': exam['university_id'] as String,
      });
      final model = EssayQuestion(
        id: q['id'] as String,
        university: universities.single['name'] as String,
        exam: '${exam['admission_year']} ${exam['exam_name']}',
        title: q['label'] as String,
        prompt: '문제와 제시문은 아래 대학 공식 원문에서 확인해 주세요.',
        passages: const [],
        origin: CriteriaOrigin.derived,
        availability: EssayAvailability.officialBasis,
        minLength: q['length_min'] as int?,
        maxLength: q['length_max'] as int?,
        examMinutes: exam['duration_minutes'] as int?,
        officialSource: exam['official_source_url'] == null
            ? null
            : Uri.tryParse(exam['official_source_url'] as String),
      );
      if (mounted && generation == epoch) question = model;
      if (store.userId == null) {
        if (mounted && generation == epoch) {
          setState(() {
            question = model;
            error = '답안 작성과 학습 기록은 로그인 후 이용할 수 있어요.';
          });
        }
        return;
      }
      final draft = await gateway.open();
      if (!mounted || generation != epoch) {
        gateway.revoke();
        return;
      }
      controller = EssayLiveController(gateway, draft);
      controller!.addListener(() {
        if (mounted) ref.invalidate(creditBalanceProvider);
      });
      question = model;
      await controller!.restore();
    } catch (e) {
      gateway?.revoke();
      if (mounted && generation == epoch) {
        error = (e is EssayClientError ? e : const EssayClientError('NETWORK'))
            .message;
      }
    } finally {
      if (mounted && generation == epoch) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    epoch++;
    auth?.cancel();
    activeGateway?.revoke();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null && question != null && !loading && error == null) {
      return EssayWorkspacePage(question: question!, controller: controller);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('논술 첨삭')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (question != null)
                      Text('${question!.university} · ${question!.title}'),
                    Text(error ?? '문항을 준비하고 있어요.'),
                    if (question?.officialSource != null)
                      ExternalLinkButton(
                        uri: question!.officialSource,
                        label: '대학 공식 원문 보기',
                      ),
                    TextButton(onPressed: load, child: const Text('다시 확인')),
                  ],
                ),
        ),
      ),
    );
  }
}
