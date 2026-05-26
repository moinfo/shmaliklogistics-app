import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../models/tenant.dart';
import '../mod_re_tenants_service.dart';
import 'tenant_detail_screen.dart';

/// Parse a backend hex colour (e.g. "#22C55E") into a [Color], falling back to
/// the slate [kMuted] when missing/invalid.
Color tenantHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return kMuted;
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse('FF$cleaned', radix: 16);
  return value == null ? kMuted : Color(value);
}

/// Real Estate — "Tenants": a polished, searchable list of tenants (wapangaji)
/// with status + type filters that taps through to a read-only detail screen.
class RealEstateTenantsScreen extends StatefulWidget {
  const RealEstateTenantsScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<RealEstateTenantsScreen> createState() =>
      _RealEstateTenantsScreenState();
}

class _RealEstateTenantsScreenState extends State<RealEstateTenantsScreen> {
  late final ModReTenantsService _service;
  late Future<TenantsPayload> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all
  String? _typeFilter; // null == all

  @override
  void initState() {
    super.initState();
    _service = ModReTenantsService(widget.apiClient);
    _future = _service.fetchTenants();
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

  void _reload() => setState(() => _future = _service.fetchTenants());

  List<TenantRow> _applyFilters(List<TenantRow> tenants) {
    return tenants.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_typeFilter != null && t.type != _typeFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        t.name,
        t.code,
        t.companyName ?? '',
        t.phone ?? '',
        t.email ?? '',
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
            title: 'Tenants',
            subtitle: 'Wapangaji · leases',
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
            child: FutureBuilder<TenantsPayload>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(
                      message: snapshot.error.toString(), onRetry: _reload);
                }
                final payload = snapshot.data ??
                    TenantsPayload(tenants: const <TenantRow>[]);
                final all = payload.tenants;
                final filtered = _applyFilters(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _stats(payload)),
                      SliverToBoxAdapter(child: _searchBar()),
                      SliverToBoxAdapter(child: _statusChips(all)),
                      SliverToBoxAdapter(child: _typeChips(all)),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.people_alt_outlined,
                            message: all.isEmpty
                                ? 'No tenants recorded yet.'
                                : 'No tenants match your search.',
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
                                child: _TenantCard(
                                  tenant: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TenantDetailScreen(
                                        tenantId: filtered[i].id,
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

  // ── Stat tiles ──────────────────────────────────────────────────────────────

  Widget _stats(TenantsPayload payload) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total',
              value: payload.total.toString(),
              icon: Icons.people_alt_rounded,
              accent: ModuleAccent.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Active',
              value: payload.active.toString(),
              icon: Icons.verified_user_rounded,
              accent: ModuleAccent.finance,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Companies',
              value: payload.companies.toString(),
              icon: Icons.business_rounded,
              accent: ModuleAccent.ops,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search name, code, company, phone…',
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

  Widget _statusChips(List<TenantRow> tenants) {
    final present = <String, String>{};
    for (final t in tenants) {
      if (t.status.isEmpty) continue;
      present.putIfAbsent(t.status, () => t.statusLabel);
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

  // ── Type filter chips ───────────────────────────────────────────────────────

  Widget _typeChips(List<TenantRow> tenants) {
    final present = <String, String>{};
    for (final t in tenants) {
      if (t.type.isEmpty) continue;
      present.putIfAbsent(t.type, () => t.typeLabel);
    }
    // Only show type filters when there's more than one type to choose from.
    if (present.length < 2) return const SizedBox.shrink();

    final entries = present.entries.toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        children: [
          _chip('All types', _typeFilter == null,
              () => setState(() => _typeFilter = null)),
          for (final e in entries)
            _chip(
              e.value,
              _typeFilter == e.key,
              () => setState(() => _typeFilter = e.key),
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
          Row(
            children: [
              Expanded(child: AppSkeleton.box(context, height: 96, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 96, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 96, radius: 20)),
            ],
          ),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 48, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 104, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tenant list card
// ─────────────────────────────────────────────────────────────────────────────

class _TenantCard extends StatelessWidget {
  final TenantRow tenant;
  final VoidCallback onTap;
  const _TenantCard({required this.tenant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = tenantHexColor(tenant.statusColorHex);
    final typeColor = tenantHexColor(tenant.typeColorHex);
    final showCompany = tenant.isCompany &&
        tenant.companyName != null &&
        tenant.companyName!.isNotEmpty;

    return AppCard(
      accentColor: statusColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(typeColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: AppType.number(16.5,
                          color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showCompany) ...[
                      const SizedBox(height: 2),
                      Text(
                        tenant.companyName!,
                        style: AppType.body(12, color: kMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: tenant.statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusPill(label: tenant.typeLabel, color: typeColor),
              if (tenant.phone != null && tenant.phone!.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.phone_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    tenant.phone!,
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              const Icon(Icons.description_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text(
                '${tenant.activeLeasesCount} ${tenant.activeLeasesCount == 1 ? 'lease' : 'leases'}',
                style: AppType.body(12,
                    color: kMuted, weight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        tenant.isCompany
            ? Icons.business_rounded
            : Icons.person_rounded,
        size: 21,
        color: color,
      ),
    );
  }
}