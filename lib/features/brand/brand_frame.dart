import 'dart:async';

import 'package:flutter/material.dart';

import 'brand_wordmark.dart';

/// Cold-start brand experience target from process start (Owner 2026-10-16:
/// ~1.8s so the logo + wordmark lockup is comfortably recognised). The Flutter
/// brand frame runs *in parallel* with initialization: it fills the time up to
/// this target and adds no extra delay once initialization already exceeded it,
/// so app launch is never lengthened by simply summing native + Flutter time.
const brandFrameTarget = Duration(milliseconds: 1800);
// Below this remaining time the frame is skipped, so a slow start never causes a
// sub-150ms text flash before entering the app.
const _minShow = Duration(milliseconds: 150);
// Short, natural hand-off to the app (Owner 2026-10-16: ~150–200ms fade-out).
const _fade = Duration(milliseconds: 180);

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
///   init 0.4s → enter ~1.8s; init 1.2s → ~1.8s; init ≥1.8s → enter right after
///   init (no extra wait). Background→foreground resume never re-shows it
///   (the process, and this static flag, persist).
/// - Sits ABOVE `MaterialApp`, so it never touches the router, auth, onboarding
///   or any existing screen; it is a temporary cover the app resolves beneath.
class BrandGate extends StatefulWidget {
  const BrandGate({
    required this.processStart,
    required this.child,
    this.ready = true,
    super.key,
  });
  final DateTime processStart;
  final Widget child;
  final bool ready;
  @override
  State<BrandGate> createState() => _BrandGateState();
}

class _BrandGateState extends State<BrandGate> {
  static bool _shownThisProcess = false;
  bool _show = false;
  bool _budgetElapsed = false;
  double _opacity = 1;
  Timer? _dismiss;

  @override
  void initState() {
    super.initState();
    if (_shownThisProcess) return; // one cold-start attempt per process
    _shownThisProcess = true;
    final remaining = brandFrameDuration(widget.processStart, DateTime.now());
    if (remaining == null && widget.ready) {
      return; // init already covered the budget
    }
    _show = true;
    _dismiss = Timer(remaining ?? Duration.zero, () {
      _budgetElapsed = true;
      if (mounted && widget.ready) setState(() => _opacity = 0);
    });
  }

  @override
  void didUpdateWidget(covariant BrandGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.ready &&
        widget.ready &&
        (_budgetElapsed ||
            brandFrameDuration(widget.processStart, DateTime.now()) == null)) {
      _opacity = 0;
    }
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

/// Light cold-start frame: the LegendStudy brand lockup — centred orange symbol
/// (position/size matched to the native launch symbol) with the 레전드스터디⁺
/// wordmark (Pretendard, navy body + orange `+`) directly beneath it. Owner
/// 2026-10-08/10-16: one simple brand screen — no tagline, no version/loading/
/// features/ads, no extra animation; logo and service name shown *together*.
///
/// Background is white and the symbol is held SOLID at the exact centre, matched
/// to the native launch symbol, so the native→Flutter handoff shows no jump,
/// flicker or background flip — the lockup simply *completes* as the wordmark
/// appears beneath the symbol. The whole frame fades out once (see [_fade]).
class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Symbol centred and solid → continuous with the native splash symbol.
          Center(
            child: Image(
              image: AssetImage(
                'assets/brand/generated/legendstudy_symbol.png',
              ),
              width: 180,
              height: 180,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Wordmark sits just below centre, shown together with the symbol.
          Align(
            alignment: Alignment(0, 0.34),
            child: BrandWordmark(fontSize: 26),
          ),
        ],
      ),
    );
  }
}
