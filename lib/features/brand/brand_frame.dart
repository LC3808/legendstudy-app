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

/// Wraps the app and shows [BrandSplashFrame] once per process (cold start only).
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
                child: const BrandSplashFrame(),
              ),
            ),
        ],
      ),
    );
  }
}

/// The symbol and wordmark form one responsive lockup. Native iOS uses the
/// same symbol centre at normal text scale; Android's OS-owned launch phase
/// retains its required centred icon, then hands off to this shared frame.
class BrandSplashFrame extends StatelessWidget {
  const BrandSplashFrame({super.key});
  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.maybeOf(context)?.padding ?? EdgeInsets.zero;
    return ColoredBox(
      color: Colors.white,
      child: CustomSingleChildLayout(
        delegate: _BrandPosition(padding),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Source alpha bounds are 136..376 of 512px. Trim only the
            // transparent layout margin, keeping the existing symbol scale.
            ClipRect(
              key: ValueKey('brand-visible-symbol'),
              child: Align(
                widthFactor: 240 / 512,
                heightFactor: 240 / 512,
                child: Image(
                  image: AssetImage(
                    'assets/brand/generated/legendstudy_symbol.png',
                  ),
                  width: 180,
                  height: 180,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            SizedBox(height: 20),
            BrandWordmark(fontSize: 26, plusColor: BrandWordmark.brandNavy),
          ],
        ),
      ),
    );
  }
}

class _BrandPosition extends SingleChildLayoutDelegate {
  const _BrandPosition(this.padding);
  final EdgeInsets padding;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: (constraints.maxWidth - padding.horizontal - 32).clamp(
          0,
          double.infinity,
        ),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minTop = padding.top + 16;
    final maxTop = (size.height - padding.bottom - childSize.height - 16).clamp(
      minTop,
      double.infinity,
    );
    return Offset(
      (size.width - childSize.width) / 2,
      (size.height / 3 - childSize.height / 2).clamp(minTop, maxTop),
    );
  }

  @override
  bool shouldRelayout(_BrandPosition oldDelegate) =>
      oldDelegate.padding != padding;
}
