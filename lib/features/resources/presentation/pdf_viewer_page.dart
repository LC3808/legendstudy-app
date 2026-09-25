import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ephemeral_pdf_loader.dart';
import '../data/trusted_resolver_client.dart';

import 'package:pdfrx/pdfrx.dart';

import '../../../core/links/external_link.dart';
import '../domain/content_resource.dart';

class PdfViewerRouteArgs {
  const PdfViewerRouteArgs({
    required this.title,
    required this.delivery,
    this.ephemeral = false,
    this.resolverResourceId,
  });

  final String title;
  final ResourceDelivery delivery;
  final bool ephemeral;
  final String? resolverResourceId;
}

class PdfViewerPage extends ConsumerStatefulWidget {
  const PdfViewerPage({required this.args, super.key});

  final PdfViewerRouteArgs? args;

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  int _attempt = 0;
  Future<Uint8List>? _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final args = widget.args;
    if (args?.ephemeral == true && args?.delivery.uri != null) {
      _bytes = _loadCurrent(args!);
    }
  }

  Future<Uint8List> _loadCurrent(PdfViewerRouteArgs args) async {
    var uri = args.delivery.uri;
    if (_attempt > 0 && args.resolverResourceId != null) {
      uri = await ref
          .read(trustedResolverProvider)
          .resolve(args.resolverResourceId!);
    }
    if (uri == null) throw StateError('자료를 열 수 없어요.');
    if (!mounted) throw StateError('자료를 열 수 없어요.');
    return ref.read(ephemeralPdfLoaderProvider)(uri);
  }

  void _retry() => setState(() {
    _attempt++;
    _load();
  });

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
              child: args!.ephemeral
                  ? FutureBuilder<Uint8List>(
                      future: _bytes,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _PdfErrorPanel(
                            onRetry: _retry,
                            sourceFallback: sourceFallback,
                          );
                        }
                        if (!snapshot.hasData) {
                          return const _PdfLoadingPanel(progress: null);
                        }
                        return PdfViewer.data(
                          snapshot.data!,
                          sourceName: '자료',
                          params: PdfViewerParams(
                            errorBannerBuilder:
                                (context, error, stackTrace, documentRef) =>
                                    _PdfErrorPanel(
                                      onRetry: _retry,
                                      sourceFallback: sourceFallback,
                                    ),
                          ),
                        );
                      },
                    )
                  : PdfViewer.uri(
                      uri,
                      timeout: const Duration(seconds: 30),
                      params: PdfViewerParams(
                        loadingBannerBuilder:
                            (context, bytesDownloaded, totalBytes) {
                              final progress =
                                  totalBytes == null || totalBytes == 0
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
