import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/shell_widgets.dart';
import '../personal/personal_providers.dart';
import '../universities/data/university_repository.dart';
import '../universities/domain/university_models.dart';
import 'application_repository.dart';

class ApplicationsEntry extends ConsumerWidget {
  const ApplicationsEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(applicationRepositoryProvider);
    final profile = ref.watch(currentProfileProvider);
    if (repo == null ||
        profile.isLoading ||
        profile.hasError ||
        profile.asData?.value?.id != repo.owner ||
        !canManageApplications(profile.asData?.value)) {
      return const SizedBox.shrink();
    }
    return LsCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LsListRow(
        title: '실제 지원 대학 관리',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ApplicationsPage()),
        ),
      ),
    );
  }
}

class ApplicationsPage extends ConsumerWidget {
  const ApplicationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(applicationRepositoryProvider);
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('실제 지원 대학')),
      body:
          repo == null ||
              profile.isLoading ||
              profile.hasError ||
              profile.asData?.value?.id != repo.owner ||
              !canManageApplications(profile.asData?.value)
          ? const Center(
              child: Text('고3·N수생 프로필에서 이용할 수 있어요. 기존 지원 기록은 보존됩니다.'),
            )
          : _ApplicationList(key: ValueKey(repo.owner)),
    );
  }
}

class _ApplicationList extends ConsumerWidget {
  const _ApplicationList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(applicationsProvider);
    return ShellPage(
      children: [
        const Text('관심 대학과 별도로 실제 지원 내역을 관리해요.'),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => ref.invalidate(applicationsProvider),
          child: const Text('목록 새로고침'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const _Editor())),
          child: const Text('지원 대학 등록하기'),
        ),
        rows.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(applicationsProvider),
            child: const Text('목록을 불러오지 못했어요. 재시도'),
          ),
          data: (items) => Column(
            children: [
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('등록된 지원 내역이 없습니다.'),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.university,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(item.division),
                        Text('${item.year}학년도 · ${item.type} · ${item.track}'),
                        Text(item.status),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _Editor(record: item),
                                ),
                              ),
                              child: const Text('수정'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _History(record: item),
                                ),
                              ),
                              child: const Text('진행·결과 및 이력'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({this.record});
  final ApplicationRecord? record;
  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final form = GlobalKey<FormState>(), keys = ApplicationRequestKey();
  late final TextEditingController year, division, track;
  final query = TextEditingController();
  University? university;
  List<University> results = [];
  String type = '수시', status = 'submitted';
  bool busy = false;
  String? error, savedId;
  String? owner;
  @override
  void initState() {
    super.initState();
    final a = widget.record;
    year = TextEditingController(
      text:
          '${a?.year ?? DateTime.now().toUtc().add(const Duration(hours: 9)).year + 1}',
    );
    division = TextEditingController(text: a?.division);
    track = TextEditingController(text: a?.track);
    type = a?.type ?? '수시';
    if (a != null) {
      university = University(
        id: a.data['university_id'] as String,
        name: a.university,
      );
    }
  }

  @override
  void dispose() {
    for (final c in [year, division, track, query]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> run(Future<void> Function(ApplicationRepository) action) async {
    final repo = ref.read(applicationRepositoryProvider);
    if (busy || repo == null || repo.owner != owner) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action(repo);
    } catch (e) {
      if (mounted && ref.read(applicationRepositoryProvider)?.owner == owner) {
        setState(() => error = applicationError(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(applicationRepositoryProvider);
    owner ??= repo?.owner;
    if (repo == null || repo.owner != owner) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('계정이 변경됐어요. 이전 화면으로 돌아가 주세요.')),
      );
    }
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.record == null ? '지원 대학 등록' : '지원 정보 수정'),
        ),
        body: ShellPage(
          children: [
            if (savedId == null) ...[
              TextField(
                controller: query,
                enabled: !busy,
                decoration: const InputDecoration(labelText: '대학 검색'),
                onChanged: (_) => setState(() => results = []),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => run((r) async {
                        final q = query.text.trim();
                        if (q.isEmpty) return;
                        final rows = await ref
                            .read(universityRepositoryProvider)!
                            .searchCatalog(q);
                        r.checkOwner();
                        if (mounted) {
                          setState(() {
                            results = rows;
                            if (rows.isEmpty) error = '검색 결과가 없습니다.';
                          });
                        }
                      }),
                child: const Text('검색'),
              ),
              for (final u in results)
                ListTile(
                  title: Text(u.name),
                  onTap: busy
                      ? null
                      : () => setState(() {
                          university = u;
                          results = [];
                        }),
                ),
              Text(university?.name ?? '대학을 선택해 주세요.'),
              Form(
                key: form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: year,
                      enabled: !busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '지원 학년도'),
                      validator: (v) {
                        final y = int.tryParse(v ?? '');
                        return y == null || y < 1900 || y > 2200
                            ? '학년도를 확인해 주세요.'
                            : null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      items: {'수시', '정시', type}
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: busy ? null : (v) => setState(() => type = v!),
                      decoration: const InputDecoration(labelText: '모집 시기'),
                    ),
                    for (final pair in [(division, '모집단위·학과'), (track, '전형명')])
                      TextFormField(
                        controller: pair.$1,
                        enabled: !busy,
                        maxLength: 120,
                        decoration: InputDecoration(labelText: pair.$2),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '입력해 주세요.' : null,
                      ),
                    if (widget.record == null)
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        items: applicationStates.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => status = v!),
                        decoration: const InputDecoration(
                          labelText: '현재 지원 상태',
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              const Text('지원 정보는 저장됐어요. 상태 기록 저장을 다시 시도해 주세요.'),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => run((r) async {
                      if (savedId == null) {
                        if (!(form.currentState?.validate() ?? false) ||
                            university == null) {
                          setState(() => error = '대학과 입력 항목을 확인해 주세요.');
                          return;
                        }
                        final input = <String, dynamic>{
                          'p_id': widget.record?.id,
                          'p_revision': widget.record?.revision ?? 0,
                          'p_year': int.parse(year.text),
                          'p_university': university!.id,
                          'p_division': division.text.trim(),
                          'p_admission_type': type,
                          'p_admission_name': track.text.trim(),
                        };
                        savedId = await r.save(input, keys.forInput(input));
                        ref.invalidate(applicationsProvider);
                      }
                      if (widget.record == null) {
                        await r.event(
                          savedId!,
                          status,
                          null,
                          keys.forInput({'id': savedId, 'kind': status}),
                        );
                      }
                      ref.invalidate(applicationsProvider);
                      if (context.mounted) Navigator.pop(context);
                    }),
              child: Text(busy ? '저장 중…' : '저장'),
            ),
          ],
        ),
      ),
    );
  }
}

class _History extends ConsumerStatefulWidget {
  const _History({required this.record});
  final ApplicationRecord record;
  @override
  ConsumerState<_History> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<_History> {
  final keys = ApplicationRequestKey();
  List<Map<String, dynamic>>? events;
  String kind = 'submitted';
  String? supersedes, error, owner;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> run(Future<void> Function(ApplicationRepository) action) async {
    final r = ref.read(applicationRepositoryProvider);
    if (r == null || busy || r.owner != owner) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action(r);
    } catch (e) {
      if (mounted) setState(() => error = applicationError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() => run((r) async {
    final rows = await r.history(widget.record.id);
    if (mounted) setState(() => events = rows);
  });
  @override
  Widget build(BuildContext context) {
    final r = ref.watch(applicationRepositoryProvider);
    owner ??= r?.owner;
    if (r == null || r.owner != owner) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('계정이 변경됐어요.')),
      );
    }
    final replaced = {
      for (final e in events ?? <Map<String, dynamic>>[])
        if (e['supersedes_event_id'] != null) e['supersedes_event_id'],
    };
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.record.university)),
        body: ShellPage(
          children: [
            const Text(
              '상태 변경은 이력으로 남아요. 잘못 입력한 기록은 아래에서 정정해 주세요. 발생 일시는 미입력으로 기록됩니다.',
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('$kind/$supersedes'),
              initialValue: kind,
              items: applicationStates.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: busy ? null : (v) => setState(() => kind = v!),
            ),
            if (supersedes != null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => supersedes = null),
                child: const Text('이전 기록을 보존하며 정정합니다 · 취소'),
              ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => run((repo) async {
                      await repo.event(
                        widget.record.id,
                        kind,
                        supersedes,
                        keys.forInput({
                          'id': widget.record.id,
                          'kind': kind,
                          'supersedes': supersedes,
                        }),
                      );
                      ref.invalidate(applicationsProvider);
                      final rows = await repo.history(widget.record.id);
                      if (mounted) {
                        setState(() {
                          events = rows;
                          supersedes = null;
                        });
                      }
                    }),
              child: const Text('진행·결과 저장'),
            ),
            if (error != null) Text(error!),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('이력 새로고침'),
            ),
            if (events == null) const Text('이력을 불러오는 중입니다.'),
            for (final e in events ?? <Map<String, dynamic>>[])
              ListTile(
                title: Text(eventLabel(e['kind'] as String)),
                subtitle: Text(
                  '기록: ${e['recorded_at']}${e['occurred_at'] == null ? '' : '\n발생: ${e['occurred_at']}'}${e['supersedes_event_id'] == null ? '' : ' · 정정 기록'}${replaced.contains(e['id']) ? ' · 정정됨' : ''}',
                ),
                trailing:
                    applicationStates.containsKey(e['kind']) &&
                        !replaced.contains(e['id'])
                    ? TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                supersedes = e['id'] as String;
                                kind = e['kind'] as String;
                              }),
                        child: const Text('정정'),
                      )
                    : null,
              ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => run((repo) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('지원 내역을 삭제할까요?'),
                          content: const Text('이 지원 내역과 기록한 이력이 함께 삭제됩니다.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await repo.delete(widget.record.id);
                      ref.invalidate(applicationsProvider);
                      if (context.mounted) Navigator.pop(context);
                    }),
              child: const Text('지원 내역 삭제'),
            ),
          ],
        ),
      ),
    );
  }
}
