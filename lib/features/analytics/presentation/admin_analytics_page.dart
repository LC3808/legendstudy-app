import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../admin_analytics_providers.dart';
import '../domain/analytics_dashboard.dart';

/// Admin Analytics dashboard. All figures are the official PostgreSQL
/// aggregates (completion/credit/revenue). Missing values render as '데이터 없음',
/// never fabricated. Access is operational-admin only.
class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final admin = ref.watch(analyticsAdminProvider);
    if (auth.isLoading || admin.isLoading) {
      return const ShellPage(
        children: [Center(child: CircularProgressIndicator())],
      );
    }
    if (admin.hasError) {
      return ShellPage(
        children: [
          ErrorState(
            message: '관리자 상태를 확인하지 못했어요.',
            onRetry: () => ref.invalidate(analyticsAdminProvider),
          ),
        ],
      );
    }
    if (admin.value != true) {
      return const ShellPage(
        children: [SectionHeader('Analytics'), EmptyState('관리자만 이용할 수 있어요.')],
      );
    }

    final period = ref.watch(analyticsPeriodProvider);
    return ShellPage(
      children: [
        const AppHeader(
          title: 'Analytics',
          subtitle: '공식 집계는 PostgreSQL 기준입니다. 행동 지표(GA4)는 별도예요.',
        ),
        _PeriodBar(period: period),
        const SizedBox(height: 12),
        _KpiSection(period: period),
        _FunnelSection(period: period),
        _FreeCreditSection(period: period),
        _RevenueSection(period: period),
        _ReliabilitySection(period: period),
        _ApiCostSection(period: period),
        _UniversitySection(period: period),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PeriodBar extends ConsumerWidget {
  const _PeriodBar({required this.period});
  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final r in [
        AnalyticsRange.today,
        AnalyticsRange.last7,
        AnalyticsRange.last30,
      ])
        ChoiceChip(
          label: Text(r.label),
          selected: period.range == r,
          onSelected: (_) => ref
              .read(analyticsPeriodProvider.notifier)
              .select(AnalyticsPeriod.preset(r)),
        ),
      ActionChip(
        avatar: const Icon(Icons.date_range, size: 18),
        label: Text(
          period.range == AnalyticsRange.custom ? _rangeLabel(period) : '기간 지정',
        ),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2026, 1, 1),
            lastDate: now,
          );
          if (picked != null) {
            ref
                .read(analyticsPeriodProvider.notifier)
                .select(period.custom(picked.start, picked.end));
          }
        },
      ),
    ],
  );
}

String _rangeLabel(AnalyticsPeriod p) {
  String d(DateTime t) {
    final l = t.toLocal();
    return '${l.month}/${l.day}';
  }

  return '${d(p.from)}~${d(p.to.subtract(const Duration(days: 1)))}';
}

/// Shared frame: titled card that loads one section and renders [builder] with
/// the aggregate map, honestly showing loading/empty/error states.
class _SectionFrame extends ConsumerWidget {
  const _SectionFrame({
    required this.title,
    required this.section,
    required this.period,
    required this.builder,
  });
  final String title;
  final AnalyticsSection section;
  final AnalyticsPeriod period;
  final Widget Function(BuildContext, Map<String, dynamic>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (section, period);
    final state = ref.watch(analyticsSectionProvider(key));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            state.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _SectionError(
                error: error,
                onRetry: () => ref.invalidate(analyticsSectionProvider(key)),
              ),
              data: (map) => builder(context, map),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final message = error is AnalyticsForbidden
        ? '관리자만 이용할 수 있어요.'
        : error is AnalyticsUnavailable
        ? (error as AnalyticsUnavailable).message
        : '불러오지 못했어요.';
    return Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}

// ---- Sections -------------------------------------------------------------

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: '상단 KPI',
    section: AnalyticsSection.kpiOverview,
    period: period,
    builder: (context, m) {
      final active = (m['active_learners'] as Map?) ?? const {};
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Tile('DAU(활동)', _n(active['dau'])),
          _Tile('WAU(활동)', _n(active['wau'])),
          _Tile('MAU(활동)', _n(active['mau'])),
          _Tile('신규 가입', _n(m['new_signups'])),
          _Tile('첨삭 완료 사용자', _n(m['completed_eval_users'])),
          _Tile('무료 첨삭 완료', _n(m['free_eval_completed_users'])),
          _Tile('유료 구매자', _n(m['paid_buyers'])),
          _Tile('매출', _won(m['revenue_krw'])),
          _Tile('첨삭 성공률', _pct(m['eval_success_rate'])),
        ],
      );
    },
  );
}

class _FunnelSection extends StatelessWidget {
  const _FunnelSection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: '전환 퍼널 (가입 코호트)',
    section: AnalyticsSection.funnel,
    period: period,
    builder: (context, m) {
      final stages = (m['stages'] as List?) ?? const [];
      if (stages.isEmpty) return const EmptyState('데이터 없음');
      final labels = {
        'signup': '가입',
        'first_submit': '첫 제출',
        'first_eval_completed': '첫 평가 완료',
        'rewrite_submit': '재첨삭 제출',
        'full_loop_nsm': '전체 루프(NSM)',
      };
      final base = _toNum(
        stages.first is Map ? (stages.first as Map)['count'] : 0,
      );
      return Column(
        children: [
          for (final s in stages)
            if (s is Map)
              _BarRow(
                label: labels[s['key']] ?? '${s['key']}',
                value: _toNum(s['count']),
                max: base == 0 ? 1 : base,
              ),
        ],
      );
    },
  );
}

class _FreeCreditSection extends StatelessWidget {
  const _FreeCreditSection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: '무료 Credit 사용 현황',
    section: AnalyticsSection.freeCredit,
    period: period,
    builder: (context, m) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Tile('지급 사용자', _n(m['granted_users'])),
        _Tile('사용 사용자', _n(m['used_users'])),
        _Tile('평균 사용', _n(m['avg_used_per_user'])),
        _Tile('1개 후', _n(m['dropoff_after_1'])),
        _Tile('2개 후', _n(m['dropoff_after_2'])),
        _Tile('3개 소진', _n(m['dropoff_after_3'])),
        _Tile('소진 사용자', _n(m['exhausted_users'])),
        _Tile('무료→유료', _n(m['free_to_paid_users'])),
      ],
    ),
  );
}

class _RevenueSection extends StatelessWidget {
  const _RevenueSection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: '상품별 매출 (LIVE)',
    section: AnalyticsSection.revenue,
    period: period,
    builder: (context, m) {
      final bySku = (m['by_sku'] as List?) ?? const [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Tile('총매출', _won(m['gross_revenue'])),
              _Tile('순매출', _won(m['net_revenue'])),
              _Tile('구매자', _n(m['buyers'])),
              _Tile('재구매자', _n(m['repeat_buyers'])),
              _Tile('객단가', _won(m['aov'])),
              _Tile('ARPPU', _won(m['arppu'])),
              _Tile('환불', _won(m['refunded'])),
            ],
          ),
          if (bySku.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final s in bySku)
              if (s is Map)
                _KeyValueRow(
                  label: '${s['sku']}',
                  value: '${_n(s['orders'])}건 · ${_won(s['revenue'])}',
                ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('데이터 없음'),
            ),
        ],
      );
    },
  );
}

class _ReliabilitySection extends StatelessWidget {
  const _ReliabilitySection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: '평가 신뢰성 · 재처리',
    section: AnalyticsSection.reliability,
    period: period,
    builder: (context, m) {
      final errors = (m['error_types'] as List?) ?? const [];
      final integrity = (m['credit_integrity'] as Map?) ?? const {};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Tile('요청', _n(m['requested'])),
              _Tile('완료', _n(m['completed'])),
              _Tile('실패', _n(m['failed'])),
              _Tile('재처리 요청', _n(m['reprocess_requested'])),
              _Tile('재처리 성공', _n(m['reprocess_success'])),
              _Tile('p50(ms)', _n(m['latency_ms_p50'])),
              _Tile('p95(ms)', _n(m['latency_ms_p95'])),
            ],
          ),
          const SizedBox(height: 12),
          Text('오류 유형', style: Theme.of(context).textTheme.labelLarge),
          if (errors.isEmpty) const Text('데이터 없음'),
          for (final e in errors)
            if (e is Map)
              _KeyValueRow(label: '${e['code']}', value: _n(e['count'])),
          const SizedBox(height: 8),
          Text(
            'Credit 정합성(목표 0)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          _KeyValueRow(
            label: 'A 실패+차감',
            value: _n(integrity['A_failed_but_settled']),
          ),
          _KeyValueRow(
            label: 'E 포함+차감',
            value: _n(integrity['E_included_but_consumed']),
          ),
          _KeyValueRow(
            label: 'F 유료+미정산',
            value: _n(integrity['F_paid_but_not_settled']),
          ),
        ],
      );
    },
  );
}

class _ApiCostSection extends StatelessWidget {
  const _ApiCostSection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: 'API 원가 (실측/추정 구분)',
    section: AnalyticsSection.apiCost,
    period: period,
    builder: (context, m) {
      final byModel = (m['by_model'] as List?) ?? const [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Tile('평가 호출', _n(m['eval_calls'])),
              _Tile('재처리 호출', _n(m['reprocess_calls'])),
              _Tile('실측 비용', _n(m['total_reported_cost'])),
              _Tile('비용 누락', _n(m['cost_missing_runs'])),
            ],
          ),
          const SizedBox(height: 12),
          if (byModel.isEmpty)
            const Text('데이터 없음')
          else
            for (final r in byModel)
              if (r is Map)
                _KeyValueRow(
                  label: '${r['provider']}/${r['model']}',
                  value:
                      '호출 ${_n(r['calls'])} · 토큰 ${_n(r['total_tokens'])} · 실측 ${_n(r['reported_cost'])}',
                ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '실측(provider_reported)만 과금 기준. 누락/추정은 공식 비용 아님.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      );
    },
  );
}

class _UniversitySection extends StatelessWidget {
  const _UniversitySection({required this.period});
  final AnalyticsPeriod period;
  @override
  Widget build(BuildContext context) => _SectionFrame(
    title: '대학별 이용',
    section: AnalyticsSection.universityUsage,
    period: period,
    builder: (context, m) {
      final list = (m['universities'] as List?) ?? const [];
      if (list.isEmpty) return const EmptyState('데이터 없음');
      return Column(
        children: [
          for (final u in list)
            if (u is Map)
              _KeyValueRow(
                label: '${u['name']}',
                value:
                    '세션 ${_n(u['sessions'])} · 제출 ${_n(u['attempts'])} · 완료 ${_n(u['completed'])}',
              ),
        ],
      );
    },
  );
}

// ---- Small widgets --------------------------------------------------------

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});
  final String label;
  final num value;
  final num max;
  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('${_fmt(value)}  (${(fraction * 100).toStringAsFixed(0)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: fraction, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(value, textAlign: TextAlign.right),
      ],
    ),
  );
}

// ---- Formatting -----------------------------------------------------------

num _toNum(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;

String _fmt(num n) {
  final s = (n % 1 == 0 ? n.toInt() : n).toString();
  final neg = s.startsWith('-');
  final digits = neg ? s.substring(1) : s;
  final parts = digits.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final out = parts.length > 1
      ? '${buf.toString()}.${parts[1]}'
      : buf.toString();
  return neg ? '-$out' : out;
}

/// Number or '데이터 없음' for null.
String _n(Object? v) => v == null ? '데이터 없음' : _fmt(_toNum(v));

String _won(Object? v) => v == null ? '데이터 없음' : '₩${_fmt(_toNum(v))}';

String _pct(Object? v) => v == null ? '데이터 없음' : '${_fmt(_toNum(v))}%';
