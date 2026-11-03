import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  bool finalCheck = false, bulkRequested = false;
  final regionKeys = <String, GlobalKey>{};
  final confirmationSummaryKey = GlobalKey();
  String? error;
  @override
  void didUpdateWidget(covariant MathRecognitionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(oldWidget.regions) != jsonEncode(widget.regions)) {
      edits.clear();
      checked.clear();
      finalCheck = false;
      bulkRequested = false;
      regionKeys.clear();
      error = null;
    }
  }

  String id(Map<String, dynamic> r) => '${r['region_id'] ?? r['id']}';
  String original(Map<String, dynamic> r) =>
      (r['raw_text'] as String? ?? '').trim().isNotEmpty
      ? r['raw_text'] as String
      : r['normalized_math'] as String? ?? '';
  List<String> get bulkConfirmable => [
    for (final r in widget.regions)
      if (r['uncertain'] != true &&
          !unresolvedMath(edits[id(r)] ?? original(r)))
        id(r),
  ];
  String regionLabel(Map<String, dynamic> region) =>
      '영역 ${region['reading_order'] ?? widget.regions.indexOf(region) + 1}';

  bool needsCorrection(Map<String, dynamic> region) =>
      unresolvedMath(edits[id(region)] ?? original(region));

  String reviewLabel(Map<String, dynamic> region) =>
      checked.contains(id(region))
      ? '확인 완료'
      : needsCorrection(region)
      ? '내용 수정 필요'
      : '원본 대조 필요';

  Future<void> reveal(GlobalKey key) async {
    FocusScope.of(context).unfocus();
    final target = key.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      alignment: 0.05,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
    );
  }

  void confirmAvailableRegions() {
    setState(() {
      // An explicit bulk action only adds eligible checks. Repeated taps never
      // undo checks or confirm uncertain/missing symbols on the student's behalf.
      final added = bulkConfirmable
          .where((key) => !checked.contains(key))
          .toList();
      checked.addAll(added);
      if (added.isNotEmpty) finalCheck = false;
      bulkRequested = true;
    });
    // Review links added above the action change the scroll extent. Keep the
    // outcome in view after layout, including when no rows can be bulk checked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && bulkRequested) reveal(confirmationSummaryKey);
    });
  }

  Widget requiredGroup(String title, List<Map<String, dynamic>> regions) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AcademicPurple.ink,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final region in regions)
                ActionChip(
                  key: ValueKey('review-region-${id(region)}'),
                  tooltip: '${regionLabel(region)} 확인하러 이동',
                  label: Text(regionLabel(region)),
                  avatar: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: widget.busy
                      ? null
                      : () => reveal(regionKeys[id(region)]!),
                ),
            ],
          ),
        ],
      );

  Widget bulkConfirmation() {
    final remaining = widget.regions
        .where((r) => !checked.contains(id(r)))
        .toList();
    final corrections = remaining.where(needsCorrection).toList();
    final comparisons = remaining
        .where((r) => !needsCorrection(r) && r['uncertain'] == true)
        .toList();
    final unchecked = remaining
        .where((r) => !needsCorrection(r) && r['uncertain'] != true)
        .toList();
    return Container(
      key: confirmationSummaryKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('confirm-recognized-regions'),
            onPressed: widget.busy ? null : confirmAvailableRegions,
            icon: const Icon(Icons.done_all),
            label: const Text('전체 내용 확인'),
          ),
          const SizedBox(height: 8),
          const Text(
            '원본과 대조한 영역을 한 번에 체크해요. 불확실한 영역은 별도 확인이 필요해요.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AcademicPurple.secondary,
            ),
          ),
          if (bulkRequested) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                '확인 완료 ${checked.length}개 · 남은 영역 ${remaining.length}개',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AcademicPurple.dark,
                ),
              ),
            ),
            if (remaining.isEmpty)
              const Text('모든 영역을 체크했어요. 아래에서 최종 확인해 주세요.')
            else ...[
              if (bulkConfirmable.isEmpty)
                const Text('일괄 체크 가능한 영역이 없어요. 아래 번호를 눌러 직접 확인해 주세요.')
              else
                const Text('남은 영역 번호를 누르면 해당 위치로 이동해요.'),
              if (corrections.isNotEmpty)
                requiredGroup('반드시 수정 · 미식별 내용이 남아 있어요', corrections),
              if (comparisons.isNotEmpty)
                requiredGroup('반드시 확인 · 원본의 기호·값을 대조해 주세요', comparisons),
              if (unchecked.isNotEmpty)
                requiredGroup('체크가 해제된 영역 · 다시 확인해 주세요', unchecked),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

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
          key: regionKeys.putIfAbsent(id(region), GlobalKey.new),
          tinted: region['uncertain'] == true,
          border: const BorderSide(color: AcademicPurple.primary, width: 1.5),
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
                      '${regionLabel(region)} · ${reviewLabel(region)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: '원본 크게 보기',
                    icon: const Icon(Icons.zoom_in, color: AcademicPurple.dark),
                    onPressed:
                        widget.sources['${region['artifact_id']}'] == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MathMobileTheme(
                                child: Scaffold(
                                  appBar: AppBar(
                                    title: Text(
                                      '${regionLabel(region)} · 원본 대조',
                                    ),
                                  ),
                                  body: SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: MathSourceRegion(
                                        region: region,
                                        bytes: widget
                                            .sources['${region['artifact_id']}'],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              _RecognitionComparison(
                key: ValueKey(id(region)),
                text: edits[id(region)] ?? original(region),
                region: region,
                bytes: widget.sources['${region['artifact_id']}'],
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
                key: ValueKey('confirm-region-${id(region)}'),
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
                  '읽지 못한 기호가 남아 있어요. 원본을 대조해 수정하거나 사진을 다시 준비해 주세요.',
                  style: TextStyle(color: AcademicPurple.error),
                ),
              if (bulkRequested)
                TextButton.icon(
                  key: ValueKey('return-to-confirmation-${id(region)}'),
                  onPressed: widget.busy
                      ? null
                      : () => reveal(confirmationSummaryKey),
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('남은 확인 목록으로'),
                ),
            ],
          ),
        ),
      if (widget.regions.length > 1) bulkConfirmation(),
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

/// Measure the rendered formula/prose, including wrapping and accessibility
/// scale. Both tabs share this height; long answers remain scrollable in full.
class _RecognitionComparison extends StatefulWidget {
  const _RecognitionComparison({
    required this.text,
    required this.region,
    required this.bytes,
    super.key,
  });
  final String text;
  final Map<String, dynamic> region;
  final Uint8List? bytes;
  @override
  State<_RecognitionComparison> createState() => _RecognitionComparisonState();
}

class _RecognitionComparisonState extends State<_RecognitionComparison> {
  double contentHeight = 96;
  @override
  Widget build(BuildContext context) {
    final minimum = MediaQuery.textScalerOf(context)
        .scale(64)
        .clamp(96.0, 192.0);
    final tabHeight = MediaQuery.textScalerOf(context).scale(14) * 2.8;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelStyle: const TextStyle(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            tabs: [
              for (final label in ['인식 수식', '원본 이미지'])
                Tab(
                  height: tabHeight < 48 ? 48 : tabHeight,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
            ],
          ),
          SizedBox(
            height: contentHeight.clamp(minimum, 320.0),
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  child: _ContentHeightObserver(
                    onChanged: (height) {
                      if (mounted && (contentHeight - height).abs() > 0.5) {
                        setState(() => contentHeight = height);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: MathStudentText(widget.text),
                    ),
                  ),
                ),
                MathSourceRegion(region: widget.region, bytes: widget.bytes),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentHeightObserver extends SingleChildRenderObjectWidget {
  const _ContentHeightObserver({required this.onChanged, required super.child});
  final ValueChanged<double> onChanged;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderContentHeightObserver(onChanged);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderContentHeightObserver renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class _RenderContentHeightObserver extends RenderProxyBox {
  _RenderContentHeightObserver(this.onChanged);
  ValueChanged<double> onChanged;
  double? previousHeight;
  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (!height.isFinite || previousHeight == height) return;
    previousHeight = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onChanged(height);
    });
  }
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
