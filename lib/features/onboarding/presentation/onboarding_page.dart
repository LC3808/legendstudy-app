import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../personal/personal_providers.dart';
import '../../school/domain/school.dart';
import '../../school/school_providers.dart';

// Onboarding-only palette (Phase 1.1). The app keeps its navy/orange identity;
// onboarding is allowed a slightly livelier, fresher feel. Accents mark
// selection and progress only — never body text. A per-option leading-icon tint
// aids scanning; the single orange accent expresses selection everywhere.
// See wiki/personalization-onboarding.md.
const _ink = Color(0xFF0D1730); // near-black navy: high-emphasis question
const _accent = Color(0xFFF97A2F); // warm, lively orange (brand-aligned)
const _accentSoft = Color(0xFFFFF1E6); // selected card tint
const _fresh = Color(0xFF2F86D6); // fresh blue: progress + student icon
const _mint = Color(0xFF1F9D57); // mint: "other" icon
const _backdropTop = Color(0xFFF6FAFF); // subtle ambient backdrop top

// Value-first labels for the canonical academic-status buckets. `student`
// carries a grade; `retaker`/`other` do not. Icon/tint are decorative only.
const _statusOptions = <(String, String, String, IconData, Color)>[
  (
    'student',
    '고등학교 재학생',
    '학년과 학교를 설정하면 학사일정·급식을 함께 볼 수 있어요.',
    Icons.school_outlined,
    _fresh,
  ),
  (
    'retaker',
    'N수생 · 검정고시 등',
    '재학 중이 아니어도 자료와 D-Day를 그대로 활용할 수 있어요.',
    Icons.autorenew_rounded,
    _accent,
  ),
  (
    'other',
    '기타 · 아직 선택 안 함',
    '나중에 MY에서 언제든 바꿀 수 있어요.',
    Icons.explore_outlined,
    _mint,
  ),
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
        backgroundColor: AppTokens.background,
        body: Stack(
          children: const [
            _OnboardingBackdrop(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTokens.space24),
                  child: _GuestNotice(),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTokens.background,
      body: Stack(
        children: [
          // Reusable background-layer slot. Phase 1.2 replaces the subtle
          // gradient with the ambient identity field (moving school/university
          // names) without restructuring the foreground.
          const _OnboardingBackdrop(),
          SafeArea(
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
        ],
      ),
    );
  }

  Widget _header(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepProgress(step: _step, total: 2),
      const SizedBox(height: AppTokens.space16),
      Text(
        title,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: _ink,
        ),
      ),
      const SizedBox(height: AppTokens.space8),
      Text(description, style: AppTokens.secondary),
      const SizedBox(height: AppTokens.space24),
    ],
  );

  List<Widget> _statusStep() => [
    _header(
      '지금의 나를 알려주세요',
      '입력한 정보는 Home·자료·D-Day 등에서 그대로 재사용돼요. 언제든 건너뛰거나 나중에 바꿀 수 있어요.',
    ),
    for (final (value, title, subtitle, icon, tint) in _statusOptions)
      Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space12),
        child: _StatusTile(
          title: title,
          subtitle: subtitle,
          icon: icon,
          tint: tint,
          selected: _status == value,
          onTap: _busy ? null : () => setState(() => _status = value),
        ),
      ),
  ];

  List<Widget> _detailStep() {
    if (!_isStudent) {
      return [
        _header('준비가 끝났어요', '학년·학교 설정은 재학생에게만 필요해요. 필요하면 나중에 MY에서 추가할 수 있어요.'),
      ];
    }
    final selection = ref.watch(schoolSelectionProvider);
    final school = selection.value;
    final results = ref.watch(schoolSearchProvider(_query));
    return [
      _header('학년과 학교', '선택 사항이에요. 비워두고 나중에 설정해도 괜찮아요.'),
      const _FieldLabel('학년'),
      const SizedBox(height: AppTokens.space12),
      Wrap(
        spacing: AppTokens.space8,
        runSpacing: AppTokens.space8,
        children: [
          for (final grade in [null, 1, 2, 3])
            _SelectChip(
              label: grade == null ? '설정 안 함' : '$grade학년',
              selected: _grade == grade,
              onTap: _busy ? null : () => setState(() => _grade = grade),
            ),
        ],
      ),
      const SizedBox(height: AppTokens.space24),
      const _FieldLabel('학교'),
      const SizedBox(height: AppTokens.space12),
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
        const SizedBox(height: AppTokens.space12),
        // Selected school rises into a foreground confirmation card — the seed
        // of the Phase 1.2 "my school becomes my information" metaphor.
        _SelectedSchoolCard(
          name: school.name,
          onClear: _busy ? null : () => _selectSchool(null),
        ),
      ],
    ];
  }

  Widget _footer() {
    final canAdvance = _step == 0 ? _status != null : true;
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(top: BorderSide(color: AppTokens.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space20,
        AppTokens.space12,
        AppTokens.space20,
        AppTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(
              _error!,
              style: AppTokens.secondary.copyWith(color: AppTokens.dangerInk),
            ),
            const SizedBox(height: AppTokens.space8),
          ],
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: !canAdvance || _busy
                  ? null
                  : _step == 0
                  ? () => setState(() => _step = 1)
                  : _finish,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTokens.disabled,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              child: Text(
                _busy
                    ? '저장 중…'
                    : _step == 0
                    ? '다음'
                    : '완료',
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
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
                style: TextButton.styleFrom(
                  foregroundColor: AppTokens.textSecondary,
                ),
                child: const Text('건너뛰기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Decorative ambient backdrop. Phase 1.1 ships a subtle gradient; Phase 1.2
// replaces it with the moving school/university identity field. Excluded from
// semantics so a screen reader never announces decorative content.
class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();
  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backdropTop, AppTokens.background],
          stops: [0.0, 0.55],
        ),
      ),
      child: SizedBox.expand(),
    ),
  );
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.total});
  final int step, total;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${step + 1}단계, 전체 $total단계',
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= step ? _fresh : AppTokens.cardBorder,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppTokens.space12),
          Text(
            '${step + 1} / $total',
            style: AppTokens.caption.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTokens.cardTitle.copyWith(color: _ink),
  );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Color tint;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          splashColor: _accent.withValues(alpha: 0.10),
          highlightColor: _accent.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space16,
              vertical: AppTokens.space16,
            ),
            decoration: BoxDecoration(
              color: selected ? _accentSoft : AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(
                color: selected ? _accent : AppTokens.cardBorder,
                width: selected ? 2 : 1.5,
              ),
              boxShadow: selected ? AppTokens.shadowMd : AppTokens.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(icon, color: tint, size: 24),
                ),
                const SizedBox(width: AppTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTokens.cardTitle.copyWith(color: _ink),
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(subtitle, style: AppTokens.secondary),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                _SelectDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectDot extends StatelessWidget {
  const _SelectDot({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    if (selected) {
      return const Icon(Icons.check_circle_rounded, color: _accent, size: 26);
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTokens.cardBorder, width: 2),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 140),
            constraints: const BoxConstraints(minHeight: 42),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: selected ? _accent : AppTokens.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(
                color: selected ? _accent : AppTokens.cardBorder,
                width: 1.5,
              ),
              boxShadow: selected ? AppTokens.shadowSm : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedSchoolCard extends StatelessWidget {
  const _SelectedSchoolCard({required this.name, required this.onClear});
  final String name;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space16,
        AppTokens.space12,
        AppTokens.space8,
        AppTokens.space12,
      ),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: _accent, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: _accent, size: 22),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택한 학교', style: AppTokens.caption),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: AppTokens.cardTitle.copyWith(color: _ink),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('선택 해제')),
        ],
      ),
    );
  }
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('개인화 설정은 로그인 후 이용할 수 있어요.'),
      const SizedBox(height: AppTokens.space16),
      FilledButton(
        onPressed: () => context.go('/home'),
        child: const Text('홈으로 가기'),
      ),
    ],
  );
}
