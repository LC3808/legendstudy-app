import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import 'source_draft.dart';
import 'source_catalog_page.dart' show essayWritingDraftKey;

/// Selection reads existing owner-scoped drafts only: no session creation,
/// submission or evaluation. The writer retains its existing sync/CAS contract.
class ExamDraftActions extends ConsumerStatefulWidget {
  const ExamDraftActions({
    super.key,
    required this.owner,
    required this.questions,
    required this.onWrite,
    required this.onReview,
    this.rewriteRun,
  });
  final String owner;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic>? rewriteRun;
  final Future<void> Function() onWrite, onReview;
  @override
  ConsumerState<ExamDraftActions> createState() => _ExamDraftActionsState();
}

class _ExamDraftActionsState extends ConsumerState<ExamDraftActions> {
  late Future<int> written = load();
  bool busy = false;
  Future<int> load() async {
    var count = 0;
    for (final q in widget.questions) {
      final store = SourceDraftGateway(
        widget.owner,
        essayWritingDraftKey(q['key'] as String, widget.rewriteRun),
      );
      var local = await store.loadDraft();
      var images = await store.loadImages();
      if (local.body.isEmpty && images.isEmpty) {
        String body = '';
        if (widget.rewriteRun != null) {
          body =
              ((widget.rewriteRun!['answers'] as List?) ?? [])
                      .where((a) => a['questionId'] == q['dbQuestionId'])
                      .firstOrNull?['body']
                  as String? ??
              '';
          // Same migration order as the writer: unfinished local edits take
          // priority over seeding from an already submitted history answer.
          final legacyStore = SourceDraftGateway(
            widget.owner,
            q['key'] as String,
          );
          final legacy = await legacyStore.loadDraft();
          if (legacy.body.isNotEmpty && legacy.body != body) body = legacy.body;
          final legacyImages = await legacyStore.loadImages();
          if (legacyImages.isNotEmpty &&
              mounted &&
              ref.read(authStateProvider).value?.userId == widget.owner) {
            images = await store.loadImages();
            if (images.isEmpty) {
              await store.saveImages(legacyImages);
              images = legacyImages;
            }
          }
        } else {
          final client = ref.read(supabaseClientProvider);
          if (client?.auth.currentUser?.id == widget.owner &&
              q['dbQuestionId'] is String) {
            try {
              final rows = await client!
                  .from('essay_practice_sessions')
                  .select('id,essay_drafts(body)')
                  .eq('user_id', widget.owner)
                  .eq('question_id', q['dbQuestionId'] as String)
                  .limit(1);
              if (client.auth.currentUser?.id != widget.owner) return 0;
              final draft = rows.firstOrNull?['essay_drafts'];
              if (draft is Map) {
                body = draft['body'] as String? ?? '';
              } else if (draft is List &&
                  draft.isNotEmpty &&
                  draft.first is Map) {
                body = (draft.first as Map)['body'] as String? ?? '';
              }
            } catch (_) {
              /* Offline/unavailable: device draft remains authoritative. */
            }
          }
        }
        if (body.isNotEmpty &&
            mounted &&
            ref.read(authStateProvider).value?.userId == widget.owner) {
          // Reload before copying: never overwrite a concurrently edited local draft.
          local = await store.loadDraft();
          if (local.body.isEmpty) {
            local = await store.saveLocalDraft(body, local.revision);
          }
        }
      }
      if (local.body.trim().isNotEmpty || images.isNotEmpty) count++;
    }
    return count;
  }

  Future<void> open(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          written = load();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading ||
        auth.hasError ||
        (auth.value?.userId ?? 'guest') != widget.owner) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<int>(
      future: written,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (count > 0)
              Text(
                count == widget.questions.length
                    ? '선택한 문항의 답안이 모두 저장돼 있어요.'
                    : '선택한 ${widget.questions.length}문항 중 $count문항에 저장된 답안이 있어요.',
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.textPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              onPressed: busy ? null : () => open(widget.onWrite),
              child: Text(
                count > 0
                    ? '답안 이어쓰기'
                    : snapshot.connectionState != ConnectionState.done
                    ? '답안 열기'
                    : '답안 작성하기',
              ),
            ),
            if (count > 0)
              OutlinedButton(
                onPressed: busy ? null : () => open(widget.onReview),
                child: const Text('답안 확인하기'),
              ),
            if (snapshot.hasError)
              const Text('저장 상태를 확인하지 못했어요. 작성 화면에서 다시 확인해 주세요.'),
          ],
        );
      },
    );
  }
}
