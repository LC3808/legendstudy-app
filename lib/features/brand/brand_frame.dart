import 'dart:async';

import 'package:flutter/material.dart';

import 'brand_wordmark.dart';

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
/// the native launch symbol) + the minimal 레전드스터디⁺ wordmark (superscript +,
/// single near-black). Owner 2026-10-08: simple splash — no tagline, no
/// version/loading/features/ads. Continuous with the native white+orange splash.
///
/// The symbol is held SOLID and pixel-matched to the native launch symbol, so
/// the native→Flutter handoff shows no jump or flicker. Only the wordmark eases
/// in (Owner 2026-10-09): the lockup *completes* smoothly instead of the name
/// popping in abruptly after the orange symbol.
class _BrandSplash extends StatefulWidget {
  const _BrandSplash();
  @override
  State<_BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<_BrandSplash> {
  // Gentle wordmark reveal. Starts transparent and fades to 1 on first frame.
  double _wordmarkOpacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _wordmarkOpacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Symbol centred and solid → continuous with the native splash symbol.
          const Center(
            child: Image(
              image: AssetImage('assets/brand/generated/legendstudy_symbol.png'),
              width: 180,
              height: 180,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Minimal wordmark sits just below centre and eases in.
          Align(
            alignment: const Alignment(0, 0.34),
            child: AnimatedOpacity(
              opacity: _wordmarkOpacity,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              child: const BrandWordmark(fontSize: 26, color: _nearBlack),
            ),
          ),
        ],
      ),
    );
  }
}
