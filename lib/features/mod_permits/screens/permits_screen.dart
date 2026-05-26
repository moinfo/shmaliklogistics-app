import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/permit.dart';
import '../permits_service.dart';
import 'permit_detail_screen.dart';

/// Compliance accent for the Permits module (amber/orange — distinct from the
/// Ops/Finance/HR families, signalling "regulatory / watch this").
const _permitAccent = ModuleAccent.danger;

/// Resolves a permit's display colour, emphasising expiry urgency:
/// red when expired/soon, otherwise the status palette colour.
Color permitColor(Permit p) {
  if (p.isExpired) return kDanger;
  if (p.isExpiringSoon) return kWarning;
  return Color(p.statusColorValue);
}

/// Staff Permits module entry point. A searchable list of permit [AppCard]s with
/// expiry emphasis; tapping pushes a [PermitDetailScreen]. Read-only.
class PermitsScreen extends StatefulWidget {
  const PermitsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PermitsScreen> createState() => _PermitsScreenState();
}

class _PermitsScreenState extends State<PermitsScreen> {
  late final PermitsService _service;
  late Future<List<Permit>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  // Mirrors Permit::$statuses on the backend (+ an "all" pseudo-filter).
  static const _statuses = [
    ('all', 'All'),
    ('active', 'Active'),
    ('pending', 'Pending'),
    ('expired', 'Expired'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _service = PermitsService(widget.apiClient);
    _future = _service.fetchPermits();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchPermits());

  List<Permit> _filter(List<Permit> permits) {
    final q = _query.trim().toLowerCase();
    return permits.where((p) {
      if (_statusFilter != 'all' && p.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return p.vehiclePlate.toLowerCase().contains(q) ||
          (p.permitNumber ?? '').toLowerCase().contains(q) ||
          p.permitType.toLowerCase().contains(q) ||
          (p.issuingCountry ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Compliance',
            title: 'Permits',
            subtitle: 'Cross-border & vehicle permits',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Permit>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeleton();
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? [];
                final filtered = _filter(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildStatsRow(all)),
                      SliverToBoxAdapter(child: _buildSearch()),
                      SliverToBoxAdapter(child: _buildFilters()),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.verified_user_outlined,
                            message: all.isEmpty
                                ? 'No permits yet.\nIssued permits will appear here.'
                                : 'No permits match your search.',
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
                                child: _PermitCard(
                                  permit: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PermitDetailScreen(
                                        permitId: filtered[i].id,
                                        service: _service,
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

  // ── Stats strip (total / active / expiring soon / expired) ──────────────────

  Widget _buildStatsRow(List<Permit> permits) {
    final active = permits.where((p) => p.status == 'active').length;
    final soon = permits.where((p) => p.isExpiringSoon).length;
    final expired = permits.where((p) => p.isExpired).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total',
              value: '${permits.length}',
              icon: Icons.description_outlined,
              accent: _permitAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Active',
              value: '$active',
              icon: Icons.verified_rounded,
              accent: ModuleAccent.finance,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Expiring',
              value: '$soon',
              icon: Icons.warning_amber_rounded,
              accent: _permitAccent,
              danger: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Expired',
              value: '$expired',
              icon: Icons.event_busy_rounded,
              accent: ModuleAccent.danger,
              danger: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search plate, number, type, country…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: kMuted, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: AppColors.surface(context),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide: BorderSide(color: _permitAccent.base, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        itemCount: _statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _statuses[i];
          final selected = _statusFilter == value;
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _permitAccent.base : AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _permitAccent.base : AppColors.border(context),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppType.body(13,
                    weight: FontWeight.w600,
                    color: selected ? Colors.white : kMuted),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(child: AppSkeleton.box(context, height: 96, radius: 20)),
                if (i < 3) const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 46, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 124, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permit list card
// ─────────────────────────────────────────────────────────────────────────────

class _PermitCard extends StatelessWidget {
  final Permit permit;
  final VoidCallback onTap;
  const _PermitCard({required this.permit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = permitColor(permit);
    final flagExpiry = permit.isExpired || permit.isExpiringSoon;
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permit.permitNumber ?? permit.permitType,
                      style: AppType.display(15, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      permit.permitType,
                      style: AppType.body(12.5,
                          color: kMuted, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: permit.statusLabel, color: Color(permit.statusColorValue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.directions_car_filled_outlined, size: 14, color: kMuted),
              const SizedBox(width: 5),
              Text(permit.vehiclePlate,
                  style: AppType.body(12.5,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary(context))),
              if (permit.issuingCountry != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.public_outlined, size: 14, color: kMuted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(permit.issuingCountry!,
                      style: AppType.body(12.5, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                flagExpiry ? Icons.warning_amber_rounded : Icons.event_available_outlined,
                size: 13,
                color: flagExpiry ? color : kMuted,
              ),
              const SizedBox(width: 5),
              Text(
                permit.expiryDate != null
                    ? '${permit.expiryLabel} · ${formatDate(permit.expiryDate)}'
                    : permit.expiryLabel,
                style: AppType.body(11.5,
                    color: flagExpiry ? color : kMuted,
                    weight: flagExpiry ? FontWeight.w700 : FontWeight.w500),
              ),
              const Spacer(),
              Text('View',
                  style: AppType.body(11, color: _permitAccent.base, weight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, size: 14, color: _permitAccent.base),
            ],
          ),
        ],
      ),
    );
  }
}
