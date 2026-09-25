import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/links/external_link.dart';
import '../domain/content_resource.dart';

class PdfViewerRouteArgs {
  const PdfViewerRouteArgs({required this.title, required this.delivery});

  final String title;
  final ResourceDelivery delivery;
}

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({required this.args, super.key});

  final PdfViewerRouteArgs? args;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  int _attempt = 0;

  void _retry() => setState(() => _attempt++);

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final delivery = args?.delivery;
    final uri = delivery?.uri;
    final sourceFallback = delivery?.sourceFallback;
    final usable =
        delivery?.kind == ResourceDeliveryKind.externalFile && uri != null;
    return Scaffold(
      appBar: AppBar(title: Text(args?.title ?? '자료 보기')),
      body: usable
          ? KeyedSubtree(
              key: ValueKey(_attempt),
              child: PdfViewer.uri(
                uri,
                timeout: const Duration(seconds: 30),
                params: PdfViewerParams(
                  loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                    final progress = totalBytes == null || totalBytes == 0
                        ? null
                        : bytesDownloaded / totalBytes;
                    return _PdfLoadingPanel(progress: progress);
                  },
                  errorBannerBuilder:
                      (context, error, stackTrace, documentRef) =>
                          _PdfErrorPanel(
                            onRetry: _retry,
                            sourceFallback: sourceFallback,
                          ),
                ),
              ),
            )
          : _PdfErrorPanel(
              onRetry: _retry,
              sourceFallback: delivery?.sourceFallback,
            ),
    );
  }
}

class _PdfLoadingPanel extends StatelessWidget {
  const _PdfLoadingPanel({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(value: progress),
        const SizedBox(height: 12),
        const Text('자료 불러오는 중'),
      ],
    ),
  );
}

class _PdfErrorPanel extends StatelessWidget {
  const _PdfErrorPanel({required this.onRetry, this.sourceFallback});

  final VoidCallback onRetry;
  final Uri? sourceFallback;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 40),
          const SizedBox(height: 12),
          const Text('자료를 바로 열 수 없어요.'),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
              if (sourceFallback != null)
                ExternalLinkButton(uri: sourceFallback, label: '원문에서 보기'),
            ],
          ),
        ],
      ),
    ),
  );
}
