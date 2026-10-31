import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';

const noticeCategories = {
  'general': '일반 공지',
  'update': '서비스 업데이트',
  'beta': '베타 테스트',
  'maintenance': '서비스 점검',
  'policy': '이용 정책',
  'event': '이벤트',
};

class Notice {
  Notice.fromJson(Map<String, dynamic> j)
    : id = j['notice_id'] as String,
      title = j['title'] as String,
      content = j['content'] as String,
      category = j['category'] as String,
      pinned = j['is_pinned'] == true,
      read = j['is_read'] == true,
      updatedAt = j['updated_at'] as String,
      publishedAt = j['published_at'] as String?;
  final String id, title, content, category, updatedAt;
  final String? publishedAt;
  final bool pinned, read;
}

class NoticeFeed {
  NoticeFeed.fromJson(Map<String, dynamic> j)
    : items = (j['items'] as List)
          .map((e) => Notice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total = (j['total'] as num).toInt(),
      unread = (j['unread'] as num).toInt();
  final List<Notice> items;
  final int total, unread;
}

abstract interface class NoticeApi {
  Future<NoticeFeed> list(int offset);
  Future<Notice?> detail(String id);
  Future<bool> markRead(Notice notice);
}

final noticeApiProvider = Provider<NoticeApi?>((ref) {
  final c = ref.watch(supabaseClientProvider);
  return c == null ? null : _NoticeApi(c);
});

class _NoticeApi implements NoticeApi {
  _NoticeApi(this.client);
  final SupabaseClient client;
  @override
  Future<NoticeFeed> list(int offset) async => NoticeFeed.fromJson(
    Map<String, dynamic>.from(
      await client.rpc<dynamic>(
        'notice_list',
        params: {'p_channel': 'app', 'p_offset': offset, 'p_limit': 20},
      ) as Map,
    ),
  );
  @override
  Future<Notice?> detail(String id) async {
    final data = await client.rpc<dynamic>(
      'notice_detail',
      params: {'p_notice_id': id, 'p_channel': 'app'},
    );
    return data == null
        ? null
        : Notice.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<bool> markRead(Notice n) async =>
      await client.rpc<dynamic>(
        'notice_mark_read',
        params: {
          'p_notice_id': n.id,
          'p_channel': 'app',
          'p_updated_at': n.updatedAt,
        },
      ) ==
      true;
}

final noticeFeedProvider = FutureProvider.autoDispose.family<NoticeFeed, int>((
  ref,
  offset,
) async {
  ref.watch(authStateProvider);
  final api = ref.watch(noticeApiProvider);
  if (api == null) throw const BackendUnavailable('공지사항 연결을 확인해 주세요.');
  return api.list(offset);
});
final noticeUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  final signed =
      ref.watch(authStateProvider).asData?.value.isAuthenticated == true;
  if (!signed || ref.watch(noticeApiProvider) == null) return 0;
  final timer = Timer.periodic(
    const Duration(seconds: 60),
    (_) => ref.invalidate(noticeFeedProvider),
  );
  ref.onDispose(timer.cancel);
  try {
    return (await ref.watch(noticeFeedProvider(0).future)).unread;
  } catch (_) {
    return 0;
  }
});
final noticeDetailProvider = FutureProvider.autoDispose.family<Notice?, String>(
  (ref, id) async {
    final auth = ref.watch(authStateProvider).asData?.value;
    final api = ref.watch(noticeApiProvider);
    if (api == null) throw const BackendUnavailable('공지사항 연결을 확인해 주세요.');
    final notice = await api.detail(id);
    // Reading content succeeds independently from saving the receipt.
    if (notice != null &&
        auth?.isAuthenticated == true &&
        ref.mounted &&
        ref.read(authStateProvider).asData?.value.userId == auth?.userId) {
      try {
        if (await api.markRead(notice) && ref.mounted) {
          ref.invalidate(noticeFeedProvider);
          ref.invalidate(noticeUnreadProvider);
        }
      } catch (_) {
        /* keep unread until confirmed by server */
      }
    }
    return notice;
  },
);

class NoticesPage extends ConsumerStatefulWidget {
  const NoticesPage({super.key});
  @override
  ConsumerState<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends ConsumerState<NoticesPage>
    with WidgetsBindingObserver {
  int offset = 0;
  Timer? refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh = Timer.periodic(const Duration(seconds: 60), (_) {
      ref.invalidate(noticeFeedProvider);
    });
  }

  @override
  void dispose() {
    refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(noticeFeedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final signed =
        ref.watch(authStateProvider).asData?.value.isAuthenticated == true;
    final data = ref.watch(noticeFeedProvider(offset));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(noticeFeedProvider);
        try {
          await ref.read(noticeFeedProvider(offset).future);
        } catch (_) {
          // The feed renders the retry state; keep refresh failures in the UI.
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Column(
              children: [
                const Text('공지사항을 불러오지 못했어요.'),
                TextButton(
                  onPressed: () => ref.invalidate(noticeFeedProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
            data: (feed) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (signed) Text('읽지 않은 공지 ${feed.unread}개'),
                if (feed.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('게시된 공지사항이 없습니다.'),
                  ),
                for (final n in feed.items)
                  Card(
                    child: ListTile(
                      title: Text(n.title),
                      subtitle: Text(
                        '${n.pinned ? '고정 · ' : ''}${noticeCategories[n.category] ?? n.category}${signed && !n.read ? ' · NEW' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await context.push('/notices/${n.id}');
                        if (!mounted) return;
                        ref.invalidate(noticeFeedProvider);
                        ref.invalidate(noticeUnreadProvider);
                      },
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: offset > 0
                          ? () => setState(() => offset -= 20)
                          : null,
                      child: const Text('이전'),
                    ),
                    Text(
                      '${offset ~/ 20 + 1} / ${((feed.total + 19) ~/ 20).clamp(1, 999999)}',
                    ),
                    TextButton(
                      onPressed: offset + 20 < feed.total
                          ? () => setState(() => offset += 20)
                          : null,
                      child: const Text('다음'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoticeDetailPage extends ConsumerWidget {
  const NoticeDetailPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(noticeDetailProvider(id))
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(noticeDetailProvider(id)),
            child: const Text('공지를 불러오지 못했어요. 다시 시도'),
          ),
        ),
        data: (n) => n == null
            ? const Center(child: Text('게시가 종료되었거나 볼 수 없는 공지입니다.'))
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(n.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(noticeCategories[n.category] ?? n.category),
                  if (n.publishedAt != null)
                    Text(n.publishedAt!.split('T').first),
                  const Divider(height: 32),
                  SelectableText(n.content),
                ],
              ),
      );
}
