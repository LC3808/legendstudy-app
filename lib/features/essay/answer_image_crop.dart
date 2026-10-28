import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Result of the crop flow: cropped [bytes] to attach, [retake] to capture
/// again, or a null outcome from [cropAnswerImage] meaning the student cancelled
/// and the existing attachment must be preserved.
class AnswerCropOutcome {
  const AnswerCropOutcome({this.bytes, this.retake = false});
  final Uint8List? bytes;
  final bool retake;
}

/// 촬영/선택 → 크롭 → 미리보기 → 첨부 전처리. Local-only (dart:ui); never calls an
/// image API. Returns null when dismissed so the caller keeps the prior answer.
Future<AnswerCropOutcome?> cropAnswerImage(
  BuildContext context,
  Uint8List source,
) => Navigator.of(context, rootNavigator: true).push<AnswerCropOutcome>(
  MaterialPageRoute<AnswerCropOutcome>(
    fullscreenDialog: true,
    builder: (_) => _CropScreen(source: source),
  ),
);

class _CropScreen extends StatefulWidget {
  const _CropScreen({required this.source});
  final Uint8List source;
  @override
  State<_CropScreen> createState() => _CropScreenState();
}

enum _Drag { none, move, tl, tr, bl, br }

class _CropScreenState extends State<_CropScreen> {
  ui.Image? image;
  String? error;
  bool working = false;
  // Crop rectangle and the fitted image rectangle, both in layout coordinates.
  Rect? crop;
  Rect imageRect = Rect.zero;
  Size boxSize = Size.zero;
  _Drag drag = _Drag.none;
  // When set, we are previewing a cropped result before attaching.
  Uint8List? preview;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.source);
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => image = frame.image);
    } catch (_) {
      if (mounted) setState(() => error = '사진을 불러오지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  void _layout(Size box, ui.Image img) {
    // Recompute the fitted (BoxFit.contain) image rect and reset the crop box to
    // the full image when the layout size changes.
    if (box == boxSize && crop != null) return;
    final scale = math.min(box.width / img.width, box.height / img.height);
    final w = img.width * scale, h = img.height * scale;
    imageRect = Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
    boxSize = box;
    crop = imageRect;
  }

  double get _min => 48;

  void _onStart(Offset p) {
    final r = crop;
    if (r == null) return;
    const hit = 32.0;
    bool near(Offset c) => (p - c).distance <= hit;
    if (near(r.topLeft)) {
      drag = _Drag.tl;
    } else if (near(r.topRight)) {
      drag = _Drag.tr;
    } else if (near(r.bottomLeft)) {
      drag = _Drag.bl;
    } else if (near(r.bottomRight)) {
      drag = _Drag.br;
    } else if (r.contains(p)) {
      drag = _Drag.move;
    } else {
      drag = _Drag.none;
    }
  }

  void _onUpdate(Offset d) {
    final r = crop;
    if (r == null || drag == _Drag.none) return;
    final b = imageRect;
    double l = r.left, t = r.top, right = r.right, bottom = r.bottom;
    switch (drag) {
      case _Drag.move:
        var nl = (l + d.dx).clamp(b.left, b.right - r.width);
        var nt = (t + d.dy).clamp(b.top, b.bottom - r.height);
        setState(() => crop = Rect.fromLTWH(nl, nt, r.width, r.height));
        return;
      case _Drag.tl:
        l = (l + d.dx).clamp(b.left, right - _min);
        t = (t + d.dy).clamp(b.top, bottom - _min);
      case _Drag.tr:
        right = (right + d.dx).clamp(l + _min, b.right);
        t = (t + d.dy).clamp(b.top, bottom - _min);
      case _Drag.bl:
        l = (l + d.dx).clamp(b.left, right - _min);
        bottom = (bottom + d.dy).clamp(t + _min, b.bottom);
      case _Drag.br:
        right = (right + d.dx).clamp(l + _min, b.right);
        bottom = (bottom + d.dy).clamp(t + _min, b.bottom);
      case _Drag.none:
        return;
    }
    setState(() => crop = Rect.fromLTRB(l, t, right, bottom));
  }

  Future<void> _apply() async {
    final img = image, r = crop;
    if (img == null || r == null || imageRect.width <= 0) return;
    setState(() => working = true);
    try {
      // Map the layout-space crop to source pixels and rasterize losslessly.
      final scale = img.width / imageRect.width;
      final src = Rect.fromLTRB(
        ((r.left - imageRect.left) * scale).clamp(0, img.width.toDouble()),
        ((r.top - imageRect.top) * scale).clamp(0, img.height.toDouble()),
        ((r.right - imageRect.left) * scale).clamp(0, img.width.toDouble()),
        ((r.bottom - imageRect.top) * scale).clamp(0, img.height.toDouble()),
      );
      final w = src.width.round(), h = src.height.round();
      if (w <= 0 || h <= 0) return;
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        img,
        src,
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final out = await recorder.endRecording().toImage(w, h);
      final data = await out.toByteData(format: ui.ImageByteFormat.png);
      out.dispose();
      if (!mounted) return;
      if (data == null) {
        setState(() => error = '사진을 자르지 못했어요. 다시 시도해 주세요.');
        return;
      }
      setState(() => preview = data.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => error = '사진을 자르지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = image;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(preview == null ? '사진 자르기' : '자른 사진 확인'),
        leading: IconButton(
          tooltip: '취소',
          icon: const Icon(Icons.close),
          // Cancel preserves any existing attachment.
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: error != null
          ? Center(
              child: Text(error!, style: const TextStyle(color: Colors.white)),
            )
          : img == null
          ? const Center(child: CircularProgressIndicator())
          : preview != null
          ? _previewBody(preview!)
          : _cropBody(img),
    );
  }

  Widget _cropBody(ui.Image img) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final box = Size(constraints.maxWidth, constraints.maxHeight);
            _layout(box, img);
            final r = crop ?? imageRect;
            return GestureDetector(
              onPanDown: (e) => _onStart(e.localPosition),
              onPanUpdate: (e) => _onUpdate(e.delta),
              onPanEnd: (_) => drag = _Drag.none,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: RawImage(
                      image: img,
                      fit: BoxFit.contain,
                      width: box.width,
                      height: box.height,
                    ),
                  ),
                  CustomPaint(
                    painter: _CropPainter(rect: r, image: imageRect),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      _bar([
        _action(Icons.replay, '다시 촬영', working ? null : _retake),
        _action(
          Icons.crop,
          '적용',
          working || crop == null ? null : _apply,
          primary: true,
        ),
      ]),
    ],
  );

  Widget _previewBody(Uint8List bytes) => Column(
    children: [
      Expanded(
        child: Center(
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
      _bar([
        _action(Icons.crop_rotate, '다시 자르기', () => setState(() => preview = null)),
        _action(Icons.replay, '다시 촬영', _retake),
        _action(
          Icons.check,
          '첨부하기',
          () => Navigator.of(context).pop(AnswerCropOutcome(bytes: bytes)),
          primary: true,
        ),
      ]),
    ],
  );

  void _retake() =>
      Navigator.of(context).pop(const AnswerCropOutcome(retake: true));

  Widget _bar(List<Widget> children) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(AppTokens.space12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    ),
  );

  Widget _action(IconData icon, String label, VoidCallback? onTap,
      {bool primary = false}) {
    final style = TextButton.styleFrom(
      foregroundColor: primary ? AppTokens.textPrimary : Colors.white,
      backgroundColor: primary ? Colors.white : Colors.transparent,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space12,
      ),
    );
    return TextButton.icon(
      style: style,
      onPressed: onTap,
      icon: Icon(icon, size: AppTokens.iconDense),
      label: Text(label),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter({required this.rect, required this.image});
  final Rect rect, image;
  @override
  void paint(Canvas canvas, Size size) {
    // Dim everything outside the crop rectangle.
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(rect),
    );
    canvas.drawPath(outside, dim);
    // Crop border.
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, border);
    // Corner handles.
    final handle = Paint()..color = Colors.white;
    for (final c in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(c, 8, handle);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.rect != rect || old.image != image;
}
