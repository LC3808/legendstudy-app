import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../answer_image.dart';
import '../answer_image_crop.dart';
import 'academic_purple.dart';

Future<Uint8List> transformMathPhoto(
  Uint8List original, {
  required int turns,
  required Rect crop,
}) async {
  if (crop.left < 0 ||
      crop.top < 0 ||
      crop.right > 1 ||
      crop.bottom > 1 ||
      crop.width <= 0 ||
      crop.height <= 0) {
    throw const FormatException('INVALID_CROP');
  }
  final codec = await ui.instantiateImageCodec(original);
  final frame = await codec.getNextFrame();
  codec.dispose();
  final source = frame.image;
  try {
    final quarter = turns % 4,
        rotatedWidth = quarter.isEven ? source.width : source.height,
        rotatedHeight = quarter.isEven ? source.height : source.width;
    final width = math.max(1, (rotatedWidth * crop.width).round()),
        height = math.max(1, (rotatedHeight * crop.height).round());
    final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
    canvas.translate(-crop.left * rotatedWidth, -crop.top * rotatedHeight);
    canvas.translate(rotatedWidth / 2, rotatedHeight / 2);
    canvas.rotate(quarter * math.pi / 2);
    canvas.drawImage(
      source,
      Offset(-source.width / 2, -source.height / 2),
      Paint(),
    );
    final picture = recorder.endRecording(),
        image = await picture.toImage(width, height);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null || bytes.lengthInBytes > 20971520) {
      throw const FormatException('IMAGE_TOO_LARGE');
    }
    return bytes.buffer.asUint8List();
  } finally {
    source.dispose();
  }
}

class MathImageInput extends StatefulWidget {
  const MathImageInput({
    required this.values,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });
  final List<Uint8List> values;
  final Future<void> Function(List<Uint8List>) onChanged;
  final bool enabled;
  @override
  State<MathImageInput> createState() => _MathImageInputState();
}

class _MathImageInputState extends State<MathImageInput> {
  final originals = <Uint8List, Uint8List>{};
  @override
  Widget build(BuildContext context) => AnswerImagesInput(
    values: widget.values,
    onChanged: widget.onChanged,
    enabled: widget.enabled,
    allowReorder: true,
    onEdit: (i) async {
      final bytes = widget.values[i], original = originals[bytes] ?? bytes;
      final edited = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => MathPhotoEditor(original: original)),
      );
      if (edited == null || !mounted || !widget.enabled) return;
      final index = widget.values.indexOf(bytes);
      if (index < 0) return;
      originals[edited] = original;
      final next = List<Uint8List>.of(widget.values);
      next[index] = edited;
      await widget.onChanged(next);
    },
  );
}

/// Uses the humanities crop handles/preview flow with the existing Math
/// rotation and immutable-original processing contract.
class MathPhotoEditor extends StatelessWidget {
  const MathPhotoEditor({required this.original, super.key});
  final Uint8List original;
  @override
  Widget build(BuildContext context) => MathMobileTheme(
    child: AnswerImageCropScreen(
      source: original,
      allowRetake: false,
      transform: (turns, crop) =>
          transformMathPhoto(original, turns: turns, crop: crop),
      onAttach: (bytes) => Navigator.of(context).pop(bytes),
    ),
  );
}
