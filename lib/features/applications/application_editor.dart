import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../universities/data/university_repository.dart';
import '../universities/domain/university_models.dart';
import 'application_repository.dart';

class ApplicationEditor extends ConsumerStatefulWidget {
  const ApplicationEditor({
    super.key,
    this.record,
    this.embedded = false,
    this.onSaved,
  });
  final bool embedded;
  final VoidCallback? onSaved;
  final ApplicationRecord? record;
  @override
  ConsumerState<ApplicationEditor> createState() => ApplicationEditorState();
}

class ApplicationEditorState extends ConsumerState<ApplicationEditor> {
  final form = GlobalKey<FormState>(), keys = ApplicationRequestKey();
  late final TextEditingController year, division, track;
  final query = TextEditingController();
  University? university;
  List<University> results = [];
  String type = '수시', status = 'submitted';
  bool busy = false, dirty = false, searched = false;
  String? universityError;
  bool confirming = false, statusChanged = false;
  String initialStatus = 'submitted';
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
    initialStatus = a?.data['latest_event']?['kind'] as String? ?? 'submitted';
    status = applicationStates.containsKey(initialStatus)
        ? initialStatus
        : 'submitted';
    if (a != null) {
      university = University(
        id: a.data['university_id'] as String,
        name: a.university,
      );
    }
  }

  Future<bool> confirmLeave() async {
    if (busy || confirming) return false;
    if (!dirty && savedId == null) return true;
    confirming = true;
    try {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('입력 중인 내용을 닫을까요?'),
              content: Text(
                savedId == null ? '아직 저장하지 않은 입력은 사라집니다. 이미 등록된 지원 내역은 유지됩니다.' : '지원 정보는 저장됐지만 상태 기록은 아직 완료되지 않았어요. 입력을 닫아도 저장된 지원 내역은 유지됩니다.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('계속 입력'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('입력 닫기'),
                ),
              ],
            ),
          ) ??
          false;
    } finally {
      confirming = false;
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

  Future<void> search() => run((r) async {
    final q = query.text.trim();
    if (q.isEmpty) return;
    final rows = await ref.read(universityRepositoryProvider)!.searchCatalog(q);
    r.checkOwner();
    if (mounted) {
      setState(() {
        results = rows;
        searched = true;
      });
    }
  });

  Widget _yearAndType() {
    final selectedYear = int.tryParse(year.text);
    final yearField = field(
      '지원 학년도 · 필수',
      DropdownButtonFormField<int>(
        isExpanded: true,
        menuMaxHeight: 320,
        initialValue:
            selectedYear != null && selectedYear >= 1900 && selectedYear <= 2200
            ? selectedYear
            : null,
        decoration: const InputDecoration(),
        items: List.generate(
          301,
          (i) =>
              DropdownMenuItem(value: 1900 + i, child: Text('${1900 + i}학년도')),
        ),
        onChanged: busy
            ? null
            : (v) => setState(() {
                year.text = '$v';
                dirty = true;
              }),
        validator: (v) =>
            v == null || v < 1900 || v > 2200 ? '학년도를 확인해 주세요.' : null,
      ),
    );
    final typeField = field(
      '모집 시기 · 필수',
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: type,
        items: {
          '수시',
          '정시',
          type,
        }.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: busy
            ? null
            : (v) => setState(() {
                type = v!;
                dirty = true;
              }),
        decoration: const InputDecoration(),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(16) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [yearField, typeField],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: yearField),
            const SizedBox(width: 12),
            Expanded(child: typeField),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(applicationRepositoryProvider);
    owner ??= repo?.owner;
    if (repo == null || repo.owner != owner) {
      if (widget.embedded) return const Text('계정이 변경됐어요. 다시 열어 주세요.');
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('계정이 변경됐어요. 이전 화면으로 돌아가 주세요.')),
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (savedId == null) ...[
          ApplicationSection(
            title: '',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field(
                  '대학 검색 · 필수',
                  TextField(
                    controller: query,
                    enabled: !busy,
                    decoration: InputDecoration(
                      hintText: '대학 이름을 검색해 주세요',
                      suffixIcon: IconButton(
                        tooltip: '검색',
                        onPressed: busy ? null : search,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: busy ? null : (_) => search(),
                    onChanged: (_) => setState(() {
                      results = [];
                      searched = false;
                      dirty = true;
                    }),
                  ),
                ),
                for (final u in results)
                  ListTile(
                    title: Text(u.name),
                    onTap: busy
                        ? null
                        : () => setState(() {
                            university = u;
                            universityError = null;
                            dirty = true;
                            results = [];
                            searched = false;
                          }),
                  ),
                if (searched && results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('검색 결과가 없습니다. 대학 이름을 다시 확인해 주세요.'),
                  ),
                if (university != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5DF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF1C2B4B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            university!.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (universityError != null)
                  Text(
                    universityError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ApplicationSection(
            title: '',
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _yearAndType(),
                  for (final pair in [(division, '모집단위·학과'), (track, '전형명')])
                    field(
                      '${pair.$2} · 필수',
                      TextFormField(
                        controller: pair.$1,
                        enabled: !busy,
                        maxLength: 120,
                        decoration: InputDecoration(hintText: pair.$2),
                        onChanged: (_) => setState(() => dirty = true),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? '입력해 주세요.' : null,
                      ),
                    ),
                  field(
                    widget.record == null
                        ? '현재 지원 상태 · 필수'
                        : '현재 지원 상태 · 변경 선택',
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          widget.record != null &&
                              !applicationStates.containsKey(initialStatus)
                          ? null
                          : status,
                      hint: Text(widget.record?.status ?? '상태를 선택해 주세요'),
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
                          : (v) => setState(() {
                              status = v!;
                              statusChanged = true;
                              dirty = true;
                            }),
                      decoration: const InputDecoration(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else
          const Text('지원 정보는 저장됐어요. 상태 기록 저장을 다시 시도해 주세요.'),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        SafeArea(
          top: false,
          child: FilledButton(
            onPressed: busy
                ? null
                : () => run((r) async {
                    if (savedId == null) {
                      if (!(form.currentState?.validate() ?? false) ||
                          university == null) {
                        setState(() {
                          universityError = university == null
                              ? '대학을 선택해 주세요.'
                              : null;
                          error = '대학과 입력 항목을 확인해 주세요.';
                        });
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
                    if (widget.record == null || statusChanged) {
                      await r.event(
                        savedId!,
                        status,
                        null,
                        keys.forInput({'id': savedId, 'kind': status}),
                      );
                    }
                    ref.invalidate(applicationsProvider);
                    if (!mounted || !context.mounted) return;
                    setState(() {
                      dirty = false;
                      savedId = null;
                    });
                    if (widget.onSaved != null) {
                      widget.onSaved!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('지원 내역을 저장했어요.')),
                      );
                      Navigator.pop(context);
                    }
                  }),
            child: Text(busy ? '저장 중…' : '저장'),
          ),
        ),
      ],
    );
    return PopScope(
      canPop: !busy && !dirty && savedId == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop &&
            Navigator.of(context).canPop() &&
            await confirmLeave() &&
            context.mounted) {
          setState(() {
            dirty = false;
            savedId = null;
          });
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        child: widget.embedded
            ? content
            : Scaffold(
                appBar: AppBar(
                  title: Text(widget.record == null ? '지원 대학 등록' : '지원 정보 수정'),
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

Widget field(String label, Widget input) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C2B4B),
        ),
      ),
      const SizedBox(height: 6),
      input,
    ],
  ),
);

class ApplicationSection extends StatelessWidget {
  const ApplicationSection({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE3E7ED)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x090D1730),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    ),
  );
}
