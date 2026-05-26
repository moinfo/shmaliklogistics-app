import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../models/lease.dart';
import '../mod_re_leases_service.dart';
import 'lease_detail_screen.dart';

/// "Leases" — a polished, searchable list of tenancies (*mikataba*) that taps
/// through to a read-only detail screen. Wired into the app drawer via
/// [RealEstateLeasesScreen].
class RealEstateLeasesScreen extends StatefulWidget {
  const RealEstateLeasesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<RealEstateLeasesScreen> createState() => _RealEstateLeasesScreenState();
}

class _RealEstateLeasesScreenState extends State<RealEstateLeasesScreen> {
  late final ModReLeasesService _service;
  late Future<LeasesPayload> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all

  @override
  void initState() {
    super.initState();
    _service = ModReLeasesService(widget.apiClient);
    _future = _service.fetchLeases();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchLeases());

  List<LeaseRow> _applyFilters(List<LeaseRow> rows) {
    return rows.where((l) {
      if (_statusFilter != null && l.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        l.leaseNumber,
        l.tenantName ?? '',
        l.propertyLabel ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Real Estate',
            title: 'Leases',
            subtitle: 'Tenancies · mikataba',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<LeasesPayload>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(
                      message: snapshot.error.toString(), onRetry: _reload);
                }
                final payload = snapshot.data;
                final all = payload?.rows ?? const <LeaseRow>[];
                final cycles = payload?.billingCycles ?? const {};
                final filtered = _applyFilters(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _statsRow(payload?.stats ?? const {})),
                      SliverToBoxAdapter(child: _searchBar()),
                      SliverToBoxAdapter(child: _statusChips(all, payload?.statuses ?? const {})),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.description_outlined,
                            message: all.isEmpty
                                ? 'No leases recorded yet.'
                                : 'No leases match your search.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => RevealOnLoad(
                              delayMs: (i * 60).clamp(0, 300),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LeaseCard(
                                  lease: filtered[i],
                                  cycles: cycles,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LeaseDetailScreen(
                                        leaseId: filtered[i].id,
                                        service: _service,
                                        initial: filtered[i],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ───────────────────────────────────────────────────────────────────

  Widget _statsRow(Map<String, dynamic> stats) {
    final active = _statInt(stats['active']);
    final expiring = _statInt(stats['expiring_30d']);
    final expired = _statInt(stats['expired']);
    final roll = _statDouble(stats['monthly_roll']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active',
                  value: active.toString(),
                  icon: Icons.verified_outlined,
                  accent: ModuleAccent.finance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Expiring ≤30d',
                  value: expiring.toString(),
                  icon: Icons.timelapse_rounded,
                  accent: ModuleAccent.brand,
                  danger: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Expired',
                  value: expired.toString(),
                  icon: Icons.event_busy_outlined,
                  accent: ModuleAccent.brand,
                  danger: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Monthly Roll TZS',
                  value: _compactTzs(roll),
                  icon: Icons.payments_outlined,
                  accent: ModuleAccent.finance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int _statInt(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;
  static double _statDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search lease, tenant, property…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                  onPressed: () => _searchCtrl.clear(),
                ),
          filled: true,
          fillColor: AppColors.surface(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Status filter chips ─────────────────────────────────────────────────────

  Widget _statusChips(List<LeaseRow> rows, Map<String, String> statuses) {
    // Prefer the API's status enum map; fall back to whatever is present.
    final present = <String, String>{};
    if (statuses.isNotEmpty) {
      present.addAll(statuses);
    } else {
      for (final l in rows) {
        present.putIfAbsent(l.status, () => l.statusLabel);
      }
    }
    if (present.isEmpty) return const SizedBox.shrink();

    final entries = present.entries.toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        children: [
          _chip('All', _statusFilter == null,
              () => setState(() => _statusFilter = null)),
          for (final e in entries)
            _chip(
              e.value,
              _statusFilter == e.key,
              () => setState(() => _statusFilter = e.key),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: AppType.body(
          12.5,
          weight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textPrimary(context),
        ),
        selectedColor: kPrimary,
        backgroundColor: AppColors.surface(context),
        showCheckmark: false,
        side: BorderSide(color: selected ? kPrimary : AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(children: [
            Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
            const SizedBox(width: 12),
            Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
            const SizedBox(width: 12),
            Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
          ]),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 48, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 104, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Money helpers (shared with the detail screen)
// ─────────────────────────────────────────────────────────────────────────────

/// `<currency> <amount>` with thousands separators, e.g. "TZS 1,200,000".
String moneyWithCurrency(String? currency, double amount) {
  final cur = (currency == null || currency.isEmpty) ? 'TZS' : currency;
  return '$cur ${NumberFormat('#,##0').format(amount)}';
}

/// Compact TZS for stat tiles, e.g. 12,500,000 → "12.5M", 240,000 → "240K".
String _compactTzs(double v) {
  if (v >= 1000000) {
    final m = v / 1000000;
    return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
  }
  if (v >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
  }
  return NumberFormat('#,##0').format(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// Lease list card
// ─────────────────────────────────────────────────────────────────────────────

class _LeaseCard extends StatelessWidget {
  final LeaseRow lease;
  final Map<String, BillingCycle> cycles;
  final VoidCallback onTap;
  const _LeaseCard({required this.lease, required this.cycles, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = lease.statusColor;
    final cycleLabel = cycles[lease.billingCycle]?.label;
    final rent = moneyWithCurrency(lease.rentCurrency, lease.rentAmount);
    final rentLine =
        cycleLabel == null || cycleLabel.isEmpty ? rent : '$rent · $cycleLabel';

    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.description_rounded, size: 21, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lease.leaseNumber,
                      style:
                          AppType.number(16.5, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lease.tenantName != null &&
                        lease.tenantName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(lease.tenantName!,
                          style: AppType.body(12, color: kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: lease.statusLabel, color: color),
            ],
          ),
          if (lease.propertyLabel != null &&
              lease.propertyLabel!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(lease.propertyLabel!,
                      style: AppType.body(12, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  rentLine,
                  style: AppType.body(13,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ContractChip(hasContract: lease.hasContract),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small "✓ Contract" (success) / "No contract" (muted) chip from has_contract.
class _ContractChip extends StatelessWidget {
  final bool hasContract;
  const _ContractChip({required this.hasContract});

  @override
  Widget build(BuildContext context) {
    final color = hasContract ? kSuccess : kMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasContract ? Icons.check_rounded : Icons.remove_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            hasContract ? 'Contract' : 'No contract',
            style: AppType.body(11, color: color, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}