import '../analytics/analytics_providers.dart';
import '../analytics/domain/analytics_events.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';

import 'package:image_picker/image_picker.dart';

import 'answer_image_crop.dart';

/// OCR photos never enter the evaluation attachment store.
class AnswerOcrEngine {
  static const channel = MethodChannel('com.legendstudy.app/answer-ocr');
  Future<String> recognize(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 20971520) {
      throw const FormatException('IMAGE_SIZE');
    }
    final result = await channel.invokeMapMethod<String, dynamic>('recognize', {
      'bytes': bytes,
    });
    final lines = (result?['lines'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();
    return assembleOcrLines(lines);
  }
}

/// Keep observed lines; large vertical gaps suggest a paragraph, never words.
String assembleOcrLines(List<Map<dynamic, dynamic>> lines) {
  final buffer = StringBuffer();
  double? bottom, previousHeight;
  for (final line in lines) {
    final text = line['text'] as String? ?? '';
    if (text.trim().isEmpty) continue;
    final top = (line['top'] as num?)?.toDouble();
    final height = (line['height'] as num?)?.toDouble();
    if (buffer.isNotEmpty) {
      buffer.write('\n');
      if (top != null &&
          bottom != null &&
          previousHeight != null &&
          top - bottom > previousHeight * 0.8) {
        buffer.write('\n');
      }
    }
    buffer.write(text);
    bottom = top == null || height == null ? null : top + height;
    previousHeight = height;
  }
  return buffer.toString();
}

class OcrTextSelection {
  const OcrTextSelection(this.text, {required this.replace});
  final String text;
  final bool replace;
}

class AnswerOcrPage extends ConsumerStatefulWidget {
  const AnswerOcrPage({
    super.key,
    required this.hasAnswer,
    required this.owner,
  });
  final String owner;
  final bool hasAnswer;
  @override
  ConsumerState<AnswerOcrPage> createState() => _AnswerOcrPageState();
}

class _AnswerOcrPageState extends ConsumerState<AnswerOcrPage> {
  final editor = TextEditingController();
  Uint8List? photo;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  bool get activeOwner =>
      mounted && ref.read(authStateProvider).value?.userId == widget.owner;

  Future<void> pick(ImageSource source) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 4000,
        maxHeight: 4000,
      );
      if (picked == null || !activeOwner) return;
      if (await picked.length() > 20971520) {
        throw const FormatException('IMAGE_SIZE');
      }
      final bytes = await picked.readAsBytes();
      if (!mounted || !activeOwner) return;
      final cropped = await cropAnswerImage(context, bytes);
      if (!activeOwner || cropped == null) return;
      if (cropped.retake) {
        setState(() => busy = false);
        return await pick(source);
      }
      if (cropped.bytes == null) return;
      setState(() => photo = cropped.bytes);
      await recognize();
    } catch (_) {
      if (mounted) setState(() => error = '사진을 불러오지 못했어요. 권한과 사진 크기를 확인해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recognize() async {
    if (photo == null) return;
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(AnalyticsEvents.essayOcrStart);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final text = await AnswerOcrEngine().recognize(photo!);
      if (!activeOwner) return;
      analytics.logEvent(
        text.trim().isEmpty
            ? AnalyticsEvents.essayOcrFailure
            : AnalyticsEvents.essayOcrSuccess,
      );
      if (text.trim().isEmpty) {
        setState(() => error = '글자를 찾지 못했어요. 사진을 확인하고 다시 시도해 주세요.');
      } else {
        editor.text = text;
      }
    } catch (_) {
      analytics.logEvent(AnalyticsEvents.essayOcrFailure);
      if (mounted) setState(() => error = '텍스트를 인식하지 못했어요. 사진과 기존 답안은 유지됩니다.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void apply(bool replace) {
    if (!activeOwner || editor.text.trim().isEmpty || busy) return;
    Navigator.pop(context, OcrTextSelection(editor.text, replace: replace));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    ref.listen(authStateProvider, (_, next) {
      if (!next.isLoading && next.value?.userId != widget.owner) {
        photo = null;
        editor.clear();
      }
    });
    if (auth.isLoading || auth.value?.userId != widget.owner) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('로그인 상태를 확인해 주세요.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('사진으로 답안 입력')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '사진은 기기에서 인식합니다. 글자·숫자·줄바꿈을 직접 확인하고 수정해 주세요. 손글씨는 잘못 인식될 수 있어요.',
          ),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('촬영'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : () => pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('갤러리'),
              ),
            ],
          ),
          if (photo != null)
            Image.memory(photo!, height: 220, fit: BoxFit.contain),
          if (busy) const LinearProgressIndicator(),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (photo != null && error != null)
            TextButton(
              onPressed: busy ? null : recognize,
              child: const Text('같은 사진 다시 인식'),
            ),
          TextField(
            controller: editor,
            enabled: !busy,
            minLines: 8,
            maxLines: null,
            maxLength: 30000,
            decoration: const InputDecoration(labelText: '인식 결과 확인·수정'),
          ),
          const Text('적용한 텍스트는 기존 임시저장에 연결됩니다. 첨삭은 답안 화면에서 직접 요청해 주세요.'),
          if (widget.hasAnswer)
            OutlinedButton(
              onPressed: busy ? null : () => apply(false),
              child: const Text('기존 답안 뒤에 합치기'),
            ),
          FilledButton(
            onPressed: busy ? null : () => apply(true),
            child: Text(widget.hasAnswer ? '기존 답안 교체하기' : '답안에 적용'),
          ),
        ],
      ),
    );
  }
}
