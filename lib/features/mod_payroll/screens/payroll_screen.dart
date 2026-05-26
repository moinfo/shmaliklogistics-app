import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/payroll_run.dart';
import '../models/salary_slip.dart';
import '../payroll_service.dart';

/// Module 18 — Payroll + Salary Slips. Read-only.
///
/// Internally exposes two sections via a top tab bar: payroll **Runs**
/// (tap-through to a run detail screen with its slip list + totals) and a flat
/// list of **Salary Slips** across all runs. Wired into the permission-driven
/// app shell by the orchestrator via the module registry.
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen>
    with SingleTickerProviderStateMixin {
  late final PayrollService _service;
  late final TabController _tabController;

  late Future<List<PayrollRun>> _runsFuture;
  late Future<List<SalarySlip>> _slipsFuture;

  @override
  void initState() {
    super.initState();
    _service = PayrollService(widget.apiClient);
    _tabController = TabController(length: 2, vsync: this);
    _runsFuture = _service.fetchRuns();
    _slipsFuture = _service.fetchSalarySlips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reloadCurrent() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _runsFuture = _service.fetchRuns();
        case 1:
          _slipsFuture = _service.fetchSalarySlips();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Payroll',
            title: 'Payroll',
            subtitle: 'Runs · Salary Slips',
            gradient: ModuleAccent.hr.colors,
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
              controller: _tabController,
              children: [
                _RunsTab(
                  service: _service,
                  future: _runsFuture,
                  onReload: _reloadCurrent,
                ),
                _SlipsTab(
                  future: _slipsFuture,
                  onReload: _reloadCurrent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: AppColors.surface(context),
      child: TabBar(
        controller: _tabController,
        indicatorColor: ModuleAccent.hr.base,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: ModuleAccent.hr.base,
        unselectedLabelColor: kMuted,
        labelStyle: AppType.body(13, weight: FontWeight.w700),
        unselectedLabelStyle: AppType.body(13, weight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Runs'),
          Tab(text: 'Salary Slips'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared loading / error / empty helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _payrollEmpty(BuildContext context, IconData icon, String title, String subtitle) {
  return ListView(
    children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: AppEmpty(icon: icon, message: '$title\n$subtitle'),
      ),
    ],
  );
}

Widget _payrollListSkeleton(BuildContext context, {double height = 132}) {
  return AppSkeleton(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (var i = 0; i < 5; i++) ...[
          AppSkeleton.box(context, height: height, radius: 16),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Runs tab
// ─────────────────────────────────────────────────────────────────────────────

class _RunsTab extends StatelessWidget {
  final PayrollService service;
  final Future<List<PayrollRun>> future;
  final VoidCallback onReload;
  const _RunsTab({required this.service, required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PayrollRun>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _payrollListSkeleton(context, height: 148);
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: onReload);
        }
        final runs = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onReload(),
          child: runs.isEmpty
              ? _payrollEmpty(context, Icons.event_repeat_outlined, 'No payroll runs',
                  'Monthly payroll batches will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: runs.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RunCard(
                        run: runs[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayrollRunDetailScreen(
                                runId: runs[i].id,
                                periodLabel: runs[i].periodLabel,
                                service: service,
                              ),
                            ),
                          );
                          onReload();
                        },
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _RunCard extends StatelessWidget {
  final PayrollRun run;
  final VoidCallback onTap;
  const _RunCard({required this.run, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = run.statusColor;
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  run.periodLabel.isNotEmpty ? run.periodLabel : '${run.monthName} ${run.year}',
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: run.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (run.documentNumber != null || run.payrollNumber != null) ...[
                Text(
                  run.documentNumber ?? run.payrollNumber!,
                  style: AppType.body(12, color: kMuted, weight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.people_alt_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text('${run.slipsCount} slips', style: AppType.body(12, color: kMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Gross', value: formatCurrency(run.grossTotal))),
              Expanded(
                child: _MiniStat(
                  label: 'Deductions',
                  value: formatCurrency(run.deductionsTotal),
                  valueColor: kDanger,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Net',
                  value: formatCurrency(run.netTotal),
                  valueColor: kSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Text('View',
                  style: AppType.body(11, color: ModuleAccent.hr.base, weight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, size: 14, color: ModuleAccent.hr.base),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Salary Slips tab
// ─────────────────────────────────────────────────────────────────────────────

class _SlipsTab extends StatelessWidget {
  final Future<List<SalarySlip>> future;
  final VoidCallback onReload;
  const _SlipsTab({required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SalarySlip>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _payrollListSkeleton(context, height: 116);
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: onReload);
        }
        final slips = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onReload(),
          child: slips.isEmpty
              ? _payrollEmpty(context, Icons.receipt_long_outlined, 'No salary slips',
                  'Salary slips will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: slips.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SalarySlipCard(slip: slips[i], showPeriod: true),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// A salary-slip card — gross / deductions / net summary with an expandable
/// breakdown. Reused by both the Salary Slips tab and the run-detail screen.
class SalarySlipCard extends StatelessWidget {
  final SalarySlip slip;
  final bool showPeriod;
  const SalarySlipCard({super.key, required this.slip, this.showPeriod = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: ModuleAccent.hr.base,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ModuleAccent.hr.base.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.badge_outlined, size: 20, color: ModuleAccent.hr.base),
          ),
          title: Text(
            slip.employeeName,
            style: AppType.display(14.5, color: AppColors.textNavy(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    [
                      if (slip.position != null && slip.position!.isNotEmpty) slip.position,
                      if (showPeriod && slip.periodLabel != null) slip.periodLabel,
                      if (!showPeriod && slip.employeeNumber != null) slip.employeeNumber,
                    ].whereType<String>().join(' · '),
                    style: AppType.body(11.5, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Net ${formatCurrency(slip.netSalary)}',
                    style: AppType.number(13, color: kSuccess)),
              ],
            ),
          ),
          children: [
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'Gross', value: formatCurrency(slip.grossSalary))),
                Expanded(
                  child: _MiniStat(
                    label: 'Deductions',
                    value: formatCurrency(slip.totalDeductions),
                    valueColor: kDanger,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Net pay',
                    value: formatCurrency(slip.netSalary),
                    valueColor: kSuccess,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _EarningsDeductions(slip: slip),
            if (slip.notes != null && slip.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(slip.notes!, style: AppType.body(11.5, color: kMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Two-column earnings / deductions breakdown for a single slip. Only non-zero
/// lines are shown to keep the card tight.
class _EarningsDeductions extends StatelessWidget {
  final SalarySlip slip;
  const _EarningsDeductions({required this.slip});

  @override
  Widget build(BuildContext context) {
    final earnings = <MapEntry<String, double>>[
      MapEntry('Basic', slip.basicSalary),
      MapEntry('Allowances', slip.allowances),
      MapEntry('Overtime', slip.overtime),
      MapEntry('Bonus', slip.netBonus),
      if (slip.adjustment != 0) MapEntry('Adjustment', slip.adjustment),
    ].where((e) => e.value != 0).toList();

    final deductions = <MapEntry<String, double>>[
      MapEntry('PAYE', slip.paye),
      MapEntry('NSSF', slip.nssfEmployee),
      MapEntry('NHIF', slip.nhifEmployee),
      MapEntry('HESLB', slip.heslb),
      MapEntry('Advance', slip.advanceDeduction),
      MapEntry('Loan', slip.loanDeduction),
      MapEntry('Other', slip.otherDeductions),
    ].where((e) => e.value != 0).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _LineColumn(
            title: 'Earnings',
            color: kSuccess,
            lines: earnings,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LineColumn(
            title: 'Deductions',
            color: kDanger,
            lines: deductions,
          ),
        ),
      ],
    );
  }
}

class _LineColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<MapEntry<String, double>> lines;
  const _LineColumn({required this.title, required this.color, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppType.eyebrow(size: 9.5, color: color)),
        const SizedBox(height: 6),
        if (lines.isEmpty)
          Text('—', style: AppType.body(12, color: kMuted))
        else
          ...lines.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(e.key,
                          style: AppType.body(11.5, color: kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    Text(formatCurrency(e.value),
                        style: AppType.number(11.5, color: AppColors.textPrimary(context))),
                  ],
                ),
              )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Run detail screen (pushed)
// ─────────────────────────────────────────────────────────────────────────────

class PayrollRunDetailScreen extends StatefulWidget {
  const PayrollRunDetailScreen({
    super.key,
    required this.runId,
    required this.periodLabel,
    required this.service,
  });

  final int runId;
  final String periodLabel;
  final PayrollService service;

  @override
  State<PayrollRunDetailScreen> createState() => _PayrollRunDetailScreenState();
}

class _PayrollRunDetailScreenState extends State<PayrollRunDetailScreen> {
  late Future<PayrollRun> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchRun(widget.runId);
  }

  void _reload() {
    setState(() => _future = widget.service.fetchRun(widget.runId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Payroll run',
            title: widget.periodLabel.isNotEmpty ? widget.periodLabel : 'Run',
            gradient: ModuleAccent.hr.colors,
            padding: const EdgeInsets.fromLTRB(8, 16, 12, 18),
            trailing: HeaderIconButton(
              icon: Icons.refresh_rounded,
              onTap: _reload,
              tooltip: 'Refresh',
            ),
          ),
          Expanded(
            child: FutureBuilder<PayrollRun>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _payrollListSkeleton(context, height: 120);
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final run = snapshot.data!;
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: _RunDetailBody(run: run),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RunDetailBody extends StatelessWidget {
  final PayrollRun run;
  const _RunDetailBody({required this.run});

  @override
  Widget build(BuildContext context) {
    final totals = run.totals;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        RevealOnLoad(
          child: AppCard(
            accentColor: run.statusColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        run.periodLabel.isNotEmpty ? run.periodLabel : '${run.monthName} ${run.year}',
                        style: AppType.display(17, color: AppColors.textNavy(context)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(label: run.statusLabel, color: run.statusColor),
                  ],
                ),
                if (run.documentNumber != null || run.payrollNumber != null) ...[
                  const SizedBox(height: 6),
                  Text(run.documentNumber ?? run.payrollNumber!,
                      style: AppType.body(12.5, color: kMuted, weight: FontWeight.w600)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _MiniStat(label: 'Slips', value: '${run.slipsCount}')),
                    Expanded(child: _MiniStat(label: 'Gross', value: formatCurrency(run.grossTotal))),
                    Expanded(
                      child: _MiniStat(
                        label: 'Net',
                        value: formatCurrency(run.netTotal),
                        valueColor: kSuccess,
                      ),
                    ),
                  ],
                ),
                if (run.createdAt != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 12, color: kMuted),
                      const SizedBox(width: 4),
                      Text('Created ${formatDate(run.createdAt)}',
                          style: AppType.body(11, color: kMuted)),
                    ],
                  ),
                ],
                if (run.notes != null && run.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(run.notes!, style: AppType.body(12, color: kMuted)),
                ],
              ],
            ),
          ),
        ),
        if (totals != null) ...[
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Totals',
            icon: Icons.summarize_outlined,
            accent: ModuleAccent.hr,
            eyebrow: 'Run breakdown',
          ),
          RevealOnLoad(delayMs: 60, child: _TotalsCard(totals: totals)),
        ],
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Salary slips (${run.slips.length})',
          icon: Icons.receipt_long_outlined,
          accent: ModuleAccent.hr,
          eyebrow: 'Employees',
        ),
        if (run.slips.isEmpty)
          AppCard(
            child: Text('No salary slips on this run.',
                style: AppType.body(13, color: kMuted)),
          )
        else
          ...run.slips.asMap().entries.map((e) => RevealOnLoad(
                delayMs: (e.key * 50).clamp(0, 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SalarySlipCard(slip: e.value),
                ),
              )),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final PayrollTotals totals;
  const _TotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final lines = <MapEntry<String, double>>[
      MapEntry('Gross', totals.gross),
      MapEntry('Bonus', totals.bonus),
      MapEntry('PAYE', totals.paye),
      MapEntry('NSSF (employee)', totals.nssfEmployee),
      MapEntry('NHIF', totals.nhif),
      MapEntry('HESLB', totals.heslb),
      MapEntry('Advances', totals.advances),
      MapEntry('Loans', totals.loans),
      MapEntry('Total deductions', totals.deductions),
      MapEntry('SDL (employer)', totals.sdl),
      MapEntry('NSSF (employer)', totals.nssfEmployer),
      MapEntry('WCF (employer)', totals.wcf),
      MapEntry('Employer cost', totals.employerCost),
    ].where((e) => e.value != 0).toList();

    return AppCard(
      child: Column(
        children: [
          for (final e in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(e.key,
                        style: AppType.body(12.5, color: kMuted, weight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text(formatCurrency(e.value),
                      style: AppType.number(13, color: AppColors.textPrimary(context))),
                ],
              ),
            ),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net payable',
                  style: AppType.display(14, color: AppColors.textNavy(context))),
              Text(formatCurrency(totals.net),
                  style: AppType.number(16, color: kSuccess)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(10, color: kMuted, weight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: AppType.number(13.5, color: valueColor ?? AppColors.textPrimary(context))),
      ],
    );
  }
}
