import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.background,
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.pagePadding),
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
    padding: const EdgeInsets.only(bottom: AppTokens.sectionGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          label: branded ? title : null,
          child: branded
              ? Image.asset(
                  'assets/brand/generated/legendstudy_wordmark_header.png',
                  width: 280,
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
    padding: const EdgeInsets.only(top: AppTokens.sectionGap, bottom: 12),
    child: Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
      border: Border.all(color: AppTokens.divider),
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
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 56),
      alignment: Alignment.centerLeft,
    ),
    icon: const Icon(Icons.search),
    label: const Text('자료 둘러보기'),
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
