import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/links/external_link.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../applications/application_repository.dart';
import '../../applications/applications_page.dart';
import '../../personal/personal_providers.dart';
import 'university_news.dart';

class UniversityNewsCard extends ConsumerWidget {
  const UniversityNewsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Padding(
    padding: EdgeInsets.only(top: 16),
    child: LsCard(child: _NewsBody(home: true)),
  );
}

class UniversityNewsPage extends StatelessWidget {
  const UniversityNewsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('나의 대학 소식')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: _NewsBody(home: false),
    ),
  );
}

class _NewsBody extends ConsumerStatefulWidget {
  const _NewsBody({required this.home});
  final bool home;
  @override
  ConsumerState<_NewsBody> createState() => _NewsBodyState();
}

class _NewsBodyState extends ConsumerState<_NewsBody>
    with WidgetsBindingObserver {
  Timer? timer;
  int source = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(universityNewsProvider);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final feed = ref.watch(universityNewsProvider);
    final now = DateTime.now().toUtc();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.home)
          const Text(
            '나의 대학 소식',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        if (auth.isLoading)
          const LinearProgressIndicator()
        else if (auth.asData?.value.userId == null) ...[
          const Text('로그인하면 등록한 대학의 소식을 확인할 수 있어요.'),
          TextButton(
            onPressed: () => context.push('/auth'),
            child: const Text('로그인'),
          ),
        ] else
          feed.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(semanticsLabel: '대학 소식 확인 중'),
            ),
            error: (error, _) => Column(
              children: [
                Text(universityNewsError(error)),
                TextButton(
                  onPressed: () => ref.invalidate(universityNewsProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
            data: (data) {
              if (data.emptyUniversities) {
                return const _UniversityLinks(empty: true);
              }
              final all = matchUniversityNews(
                data.items,
                data.applications,
                data.interests,
                now,
              );
              final rows =
                  matchUniversityNews(
                        data.items,
                        data.applications,
                        data.interests,
                        now,
                        home: widget.home,
                      )
                      .where(
                        (r) =>
                            source == 0 ||
                            (source == 1 ? r.application : r.interest),
                      )
                      .toList();
              final missingTrack = data.applications.any(
                (a) => !data.items.any(
                  (i) => i.isSchedule && i.matchesApplication(a),
                ),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.home)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (var i = 0; i < 3; i++)
                          ChoiceChip(
                            label: Text(['전체', '실제 지원 대학', '희망 대학'][i]),
                            selected: source == i,
                            onSelected: (_) => setState(() => source = i),
                          ),
                      ],
                    ),
                  if (all.isEmpty) const Text('공식 일정·소식이 아직 없어요. 일정 확인 중'),
                  if (missingTrack)
                    const Text('등록한 전형 중 연결된 공식 일정이 없는 전형이 있어요. 일정 확인 중'),
                  if (all.any((r) => r.item.stale(now)))
                    const Text('재확인이 필요한 자료가 있어요. 공식 출처를 확인해 주세요.'),
                  if (widget.home && rows.isEmpty && all.isNotEmpty)
                    const Text('다가오는 확인된 일정이나 최신 소식이 없어요.'),
                  for (final kind
                      in widget.home ? [null] : ['schedule', 'news']) ...[
                    if (kind != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          kind == 'schedule' ? '주요 일정' : '대학별 소식',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    for (final row in rows.where(
                      (r) => kind == null || r.item.data['kind'] == kind,
                    ))
                      _NewsTile(row: row, now: now),
                    if (kind != null &&
                        !rows.any((r) => r.item.data['kind'] == kind))
                      const Text('해당하는 공식 정보가 없어요.'),
                  ],
                  if (widget.home)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const UniversityNewsPage(),
                        ),
                      ),
                      child: const Text('전체 보기'),
                    )
                  else ...[
                    TextButton(
                      onPressed: () => ref.invalidate(universityNewsProvider),
                      child: const Text('새로고침'),
                    ),
                    const _UniversityLinks(empty: false),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _UniversityLinks extends ConsumerWidget {
  const _UniversityLinks({required this.empty});
  final bool empty;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final owner = ref.watch(authStateProvider).asData?.value.userId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (empty) const Text('관심 있는 대학을 등록하고 맞춤 입시 정보를 받아보세요.'),
        TextButton(
          onPressed: () => context.push('/my/aspirations'),
          child: Text(empty ? '희망 대학 등록하기' : '희망 대학 관리'),
        ),
        if (!profile.isLoading &&
            !profile.hasError &&
            profile.asData?.value?.id == owner &&
            canManageApplications(profile.asData?.value))
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ApplicationsPage()),
            ),
            child: Text(empty ? '지원 대학 등록하기' : '실제 지원 대학 관리'),
          ),
      ],
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.row, required this.now});
  final MatchedUniversityNews row;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final item = row.item;
    String day(Object? value) => value == null
        ? '미확인'
        : koreanDay(DateTime.parse(value as String))
              .toIso8601String()
              .substring(0, 10);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              item.data['university_name'],
              if (item.year != null) '${item.year}학년도',
              item.round,
              item.track,
              item.division,
            ].whereType<String>().join(' · '),
          ),
          Text(
            item.data['title'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (item.isSchedule) Text(item.dateLabel(now)),
          if (!item.isSchedule && item.stale(now))
            const Text('오래된 정보 · 재확인 필요'),
          if (item.important(now) && !item.stale(now)) const Text('중요 · 등록 마감'),
          Text(
            '게시 ${day(item.data['published_at'])} · 확인 ${day(item.data['verified_at'])}',
          ),
          Text(
            '수정 ${day(item.data['updated_at'])} · 버전 ${item.data['revision']}${(item.data['revision'] as int) > 1 ? ' · 변경된 공지' : ''}',
          ),
          ExternalLinkButton(
            uri: Uri.parse(item.data['source_url'] as String),
            label: item.data['source_title'] as String,
          ),
          if (item.data['event_type'] == 'essay_past_paper')
            TextButton(
              onPressed: () => context.push(
                Uri(
                  path: '/materials',
                  queryParameters: {
                    'type': 'university_essay',
                    'q': item.data['university_name'] as String,
                  },
                ).toString(),
              ),
              child: const Text('논술 자료실'),
            ),
        ],
      ),
    );
  }
}
