import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Cold-start brand experience target from process start. The Flutter brand
/// frame runs *in parallel* with initialization: it fills the time up to this
/// target and adds no extra delay once initialization already exceeded it.
const brandFrameTarget = Duration(milliseconds: 1500);
// Below this remaining time the frame is skipped, so a slow start never causes a
// sub-150ms text flash before entering the app.
const _minShow = Duration(milliseconds: 150);
const _fade = Duration(milliseconds: 260);

const _nearBlack = Color(0xFF12161F);

/// How long the cold-start frame should stay visible given when the process
/// started, or `null` to skip it entirely (initialization already consumed the
/// target, so no extra delay is added). Pure for testing.
Duration? brandFrameDuration(DateTime processStart, DateTime now) {
  final remaining = brandFrameTarget - now.difference(processStart);
  return remaining <= _minShow ? null : remaining;
}

/// Wraps the app and shows [_BrandSplash] once per process (cold start only).
///
/// - `processStart` is captured at the top of `main()`, before initialization.
///   The frame is visible for `brandFrameTarget - elapsed`, so:
///   init 0.4s → enter ~1.5s; init 1.2s → ~1.5s; init ≥1.5s → enter right after
///   init (no extra wait). Background→foreground resume never re-shows it
///   (the process, and this static flag, persist).
/// - Sits ABOVE `MaterialApp`, so it never touches the router, auth, onboarding
///   or any existing screen; it is a temporary cover the app resolves beneath.
class BrandGate extends StatefulWidget {
  const BrandGate({required this.processStart, required this.child, super.key});
  final DateTime processStart;
  final Widget child;
  @override
  State<BrandGate> createState() => _BrandGateState();
}

class _BrandGateState extends State<BrandGate> {
  static bool _shownThisProcess = false;
  bool _show = false;
  double _opacity = 1;
  Timer? _dismiss;

  @override
  void initState() {
    super.initState();
    if (_shownThisProcess) return; // one cold-start attempt per process
    _shownThisProcess = true;
    final remaining = brandFrameDuration(widget.processStart, DateTime.now());
    if (remaining == null) return; // init already covered the budget
    _show = true;
    _dismiss = Timer(remaining, () {
      if (mounted) setState(() => _opacity = 0);
    });
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_show)
            AbsorbPointer(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: _fade,
                curve: Curves.easeOut,
                onEnd: () {
                  if (mounted && _opacity == 0) setState(() => _show = false);
                },
                child: const _BrandSplash(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Warm-white cold-start frame: centred orange symbol (position/size matched to
/// the native launch symbol) + 레전드스터디⁺ (superscript +, single near-black)
/// + the two-line brand tagline. No version/loading/features/ads.
class _BrandSplash extends StatelessWidget {
  const _BrandSplash();
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Symbol centred → continuous with the native splash symbol.
          Center(
            child: Image(
              image: AssetImage('assets/brand/generated/legendstudy_symbol.png'),
              width: 180,
              height: 180,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Name + tagline sit just below centre.
          Align(
            alignment: Alignment(0, 0.42),
            child: _NameAndTagline(),
          ),
        ],
      ),
    );
  }
}

class _NameAndTagline extends StatelessWidget {
  const _NameAndTagline();
  @override
  Widget build(BuildContext context) {
    const nameStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: _nearBlack,
      letterSpacing: -0.2,
      height: 1.1,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '레전드스터디+',
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '레전드스터디'),
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: Transform.translate(
                    offset: const Offset(1, 1),
                    child: const Text(
                      '+',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _nearBlack,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            style: nameStyle,
            textDirection: TextDirection.ltr,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '나의 학습 기록이 쌓일수록,\n나의 가능성은 선명해집니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: AppTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}
