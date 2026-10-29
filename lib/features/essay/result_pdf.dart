import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'evaluation_report.dart';

/// Local private export; no public URL, source artifact, account or answer body.
Future<Uint8List> evaluationPdf(EvaluationReport report) async {
  final blocks = <String>[
    '논술 첨삭 결과',
    '종합 평가',
    report.summary,
    '평가 기준별 결과',
    for (final c in report.rubric) '${c.name} · ${c.display}\n${c.feedback}',
    '잘한 점',
    for (final f in report.strengths) '${f.title}\n${f.explanation}',
    '보완할 점',
    for (final f in report.weaknesses)
      '${f.title}\n${f.explanation}\n${f.action}',
    '다음 재작성',
    ...report.actions,
    ...report.nextSteps,
  ];
  final pages = <Uint8List>[];
  var recorder = ui.PictureRecorder();
  var canvas = Canvas(recorder);
  double y = 60;
  void background() => canvas.drawRect(
    const Rect.fromLTWH(0, 0, 840, 1188),
    Paint()..color = Colors.white,
  );
  background();
  Future<void> finish() async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(840, 1188);
    final raw = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final rgb = Uint8List(840 * 1188 * 3);
    for (int i = 0, j = 0; i < raw.length; i += 4) {
      rgb[j++] = raw[i];
      rgb[j++] = raw[i + 1];
      rgb[j++] = raw[i + 2];
    }
    pages.add(Uint8List.fromList(zlib.encode(rgb)));
    image.dispose();
    picture.dispose();
  }

  for (final block in blocks) {
    // Bounded fragments also paginate unusually long stored paragraphs.
    for (final line in block.split('\n')) {
      final runes = line.runes.toList();
      for (var start = 0; start < runes.length; start += 48) {
        final text = String.fromCharCodes(
          runes.sublist(start, (start + 48).clamp(0, runes.length)),
        );
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 21,
              color: Color(0xff172b46),
              fontFamily: 'Pretendard',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 720);
        if (y + painter.height > 1120) {
          await finish();
          if (pages.length >= 30) throw StateError('REPORT_TOO_LONG');
          recorder = ui.PictureRecorder();
          canvas = Canvas(recorder);
          background();
          y = 60;
        }
        painter.paint(canvas, Offset(60, y));
        y += painter.height + 8;
        painter.dispose();
      }
      y += 8;
    }
    y += 12;
  }
  await finish();
  final objects = <List<int>>[];
  List<int> ascii(String s) => s.codeUnits;
  objects.add(ascii('<< /Type /Catalog /Pages 2 0 R >>'));
  objects.add(
    ascii(
      '<< /Type /Pages /Count ${pages.length} /Kids [${List.generate(pages.length, (i) => '${3 + i * 3} 0 R').join(' ')}] >>',
    ),
  );
  for (var i = 0; i < pages.length; i++) {
    final base = 3 + i * 3, data = pages[i];
    objects.add(
      ascii(
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /XObject << /Im ${base + 1} 0 R >> >> /Contents ${base + 2} 0 R >>',
      ),
    );
    objects.add([
      ...ascii(
        '<< /Type /XObject /Subtype /Image /Width 840 /Height 1188 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /Length ${data.length} >>\nstream\n',
      ),
      ...data,
      ...ascii('\nendstream'),
    ]);
    final drawing = 'q 595 0 0 842 0 0 cm /Im Do Q';
    objects.add(
      ascii('<< /Length ${drawing.length} >>\nstream\n$drawing\nendstream'),
    );
  }
  final output = BytesBuilder();
  void add(String s) => output.add(ascii(s));
  add('%PDF-1.4\n');
  final offsets = <int>[0];
  for (var i = 0; i < objects.length; i++) {
    offsets.add(output.length);
    add('${i + 1} 0 obj\n');
    output.add(objects[i]);
    add('\nendobj\n');
  }
  final xref = output.length;
  add('xref\n0 ${offsets.length}\n0000000000 65535 f \n');
  for (final n in offsets.skip(1)) {
    add('${n.toString().padLeft(10, '0')} 00000 n \n');
  }
  add(
    'trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n',
  );
  return output.takeBytes();
}

class ResultPdfButton extends StatefulWidget {
  const ResultPdfButton({required this.report, super.key});
  final EvaluationReport report;
  @override
  State<ResultPdfButton> createState() => _ResultPdfButtonState();
}

class _ResultPdfButtonState extends State<ResultPdfButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1C2B4B),
      backgroundColor: const Color(0xFFFFF2D9),
      side: const BorderSide(color: Color(0xFFFFAC14)),
    ),
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              final bytes = await evaluationPdf(widget.report);
              if (!mounted) return;
              await const MethodChannel('com.legendstudy.app/export')
                  .invokeMethod<bool>('save', {
                    'bytes': bytes,
                    'name': 'legendstudy-feedback.pdf',
                    'mime': 'application/pdf',
                  });
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('파일을 저장하지 못했어요. 다시 시도해 주세요.')),
                );
              }
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
    child: Text(busy ? 'PDF 준비 중' : '첨삭 결과 PDF 저장'),
  );
}
