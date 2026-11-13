import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/links/external_link.dart';
import '../../analytics/analytics_providers.dart';
import '../../analytics/domain/analytics_events.dart';
import '../data/pdf_download.dart';
import '../data/download_history.dart';
import '../../../core/supabase/supabase_providers.dart';

class PdfDownloadAction extends ConsumerStatefulWidget {
  const PdfDownloadAction({
    required this.resourceId,
    required this.postId,
    required this.resourceType,
    this.screen = 'material_detail',
    this.contentSlug,
    super.key,
  });
  final String resourceId, postId, resourceType, screen;
  final String? contentSlug;
  @override
  ConsumerState<PdfDownloadAction> createState() => _PdfDownloadActionState();
}

class _PdfDownloadActionState extends ConsumerState<PdfDownloadAction> {
  bool busy = false, cancelled = false;
  String? message;
  void event(String name, String status) =>
      ref.read(analyticsServiceProvider).logEvent(name, {
        'platform': analyticsPlatform(),
        'post_id': widget.postId,
        'resource_id': widget.resourceId,
        'resource_type': widget.resourceType,
        'screen': widget.screen,
        'source': 'popular_pdf_pilot',
        'status': status,
      });
  Future<void> download() async {
    if (busy) return;
    setState(() {
      busy = true;
      cancelled = false;
      message = null;
    });
    final owner = ref.read(authStateProvider).value?.userId;
    String? savedName;
    event(AnalyticsEvents.pdfDownloadClick, 'started');
    try {
      final saved = await ref
          .read(pdfDownloadServiceProvider)
          .download(
            widget.resourceId,
            cancelled: () => cancelled || !mounted,
            onSaved: (name) => savedName = name,
          );
      if (!mounted) return;
      event(
        saved
            ? AnalyticsEvents.pdfDownloadSuccess
            : AnalyticsEvents.pdfDownloadCancel,
        saved ? 'saved' : 'cancelled',
      );
      setState(() => message = saved ? 'PDF를 저장했어요.' : '저장을 취소했어요.');
      if (saved &&
          owner != null &&
          savedName != null &&
          widget.contentSlug != null &&
          ref.read(authStateProvider).value?.userId == owner) {
        try {
          await ref
              .read(downloadHistoryProvider)
              .record(
                owner,
                DownloadReceipt(
                  widget.resourceId,
                  widget.contentSlug!,
                  savedName!,
                  DateTime.now(),
                ),
              );
          if (mounted) ref.invalidate(downloadedMaterialsProvider);
        } catch (_) {
          if (mounted) setState(() => message = 'PDF는 저장했지만 MY 목록에 기록하지 못했어요.');
        }
      }
    } catch (_) {
      if (!mounted) return;
      event(AnalyticsEvents.pdfDownloadFailure, 'failed');
      setState(() => message = '저장하지 못했어요. 네트워크와 기기 저장 공간을 확인한 뒤 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref
        .watch(pdfDownloadPolicyProvider(widget.resourceId))
        .asData
        ?.value;
    if (policy?.state == 'OFFICIAL_LINK') {
      return ExternalLinkButton(uri: policy!.official, label: '공식 자료 페이지');
    }
    if (policy?.state != 'ALLOWED' && !busy) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: busy ? null : download,
          icon: const Icon(Icons.download_outlined),
          label: Text(busy ? '저장 준비 중…' : 'PDF 다운로드'),
        ),
        if (busy)
          TextButton(
            onPressed: () => setState(() => cancelled = true),
            child: const Text('취소'),
          ),
        if (message != null) Text(message!, semanticsLabel: message),
      ],
    );
  }
}
