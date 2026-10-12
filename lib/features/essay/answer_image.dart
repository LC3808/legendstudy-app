import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

String? answerImageType(List<int> bytes) {
  if (bytes.length < 12 || bytes.length > 20971520) return null;
  if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
    return 'image/jpeg';
  }
  if ([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
  ].asMap().entries.every((e) => bytes[e.key] == e.value)) {
    return 'image/png';
  }
  if (String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

/// Native camera/library input; no upload, billing or evaluator selection here.
class AnswerImageInput extends StatefulWidget {
  const AnswerImageInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final Uint8List? value;
  final Future<void> Function(Uint8List?) onChanged;
  final bool enabled;
  @override
  State<AnswerImageInput> createState() => _AnswerImageInputState();
}

class _AnswerImageInputState extends State<AnswerImageInput> {
  bool busy = false;
  String? error;
  Future<void> pick(ImageSource source) async {
    setState(() => busy = true);
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null || !mounted) return;
      if (await file.length() > 20971520) throw const FormatException('size');
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (answerImageType(bytes) == null) throw const FormatException('format');
      await widget.onChanged(bytes);
      if (mounted) setState(() => error = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              '사진을 첨부하지 못했어요. 권한을 확인하고 20MB 이하 JPG, PNG, WebP 사진을 선택해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: widget.enabled && !busy
                ? () => pick(ImageSource.camera)
                : null,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('답안 사진 촬영'),
          ),
          OutlinedButton.icon(
            onPressed: widget.enabled && !busy
                ? () => pick(ImageSource.gallery)
                : null,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('이미지 첨부'),
          ),
        ],
      ),
      if (widget.value != null) ...[
        Image.memory(
          widget.value!,
          height: 240,
          fit: BoxFit.contain,
          semanticLabel: '선택한 답안 사진',
          errorBuilder: (_, _, _) => const Text('사진 미리보기를 표시할 수 없습니다.'),
        ),
        TextButton(
          onPressed: widget.enabled && !busy
              ? () => widget.onChanged(null)
              : null,
          child: const Text('사진 삭제'),
        ),
      ],
      if (error != null) Text(error!),
    ],
  );
}

/// Ordered pages; existing single-page camera/gallery component remains unchanged.
class AnswerImagesInput extends StatelessWidget {
  const AnswerImagesInput({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });
  final List<Uint8List> values;
  final Future<void> Function(List<Uint8List>) onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < values.length; i++) ...[
        Text('답안 사진 ${i + 1}'),
        AnswerImageInput(
          value: values[i],
          enabled: enabled,
          onChanged: (next) async {
            final changed = List<Uint8List>.of(values);
            if (next == null) {
              changed.removeAt(i);
            } else {
              changed[i] = next;
            }
            await onChanged(changed);
          },
        ),
      ],
      if (values.length < 6)
        AnswerImageInput(
          value: null,
          enabled: enabled,
          onChanged: (next) async {
            if (next != null) await onChanged([...values, next]);
          },
        ),
      Text('사진 ${values.length}/6장 · 첨부한 순서로 저장됩니다.'),
    ],
  );
}
