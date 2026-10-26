import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../models/financial_summary.dart';
import '../models/fleet_utilization.dart';
import '../models/route_profitability.dart';
import '../reports_service.dart';

/// Reports feature entry point (Module 20) — read-only analytics with three
/// internal tabs (Route Profitability / Financial Summary / Fleet Utilization).
/// Each tab shows headline [StatCard]s plus a list of [AppCard] rows.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.apiClient, this.initialTab = 0});

  final ApiClient apiClient;

  /// 0 = Route Profitability, 1 = Financial Summary, 2 = Fleet Utilization.
  final int initialTab;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final ReportsService _service;
  late final TabController _tabs;

  late Future<RouteProfitabilityReport> _routeFuture;
  late Future<FinancialSummaryReport> _financeFuture;
  late Future<FleetUtilizationReport> _fleetFuture;

  @override
  void initState() {
    super.initState();
    _service = ReportsService(widget.apiClient);
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _loadAll();
  }

  void _loadAll() {
    _routeFuture = _service.fetchRouteProfitability();
    _financeFuture = _service.fetchFinancialSummary();
    _fleetFuture = _service.fetchFleetUtilization();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reloadRoute() => setState(() => _routeFuture = _service.fetchRouteProfitability());
  void _reloadFinance() =>
      setState(() => _financeFuture = _service.fetchFinancialSummary());
  void _reloadFleet() => setState(() => _fleetFuture = _service.fetchFleetUtilization());

  void _reloadCurrent() {
    switch (_tabs.index) {
      case 0:
        _reloadRoute();
      case 1:
        _reloadFinance();
      case 2:
        _reloadFleet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Analytics',
            title: 'Reports',
            subtitle: 'Profitability · Finance · Fleet',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reloadCurrent,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _RouteProfitabilityTab(future: _routeFuture, onRetry: _reloadRoute),
                _FinancialSummaryTab(future: _financeFuture, onRetry: _reloadFinance),
                _FleetUtilizationTab(future: _fleetFuture, onRetry: _reloadFleet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: kPrimary,
        indicatorWeight: 2.5,
        labelColor: AppColors.textNavy(context),
        unselectedLabelColor: kMuted,
        labelStyle: AppType.body(13.5, weight: FontWeight.w700),
        unselectedLabelStyle: AppType.body(13.5, weight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Route Profitability'),
          Tab(text: 'Financial Summary'),
          Tab(text: 'Fleet Utilization'),
        ],
      ),
    );
  }
}

// ── Shared helpers ──────────────────────────────────────────────────────────

/// Compact TZS money string for headline stats (e.g. `TZS 12.4M`).
String _money(double v) {
  final neg = v < 0;
  final a = v.abs();
  String body;
  if (a >= 1e9) {
    body = '${(a / 1e9).toStringAsFixed(1)}B';
  } else if (a >= 1e6) {
    body = '${(a / 1e6).toStringAsFixed(1)}M';
  } else if (a >= 1e3) {
    body = '${(a / 1e3).toStringAsFixed(1)}K';
  } else {
    body = a.toStringAsFixed(0);
  }
  return '${neg ? '-' : ''}TZS $body';
}

String _fullMoney(double v) {
  final neg = v < 0;
  final whole = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return '${neg ? '-' : ''}TZS $buf';
}

String _pct(double v) => '${v.toStringAsFixed(1)}%';

Color _profitColor(double v) => v < 0 ? kDanger : kSuccess;

Widget _tabSkeleton(BuildContext context) {
  return AppSkeleton(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: AppSkeleton.box(context, height: 96, radius: 20)),
            const SizedBox(width: 12),
            Expanded(child: AppSkeleton.box(context, height: 96, radius: 20)),
          ],
        ),
        const SizedBox(height: 12),
        AppSkeleton.box(context, height: 96, radius: 20),
        const SizedBox(height: 20),
        for (var i = 0; i < 5; i++) ...[
          AppSkeleton.box(context, height: 88, radius: 18),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

/// Two small label/value metrics on a card footer.
class _MetricRow extends StatelessWidget {
  final List<({String label, String value, Color? color})> metrics;
  const _MetricRow(this.metrics);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metrics[i].label.toUpperCase(),
                    style: AppType.eyebrow(size: 9, color: kMuted)),
                const SizedBox(height: 2),
                Text(
                  metrics[i].value,
                  style: AppType.number(15,
                      color: metrics[i].color ?? AppColors.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tab 1: Route Profitability ───────────────────────────────────────────────

class _RouteProfitabilityTab extends StatelessWidget {
  final Future<RouteProfitabilityReport> future;
  final VoidCallback onRetry;
  const _RouteProfitabilityTab({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RouteProfitabilityReport>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _tabSkeleton(context);
        }
        if (snap.hasError) {
          return AppError(message: snap.error.toString(), onRetry: onRetry);
        }
        final r = snap.data!;
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onRetry(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              RevealOnLoad(
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Revenue · ${r.year}',
                        value: _money(r.totalRevenue),
                        icon: Icons.payments_rounded,
                        accent: ModuleAccent.ops,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Profit',
                        value: _money(r.totalProfit),
                        icon: Icons.trending_up_rounded,
                        accent: r.totalProfit < 0
                            ? ModuleAccent.danger
                            : ModuleAccent.finance,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RevealOnLoad(
                delayMs: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Trips',
                        value: r.totalTrips.toString(),
                        icon: Icons.local_shipping_rounded,
                        accent: ModuleAccent.ops,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Margin',
                        value: _pct(r.margin),
                        icon: Icons.percent_rounded,
                        accent: ModuleAccent.ops,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Routes',
                eyebrow: '${r.routeCount} routes',
                icon: Icons.alt_route_rounded,
                accent: ModuleAccent.ops,
              ),
              if (r.rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AppEmpty(
                    icon: Icons.alt_route_outlined,
                    message: 'No route data\nCompleted trips will appear here.',
                  ),
                )
              else
                for (var i = 0; i < r.rows.length; i++)
                  RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RouteCard(row: r.rows[i]),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteRow row;
  const _RouteCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: _profitColor(row.totalProfit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  row.routeLabel,
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(label: _pct(row.margin), color: _profitColor(row.totalProfit)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${row.tripCount} trips · ${row.totalCargoTons.toStringAsFixed(1)} t',
              style: AppType.body(12, color: kMuted, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          _MetricRow([
            (label: 'Revenue', value: _money(row.totalRevenue), color: null),
            (label: 'Costs', value: _money(row.totalCosts), color: null),
            (
              label: 'Profit',
              value: _money(row.totalProfit),
              color: _profitColor(row.totalProfit)
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Tab 2: Financial Summary ─────────────────────────────────────────────────

class _FinancialSummaryTab extends StatelessWidget {
  final Future<FinancialSummaryReport> future;
  final VoidCallback onRetry;
  const _FinancialSummaryTab({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FinancialSummaryReport>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _tabSkeleton(context);
        }
        if (snap.hasError) {
          return AppError(message: snap.error.toString(), onRetry: onRetry);
        }
        final r = snap.data!;
        final active = r.rows.where((m) => m.hasActivity).toList();
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onRetry(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              RevealOnLoad(
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Revenue · ${r.year}',
                        value: _money(r.totalRevenue),
                        icon: Icons.account_balance_wallet_rounded,
                        accent: ModuleAccent.finance,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Profit',
                        value: _money(r.totalProfit),
                        icon: Icons.trending_up_rounded,
                        accent: r.totalProfit < 0
                            ? ModuleAccent.danger
                            : ModuleAccent.finance,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RevealOnLoad(
                delayMs: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total costs',
                        value: _money(r.totalCosts),
                        icon: Icons.receipt_long_rounded,
                        accent: ModuleAccent.finance,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Outstanding',
                        value: _money(r.outstandingBalance),
                        icon: Icons.pending_actions_rounded,
                        accent: ModuleAccent.finance,
                        danger: r.outstandingBalance > 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RevealOnLoad(
                delayMs: 120,
                child: StatCard(
                  label: 'Margin',
                  value: _pct(r.margin),
                  icon: Icons.percent_rounded,
                  accent: ModuleAccent.finance,
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Monthly breakdown',
                eyebrow: '${active.length} active months',
                icon: Icons.calendar_month_rounded,
                accent: ModuleAccent.finance,
              ),
              if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AppEmpty(
                    icon: Icons.calendar_today_outlined,
                    message: 'No monthly activity\nRevenue and costs will appear here.',
                  ),
                )
              else
                for (var i = 0; i < active.length; i++)
                  RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MonthCard(row: active[i]),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  final MonthRow row;
  const _MonthCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: _profitColor(row.profit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.monthName,
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                label: _money(row.profit),
                color: _profitColor(row.profit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricRow([
            (label: 'Revenue', value: _money(row.revenue), color: null),
            (label: 'Expenses', value: _money(row.expenses), color: null),
            (label: 'Maint.', value: _money(row.maintenance), color: null),
          ]),
        ],
      ),
    );
  }
}

// ── Tab 3: Fleet Utilization ─────────────────────────────────────────────────

class _FleetUtilizationTab extends StatelessWidget {
  final Future<FleetUtilizationReport> future;
  final VoidCallback onRetry;
  const _FleetUtilizationTab({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FleetUtilizationReport>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _tabSkeleton(context);
        }
        if (snap.hasError) {
          return AppError(message: snap.error.toString(), onRetry: onRetry);
        }
        final r = snap.data!;
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onRetry(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              RevealOnLoad(
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Utilization',
                        value: _pct(r.utilizationRate),
                        icon: Icons.speed_rounded,
                        accent: ModuleAccent.brand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Active / Fleet',
                        value: '${r.activeVehicles} / ${r.totalFleet}',
                        icon: Icons.local_shipping_rounded,
                        accent: ModuleAccent.brand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RevealOnLoad(
                delayMs: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Idle vehicles',
                        value: r.idleVehicles.toString(),
                        icon: Icons.pause_circle_outline_rounded,
                        accent: ModuleAccent.brand,
                        danger: r.idleVehicles > 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Trips · ${r.year}',
                        value: r.totalTrips.toString(),
                        icon: Icons.route_rounded,
                        accent: ModuleAccent.brand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              RevealOnLoad(
                delayMs: 120,
                child: StatCard(
                  label: 'Fleet revenue',
                  value: _money(r.totalRevenue),
                  icon: Icons.payments_rounded,
                  accent: ModuleAccent.brand,
                ),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Vehicles',
                eyebrow: '${r.rows.length} active',
                icon: Icons.directions_bus_filled_rounded,
                accent: ModuleAccent.brand,
              ),
              if (r.rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AppEmpty(
                    icon: Icons.no_transfer_rounded,
                    message: 'No vehicle activity\nActive vehicles will appear here.',
                  ),
                )
              else
                for (var i = 0; i < r.rows.length; i++)
                  RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VehicleCard(row: r.rows[i]),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final FleetVehicleRow row;
  const _VehicleCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: _profitColor(row.totalProfit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.plateLabel,
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                label: '${row.tripCount} trips',
                color: ModuleAccent.brand.base,
                icon: Icons.local_shipping_rounded,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${row.totalCargoTons.toStringAsFixed(1)} t · avg ${_fullMoney(row.avgRevenuePerTrip)}/trip',
            style: AppType.body(12, color: kMuted, weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _MetricRow([
            (label: 'Revenue', value: _money(row.totalRevenue), color: null),
            (label: 'Costs', value: _money(row.totalCosts), color: null),
            (
              label: 'Profit',
              value: _money(row.totalProfit),
              color: _profitColor(row.totalProfit)
            ),
          ]),
        ],
      ),
    );
  }
}
