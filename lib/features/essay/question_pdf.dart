import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Backend-issued, question-only derivative. Never accept a source PDF URL here.
class QuestionPdfAsset {
  const QuestionPdfAsset(this.id, this.hash, this.pages, this.startPage);
  final String id, hash;
  final int pages, startPage;
  static QuestionPdfAsset? parse(dynamic value, String questionId) {
    if (questionId.isEmpty ||
        value is! Map ||
        value['kind'] != 'student_question' ||
        value['questionId'] != questionId ||
        value['verification'] != 'VERIFIED' ||
        value['studentDisplay'] != 'APPROVED' ||
        value['assetId'] is! String ||
        !RegExp(r'^[-a-zA-Z0-9]{1,80}$').hasMatch(value['assetId'] as String) ||
        value['sha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['sha256'] as String) ||
        value['pageCount'] is! int ||
        value['startPage'] is! int) {
      return null;
    }
    final pages = value['pageCount'] as int, start = value['startPage'] as int;
    if (pages < 1 || pages > 3000 || start < 1 || start > pages) return null;
    return QuestionPdfAsset(
      value['assetId'] as String,
      value['sha256'] as String,
      pages,
      start,
    );
  }

  Uint8List validate(Uint8List bytes) {
    if (bytes.length > 32 * 1024 * 1024 ||
        bytes.length < 5 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-' ||
        sha256.convert(bytes).toString() != hash) {
      throw StateError('문제 자료를 확인하지 못했어요.');
    }
    return bytes;
  }
}

/// Reuses pdfrx native renderer; load is an authenticated backend transport.
/// Caller retains the widget with Offstage so switching to writing preserves zoom.
class EssayQuestionPdf extends StatefulWidget {
  const EssayQuestionPdf({
    super.key,
    required this.asset,
    required this.load,
    required this.restorePage,
    required this.savePage,
  });
  final QuestionPdfAsset asset;
  final Future<Uint8List> Function() load;
  final Future<int?> Function() restorePage;
  final Future<void> Function(int) savePage;
  @override
  State<EssayQuestionPdf> createState() => _EssayQuestionPdfState();
}

class _EssayQuestionPdfState extends State<EssayQuestionPdf> {
  final controller = PdfViewerController();
  late Future<Uint8List> bytes = load();
  int page = 1;
  bool ready = false;
  Future<Uint8List> load() async {
    final restored = await widget.restorePage();
    page = (restored ?? widget.asset.startPage).clamp(1, widget.asset.pages);
    return widget.asset.validate(await widget.load());
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 520,
    child: Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            IconButton(
              tooltip: '이전 페이지',
              onPressed: ready && page > 1
                  ? () => controller.goToPage(pageNumber: page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('$page / ${widget.asset.pages}'),
            IconButton(
              tooltip: '다음 페이지',
              onPressed: ready && page < widget.asset.pages
                  ? () => controller.goToPage(pageNumber: page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: '축소',
              onPressed: ready ? () => controller.zoomDown() : null,
              icon: const Icon(Icons.zoom_out),
            ),
            IconButton(
              tooltip: '확대',
              onPressed: ready ? () => controller.zoomUp() : null,
              icon: const Icon(Icons.zoom_in),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<Uint8List>(
            future: bytes,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      ready = false;
                      bytes = load();
                    }),
                    child: const Text('PDF를 열지 못했어요. 다시 시도'),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return PdfViewer.data(
                snapshot.data!,
                sourceName: '문제 자료',
                controller: controller,
                initialPageNumber: page,
                params: PdfViewerParams(
                  onViewerReady: (document, c) {
                    if (mounted) setState(() => ready = true);
                  },
                  onPageChanged: (p) {
                    if (p != null && mounted) {
                      setState(() => page = p);
                      widget.savePage(p).catchError((Object _) {});
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
