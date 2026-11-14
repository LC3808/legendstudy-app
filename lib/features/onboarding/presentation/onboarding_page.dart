import '../onboarding_progress.dart';
import '../../applications/onboarding_applications.dart';
import '../../home/customization/home_configuration.dart';
import '../../home/customization/home_editor.dart';
import '../device_intro.dart';
import '../../analytics/analytics_providers.dart';
import '../../analytics/domain/analytics_events.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../brand/brand_wordmark.dart';
import '../../personal/personal_providers.dart';
import '../../school/domain/school.dart';
import '../../school/school_providers.dart';
import '../../school/presentation/school_search_picker.dart';
import '../../universities/presentation/interested_universities_field.dart';
import '../../profile/presentation/intended_major_field.dart';
import '../../profile/nickname_validation.dart';

// Onboarding-only palette (Phase 1.1). The app keeps its navy/orange identity;
// onboarding is allowed a slightly livelier, fresher feel. Accents mark
// selection and progress only — never body text. A per-option leading-icon tint
// aids scanning; the single orange accent expresses selection everywhere.
// See wiki/personalization-onboarding.md.
const _ink = Color(0xFF0D1730); // near-black navy: high-emphasis question
const _accent = Color(0xFFFFAC14); // warm, lively orange (brand-aligned)
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
    '학교 공부 기록과 급식을 함께 챙겨보세요.',
    Icons.school_outlined,
    _fresh,
  ),
  (
    'retaker',
    'N수생 · 검정고시 등',
    '목표 대학과 지원 기록, D-Day로 다음 도전을 준비해요.',
    Icons.autorenew_rounded,
    _accent,
  ),
  ('other', '기타', '나만의 목표에 맞춰 공부 기록을 쌓아보세요.', Icons.explore_outlined, _mint),
];

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 1;
  bool _stepRestored = false;
  int _ownerEpoch = 0;
  // Stable IDs keep the existing steps intact; only N수 accounts gain a step.
  List<int> get _steps => [
    1,
    if (_isStudent) 2,
    3,
    if (_status == 'retaker') 7,
    4,
    5,
    6,
  ];
  GlobalKey<OnboardingApplicationsState> _applicationsKey = GlobalKey();
  HomeConfiguration _homeDraft = HomeConfiguration.defaults();
  int? _homeSavedRevision;
  bool _homeEdited = false;
  final _nickname = TextEditingController();
  String? _savedNickname;
  bool _nicknameDirty = false;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  String? _status;
  int? _grade;
  bool _busy = false;
  // Debounces step changes so a fast double-tap can't skip a question (the
  // transition owns the short lock; values are untouched).
  bool _advancing = false;
  bool _applicationEditing = false;
  String? _error;
  School? _schoolDraft;
  bool _schoolSearchPending = false;
  bool _universitySearchPending = false;
  bool _statusDirty = false, _gradeDirty = false, _hydrated = false;
  String? _owner;

  bool _sameOwner(String? owner) =>
      mounted &&
      owner != null &&
      ref.read(authStateProvider).value?.userId == owner;

  Future<void> _restoreStep(String owner, int epoch) async {
    var saved = 1;
    try {
      saved = await ref.read(onboardingProgressStoreProvider).load(owner);
      if (saved == 6) {
        final repo = ref.read(homeConfigurationRepositoryProvider);
        if (repo != null && repo.owner == owner) {
          final settings = await repo.load().last;
          if (_sameOwner(owner) && epoch == _ownerEpoch && settings.confirmed) {
            _homeDraft = settings.configuration;
          }
        }
      }
    } catch (_) {
      // A local read failure never discards server answers or marks completion.
    }
    if (!_sameOwner(owner) || epoch != _ownerEpoch) return;
    setState(() {
      _step = saved;
      _stepRestored = true;
    });
  }

  Future<void> _persistDraft(String? owner) async {
    if (!_sameOwner(owner)) throw StateError('Account changed');
    if (!_statusDirty && !_gradeDirty) return;
    await ref
        .read(profileRepositoryProvider)
        .upsertCurrentProfile(
          academicStatus: _statusDirty ? _status : null,
          gradeLevel: _gradeDirty && _isStudent ? _grade : null,
          clearGrade:
              (_statusDirty && !_isStudent) || (_gradeDirty && _grade == null),
        );
    if (!_sameOwner(owner)) throw StateError('Account changed');
    _statusDirty = _gradeDirty = false;
    ref.invalidate(currentProfileProvider);
  }

  Future<void> _move(int delta, {bool skip = false}) async {
    if (_busy || _advancing || !_hydrated) return;
    if (!skip &&
        delta > 0 &&
        _step == 2 &&
        _isStudent &&
        _schoolSearchPending) {
      return;
    }
    if (!skip && delta > 0 && _step == 3 && _universitySearchPending) return;
    if (delta > 0 && _step == 7 && _applicationEditing) return;
    final leavingOwner = ref.read(authStateProvider).value?.userId;
    final leavingStep = _step;
    if (_step == 7 &&
        !await (_applicationsKey.currentState?.confirmLeave() ??
            Future.value(true))) {
      return;
    }
    if (!_sameOwner(leavingOwner) || _step != leavingStep) return;
    final owner = leavingOwner;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _persistDraft(owner);
      if (!skip && delta > 0 && _step == 5) {
        final nickname = _nickname.text == _savedNickname
            ? _nickname.text
            : _nickname.text.trim();
        final validation = nickname.isEmpty
            ? null
            : nicknameValidationError(nickname, previous: _savedNickname);
        if (validation != null) {
          if (_sameOwner(owner)) setState(() => _error = validation);
          return;
        }
        if (nickname.isNotEmpty && nickname != _savedNickname) {
          await ref
              .read(profileRepositoryProvider)
              .upsertCurrentProfile(displayName: nickname);
          if (!_sameOwner(owner)) return;
          _savedNickname = nickname;
          _nicknameDirty = false;
          ref.invalidate(currentProfileProvider);
        }
      }
      if (!skip &&
          delta > 0 &&
          _step == 2 &&
          _isStudent &&
          _schoolDraft != null) {
        final applied = await ref
            .read(schoolSelectionProvider.notifier)
            .select(_schoolDraft);
        if (!applied) throw StateError('School was not saved');
      }
      if (!_sameOwner(owner)) return;
      final nextStep = _steps[_steps.indexOf(_step) + delta];
      await ref.read(onboardingProgressStoreProvider).save(owner!, nextStep);
      if (!_sameOwner(owner)) return;
      setState(() {
        _schoolDraft = null;
        _schoolSearchPending = _universitySearchPending = false;
        _step = nextStep;
        _advancing = true;
      });
      _unlockSoon();
    } catch (_) {
      if (_sameOwner(owner)) setState(() => _error = '저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (_sameOwner(owner)) setState(() => _busy = false);
    }
  }

  // Guarded forward/back step moves. One move per transition; selections are
  // kept in state/providers, so moving never loses an entered value.
  void _advance() => _move(1);

  void _back() => _move(-1);

  void _unlockSoon() {
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _advancing = false);
    });
  }

  bool get _isStudent => _status == 'student';

  Future<void> _leave() async {
    // Only the final step records completion; intermediate skips advance one step.
    final owner = ref.read(authStateProvider).value?.userId;
    if (owner != null) {
      try {
        await ref.read(onboardingProgressStoreProvider).clear(owner);
      } catch (_) {
        // The server completion marker still wins if local cleanup fails.
      }
      if (!_sameOwner(owner)) return;
    }
    ref.invalidate(currentProfileProvider);
    ref.invalidate(schoolSelectionProvider);
    if (mounted) context.go('/home');
  }

  Future<void> _skip() async {
    if (_busy ||
        _advancing ||
        !_hydrated ||
        _step == 6 ||
        _applicationEditing) {
      return;
    }
    final owner = _owner;
    final step = _step;
    final hasDraft =
        (_step == 2 && (_schoolDraft != null || _schoolSearchPending)) ||
        (_step == 3 && _universitySearchPending) ||
        (_step == 5 && _nicknameDirty);
    if (hasDraft) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('이 단계의 입력을 건너뛸까요?'),
          content: const Text('아직 저장하지 않은 입력은 반영되지 않아요. 이미 저장한 정보는 유지됩니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 입력'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('이 단계 건너뛰기'),
            ),
          ],
        ),
      );
      if (discard != true || !_sameOwner(owner) || _step != step) return;
    }
    if (_step == 5) {
      _nickname.text = _savedNickname ?? '';
      _nicknameDirty = false;
    }
    await _move(1, skip: true);
  }

  Future<void> _finish() async {
    if (_busy || _advancing || !_hydrated) return;
    final nickname = _nickname.text == _savedNickname
        ? _nickname.text
        : _nickname.text.trim();
    final validationError = nickname.isEmpty
        ? null
        : nicknameValidationError(nickname, previous: _savedNickname);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final owner = ref.read(authStateProvider).value?.userId;
    try {
      final repo = ref.read(profileRepositoryProvider);
      await _persistDraft(owner);
      if (nickname.isNotEmpty && nickname != _savedNickname) {
        await repo.upsertCurrentProfile(displayName: nickname);
        if (!_sameOwner(owner)) return;
        _savedNickname = nickname;
        _nicknameDirty = false;
        ref.invalidate(currentProfileProvider);
      }
      if (!_sameOwner(owner)) return;
      if (_homeSavedRevision == null) {
        final settingsRepo = ref.read(homeConfigurationRepositoryProvider);
        if (settingsRepo == null || settingsRepo.owner != owner) {
          throw StateError('Settings unavailable');
        }
        final settings = await settingsRepo.load().last;
        if (!settings.confirmed) throw StateError('Settings read failed');
        // A resumed onboarding on an older client must retain future card IDs.
        final draft = _homeEdited ? _homeDraft : settings.configuration;
        final chosenIds = draft.cards.map((card) => card.id).toSet();
        final configuration = HomeConfiguration([
          ...draft.cards,
          ...settings.configuration.cards.where(
            (card) => !chosenIds.contains(card.id),
          ),
        ]);
        final saved = await settingsRepo.save(configuration, settings.revision);
        if (!_sameOwner(owner)) return;
        _homeSavedRevision = saved.revision;
        ref.invalidate(homeConfigurationProvider);
      }
      await repo.markOnboardingComplete();
      if (!_sameOwner(owner)) return;
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.onboardingComplete,
        {'status': 'completed'},
      );
      await _leave();
    } catch (_) {
      if (_sameOwner(owner)) {
        setState(() => _error = '완료하지 못했어요. 입력값은 유지되어 있어요. 다시 시도해 주세요.');
      }
    } finally {
      if (_sameOwner(owner)) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (_owner != auth.value?.userId) {
      _owner = auth.value?.userId;
      _step = 1;
      _applicationsKey = GlobalKey();
      _applicationEditing = false;
      _stepRestored = false;
      final epoch = ++_ownerEpoch;
      if (_owner != null) _restoreStep(_owner!, epoch);
      _homeDraft = HomeConfiguration.defaults();
      _homeSavedRevision = null;
      _homeEdited = false;
      _status = null;
      _grade = null;
      _nickname.clear();
      _savedNickname = null;
      _nicknameDirty = false;
      _hydrated = false;
      _statusDirty = _gradeDirty = _busy = _advancing = false;
      _schoolDraft = null;
      _schoolSearchPending = _universitySearchPending = false;
    }
    final profileState = ref.watch(currentProfileProvider);
    if (!_hydrated &&
        _stepRestored &&
        profileState.hasValue &&
        !profileState.isLoading) {
      final profile = profileState.asData?.value;
      if (!_statusDirty) _status = profile?.academicStatus;
      if (!_gradeDirty) _grade = profile?.gradeLevel;
      _savedNickname = profile?.displayName;
      if (!_nicknameDirty) _nickname.text = _savedNickname ?? '';
      if (_step == 2 && _status != null && !_isStudent) _step = 3;
      if (!_steps.contains(_step)) {
        _step = 1;
      }
      _hydrated = true;
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
          // Background layer: a subtle gradient plus a soft brand glow that
          // drifts to a new position as the question changes (Reduce Motion →
          // static). Decorative only; readability always wins.
          _OnboardingBackdrop(step: _step, reduceMotion: reduceMotion),
          SafeArea(
            child: _step == 0
                ? BrandOnboarding(onStart: () => setState(() => _step = 1))
                : Column(
                    children: [
                      Expanded(
                        // One question per screen, with a gentle fade + short
                        // slide between steps (keyed by _step). Reduce Motion
                        // swaps instantly with no transform.
                        child: AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            if (reduceMotion) return child;
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.06, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: ListView(
                            key: ValueKey(_step),
                            padding: const EdgeInsets.fromLTRB(
                              AppTokens.space20,
                              AppTokens.space24,
                              AppTokens.space20,
                              AppTokens.space16,
                            ),
                            children: _hydrated
                                ? [
                                    ..._stepContent(),
                                    if (_step != 6 &&
                                        !_applicationEditing &&
                                        MediaQuery.viewInsetsOf(context)
                                                .bottom ==
                                            0)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 28,
                                          bottom: 12,
                                        ),
                                        child: Center(
                                          child: TextButton(
                                            key: const ValueKey(
                                              'onboarding-step-skip',
                                            ),
                                            onPressed: _busy || _advancing
                                                ? null
                                                : _skip,
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppTokens.textSecondary,
                                            ),
                                            child: const Text('이 단계 건너뛰기'),
                                          ),
                                        ),
                                      ),
                                  ]
                                : [
                                    if (profileState.hasError)
                                      TextButton(
                                        onPressed: () => ref.invalidate(
                                          currentProfileProvider,
                                        ),
                                        child: const Text(
                                          '프로필을 불러오지 못했어요. 다시 시도',
                                        ),
                                      )
                                    else
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  ],
                          ),
                        ),
                      ),
                      // Do not put a step-changing CTA above a search
                      // keyboard where users expect the search action.
                      if (!_applicationEditing &&
                          !(((_step == 2 && _isStudent) || _step == 3) &&
                              MediaQuery.viewInsetsOf(context).bottom > 0))
                        _footer(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title, String description) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StepProgress(step: _steps.indexOf(_step), total: _steps.length),
      const SizedBox(height: AppTokens.space16),
      Text(
        title,
        textAlign: TextAlign.center,
        softWrap: true,
        style: const TextStyle(
          letterSpacing: 0,
          wordSpacing: 0,
          fontSize: 26,
          fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'],
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: _ink,
        ),
      ),
      const SizedBox(height: AppTokens.space8),
      Text(
        description,
        textAlign: TextAlign.center,
        style: AppTokens.secondary.copyWith(letterSpacing: 0, wordSpacing: 0),
      ),
      SizedBox(height: _step == 7 ? AppTokens.space16 : AppTokens.space24),
    ],
  );

  List<Widget> _stepContent() {
    switch (_step) {
      case 1:
        return _statusStep();
      case 2:
        return _detailStep();
      case 3:
        return _universitiesStep();
      case 7:
        return [
          _header(
            '합격의 순간까지, 함께할게요! 🎓',
            '지원 대학과 전형을 한곳에 모아보세요. 지원부터 합격·등록까지, 나의 도전을 차곡차곡 기록해요.',
          ),
          OnboardingApplications(
            key: _applicationsKey,
            onEditingChanged: (value) =>
                setState(() => _applicationEditing = value),
          ),
        ];
      case 4:
        return _majorStep();
      case 5:
        return _nicknameStep();
      default:
        return [
          _header(
            '나만의 합격 준비 공간을 완성해요!',
            '필요한 기능을 골라 나만의 홈을 꾸며보세요. 매일의 공부와 입시 준비가 더 편리해집니다.',
          ),
          HomeCardSelector(
            value: _homeDraft,
            onChanged: _busy
                ? null
                : (value) => setState(() {
                    _homeDraft = value;
                    _homeEdited = true;
                    _homeSavedRevision = null;
                  }),
          ),
        ];
    }
  }

  List<Widget> _universitiesStep() => [
    _header(
      '꿈꾸는 대학, 이제 목표로 만들어 볼까요? 🎓',
      '마음에 두고 있는 대학을 모아보세요. 나의 목표 대학과 관심 학과를 한곳에서 관리할 수 있어요.',
    ),
    InterestedUniversitiesField(
      source: 'onboarding',
      onSearchPendingChanged: (pending) =>
          setState(() => _universitySearchPending = pending),
    ),
  ];

  List<Widget> _majorStep() => [
    _header(
      '어떤 미래를 꿈꾸고 있나요? ✨',
      '관심 있는 전공 계열을 선택해 주세요. 아직 정하지 못했다면 나만의 목표에 맞춰 공부 기록을 쌓아보세요.',
    ),
    const IntendedMajorField(),
  ];

  List<Widget> _nicknameStep() => [
    _header('나의 도전에 어울리는 이름은?', '나를 표현하는 닉네임을 정해보세요. 레전드스터디에서 함께할 나만의 이름이에요.'),
    if (!_hydrated) ...[
      const Text('기존 닉네임 정보를 불러오는 중이에요.'),
      if (ref.watch(currentProfileProvider).hasError)
        TextButton(
          onPressed: () => ref.invalidate(currentProfileProvider),
          child: const Text('다시 불러오기'),
        ),
    ],
    TextField(
      controller: _nickname,
      enabled: !_busy && _hydrated,
      maxLength: 20,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: '닉네임',
        hintText: '사용할 닉네임',
        helperText: '실명 대신 나를 표현하는 이름을 사용해 주세요.',
        helperMaxLines: 3,
        suffixIcon: IconButton(
          tooltip: '키보드 닫기',
          onPressed: () => FocusScope.of(context).unfocus(),
          icon: const Icon(Icons.keyboard_hide_outlined),
        ),
      ),
      onChanged: (_) => setState(() {
        _nicknameDirty = true;
        _error = null;
      }),
      onSubmitted: (_) => _move(1),
    ),
  ];

  List<Widget> _statusStep() => [
    _header(
      '지금, 어떤 목표를 향해 달리고 있나요?',
      '현재 학습 단계를 알려주세요. 나에게 맞는 공부와 입시 준비의 첫걸음이에요.',
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
          onTap: _busy
              ? null
              : () => setState(() {
                  _status = value;
                  _statusDirty = true;
                }),
        ),
      ),
  ];

  List<Widget> _detailStep() {
    ref.watch(schoolSelectionProvider);
    if (!_isStudent) {
      return [
        _header(
          '학년·학교는 재학생 전용이에요',
          '재학생이 아니어도 관심 대학과 전공을 설정하면 맞춤 입시 정보를 받아볼 수 있어요.',
        ),
      ];
    }

    return [
      _header('우리 학교에서 시작하는 합격 준비!', '학교와 학년을 등록하고, 같은 학교 친구들과 공부 기록을 쌓아보세요.'),
      Row(
        children: [
          const _FieldLabel('학년'),
          const SizedBox(width: AppTokens.space12),
          for (final grade in [1, 2, 3]) ...[
            if (grade > 1) const SizedBox(width: AppTokens.space8),
            Expanded(
              child: _SelectChip(
                label: '$grade학년',
                selected: _grade == grade,
                onTap: _busy
                    ? null
                    : () => setState(() {
                        _grade = _grade == grade ? null : grade;
                        _gradeDirty = true;
                      }),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: AppTokens.space16),
      const _FieldLabel('학교'),
      const SizedBox(height: AppTokens.space12),
      SchoolSearchPicker(
        key: ValueKey('onboarding-school:$_owner'),
        inlineSearch: true,
        enabled: !_busy,
        onChanged: (school) => setState(() => _schoolDraft = school),
        onSearchPendingChanged: (pending) =>
            setState(() => _schoolSearchPending = pending),
      ),
    ];
  }

  Widget _footer() {
    final canAdvance = _step == 5
        ? _hydrated
        : _step == 1
        ? _status != null
        : !((_step == 2 && _isStudent && _schoolSearchPending) ||
              (_step == 3 && _universitySearchPending));
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
          if (_step == 2 && _isStudent && _schoolSearchPending) ...[
            const Text('학교를 검색한 뒤 선택한 학교를 확인해 주세요.'),
            const SizedBox(height: AppTokens.space8),
          ],
          if (_step == 3 && _universitySearchPending) ...[
            const Text('입력창의 검색 버튼으로 대학을 찾아 주세요.'),
            const SizedBox(height: AppTokens.space8),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: AppTokens.secondary.copyWith(color: AppTokens.dangerInk),
            ),
            const SizedBox(height: AppTokens.space8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: FilledButton(
              onPressed: !_hydrated || !canAdvance || _busy || _advancing
                  ? null
                  : _step != 6
                  ? _advance
                  : _finish,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _ink,
                disabledBackgroundColor: AppTokens.disabled,
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              child: Text(
                _busy
                    ? '저장 중…'
                    : _step == 2 && _isStudent && _schoolDraft != null
                    ? '${_schoolDraft!.name}로 설정하기'
                    : _step != 6
                    ? '다음'
                    : '이대로 시작하기',
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Row(
            children: [
              if (_step > 1)
                TextButton(
                  onPressed: _busy || _advancing ? null : _back,
                  child: const Text('이전'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Decorative ambient backdrop: a subtle top gradient plus a soft brand glow
// that settles into a new position as the question (step) changes, giving gentle
// forward momentum. Low-stimulus (max ~10% alpha), moves only on step change (no
// infinite loop), static under Reduce Motion. Excluded from semantics so a
// screen reader never announces decorative content; IgnorePointer so it never
// intercepts touches. Readability of the foreground always wins.
class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop({this.step = 0, this.reduceMotion = false});
  final int step;
  final bool reduceMotion;

  static const _glowAligns = <Alignment>[
    Alignment(-0.7, -0.8),
    Alignment(0.8, -0.7),
    Alignment(-0.75, -0.1),
    Alignment(0.8, 0.15),
    Alignment(0.0, 0.5),
  ];

  @override
  Widget build(BuildContext context) {
    final align = _glowAligns[step.clamp(0, _glowAligns.length - 1)];
    return ExcludeSemantics(
      child: Stack(
        children: [
          const DecoratedBox(
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
          AnimatedAlign(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 420),
            curve: Curves.easeOut,
            alignment: align,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withValues(alpha: 0.10),
                      _accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) =>
      Text(text, style: AppTokens.cardTitle.copyWith(color: _ink));
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

// Concise brand intro (2–3 screens, no carousel overload). Positioning is fixed
// by product authority: "내신 관리부터 수능, 논술 준비까지" — never 기출/AI as the
// headline, and LAB = 내신·수능·논술 LAB. Reused by the Settings "앱 사용 안내
// 다시 보기" replay, which never resets personalization.
const List<(String, String, IconData)> brandSlides = [
  (
    // Official plain name (a11y / replay). The onboarding brand slide renders
    // this title as the BrandWordmark logotype (레전드스터디⁺). Official English
    // name is "LegendStudy Plus" — never "LegendStudy+".
    '레전드스터디+',
    '내신 관리부터 수능, 논술 준비까지.\n데이터가 쌓일수록\n나의 가능성은 더 선명해집니다.',
    Icons.auto_graph_rounded,
  ),
  (
    '나의 학습을 기록하고 관리하세요',
    '공부 시간과 학습 기록, 성적의 변화를\n한곳에서 확인하세요.',
    Icons.insights_rounded,
  ),
  ('내신 · 수능 · 논술을 하나로', '나의 가능성을 선명하게 만드세요.', Icons.school_rounded),
];

class BrandOnboarding extends StatefulWidget {
  const BrandOnboarding({required this.onStart, super.key});
  final VoidCallback onStart;
  @override
  State<BrandOnboarding> createState() => BrandOnboardingState();
}

class BrandOnboardingState extends State<BrandOnboarding> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == brandSlides.length - 1;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: brandSlides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              // Owner 2026-10-09: every onboarding slide uses the SAME brand mark
              // (the LegendStudy symbol — no per-screen icons), centred, with a
              // compact single-screen layout. The slide's `icon` is intentionally
              // unused here (still used by the Settings app-guide replay).
              final (title, body, _) = brandSlides[i];
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space24,
                    AppTokens.space32,
                    AppTokens.space24,
                    AppTokens.space16,
                  ),
                  child: ConstrainedBox(
                    // Centre when the content is short; scroll (never clip) on a
                    // small screen or at large text scale.
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          AppTokens.space32 -
                          AppTokens.space16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Image(
                          image: AssetImage(
                            'assets/brand/generated/legendstudy_symbol.png',
                          ),
                          width: 84,
                          height: 84,
                          filterQuality: FilterQuality.medium,
                        ),
                        const SizedBox(height: AppTokens.space24),
                        // Slide 0 is the brand identity → the canonical logotype
                        // (레전드스터디⁺); later slides use their plain headline.
                        if (i == 0)
                          const BrandWordmark(fontSize: 26, color: _ink)
                        else
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: _ink,
                            ),
                          ),
                        const SizedBox(height: AppTokens.space12),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: AppTokens.body.copyWith(
                            color: AppTokens.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < brandSlides.length; i++)
              Container(
                width: i == _page ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? _accent : AppTokens.cardBorder,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space20,
            AppTokens.space16,
            AppTokens.space20,
            AppTokens.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: last
                      ? widget.onStart
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _ink,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                  ),
                  child: Text(last ? '시작하기' : '다음'),
                ),
              ),
              if (!last)
                TextButton(
                  onPressed: widget.onStart,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTokens.textSecondary,
                  ),
                  child: const Text('건너뛰기'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class DeviceIntroPage extends ConsumerStatefulWidget {
  const DeviceIntroPage({super.key});
  @override
  ConsumerState<DeviceIntroPage> createState() => _DeviceIntroPageState();
}

class _DeviceIntroPageState extends ConsumerState<DeviceIntroPage> {
  bool busy = false;
  String? error;
  Future<void> finish() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(deviceIntroProvider.notifier).complete();
      if (mounted) context.go('/auth');
    } catch (_) {
      if (mounted) setState(() => error = '앱 소개 완료를 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTokens.background,
    body: SafeArea(
      child: Column(
        children: [
          if (error != null) Text(error!),
          Expanded(
            child: AbsorbPointer(
              absorbing: busy,
              child: BrandOnboarding(onStart: finish),
            ),
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
