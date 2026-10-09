import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../credits/credit_balance.dart';
import '../../shared/widgets/shell_widgets.dart';
import '../../shared/widgets/legendstudy_lab_entry.dart';

/// LegendStudy LAB home. LAB is the umbrella: 논술 LAB / 내신 LAB / 모의/수능 LAB.
/// Only 논술 LAB is live today (and leads as the primary CTA); the other two are
/// 준비 중 but still discoverable (clickable → a 준비 중 detail), never hidden and
/// never shown as if already available.
class LabPage extends StatelessWidget {
  const LabPage({super.key});
  @override
  Widget build(BuildContext context) => ShellPage(
    children: [
      const AppHeader(title: 'LAB'),
      const CreditBalanceCard(showTopUp: true),
      // Owner order (2026-10-09): 논술 LAB first (live, primary CTA), then
      // 내신 LAB, then 모의/수능 LAB.
      const LegendStudyLabEntry(),
      const SizedBox(height: 12),
      const _LabServiceCard(
        icon: Icons.school_outlined,
        title: '내신 LAB',
        subtitle: '내신 성적 기반 강점·보완 분석 (관심 대학 기준)',
        available: false,
        route: '/lab/school-record',
      ),
      const SizedBox(height: 12),
      const _LabServiceCard(
        icon: Icons.assessment_outlined,
        title: '모의/수능 LAB',
        subtitle: '모의고사·수능 성적 기반 영역별 분석 (관심 대학 기준)',
        available: false,
        route: '/lab/csat-mock',
      ),
    ],
  );
}

/// A LAB service row with an explicit availability badge. "준비 중" rows stay
/// tappable so the user can read what the service will do.
class _LabServiceCard extends StatelessWidget {
  const _LabServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.available,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool available;
  final String route;

  @override
  Widget build(BuildContext context) => LsCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Row(
        children: [
          Flexible(child: Text(title, style: AppTokens.cardTitle)),
          const SizedBox(width: AppTokens.space8),
          LabStatusBadge(available: available),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(subtitle, style: AppTokens.secondary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    ),
  );
}

/// 이용 가능 / 준비 중 badge — never color-only (the text label carries the state).
class LabStatusBadge extends StatelessWidget {
  const LabStatusBadge({super.key, required this.available});
  final bool available;
  @override
  Widget build(BuildContext context) {
    final label = available ? '이용 가능' : '준비 중';
    final bg = available ? AppTokens.primarySoft : AppTokens.background;
    final fg = available ? AppTokens.primaryInk : AppTokens.textSecondary;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          border: Border.all(color: AppTokens.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}
