import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';
import '../../school/domain/school.dart';
import '../../school/school_providers.dart';

// Value-first labels for the canonical academic-status buckets. `student`
// carries a grade; `retaker`/`other` do not.
const _statusOptions = <(String, String, String)>[
  ('student', '고등학교 재학생', '학년과 학교를 설정하면 학사일정·급식을 함께 볼 수 있어요.'),
  ('retaker', 'N수생 · 검정고시 등', '재학 중이 아니어도 자료와 D-Day를 그대로 활용할 수 있어요.'),
  ('other', '기타 · 아직 선택 안 함', '나중에 MY에서 언제든 바꿀 수 있어요.'),
];

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  String? _status;
  int? _grade;
  bool _busy = false;
  String? _error;
  final _searchInput = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchInput.dispose();
    super.dispose();
  }

  bool get _isStudent => _status == 'student';

  Future<void> _leave() async {
    // Both finish and skip mark onboarding complete so it never re-prompts.
    ref.invalidate(currentProfileProvider);
    ref.invalidate(schoolSelectionProvider);
    if (mounted) context.go('/home');
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).markOnboardingComplete();
      await _leave();
    } catch (_) {
      if (mounted) {
        setState(() => _error = '잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_busy || _status == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.upsertCurrentProfile(
        academicStatus: _status,
        // Non-students never carry a grade; clear any stale value.
        gradeLevel: _isStudent ? _grade : null,
        clearGrade: !_isStudent || _grade == null,
      );
      await repo.markOnboardingComplete();
      await _leave();
    } catch (_) {
      if (mounted) {
        setState(() => _error = '저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectSchool(School? school) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(schoolSelectionProvider.notifier).select(school);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학교를 저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    // Personalization is account-scoped; a guest has nothing to persist.
    if (auth.value?.isAuthenticated != true) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('개인화 설정은 로그인 후 이용할 수 있어요.'),
                  const SizedBox(height: AppTokens.space16),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('홈으로 가기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space20,
                  AppTokens.space24,
                  AppTokens.space20,
                  AppTokens.space16,
                ),
                children: _step == 0 ? _statusStep() : _detailStep(),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _statusStep() => [
    Text('${_step + 1} / 2', style: AppTokens.caption),
    const SizedBox(height: AppTokens.space8),
    Text('지금의 나를 알려주세요', style: AppTokens.pageTitle),
    const SizedBox(height: AppTokens.space8),
    Text(
      '입력한 정보는 Home·자료·D-Day 등에서 그대로 재사용돼요. 언제든 건너뛰거나 나중에 바꿀 수 있어요.',
      style: AppTokens.secondary,
    ),
    const SizedBox(height: AppTokens.space20),
    for (final (value, title, subtitle) in _statusOptions)
      Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space12),
        child: _StatusTile(
          title: title,
          subtitle: subtitle,
          selected: _status == value,
          onTap: _busy ? null : () => setState(() => _status = value),
        ),
      ),
  ];

  List<Widget> _detailStep() {
    if (!_isStudent) {
      return [
        Text('2 / 2', style: AppTokens.caption),
        const SizedBox(height: AppTokens.space8),
        Text('준비가 끝났어요', style: AppTokens.pageTitle),
        const SizedBox(height: AppTokens.space8),
        Text(
          '학년·학교 설정은 재학생에게만 필요해요. 필요하면 나중에 MY에서 추가할 수 있어요.',
          style: AppTokens.secondary,
        ),
      ];
    }
    final selection = ref.watch(schoolSelectionProvider);
    final school = selection.value;
    final results = ref.watch(schoolSearchProvider(_query));
    return [
      Text('2 / 2', style: AppTokens.caption),
      const SizedBox(height: AppTokens.space8),
      Text('학년과 학교', style: AppTokens.pageTitle),
      const SizedBox(height: AppTokens.space8),
      Text('선택 사항이에요. 비워두고 나중에 설정해도 괜찮아요.', style: AppTokens.secondary),
      const SizedBox(height: AppTokens.space20),
      Text('학년', style: AppTokens.cardTitle),
      const SizedBox(height: AppTokens.space8),
      Wrap(
        spacing: AppTokens.space8,
        children: [
          for (final grade in [null, 1, 2, 3])
            ChoiceChip(
              label: Text(grade == null ? '설정 안 함' : '$grade학년'),
              selected: _grade == grade,
              onSelected: _busy ? null : (_) => setState(() => _grade = grade),
            ),
        ],
      ),
      const SizedBox(height: AppTokens.space20),
      Text('학교', style: AppTokens.cardTitle),
      const SizedBox(height: AppTokens.space8),
      TextField(
        controller: _searchInput,
        enabled: !_busy,
        maxLength: 100,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: '학교 이름을 검색해 주세요',
          prefixIcon: Icon(Icons.search),
          counterText: '',
        ),
        onChanged: (value) {
          if (value.trim().isEmpty && _query.isNotEmpty) {
            setState(() => _query = '');
          }
        },
        onSubmitted: (value) => setState(() => _query = value.trim()),
      ),
      if (_query.isNotEmpty)
        results.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const Padding(
            padding: EdgeInsets.all(AppTokens.space16),
            child: Center(child: CircularProgressIndicator()),
          ),
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
                    [result.schoolType, result.address]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                  ),
                  selected: result.identity == school?.identity,
                  trailing: result.identity == school?.identity
                      ? const Icon(Icons.check, semanticLabel: '선택됨')
                      : null,
                  onTap: _busy ? null : () => _selectSchool(result),
                ),
            ],
          ),
        ),
      if (school != null) ...[
        const SizedBox(height: AppTokens.space8),
        Text('선택한 학교: ${school.name}', style: AppTokens.body),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : () => _selectSchool(null),
            child: const Text('선택 해제'),
          ),
        ),
      ],
    ];
  }

  Widget _footer() {
    final canAdvance = _step == 0 ? _status != null : true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space20,
        AppTokens.space8,
        AppTokens.space20,
        AppTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, style: AppTokens.secondary.copyWith(color: AppTokens.dangerInk)),
            const SizedBox(height: AppTokens.space8),
          ],
          Row(
            children: [
              if (_step == 1)
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _step = 0),
                  child: const Text('이전'),
                ),
              const Spacer(),
              TextButton(
                onPressed: _busy ? null : _skip,
                child: const Text('건너뛰기'),
              ),
              const SizedBox(width: AppTokens.space8),
              FilledButton(
                onPressed: !canAdvance || _busy
                    ? null
                    : _step == 0
                    ? () => setState(() => _step = 1)
                    : _finish,
                child: Text(
                  _busy
                      ? '저장 중…'
                      : _step == 0
                      ? '다음'
                      : '완료',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space16),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: selected ? AppTokens.primary : AppTokens.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTokens.cardTitle),
                  const SizedBox(height: AppTokens.space4),
                  Text(subtitle, style: AppTokens.secondary),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTokens.primary),
          ],
        ),
      ),
    );
  }
}
