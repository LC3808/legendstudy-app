import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../answer_image.dart';
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

class MathPhotoEditor extends StatefulWidget {
  const MathPhotoEditor({required this.original, super.key});
  final Uint8List original;
  @override
  State<MathPhotoEditor> createState() => _MathPhotoEditorState();
}

class _MathPhotoEditorState extends State<MathPhotoEditor> {
  late final Future<Size> dimensions = () async {
    final codec = await ui.instantiateImageCodec(widget.original);
    try {
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  }();
  int turns = 0;
  RangeValues horizontal = const RangeValues(0, 1),
      vertical = const RangeValues(0, 1);
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => MathMobileTheme(
    child: Scaffold(
      appBar: AppBar(title: const Text('사진 보정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('원본은 유지하고 보정한 사본을 제출합니다. 두 손가락으로 확대해 확인하세요.'),
          SizedBox(
            height: 360,
            child: FutureBuilder<Size>(
              future: dimensions,
              builder: (context, state) {
                if (!state.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final size = state.data!;
                final ratio = turns.isEven
                    ? size.width / size.height
                    : size.height / size.width;
                return Center(
                  child: InteractiveViewer(
                    maxScale: 6,
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: LayoutBuilder(
                        builder: (context, b) => Stack(
                          fit: StackFit.expand,
                          children: [
                            RotatedBox(
                              quarterTurns: turns,
                              child: Image.memory(
                                widget.original,
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned(
                              left: horizontal.start * b.maxWidth,
                              top: vertical.start * b.maxHeight,
                              width:
                                  (horizontal.end - horizontal.start) *
                                  b.maxWidth,
                              height:
                                  (vertical.end - vertical.start) * b.maxHeight,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AcademicPurple.primary,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => setState(() => turns = (turns + 1) % 4),
            icon: const Icon(Icons.rotate_right),
            label: const Text('오른쪽으로 90° 회전'),
          ),
          Text(
            '가로 자르기 · ${(horizontal.start * 100).round()}–${(horizontal.end * 100).round()}%',
          ),
          RangeSlider(
            values: horizontal,
            onChanged: busy
                ? null
                : (v) {
                    if (v.end - v.start >= .1) setState(() => horizontal = v);
                  },
          ),
          Text(
            '세로 자르기 · ${(vertical.start * 100).round()}–${(vertical.end * 100).round()}%',
          ),
          RangeSlider(
            values: vertical,
            onChanged: busy
                ? null
                : (v) {
                    if (v.end - v.start >= .1) setState(() => vertical = v);
                  },
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    turns = 0;
                    horizontal = vertical = const RangeValues(0, 1);
                  }),
            child: const Text('원본으로 되돌리기'),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: AcademicPurple.error)),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      final image = await transformMathPhoto(
                        widget.original,
                        turns: turns,
                        crop: Rect.fromLTRB(
                          horizontal.start,
                          vertical.start,
                          horizontal.end,
                          vertical.end,
                        ),
                      );
                      if (context.mounted) Navigator.pop(context, image);
                    } catch (_) {
                      if (mounted) {
                        setState(() => error = '사진 보정에 실패했습니다. 원본은 보존되어 있습니다.');
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(busy ? '사본 처리 중…' : '보정 사본 적용'),
          ),
        ],
      ),
    ),
  );
}
