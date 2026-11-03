import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../math_text.dart';
import 'academic_purple.dart';
import 'math_formula_editor.dart';

class MathRecognitionPanel extends StatefulWidget {
  const MathRecognitionPanel({
    required this.regions,
    required this.onConfirm,
    this.sources = const {},
    this.busy = false,
    super.key,
  });
  final List<Map<String, dynamic>> regions;
  final Map<String, Uint8List> sources;
  final Future<void> Function(Map<String, String>) onConfirm;
  final bool busy;
  @override
  State<MathRecognitionPanel> createState() => _MathRecognitionPanelState();
}

class _MathRecognitionPanelState extends State<MathRecognitionPanel> {
  final edits = <String, String>{}, checked = <String>{};
  bool finalCheck = false;
  String? error;
  @override
  void didUpdateWidget(covariant MathRecognitionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(oldWidget.regions) != jsonEncode(widget.regions)) {
      edits.clear();
      checked.clear();
      finalCheck = false;
      error = null;
    }
  }

  String id(Map<String, dynamic> r) => '${r['region_id'] ?? r['id']}';
  String original(Map<String, dynamic> r) =>
      (r['raw_text'] as String? ?? '').trim().isNotEmpty
      ? r['raw_text'] as String
      : r['normalized_math'] as String? ?? '';
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MathInputProgress(stage: 1),
      const SizedBox(height: 20),
      const Text(
        '인식 결과 확인',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        '신뢰도가 높아도 원본과 다를 수 있어요. 부호·지수·첨자·분수·괄호·적분 범위·숫자·단위를 대조해 주세요.',
        style: TextStyle(color: AcademicPurple.secondary, height: 1.5),
      ),
      const SizedBox(height: 16),
      for (final region in widget.regions)
        MathCard(
          tinted: region['uncertain'] == true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    region['uncertain'] == true
                        ? Icons.warning_amber_rounded
                        : Icons.fact_check_outlined,
                    color: region['uncertain'] == true
                        ? AcademicPurple.error
                        : AcademicPurple.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '영역 ${region['reading_order'] ?? ''} · 원본 대조 필요',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: '인식 수식'),
                        Tab(text: '원본 이미지'),
                      ],
                    ),
                    SizedBox(
                      height: 230,
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: MathStudentText(
                              edits[id(region)] ?? original(region),
                            ),
                          ),
                          MathSourceRegion(
                            region: region,
                            bytes: widget.sources['${region['artifact_id']}'],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ExpansionTile(
                title: const Text('전사 내용 수정'),
                children: [
                  MathFormulaEditor(
                    key: ValueKey('${id(region)}/${original(region)}'),
                    value: original(region),
                    enabled: !widget.busy,
                    onChanged: (value) => setState(() {
                      edits[id(region)] = value;
                      checked.remove(id(region));
                      finalCheck = false;
                    }),
                  ),
                ],
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: checked.contains(id(region)),
                title: Text(
                  edits.containsKey(id(region))
                      ? '원본을 대조했고 수정한 기호·값을 확인했어요'
                      : '원본과 기호·값이 일치함을 확인했어요',
                ),
                onChanged:
                    widget.busy ||
                        unresolvedMath(edits[id(region)] ?? original(region))
                    ? null
                    : (v) => setState(() {
                        if (v == true) {
                          checked.add(id(region));
                        } else {
                          checked.remove(id(region));
                        }
                        finalCheck = false;
                      }),
              ),
              if (unresolvedMath(edits[id(region)] ?? original(region)))
                const Text(
                  'UNCERTAIN · 불명확한 기호를 확인하거나 사진을 다시 준비해 주세요.',
                  style: TextStyle(color: AcademicPurple.error),
                ),
            ],
          ),
        ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: finalCheck,
        title: const Text('모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.'),
        onChanged:
            widget.busy ||
                checked.length != widget.regions.length ||
                widget.regions.isEmpty
            ? null
            : (v) => setState(() => finalCheck = v == true),
      ),
      if (error != null)
        Text(error!, style: const TextStyle(color: AcademicPurple.error)),
      FilledButton.icon(
        onPressed: widget.busy || !finalCheck
            ? null
            : () async {
                try {
                  await widget.onConfirm({
                    for (final r in widget.regions)
                      id(r): edits[id(r)] ?? original(r),
                  });
                } catch (_) {
                  if (mounted) {
                    setState(
                      () =>
                          error = '확인본 저장 결과를 확인하지 못했습니다. 같은 내용으로 다시 확인해 주세요.',
                    );
                  }
                }
              },
        icon: const Icon(Icons.check),
        label: const Text('답안 입력 완료'),
      ),
    ],
  );
}

class MathInputProgress extends StatelessWidget {
  const MathInputProgress({required this.stage, super.key});
  final int stage;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, label) in ['제출', '확인', '입력 완료'].indexed)
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: i == stage
                    ? AcademicPurple.primary
                    : AcademicPurple.emphasis,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i == stage ? Colors.white : AcademicPurple.dark,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  color: i == stage
                      ? AcademicPurple.ink
                      : AcademicPurple.secondary,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class MathSourceRegion extends StatefulWidget {
  const MathSourceRegion({required this.region, this.bytes, super.key});
  final Map<String, dynamic> region;
  final Uint8List? bytes;
  @override
  State<MathSourceRegion> createState() => _MathSourceRegionState();
}

class _MathSourceRegionState extends State<MathSourceRegion> {
  Future<Size>? dimensions;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant MathSourceRegion old) {
    super.didUpdateWidget(old);
    if (old.bytes != widget.bytes) load();
  }

  void load() {
    dimensions = widget.bytes == null ? null : measure(widget.bytes!);
  }

  Future<Size> measure(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bytes == null) {
      return const Center(child: Text('원본 사진을 다시 선택해 대조해 주세요.'));
    }
    double value(String k) =>
        (widget.region[k] as num?)?.toDouble() ?? double.nan;
    final x = value('x'),
        y = value('y'),
        w = value('width'),
        h = value('height');
    final valid =
        [x, y, w, h].every((v) => v.isFinite) &&
        x >= 0 &&
        y >= 0 &&
        w > 0 &&
        h > 0 &&
        x + w <= 1 &&
        y + h <= 1;
    return FutureBuilder<Size>(
      future: dimensions,
      builder: (context, state) {
        if (state.hasError) {
          return const Center(child: Text('원본 이미지를 표시할 수 없습니다.'));
        }
        if (!state.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 6,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: state.data!.width / state.data!.height,
                    child: LayoutBuilder(
                      builder: (context, b) => Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(widget.bytes!, fit: BoxFit.fill),
                          if (valid)
                            Positioned(
                              left: x * b.maxWidth,
                              top: y * b.maxHeight,
                              width: w * b.maxWidth,
                              height: h * b.maxHeight,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AcademicPurple.error,
                                      width: 2,
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
              ),
            ),
            if (!valid)
              const Text(
                '영역 좌표 미확정 · 전체 원본 대조',
                style: TextStyle(color: AcademicPurple.error),
              ),
          ],
        );
      },
    );
  }
}
