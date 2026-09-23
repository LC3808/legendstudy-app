import 'grade_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../school/domain/school.dart';
import '../../school/school_providers.dart';
import '../../school/presentation/neis_attribution.dart';

class SchoolPage extends ConsumerStatefulWidget {
  const SchoolPage({super.key});
  @override
  ConsumerState<SchoolPage> createState() => _SchoolPageState();
}

class _SchoolPageState extends ConsumerState<SchoolPage> {
  final _input = TextEditingController();
  String _query = '';
  bool _saving = false;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  School? _draft;
  bool _edited = false, _completed = false;
  String? _owner;

  void _choose(School? school) {
    setState(() {
      _draft = school;
      _edited = true;
    });
  }

  Future<bool> _saveSchool() async {
    if (!_edited) return true;
    final applied = await ref
        .read(schoolSelectionProvider.notifier)
        .select(_draft);
    if (!mounted || !applied) return false;
    _edited = false;
    return true;
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    if (ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _saveGuest() async {
    if (_saving || _completed) return;
    setState(() => _saving = true);
    try {
      if (await _saveSchool()) _finish();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학교 설정을 변경하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final selection = ref.watch(schoolSelectionProvider);
    if (_owner != auth.value?.userId) {
      _owner = auth.value?.userId;
      _saving = false;
      _edited = false;
      _completed = false;
    }
    final school = _edited
        ? _draft
        : selection.isLoading || selection.hasError
        ? null
        : selection.value;
    final results = ref.watch(schoolSearchProvider(_query));
    return ShellPage(
      children: [
        TextField(
          controller: _input,
          enabled: !_saving,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '학교 이름을 검색해 주세요',
            prefixIcon: Icon(Icons.search),
            counterText: '',
          ),
          onChanged: (value) {
            if (value.trim().isEmpty) setState(() => _query = '');
          },
          onSubmitted: (value) {
            setState(() => _query = value.trim());
          },
        ),
        if (_query.isNotEmpty) ...[
          const SectionHeader('검색 결과'),
          results.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => ErrorState(
              message: '학교를 불러오지 못했어요.',
              onRetry: () => ref.invalidate(schoolSearchProvider(_query)),
            ),
            data: (schools) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (schools.isEmpty) const EmptyState('검색 결과가 없어요.'),
                if (schools.length >= 100)
                  const Text('결과가 많아요. 학교 이름을 더 자세히 입력해 주세요.'),
                for (final result in schools)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(result.name),
                    subtitle: Text(
                      [
                        result.schoolType,
                        result.address,
                      ].where((s) => s.isNotEmpty).join(' · '),
                    ),
                    selected: result.identity == school?.identity,
                    trailing: result.identity == school?.identity
                        ? const Icon(Icons.check, semanticLabel: '선택됨')
                        : null,
                    onTap:
                        _saving ||
                            selection.isLoading ||
                            auth.isLoading ||
                            auth.hasError
                        ? null
                        : () => _choose(result),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (auth.value?.isAuthenticated != true)
          const Text('비회원 선택은 이번 앱 실행 동안만 유지돼요.')
        else
          const Text('학교·학년을 확인한 뒤 저장해 주세요.'),
        if (selection.isLoading || _saving)
          const Center(child: CircularProgressIndicator()),
        if (selection.hasError)
          ErrorState(
            message: '저장한 학교를 불러오지 못했어요.',
            onRetry: () => ref.invalidate(schoolSelectionProvider),
          ),
        if (school != null) ...[
          const SectionHeader('선택한 학교'),
          Text(school.name),
          Text(
            [
              school.schoolType,
              school.address,
            ].where((s) => s.isNotEmpty).join(' · '),
          ),
          Wrap(
            children: [
              TextButton(
                onPressed: _saving ? null : () => _choose(null),
                child: const Text('선택 해제'),
              ),
              if (auth.value?.isAuthenticated != true)
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('로그인하면 학교 설정을 저장할 수 있어요.')),
                    ),
                  child: const Text('학교 설정 저장'),
                ),
            ],
          ),
        ],
        if (auth.value?.isAuthenticated == true) ...[
          GradePage(
            key: ValueKey(auth.value?.userId),
            enabled: !selection.isLoading && !selection.hasError && !_completed,
            beforeSave: _saveSchool,
            onSavingChanged: (value) => setState(() => _saving = value),
            onSaved: _finish,
          ),
        ],
        if (auth.value?.isAuthenticated != true)
          FilledButton(
            onPressed: _saving || selection.isLoading || selection.hasError
                ? null
                : _saveGuest,
            child: const Text('저장'),
          ),
        const Align(
          alignment: Alignment.centerRight,
          child: NeisAttribution(label: '출처: 교육부·시도교육청 NEIS'),
        ),
      ],
    );
  }
}
