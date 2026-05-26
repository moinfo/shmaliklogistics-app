import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/models/driver_alert.dart';
import '../../../core/models/trip.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/fleet_vehicle.dart';
import '../staff_ops_service.dart';
import 'ops_trip_detail_screen.dart';

/// Staff Operations home — Live Trips, Fleet Status and Alerts.
///
/// Sections the signed-in user cannot view are hidden via
/// `AppSession.instance.can(...)` (see the implementation contract).
class OpsHomeScreen extends StatefulWidget {
  const OpsHomeScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<OpsHomeScreen> createState() => _OpsHomeScreenState();
}

class _OpsHomeScreenState extends State<OpsHomeScreen> with SingleTickerProviderStateMixin {
  late final StaffOpsService _service;
  late final List<_OpsSection> _sections;
  TabController? _tabController;

  // ── Live trips ───────────────────────────────────────────────────────────────
  List<Trip>? _trips;
  bool _tripsLoading = true;
  String? _tripsError;
  String _tripFilter = 'all';

  static const _tripFilters = [
    ('all', 'All'),
    ('in_transit', 'In Transit'),
    ('at_border', 'At Border'),
    ('loading', 'Loading'),
    ('planned', 'Planned'),
  ];

  // ── Fleet ──────────────────────────────────────────────────────────────────
  List<FleetVehicle>? _fleet;
  bool _fleetLoading = true;
  String? _fleetError;

  // ── Alerts ─────────────────────────────────────────────────────────────────
  AlertBundle? _alerts;
  bool _alertsLoading = true;
  String? _alertsError;

  @override
  void initState() {
    super.initState();
    _service = StaffOpsService(widget.apiClient);

    final session = AppSession.instance;
    _sections = [
      if (session.can('trips.view')) _OpsSection.liveTrips,
      if (session.can('fleet.view')) _OpsSection.fleet,
      if (session.can('trips.view') || session.can('drivers.view')) _OpsSection.alerts,
    ];

    if (_sections.isNotEmpty) {
      _tabController = TabController(length: _sections.length, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) setState(() {});
      });
      // Kick off only the loads the user is allowed to see.
      if (_sections.contains(_OpsSection.liveTrips)) _loadTrips();
      if (_sections.contains(_OpsSection.fleet)) _loadFleet();
      if (_sections.contains(_OpsSection.alerts)) _loadAlerts();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ── Loaders ──────────────────────────────────────────────────────────────────

  Future<void> _loadTrips() async {
    setState(() { _tripsLoading = true; _tripsError = null; });
    try {
      final trips = await _service.fetchTrips();
      if (mounted) setState(() => _trips = trips);
    } on ApiException catch (e) {
      if (mounted) setState(() => _tripsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _tripsError = 'Unable to load trips.');
    } finally {
      if (mounted) setState(() => _tripsLoading = false);
    }
  }

  Future<void> _loadFleet() async {
    setState(() { _fleetLoading = true; _fleetError = null; });
    try {
      final fleet = await _service.fetchFleet();
      if (mounted) setState(() => _fleet = fleet);
    } on ApiException catch (e) {
      if (mounted) setState(() => _fleetError = e.message);
    } catch (_) {
      if (mounted) setState(() => _fleetError = 'Unable to load fleet.');
    } finally {
      if (mounted) setState(() => _fleetLoading = false);
    }
  }

  Future<void> _loadAlerts() async {
    setState(() { _alertsLoading = true; _alertsError = null; });
    try {
      final alerts = await _service.fetchAlerts();
      if (mounted) setState(() => _alerts = alerts);
    } on ApiException catch (e) {
      if (mounted) setState(() => _alertsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _alertsError = 'Unable to load alerts.');
    } finally {
      if (mounted) setState(() => _alertsLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Fleet & dispatch',
            subtitle: AppSession.instance.name.isNotEmpty
                ? AppSession.instance.name
                : 'Live trips · fleet · alerts',
            title: 'Operations',
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _refreshActive,
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (_sections.length > 1) _buildTabBar(),
          if (_sections.isEmpty)
            Expanded(child: _buildNoAccess())
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _sections.map(_buildSection).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Section tab bar (rendered cleanly under the gradient header) ─────────────

  Widget _buildTabBar() {
    final selected = _tabController?.index ?? 0;
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _sections.length; i++)
              Padding(
                padding: EdgeInsets.only(right: i == _sections.length - 1 ? 0 : 8),
                child: _SectionChip(
                  label: _sections[i].title,
                  icon: _sections[i].icon,
                  selected: selected == i,
                  onTap: () => _tabController?.animateTo(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Refresh whichever section is currently visible.
  void _refreshActive() {
    if (_sections.isEmpty) return;
    final section = _sections[_tabController?.index ?? 0];
    switch (section) {
      case _OpsSection.liveTrips:
        _loadTrips();
      case _OpsSection.fleet:
        _loadFleet();
      case _OpsSection.alerts:
        _loadAlerts();
    }
  }

  Widget _buildSection(_OpsSection section) {
    switch (section) {
      case _OpsSection.liveTrips:
        return _buildTripsTab();
      case _OpsSection.fleet:
        return _buildFleetTab();
      case _OpsSection.alerts:
        return _buildAlertsTab();
    }
  }

  // ── Live trips tab ─────────────────────────────────────────────────────────────

  Widget _buildTripsTab() {
    if (_tripsLoading) return _buildListSkeleton();
    if (_tripsError != null) return _wrapScroll(AppError(message: _tripsError!, onRetry: _loadTrips));

    final all = _trips ?? [];
    final trips = _tripFilter == 'all' ? all : all.where((t) => t.status == _tripFilter).toList();

    return Column(
      children: [
        _buildTripFilterChips(),
        Expanded(
          child: RefreshIndicator(
            color: kPrimary,
            onRefresh: _loadTrips,
            child: trips.isEmpty
                ? _wrapScroll(
                    AppEmpty(
                      icon: Icons.local_shipping_outlined,
                      message: _tripFilter == 'all'
                          ? 'No live trips. Active trips will appear here.'
                          : 'No ${_tripFilter.replaceAll('_', ' ')} trips right now.',
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    itemCount: trips.length,
                    itemBuilder: (_, i) => RevealOnLoad(
                      delayMs: (i * 60).clamp(0, 300),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OpsTripCard(
                          trip: trips[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OpsTripDetailScreen(trip: trips[i]),
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
  }

  Widget _buildTripFilterChips() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _tripFilters.map((f) {
            final (value, label) = f;
            final selected = _tripFilter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _tripFilter = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? ModuleAccent.ops.base : AppColors.chipUnselected(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? ModuleAccent.ops.base : AppColors.border(context),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppType.body(12,
                        weight: FontWeight.w600,
                        color: selected ? Colors.white : kMuted),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Fleet tab ─────────────────────────────────────────────────────────────────

  Widget _buildFleetTab() {
    if (_fleetLoading) return _buildListSkeleton();
    if (_fleetError != null) return _wrapScroll(AppError(message: _fleetError!, onRetry: _loadFleet));

    final fleet = _fleet ?? [];
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadFleet,
      child: fleet.isEmpty
          ? _wrapScroll(const AppEmpty(icon: Icons.directions_car_outlined, message: 'No vehicles. Fleet vehicles will appear here.'))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              itemCount: fleet.length,
              itemBuilder: (_, i) => RevealOnLoad(
                delayMs: (i * 60).clamp(0, 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FleetCard(vehicle: fleet[i]),
                ),
              ),
            ),
    );
  }

  // ── Alerts tab ─────────────────────────────────────────────────────────────────

  Widget _buildAlertsTab() {
    if (_alertsLoading) return _buildListSkeleton();
    if (_alertsError != null) return _wrapScroll(AppError(message: _alertsError!, onRetry: _loadAlerts));

    final items = _alerts?.items ?? [];
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _loadAlerts,
      child: items.isEmpty
          ? _wrapScroll(const AppEmpty(icon: Icons.check_circle_outline_rounded, message: 'All clear. No operational alerts right now.'))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              itemCount: items.length,
              itemBuilder: (_, i) => RevealOnLoad(
                delayMs: (i * 60).clamp(0, 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AlertCard(alert: items[i]),
                ),
              ),
            ),
    );
  }

  // ── Shared states ─────────────────────────────────────────────────────────────

  /// Wraps a centered state widget so it stays pull-to-refreshable.
  Widget _wrapScroll(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: child,
        ),
      ],
    );
  }

  Widget _buildNoAccess() {
    return const AppEmpty(
      icon: Icons.lock_outline_rounded,
      message: 'No operations access.\nYou do not have permission to view operations data.',
    );
  }

  Widget _buildListSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppSkeleton.box(context, height: 110, radius: 16),
            ),
        ],
      ),
    );
  }
}

/// The sections available on the Operations home, gated by permission.
enum _OpsSection {
  liveTrips('Live Trips', Icons.route_rounded),
  fleet('Fleet', Icons.local_shipping_rounded),
  alerts('Alerts', Icons.warning_amber_rounded);

  const _OpsSection(this.title, this.icon);
  final String title;
  final IconData icon;
}

// ── Section chip (segmented control under the header) ────────────────────────────

class _SectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SectionChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColors.chipUnselected(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : AppColors.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : kMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppType.body(13,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip card (read-only, ops variant) ──────────────────────────────────────────

class _OpsTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _OpsTripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);

    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trip.tripNumber,
                style: AppType.number(14, color: AppColors.textNavy(context)),
              ),
              StatusPill(label: trip.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 14),
          _RouteColumn(from: trip.routeFrom, to: trip.routeTo, color: color),
          const SizedBox(height: 12),
          Row(
            children: [
              if (trip.departureDate != null) ...[
                const Icon(Icons.calendar_today_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(trip.departureDate), style: AppType.body(11, color: kMuted)),
              ],
              if (trip.vehiclePlate != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.directions_car_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(trip.vehiclePlate!, style: AppType.body(11, color: kMuted)),
              ],
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 16, color: kMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteColumn extends StatelessWidget {
  final String from;
  final String to;
  final Color color;
  const _RouteColumn({required this.from, required this.to, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimary)),
            Container(width: 1.5, height: 18, color: AppColors.border(context)),
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface(context), border: Border.all(color: color, width: 2)),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from, style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Text(to, style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Fleet card ─────────────────────────────────────────────────────────────────

class _FleetCard extends StatelessWidget {
  final FleetVehicle vehicle;
  const _FleetCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final color = Color(vehicle.statusColorValue);

    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_shipping_rounded, size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.plate,
                              style: AppType.number(14, color: AppColors.textNavy(context)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(vehicle.description,
                              style: AppType.body(11, color: kMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
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
              const Icon(Icons.person_outline_rounded, size: 13, color: kMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  vehicle.hasDriver ? vehicle.driverName! : 'Unassigned',
                  style: AppType.body(12,
                      color: vehicle.hasDriver ? AppColors.textPrimary(context) : kMuted,
                      weight: vehicle.hasDriver ? FontWeight.w600 : FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (vehicle.lastOdometerKm != null) ...[
                const Icon(Icons.speed_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text('${vehicle.lastOdometerKm} km',
                    style: AppType.number(11, weight: FontWeight.w700, color: kMuted)),
              ],
            ],
          ),
          if (vehicle.lastFuelDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_gas_station_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Last fuel ${formatDate(vehicle.lastFuelDate)}'
                    '${vehicle.lastFuelLiters != null ? ' · ${vehicle.lastFuelLiters!.toStringAsFixed(0)} L' : ''}',
                    style: AppType.body(11, color: kMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Alert card ─────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final DriverAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final Color severityColor;
    final IconData severityIcon;
    if (alert.isCritical) {
      severityColor = kDanger;
      severityIcon = Icons.error_outline;
    } else if (alert.isWarning) {
      severityColor = kWarning;
      severityIcon = Icons.warning_amber_rounded;
    } else {
      severityColor = kPrimary;
      severityIcon = Icons.info_outline;
    }

    return AppCard(
      accentColor: severityColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(severityIcon, color: severityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: AppType.display(14, color: AppColors.textNavy(context))),
                const SizedBox(height: 2),
                Text(alert.message, style: AppType.body(12, color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
