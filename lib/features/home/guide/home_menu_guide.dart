import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../onboarding/device_intro.dart';
import '../../personal/personal_providers.dart';

/// Installation-local presentation state. Never changes onboarding/profile data.
/// Existing accounts are excluded even when they lack onboarding_completed_at.
class HomeGuideStore {
  HomeGuideStore(this.preferences);
  final SharedPreferences preferences;
  static const firstSeenKey = 'home_menu_guide_v1.first_seen';
  static const freshGuestKey = 'home_menu_guide_v1.fresh_guest';
  static const consumedKey = 'home_menu_guide_v1.consumed';
  bool _claiming = false;

  static Future<HomeGuideStore?> initialize({
    required DateTime now,
    required bool freshGuest,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(firstSeenKey)) {
        // Write the conservative default first; interruption cannot expose an
        // existing user as a new guest installation.
        if (!await prefs.setBool(freshGuestKey, freshGuest) ||
            !await prefs.setString(
              firstSeenKey,
              now.toUtc().toIso8601String(),
            )) {
          return null;
        }
      }
      return HomeGuideStore(prefs);
    } catch (_) {
      return null;
    }
  }

  bool eligible({required bool guest, DateTime? accountCreatedAt}) {
    if (preferences.getBool(consumedKey) == true) return false;
    final firstSeen = DateTime.tryParse(
      preferences.getString(firstSeenKey) ?? '',
    );
    if (firstSeen == null) return false;
    return guest
        ? preferences.getBool(freshGuestKey) == true
        : accountCreatedAt != null && !accountCreatedAt.isBefore(firstSeen);
  }

  Future<bool> claim() async {
    if (_claiming || preferences.getBool(consumedKey) == true) return false;
    _claiming = true;
    try {
      // Persist before display, including skip/process interruption. Never
      // re-open a partially seen guide on relaunch or an account transition.
      return await preferences.setBool(consumedKey, true);
    } catch (_) {
      return false;
    } finally {
      _claiming = false;
    }
  }
}

final homeGuideStoreProvider = Provider<HomeGuideStore?>((ref) => null);
final homeGuideEligibleProvider = Provider<bool>((ref) {
  final store = ref.watch(homeGuideStoreProvider);
  final auth = ref.watch(authStateProvider);
  if (store == null ||
      ref.watch(deviceIntroProvider) ||
      auth.isLoading ||
      auth.hasError) {
    return false;
  }
  final owner = auth.value?.userId;
  if (owner == null) return store.eligible(guest: true);
  final profile = ref.watch(currentProfileProvider);
  final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
  if (profile.isLoading ||
      profile.hasError ||
      profile.value?.id != owner ||
      profile.value?.hasCompletedOnboarding != true ||
      user?.id != owner) {
    return false;
  }
  return store.eligible(
    guest: false,
    accountCreatedAt: DateTime.tryParse(user!.createdAt),
  );
});

const homeGuideSteps = <({String title, String description})>[
  (title: '홈', description: '입시 소식과 관심 대학 정보를 한눈에 확인하세요.'),
  (title: '자료', description: '수능·모의고사·대학별 기출 자료를 찾아보세요.'),
  (title: '학습', description: '공부시간을 기록하고 나의 학습 성장을 확인하세요.'),
  (title: 'LAB', description: '논술 LAB에서 제공하는 문항으로 답안을 점검하고 개선해 보세요.'),
  (title: 'MY', description: '내 정보와 관심 대학, 저장한 자료를 관리하세요.'),
];

/// Overlay coordinates come from the real NavigationDestination render boxes.
/// No screenshot, copied navigation bar or fixed screen-coordinate spotlight.
class HomeMenuGuide extends StatefulWidget {
  const HomeMenuGuide({required this.targets, required this.onDone, super.key});
  final List<GlobalKey> targets;
  final VoidCallback onDone;
  @override
  State<HomeMenuGuide> createState() => _HomeMenuGuideState();
}

class _HomeMenuGuideState extends State<HomeMenuGuide>
    with WidgetsBindingObserver {
  final _root = GlobalKey();
  int _step = 0;
  Rect? _target;
  Size? _size;
  double? _scale;
  bool _scheduled = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _measure();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _measure();

  void _measure() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final root = _root.currentContext?.findRenderObject();
      final target = widget.targets[_step].currentContext?.findRenderObject();
      if (root is! RenderBox || target is! RenderBox || !target.hasSize) return;
      final rect =
          root.globalToLocal(target.localToGlobal(Offset.zero)) & target.size;
      if (_target != rect) setState(() => _target = rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (_size != media.size || _scale != media.textScaler.scale(16)) {
      _size = media.size;
      _scale = media.textScaler.scale(16);
      _measure();
    }
    final step = homeGuideSteps[_step];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDone();
      },
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: '메뉴 가이드',
        child: Material(
          key: _root,
          type: MaterialType.transparency,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final target = _target;
              final bottom = target == null
                  ? bounds.maxHeight - media.padding.bottom - 100
                  : target.top - 16;
              final top = media.padding.top + 16;
              final maxHeight = (bottom - top).clamp(0.0, bounds.maxHeight);
              final left = ((target?.center.dx ?? bounds.maxWidth / 2) - 7)
                  .clamp(16.0, bounds.maxWidth - 30);
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: CustomPaint(painter: _GuideScrim(target)),
                    ),
                  ),
                  if (target != null)
                    Positioned(
                      left: left,
                      top: bottom - 1,
                      child: const CustomPaint(
                        size: Size(14, 10),
                        painter: _GuideArrow(),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: bounds.maxHeight - bottom,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: FocusScope(
                            autofocus: true,
                            child: DefaultTextStyle(
                              style: TextStyle(
                                fontFamily: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontFamily,
                                color: const Color(0xff1c2a49),
                                fontSize: 16,
                                height: 1.4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '${_step + 1} / ${homeGuideSteps.length}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Semantics(
                                    liveRegion: true,
                                    header: true,
                                    child: Text(
                                      step.title,
                                      style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(step.description),
                                  const SizedBox(height: 18),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xffffac14),
                                      foregroundColor: const Color(0xff1c2a49),
                                    ),
                                    onPressed: () {
                                      if (_step == homeGuideSteps.length - 1) {
                                        widget.onDone();
                                      } else {
                                        setState(() {
                                          _step++;
                                          _target = null;
                                        });
                                        _measure();
                                      }
                                    },
                                    child: Text(
                                      _step == homeGuideSteps.length - 1
                                          ? '시작하기'
                                          : '다음',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onDone,
                                    child: const Text('건너뛰기'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GuideScrim extends CustomPainter {
  const _GuideScrim(this.target);
  final Rect? target;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final rect = target;
    if (rect != null) {
      path.addRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(16)),
      );
    }
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = const Color(0xb3000000));
    if (rect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(16)),
        Paint()
          ..color = const Color(0xffffac14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_GuideScrim oldDelegate) => oldDelegate.target != target;
}

class _GuideArrow extends CustomPainter {
  const _GuideArrow();
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = Colors.white,
  );
  @override
  bool shouldRepaint(_GuideArrow oldDelegate) => false;
}
