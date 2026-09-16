import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/resources/domain/content_resource.dart';

typedef ExternalOpener = Future<bool> Function(Uri uri);
final externalOpenerProvider = Provider<ExternalOpener>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class ExternalLinkButton extends ConsumerStatefulWidget {
  const ExternalLinkButton({
    required this.uri,
    required this.label,
    this.onOpenAttempted,
    super.key,
  });
  final Uri? uri;
  final String label;
  final VoidCallback? onOpenAttempted;
  @override
  ConsumerState<ExternalLinkButton> createState() => _ExternalLinkButtonState();
}

class _ExternalLinkButtonState extends ConsumerState<ExternalLinkButton> {
  bool opening = false;
  Future<void> open() async {
    final uri = publicWebUri(widget.uri?.toString());
    if (uri == null || opening) return;
    setState(() => opening = true);
    widget.onOpenAttempted?.call();
    var success = false;
    try {
      success = await ref.read(externalOpenerProvider)(uri);
    } catch (_) {
      // Do not surface raw platform errors or URL query tokens.
    }
    if (!mounted) return;
    setState(() => opening = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('외부 링크를 열지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: opening || publicWebUri(widget.uri?.toString()) == null
        ? null
        : open,
    icon: opening
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.open_in_new),
    label: Text(widget.label),
  );
}
