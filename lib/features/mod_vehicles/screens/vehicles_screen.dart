import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/vehicle.dart';
import '../mod_vehicles_service.dart';
import 'vehicle_detail_screen.dart';

/// "All Vehicles" — a polished, searchable fleet list that taps through to a
/// read-only detail screen. Wired into the app drawer via [VehiclesScreen].
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  late final ModVehiclesService _service;
  late Future<List<Vehicle>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all

  @override
  void initState() {
    super.initState();
    _service = ModVehiclesService(widget.apiClient);
    _future = _service.fetchVehicles();
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

  void _reload() => setState(() => _future = _service.fetchVehicles());

  List<Vehicle> _applyFilters(List<Vehicle> vehicles) {
    return vehicles.where((v) {
      if (_statusFilter != null && v.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        v.plate,
        v.make ?? '',
        v.modelName ?? '',
        v.type ?? '',
        v.driverName ?? '',
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
            eyebrow: 'Fleet',
            title: 'All Vehicles',
            subtitle: 'Registry · documents · assignments',
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
            child: FutureBuilder<List<Vehicle>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? const <Vehicle>[];
                final filtered = _applyFilters(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _searchBar()),
                      SliverToBoxAdapter(child: _statusChips(all)),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.directions_car_outlined,
                            message: all.isEmpty
                                ? 'No vehicles registered yet.'
                                : 'No vehicles match your search.',
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
                                child: _VehicleCard(
                                  vehicle: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VehicleDetailScreen(
                                        vehicleId: filtered[i].id,
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

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search plate, make, model, driver…',
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
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Status filter chips ─────────────────────────────────────────────────────

  Widget _statusChips(List<Vehicle> vehicles) {
    final present = <String, String>{};
    for (final v in vehicles) {
      present.putIfAbsent(v.status, () => v.statusLabel);
    }
    if (present.isEmpty) return const SizedBox.shrink();

    final entries = present.entries.toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        children: [
          _chip('All', _statusFilter == null, () => setState(() => _statusFilter = null)),
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
// Vehicle list card
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = vehicle.statusColor;
    final subtitle = [
      vehicle.description == vehicle.plate ? null : vehicle.description,
      vehicle.year?.toString(),
    ].whereType<String>().join(' · ');

    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _typeBadge(color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate,
                      style: AppType.number(16.5, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppType.body(12, color: kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: vehicle.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (vehicle.type != null && vehicle.type!.isNotEmpty) ...[
                const Icon(Icons.category_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(vehicle.type!, style: AppType.body(12, color: kMuted)),
                const SizedBox(width: 12),
              ],
              if (vehicle.driverName != null && vehicle.driverName!.isNotEmpty) ...[
                const Icon(Icons.person_outline_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(vehicle.driverName!,
                      style: AppType.body(12, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 18, color: kMuted),
            ],
          ),
          if (vehicle.hasDocumentWarning) ...[
            const SizedBox(height: 10),
            _DocWarning(doc: vehicle.soonestDocument!),
          ],
        ],
      ),
    );
  }

  /// Type icon in a tinted square. The truck-type → icon mapping lives in
  /// [iconForVehicleType] so it can be tuned without touching layout code.
  Widget _typeBadge(Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(iconForVehicleType(vehicle.type), size: 21, color: color),
    );
  }
}

/// Maps a vehicle [type] (Flatbed, Container, Tanker, …) to a Material icon.
///
/// Shared by the list card and the detail header. Unknown / null types fall
/// back to a generic vehicle glyph.
IconData iconForVehicleType(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'flatbed':
    case 'lowboy':
      return Icons.local_shipping_rounded;
    case 'container':
    case 'box body':
      return Icons.inventory_2_rounded;
    case 'reefer':
      return Icons.ac_unit_rounded;
    case 'tipper':
      return Icons.fire_truck_rounded;
    case 'tanker':
      return Icons.local_gas_station_rounded;
    default:
      return Icons.directions_car_rounded;
  }
}

/// A tinted inline banner shown when a statutory document is expired/expiring.
class _DocWarning extends StatelessWidget {
  final VehicleDocument doc;
  const _DocWarning({required this.doc});

  @override
  Widget build(BuildContext context) {
    final expired = doc.expired;
    final color = expired ? kDanger : kWarning;
    final days = doc.days;
    final label = expired
        ? '${doc.label} expired ${days.abs()}d ago'
        : days == 0
            ? '${doc.label} expires today'
            : '${doc.label} expires in ${days}d';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label  ·  ${formatDate(doc.expiry)}',
              style: AppType.body(11.5, color: color, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
