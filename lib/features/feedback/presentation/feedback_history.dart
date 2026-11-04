import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';

final supportHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, offset) async {
      final auth = ref.watch(authStateProvider);
      if (auth.isLoading || auth.value?.userId == null) return [];
      final client = ref.watch(supabaseClientProvider);
      if (client == null) throw const BackendUnavailable('문의 내역을 불러올 수 없어요.');
      final result = await client.rpc<Map<String, dynamic>>(
        'support_mine',
        params: {
          'p': {'dto_version': 'inquiry-v1', 'limit': 20, 'offset': offset},
        },
      );
      return (result['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });
final supportDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, (String, String)>((ref, key) async {
      final auth = ref.watch(authStateProvider);
      if (auth.isLoading || auth.value?.userId == null) {
        throw const SignedOutException();
      }
      final client = ref.watch(supabaseClientProvider);
      if (client == null) throw const BackendUnavailable('답변을 불러올 수 없어요.');
      return client.rpc<Map<String, dynamic>>(
        'support_detail',
        params: {
          'p': {'dto_version': 'inquiry-v1', 'source': key.$1, 'id': key.$2},
        },
      );
    });
String supportStatusLabel(String status) => switch (status) {
  'RECEIVED' => '접수',
  'IN_PROGRESS' => '처리 중',
  'ANSWERED' => '답변 완료',
  'CLOSED' => '종결',
  _ => status,
};

class FeedbackHistory extends ConsumerStatefulWidget {
  const FeedbackHistory({super.key});
  @override
  ConsumerState<FeedbackHistory> createState() => _FeedbackHistoryState();
}

class _FeedbackHistoryState extends ConsumerState<FeedbackHistory> {
  int offset = 0;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return const LinearProgressIndicator();
    if (auth.value?.userId == null) {
      return const Text('로그인 후 접수한 문의와 답변을 여기서 확인할 수 있어요.');
    }
    final history = ref.watch(supportHistoryProvider(offset));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '내 문의·답변',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: '문의 내역 새로고침',
              onPressed: () => ref.invalidate(supportHistoryProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        history.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, s) => TextButton(
            onPressed: () => ref.invalidate(supportHistoryProvider),
            child: const Text('문의 내역을 불러오지 못했어요. 다시 시도'),
          ),
          data: (items) => Column(
            children: [
              if (items.isEmpty) const Text('접수한 문의가 없습니다.'),
              for (final item in items)
                ListTile(
                  title: Text(item['title'] as String),
                  subtitle: Text(
                    '${item['source']} · ${supportStatusLabel(item['status'] as String)} · ${DateTime.parse(item['created_at'] as String).toLocal().toString().substring(0, 16)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SupportReplyPage(
                        source: item['source'] as String,
                        id: item['inquiry_id'] as String,
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: offset == 0
                        ? null
                        : () => setState(() => offset -= 20),
                    child: const Text('이전'),
                  ),
                  TextButton(
                    onPressed: items.length < 20
                        ? null
                        : () => setState(() => offset += 20),
                    child: const Text('다음'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SupportReplyPage extends ConsumerWidget {
  const SupportReplyPage({super.key, required this.source, required this.id});
  final String source, id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(supportDetailProvider((source, id)));
    return Scaffold(
      appBar: AppBar(title: const Text('문의·답변')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: TextButton(
            onPressed: () =>
                ref.invalidate(supportDetailProvider((source, id))),
            child: const Text('답변을 불러오지 못했어요. 다시 시도'),
          ),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              item['title'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(supportStatusLabel(item['status'] as String)),
            const SizedBox(height: 16),
            Text(item['body'] as String),
            const Divider(),
            const Text('관리자 답변'),
            if ((item['replies'] as List).isEmpty) const Text('아직 답변이 없습니다.'),
            for (final reply in item['replies'] as List)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateTime.parse(reply['created_at'] as String)
                          .toLocal()
                          .toString()
                          .substring(0, 16),
                    ),
                    SelectableText(reply['body'] as String),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
