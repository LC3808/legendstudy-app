import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'evaluation_report.dart';

/// Explicit allowlist: no account, answer, feedback prose or evidence identifiers.
Future<Uint8List> growthPng({
  required int completed,
  required int rewrites,
  EvaluationReport? report,
  EvaluationReport? before,
}) async {
  final changes = report == null || before == null
      ? null
      : compareEvaluationReports(before, report);
  final points =
      changes
          ?.where((c) => c.before.rating != null && c.after.rating != null)
          .take(12)
          .toList() ??
      [];
  final recorder = ui.PictureRecorder();
  // A separate canvas avoids capturing any widget containing private profile text.
  final c = Canvas(recorder);
  final height = 360 + points.length * 150;
  c.drawRect(
    Rect.fromLTWH(0, 0, 900, height.toDouble()),
    Paint()..color = Colors.white,
  );
  void text(String value, double x, double y, {double size = 26}) {
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: const Color(0xff172b46),
          fontSize: size,
          fontFamily: 'Pretendard',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 800);
    p.paint(c, Offset(x, y));
  }

  text('나의 논술 성장', 50, 45, size: 40);
  text('첨삭한 답안 $completed · 재작성 $rewrites', 50, 115);
  text('같은 문제·평가 기준의 저장된 결과', 50, 165, size: 22);
  for (var i = 0; i < points.length; i++) {
    final p = points[i], y = 220 + i * 150.0;
    text(p.after.name, 50, y, size: 22);
    c.drawRect(
      Rect.fromLTWH(
        100,
        y + 125 - p.before.rating! * 14,
        40,
        p.before.rating! * 14.0,
      ),
      Paint()..color = Colors.blueGrey,
    );
    c.drawRect(
      Rect.fromLTWH(
        220,
        y + 125 - p.after.rating! * 14,
        40,
        p.after.rating! * 14.0,
      ),
      Paint()..color = const Color(0xffff7043),
    );
    text('이전 ${p.before.rating}   최근 ${p.after.rating}', 320, y + 65, size: 22);
  }
  text('lab.legendstudy.com', 50, height - 65.0, size: 23);
  final picture = recorder.endRecording();
  final image = await picture.toImage(900, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  // Do not persist the renderer or private result object.
  return bytes!.buffer.asUint8List();
}

Future<void> showGrowthShare(
  BuildContext context, {
  required int completed,
  required int rewrites,
  EvaluationReport? report,
  EvaluationReport? before,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('논술 LAB 주소 복사'),
            leading: const Icon(Icons.link),
            onTap: () => Navigator.pop(ctx, 'copy'),
          ),
          ListTile(
            title: const Text('이미지 저장'),
            leading: const Icon(Icons.image_outlined),
            onTap: () => Navigator.pop(ctx, 'image'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  try {
    if (action == 'copy') {
      await Clipboard.setData(
        const ClipboardData(text: 'https://lab.legendstudy.com'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('주소를 복사했어요.')));
      }
    } else {
      final bytes = await growthPng(
        completed: completed,
        rewrites: rewrites,
        report: report,
        before: before,
      );
      await const MethodChannel('com.legendstudy.app/export')
          .invokeMethod<bool>('save', {
            'bytes': bytes,
            'name': 'legendstudy-growth.png',
            'mime': 'image/png',
          });
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
    }
  }
}
