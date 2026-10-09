import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'shared_history.dart';

class SharedEssayHistoryPage extends ConsumerWidget {
  const SharedEssayHistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('나의 논술 기록')),
      body: owner == null
          ? const Center(child: Text('로그인 상태를 확인해 주세요.'))
          : _HistoryBody(key: ValueKey(owner), owner: owner),
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.owner, super.key});
  final String owner;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sharedEssayHistoryProvider(owner));
    return history.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(sharedEssayHistoryProvider(owner)),
          child: const Text('기록을 불러오지 못했어요. 다시 시도'),
        ),
      ),
      data: (rows) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sharedEssayHistoryProvider(owner));
          await ref.read(sharedEssayHistoryProvider(owner).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text('논술·수리논술 각각 최근 답안 50개'),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('아직 첨삭 기록이 없습니다.'),
              ),
            for (final row in rows)
              ListTile(
                title: Text(
                  '${row.math ? '수리논술' : '논술'} · ${row.rewrite ? '재작성' : '최초 답안'}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.at.toLocal().toString().substring(0, 16)),
                    if (row.evaluations.isEmpty) const Text('평가 요청 전'),
                    for (final e in row.evaluations)
                      e['state'] == 'COMPLETED'
                          ? TextButton(
                              onPressed: () async {
                                final client = ref.read(supabaseClientProvider);
                                if (client == null) return;
                                try {
                                  final text = await SharedEssayHistory(
                                    client,
                                    owner,
                                  ).evaluationText(row.math, e['id'] as String);
                                  if (!context.mounted ||
                                      ref
                                              .read(authStateProvider)
                                              .value
                                              ?.userId !=
                                          owner) {
                                    return;
                                  }
                                  // Detail stays on this owner-keyed page; account switch removes it.
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          _Result(owner: owner, text: text),
                                    ),
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('평가를 불러오지 못했어요.'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('첨삭 결과 보기'),
                            )
                          : Text(switch (e['state']) {
                              'PROCESSING' => '첨삭 중',
                              'QUEUED' => '대기 중',
                              'FAILED' => '첨삭 실패',
                              'INVALIDATED' => '평가 확인 필요',
                              _ => '상태 확인 필요',
                            }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.owner, required this.text});
  final String owner, text;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('첨삭 결과')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: SelectableText(
            !auth.isLoading && !auth.hasError && auth.value?.userId == owner
                ? text
                : '로그인 상태가 변경되었습니다.',
          ),
        ),
      ),
    );
  }
}
