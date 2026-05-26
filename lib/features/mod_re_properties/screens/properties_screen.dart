import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../models/property.dart';
import '../mod_re_properties_service.dart';
import 'property_detail_screen.dart';

/// Formats a plain TZS amount with thousands separators, e.g. "TZS 1,250,000".
String tzs(num n) => 'TZS ${NumberFormat('#,##0', 'en').format(n)}';

/// "Properties" — a searchable real-estate portfolio list with occupancy and
/// rent-roll headline stats, status + type filters, and tap-through detail.
/// Wired into the app drawer via [RealEstatePropertiesScreen].
class RealEstatePropertiesScreen extends StatefulWidget {
  const RealEstatePropertiesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<RealEstatePropertiesScreen> createState() =>
      _RealEstatePropertiesScreenState();
}

class _RealEstatePropertiesScreenState
    extends State<RealEstatePropertiesScreen> {
  late final ModRePropertiesService _service;
  late Future<PropertiesPayload> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all
  String? _typeFilter; // null == all

  @override
  void initState() {
    super.initState();
    _service = ModRePropertiesService(widget.apiClient);
    _future = _service.fetchProperties();
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

  void _reload() => setState(() => _future = _service.fetchProperties());

  List<PropertyRow> _applyFilters(List<PropertyRow> rows) {
    return rows.where((p) {
      if (_statusFilter != null && p.status != _statusFilter) return false;
      if (_typeFilter != null && p.type != _typeFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        p.name,
        p.code,
        p.address ?? '',
        p.region ?? '',
        p.district ?? '',
        p.typeLabel ?? '',
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
            title: 'Properties',
            subtitle: 'Portfolio · occupancy · rent roll',
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
            child: FutureBuilder<PropertiesPayload>(
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
                final all = payload?.properties ?? const <PropertyRow>[];
                final filtered = _applyFilters(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (payload != null)
                        SliverToBoxAdapter(child: _statsRow(payload.stats)),
                      SliverToBoxAdapter(child: _searchBar()),
                      if (payload != null)
                        SliverToBoxAdapter(
                            child: _statusChips(payload.statuses, all)),
                      if (payload != null)
                        SliverToBoxAdapter(
                            child: _typeChips(payload.types, all)),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.apartment_outlined,
                            message: all.isEmpty
                                ? 'No properties registered yet.'
                                : 'No properties match your search.',
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
                                child: _PropertyCard(
                                  property: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PropertyDetailScreen(
                                        propertyId: filtered[i].id,
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

  // ── Headline stats ──────────────────────────────────────────────────────────

  Widget _statsRow(PropertiesStats s) {
    final cards = [
      StatCard(
        label: 'Total',
        value: '${s.total}',
        icon: Icons.apartment_rounded,
        accent: ModuleAccent.brand,
      ),
      StatCard(
        label: 'Occupied',
        value: '${s.occupied}',
        icon: Icons.meeting_room_rounded,
        accent: ModuleAccent.finance,
      ),
      StatCard(
        label: 'Under Renovation',
        value: '${s.underRenovation}',
        icon: Icons.construction_rounded,
        accent: ModuleAccent.ops,
      ),
      StatCard(
        label: 'Monthly Roll',
        value: tzs(s.monthlyRoll),
        icon: Icons.payments_rounded,
        accent: ModuleAccent.hr,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: cards,
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
          hintText: 'Search name, code, address, region…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon:
                      const Icon(Icons.close_rounded, size: 18, color: kMuted),
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

  Widget _statusChips(List<EnumOption> statuses, List<PropertyRow> rows) {
    // Prefer the backend enum map; fall back to statuses present in the rows.
    final entries = <MapEntry<String, String>>[];
    if (statuses.isNotEmpty) {
      for (final s in statuses) {
        entries.add(MapEntry(s.key, s.label));
      }
    } else {
      final present = <String, String>{};
      for (final p in rows) {
        present.putIfAbsent(p.status, () => p.statusLabel);
      }
      entries.addAll(present.entries);
    }
    if (entries.isEmpty) return const SizedBox.shrink();

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

  Widget _typeChips(List<EnumOption> types, List<PropertyRow> rows) {
    final entries = <MapEntry<String, String>>[];
    if (types.isNotEmpty) {
      for (final t in types) {
        entries.add(MapEntry(t.key, t.label));
      }
    } else {
      final present = <String, String>{};
      for (final p in rows) {
        if (p.type != null) {
          present.putIfAbsent(p.type!, () => p.typeLabel ?? p.type!);
        }
      }
      entries.addAll(present.entries);
    }
    if (entries.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            ],
          ),
          const SizedBox(height: 12),
          AppSkeleton.box(context, height: 48, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 108, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Property list card
// ─────────────────────────────────────────────────────────────────────────────

class _PropertyCard extends StatelessWidget {
  final PropertyRow property;
  final VoidCallback onTap;
  const _PropertyCard({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = property.statusColor;
    final location = [property.address, property.region]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');

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
                      property.name,
                      style:
                          AppType.display(16, color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (property.code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(property.code,
                          style: AppType.number(12, color: kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: property.statusLabel, color: color),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(location,
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
              const Icon(Icons.meeting_room_outlined, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Text(
                '${property.unitsCount} units · ${property.occupiedUnitsCount} occupied',
                style: AppType.body(12, color: kMuted),
              ),
              const Spacer(),
              Text(tzs(property.monthlyRentRoll),
                  style: AppType.number(13.5,
                      color: AppColors.textNavy(context))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(iconForPropertyType(property.type), size: 21, color: color),
    );
  }
}

/// Maps a property [type] to a Material icon. Shared by the list card and the
/// detail header. Unknown / null types fall back to a generic building glyph.
IconData iconForPropertyType(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'apartment':
    case 'apartments':
    case 'residential':
      return Icons.apartment_rounded;
    case 'house':
    case 'villa':
      return Icons.house_rounded;
    case 'commercial':
    case 'office':
      return Icons.business_rounded;
    case 'retail':
    case 'shop':
      return Icons.storefront_rounded;
    case 'warehouse':
    case 'industrial':
      return Icons.warehouse_rounded;
    case 'land':
    case 'plot':
      return Icons.landscape_rounded;
    case 'mixed':
    case 'mixed_use':
      return Icons.domain_rounded;
    default:
      return Icons.location_city_rounded;
  }
}