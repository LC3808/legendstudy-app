import 'package:flutter/material.dart';

import 'brand_wordmark.dart';

/// Native splash hands off to a painted Flutter lockup. Initialization and the
/// first frame, not a fixed timer or process-age budget, control dismissal.
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
  bool _painted = false, _show = true;
  double _opacity = 1;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _painted = true;
      if (widget.ready) setState(() => _opacity = 0);
    });
  }

  @override
  void didUpdateWidget(covariant BrandGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_painted && widget.ready) _opacity = 0;
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_show)
          AbsorbPointer(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 260),
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

const _nearBlack = Color(0xFF12161F);

/// Warm-white cold-start frame: centred orange symbol (position/size matched to
/// the native launch symbol) + the minimal 레전드스터디⁺ wordmark (superscript +,
/// single near-black). Owner 2026-10-08: simple splash — no tagline, no
/// version/loading/features/ads. Continuous with the native white+orange splash.
///
/// Symbol and wordmark are visible together from the first Flutter frame.
class _BrandSplash extends StatelessWidget {
  const _BrandSplash();
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
              image: AssetImage(
                'assets/brand/generated/legendstudy_symbol.png',
              ),
              width: 180,
              height: 180,
              filterQuality: FilterQuality.medium,
            ),
          ),
          // Wordmark is visible even while authentication is still initializing.
          Align(
            alignment: const Alignment(0, 0.34),
            child: const BrandWordmark(fontSize: 26, color: _nearBlack),
          ),
        ],
      ),
    );
  }
}
