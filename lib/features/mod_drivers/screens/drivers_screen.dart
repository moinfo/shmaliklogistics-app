import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/driver.dart';
import '../mod_drivers_service.dart';
import '../widgets/driver_avatar.dart';
import 'driver_detail_screen.dart';

/// Module 1 — Drivers. A polished, searchable list of personnel cards that
/// taps through to a read-only detail screen. Wired into the app drawer by the
/// orchestrator via the [DriversScreen] entry class.
class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  late final ModDriversService _service;
  late Future<List<Driver>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all

  @override
  void initState() {
    super.initState();
    _service = ModDriversService(widget.apiClient);
    _future = _service.fetchDrivers();
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

  void _reload() => setState(() => _future = _service.fetchDrivers());

  List<Driver> _applyFilters(List<Driver> drivers) {
    return drivers.where((d) {
      if (_statusFilter != null && d.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        d.name,
        d.phone ?? '',
        d.licenseNumber ?? '',
        d.vehiclePlate ?? '',
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
            eyebrow: 'Personnel',
            title: 'Drivers',
            subtitle: 'Roster · licences · assignments',
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
            child: FutureBuilder<List<Driver>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? const <Driver>[];
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
                            icon: Icons.badge_outlined,
                            message: all.isEmpty
                                ? 'No drivers registered yet.'
                                : 'No drivers match your search.',
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
                                child: _DriverCard(
                                  driver: filtered[i],
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriverDetailScreen(
                                        driverId: filtered[i].id,
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
          hintText: 'Search name, phone, licence, plate…',
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

  Widget _statusChips(List<Driver> drivers) {
    // Distinct statuses present, preserving a sensible order.
    final present = <String, String>{};
    for (final d in drivers) {
      present.putIfAbsent(d.status, () => d.statusLabel);
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
// Driver list card
// ─────────────────────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback onTap;
  const _DriverCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = driver.statusColor;
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DriverAvatar(driver: driver),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  driver.name,
                  style: AppType.display(15.5, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: driver.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (driver.phone != null && driver.phone!.isNotEmpty)
                      _meta(Icons.phone_outlined, driver.phone!),
                    if (driver.licenseNumber != null && driver.licenseNumber!.isNotEmpty)
                      _meta(Icons.badge_outlined, driver.licenseNumber!),
                    if (driver.vehiclePlate != null && driver.vehiclePlate!.isNotEmpty)
                      _meta(Icons.local_shipping_outlined, driver.vehiclePlate!),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: kMuted),
            ],
          ),
          if (driver.licenseExpiringSoon) ...[
            const SizedBox(height: 10),
            _LicenseWarning(driver: driver),
          ],
        ],
      ),
    );
  }

  /// A compact icon + label used in the card's wrapping meta row (phone,
  /// licence number, assigned plate).
  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 4),
        Text(text, style: AppType.body(12, color: kMuted)),
      ],
    );
  }
}

/// A tinted inline banner shown when a driver's licence is expired or expiring.
class _LicenseWarning extends StatelessWidget {
  final Driver driver;
  const _LicenseWarning({required this.driver});

  @override
  Widget build(BuildContext context) {
    final expired = driver.licenseExpired;
    final color = expired ? kDanger : kWarning;
    final days = driver.licenseDays ?? 0;
    final label = expired
        ? 'Licence expired ${days.abs()}d ago'
        : days == 0
            ? 'Licence expires today'
            : 'Licence expires in ${days}d';
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
              '$label  ·  ${formatDate(driver.licenseExpiry)}',
              style: AppType.body(11.5, color: color, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
