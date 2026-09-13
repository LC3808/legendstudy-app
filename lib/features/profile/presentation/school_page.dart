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

  Future<void> _select(School? school) async {
    setState(() => _saving = true);
    try {
      final applied = await ref
          .read(schoolSelectionProvider.notifier)
          .select(school);
      if (!mounted || !applied) return;
      final signedIn =
          ref.read(authStateProvider).value?.isAuthenticated == true;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              signedIn ? '학교 설정을 저장했어요.' : '이번 실행 동안 선택한 학교의 급식을 볼 수 있어요.',
            ),
          ),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
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
    final school = selection.isLoading || selection.hasError
        ? null
        : selection.value;
    final results = ref.watch(schoolSearchProvider(_query));
    return ShellPage(
      children: [
        TextField(
          controller: _input,
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
        const SizedBox(height: 16),
        if (auth.value?.isAuthenticated != true)
          const Text('비회원 선택은 이번 앱 실행 동안만 유지돼요.')
        else
          const Text('학교를 선택하면 내 계정에 저장돼요.'),
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
                onPressed: _saving ? null : () => _select(null),
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
                        : () => _select(result),
                  ),
              ],
            ),
          ),
        ],
        const Align(
          alignment: Alignment.centerRight,
          child: NeisAttribution(label: '출처: 교육부·시도교육청 NEIS'),
        ),
      ],
    );
  }
}
