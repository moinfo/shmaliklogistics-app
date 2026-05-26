import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../cargo_service.dart';
import '../models/cargo.dart';
import 'cargo_detail_screen.dart';

/// Maps a cargo status to its display colour (mirrors the web `Cargo::$statuses`
/// palette). Falls back to a hex string from the API when present.
Color cargoStatusColor(Cargo c) {
  final hex = c.statusColor;
  if (hex != null && hex.isNotEmpty) return hexColor(hex);
  switch (c.status) {
    case 'delivered':
    case 'cleared':
      return kSuccess;
    case 'in_transit':
    case 'loaded':
      return kPrimary;
    case 'at_border':
      return kWarning;
    case 'cancelled':
      return kDanger;
    default:
      return kMuted;
  }
}

/// Maps a cargo type to its accent colour.
Color cargoTypeColor(Cargo c) {
  final hex = c.typeColor;
  if (hex != null && hex.isNotEmpty) return hexColor(hex);
  return const Color(0xFF3B82F6);
}

Color hexColor(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF64748B);
}

/// Thousands-grouped weight, dropping the decimal when whole (e.g. `12,500`).
String formatWeight(double kg) {
  final whole = kg.truncateToDouble() == kg;
  return NumberFormat(whole ? '#,###' : '#,##0.##').format(kg);
}

/// Module #7 — Cargo. A polished, searchable list of freight consignments with
/// status filtering and tap-through to a detail screen that includes a
/// status-change timeline. Read-only.
class CargoScreen extends StatefulWidget {
  const CargoScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<CargoScreen> createState() => _CargoScreenState();
}

class _CargoScreenState extends State<CargoScreen> {
  late final CargoService _service;
  late Future<List<Cargo>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';

  static const _accent = ModuleAccent.ops;

  @override
  void initState() {
    super.initState();
    _service = CargoService(widget.apiClient);
    _future = _service.fetchCargo();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchCargo());

  List<Cargo> _filter(List<Cargo> all) {
    return all.where((c) {
      if (_statusFilter != 'all' && c.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.cargoNumber.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          (c.clientName ?? '').toLowerCase().contains(q) ||
          c.routeDescription.toLowerCase().contains(q) ||
          (c.consigneeName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Freight',
            title: 'Cargo',
            subtitle: 'Consignments & shipments',
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
            child: FutureBuilder<List<Cargo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? [];
                final filtered = _filter(all);
                return Column(
                  children: [
                    _buildControls(all),
                    Expanded(
                      child: RefreshIndicator(
                        color: kPrimary,
                        onRefresh: () async => _reload(),
                        child: filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: AppEmpty(
                                      icon: Icons.inventory_2_outlined,
                                      message: all.isEmpty
                                          ? 'No cargo yet.\nRegistered consignments will appear here.'
                                          : 'No cargo matches your filters.',
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => RevealOnLoad(
                                  delayMs: (i * 60).clamp(0, 300),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _CargoCard(
                                      cargo: filtered[i],
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CargoDetailScreen(
                                            cargoId: filtered[i].id,
                                            service: _service,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(List<Cargo> all) {
    int countFor(String s) => all.where((c) => c.status == s).length;
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: AppType.body(14, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Search cargo, client, route…',
              hintStyle: AppType.body(13.5, color: kMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceVariant(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('all', 'All', all.length),
                _chip('in_transit', 'In Transit', countFor('in_transit')),
                _chip('at_border', 'At Border', countFor('at_border')),
                _chip('cleared', 'Cleared', countFor('cleared')),
                _chip('delivered', 'Delivered', countFor('delivered')),
                _chip('registered', 'Registered', countFor('registered')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, int count) {
    final selected = _statusFilter == value;
    final color = value == 'at_border'
        ? kWarning
        : value == 'delivered' || value == 'cleared'
            ? kSuccess
            : value == 'all'
                ? _accent.base
                : kPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : AppColors.surfaceVariant(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : AppColors.border(context),
            ),
          ),
          child: Text(
            '$label  $count',
            style: AppType.body(12.5,
                weight: FontWeight.w700, color: selected ? color : kMuted),
          ),
        ),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 124, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _CargoCard extends StatelessWidget {
  final Cargo cargo;
  final VoidCallback onTap;
  const _CargoCard({required this.cargo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = cargoStatusColor(cargo);
    final typeColor = cargoTypeColor(cargo);
    return AppCard(
      accentColor: statusColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cargo.description.isNotEmpty ? cargo.description : cargo.cargoNumber,
                  style: AppType.display(16, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusPill(label: cargo.statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            cargo.cargoNumber,
            style: AppType.body(12, color: kMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          if (cargo.routeDescription.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.route_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(cargo.routeDescription,
                      style: AppType.body(12.5, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusPill(label: cargo.typeLabel, color: typeColor),
              const Spacer(),
              const Icon(Icons.scale_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text('${formatWeight(cargo.weightKg)} kg',
                  style: AppType.number(13, color: AppColors.textPrimary(context))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(cargo.clientName ?? 'No client',
                    style: AppType.body(12, color: kMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('View',
                  style: AppType.body(11,
                      color: ModuleAccent.ops.base, weight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, size: 14, color: ModuleAccent.ops.base),
            ],
          ),
        ],
      ),
    );
  }
}
