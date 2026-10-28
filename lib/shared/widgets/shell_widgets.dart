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
        if (branded) ...[
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}

/// A semantic section title; surface grouping carries the visual boundary.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppTokens.sectionGap,
      bottom: AppTokens.space12,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: AppTokens.sectionTitle.copyWith(color: AppTokens.textPrimary),
      ),
    ),
  );
}

enum LsSurfaceLevel { major, nested }

class LsCard extends StatelessWidget {
  const LsCard({
    required this.child,
    this.level = LsSurfaceLevel.major,
    this.padding = const EdgeInsets.all(AppTokens.space16),
    super.key,
  });
  final Widget child;
  final LsSurfaceLevel level;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    // A child group must never repeat the parent's elevation.
    final major =
        level == LsSurfaceLevel.major &&
        context.findAncestorWidgetOfExactType<LsCard>() == null;
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: major ? AppTokens.majorSurfaceBorder : AppTokens.cardBorder,
        ),
        boxShadow: major ? AppTokens.majorSurfaceShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class LsListRow extends StatelessWidget {
  const LsListRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: icon == null ? null : Icon(icon, size: AppTokens.iconDense),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right, size: AppTokens.iconDense),
    onTap: onTap,
  );
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.title, required this.children, super.key});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space8),
          child: Semantics(
            header: true,
            child: Text(title, style: AppTokens.caption),
          ),
        ),
        LsCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space16,
            vertical: AppTokens.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(),
                children[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class GuestAccountPrompt extends StatelessWidget {
  const GuestAccountPrompt({required this.onLogin, super.key});
  final VoidCallback onLogin;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('학습 기록과 저장한 자료를 계정에 연결해 관리하세요.'),
      const SizedBox(height: AppTokens.space16),
      // Login is a general/entry CTA → orange outline (see app_theme CTA hierarchy).
      OutlinedButton(onPressed: onLogin, child: const Text('로그인')),
    ],
  );
}

/// A small, calm "BETA" badge for 논술 LAB surfaces. Navy text on a soft
/// grey-blue fill, text-labelled (never color-only) and deliberately low-key so
/// it reads as a quiet status, not an orange emphasis.
class LabBetaBadge extends StatelessWidget {
  const LabBetaBadge({super.key, this.label = 'BETA'});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label · 베타 서비스',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTokens.primarySoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTokens.cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppTokens.info,
        ),
      ),
    ),
  );
}

class CompactUtilityCard extends StatelessWidget {
  const CompactUtilityCard({
    required this.title,
    required this.body,
    this.action,
    this.titleBadge,
    super.key,
  });
  final String title, body;
  final Widget? action;

  /// Optional small badge shown next to the title (e.g. a [LabBetaBadge]).
  final Widget? titleBadge;
  @override
  Widget build(BuildContext context) => LsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleBadge == null
            ? Text(title, style: Theme.of(context).textTheme.titleMedium)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  titleBadge!,
                ],
              ),
        const SizedBox(height: AppTokens.smallGap),
        Text(body),
        if (action != null) ...[const SizedBox(height: 8), action!],
      ],
    ),
  );
}

/// A calm, labelled step indicator for multi-stage server work (제출 → 첨삭 중 →
/// 결과) where no percentage is available. The active stage is named so progress
/// never relies on color alone; an indeterminate bar runs until [done].
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    required this.steps,
    required this.activeIndex,
    this.done = false,
    super.key,
  });
  final List<String> steps;
  final int activeIndex;
  final bool done;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: done
        ? '${steps.last} 완료'
        : '${steps[activeIndex.clamp(0, steps.length - 1)]} 진행 중',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= activeIndex
                        ? AppTokens.info
                        : AppTokens.primarySoft,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppTokens.space8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < steps.length; i++)
              Text(
                steps[i],
                style: AppTokens.caption.copyWith(
                  color: i == activeIndex && !done
                      ? AppTokens.info
                      : i <= activeIndex
                      ? AppTokens.textPrimary
                      : AppTokens.textTertiary,
                  fontWeight: i == activeIndex
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
          ],
        ),
        if (!done) ...[
          const SizedBox(height: AppTokens.space12),
          const LinearProgressIndicator(minHeight: 3),
        ],
      ],
    ),
  );
}

class SearchEntry extends StatelessWidget {
  const SearchEntry({required this.onTap, super.key});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      side: const BorderSide(color: AppTokens.cardBorder),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
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
    this.action,
    required this.body,
    this.heading,
    this.wrapHeader = false,
    this.accentColor,
    this.icon,
    super.key,
  });
  final String title;
  final bool wrapHeader;
  final Color? accentColor;
  final IconData? icon;
  final Widget? heading;
  final Widget? action;
  final Widget body;
  Widget _heading(BuildContext context) {
    final text =
        heading ?? Text(title, style: Theme.of(context).textTheme.titleMedium);
    return icon == null
        ? text
        : Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Expanded(child: text),
            ],
          );
  }

  @override
  Widget build(BuildContext context) => LsCard(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.space16,
      vertical: AppTokens.space8,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => action == null
              ? _heading(context)
              : wrapHeader && MediaQuery.textScalerOf(context).scale(1) >= 1.5
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading(context),
                    Align(alignment: Alignment.centerRight, child: action!),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _heading(context)),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * .45,
                      ),
                      child: action!,
                    ),
                  ],
                ),
        ),
        body,
      ],
    ),
  );
}
