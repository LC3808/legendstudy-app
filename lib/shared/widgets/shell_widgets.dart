import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({
    required this.children,
    this.padding = const EdgeInsets.all(AppTokens.pagePadding),
    super.key,
  });
  final EdgeInsetsGeometry padding;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.background,
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.subtitle,
    this.branded = false,
    super.key,
  });
  final String title;
  final String? subtitle;
  final bool branded;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: branded ? 8 : AppTokens.sectionGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: branded ? title : null,
          child: branded
              ? Image.asset(
                  'assets/brand/generated/legendstudy_wordmark_header.png',
                  width: 180,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                )
              : Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppTokens.sectionGap, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(title, style: AppTokens.sectionTitle),
    ),
  );
}

class CompactUtilityCard extends StatelessWidget {
  const CompactUtilityCard({
    required this.title,
    required this.body,
    this.action,
    super.key,
  });
  final String title, body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTokens.surfaceWarm,
      border: Border.all(color: AppTokens.cardBorder),
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTokens.smallGap),
        Text(body),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    ),
  );
}

class SearchEntry extends StatelessWidget {
  const SearchEntry({required this.onTap, super.key});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppTokens.cardBorder),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.search, color: AppTokens.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '모의고사, 논술, 학습자료 검색',
                  style: TextStyle(color: AppTokens.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class QuickFilterChip extends StatelessWidget {
  const QuickFilterChip(this.label, {required this.onTap, super.key});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.chipRadius),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(message),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, required this.onRetry, super.key});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(liveRegion: true, child: Text(message)),
      TextButton(onPressed: onRetry, child: const Text('다시 시도')),
    ],
  );
}

/// Compact daily card: action shares the heading's 48px row; body stays below.
class DailyUtilityCard extends StatelessWidget {
  const DailyUtilityCard({
    required this.title,
    required this.action,
    required this.body,
    this.heading,
    this.wrapHeader = false,
    this.accentColor,
    super.key,
  });
  final String title;
  final bool wrapHeader;
  final Widget? heading;
  final Widget action, body;
  final Color? accentColor;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTokens.surfaceWarm,
      border: Border.all(color: AppTokens.cardBorder),
      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.cardRadius - 1),
      child: CustomPaint(
        painter: accentColor == null ? null : _AccentBarPainter(accentColor!),
        child: Padding(
          padding: EdgeInsets.fromLTRB(accentColor == null ? 16 : 13, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) =>
                    wrapHeader &&
                        MediaQuery.textScalerOf(context).scale(1) >= 1.5
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          heading ??
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: action,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child:
                                heading ??
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * .45,
                            ),
                            child: action,
                          ),
                        ],
                      ),
              ),
              body,
            ],
          ),
        ),
      ),
    ),
  );
}

class _AccentBarPainter extends CustomPainter {
  const _AccentBarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 4, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_AccentBarPainter oldDelegate) =>
      oldDelegate.color != color;
}
