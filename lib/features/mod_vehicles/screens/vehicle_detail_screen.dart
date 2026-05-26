import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/vehicle.dart';
import '../mod_vehicles_service.dart';
import 'vehicles_screen.dart' show iconForVehicleType;

/// Read-only detail for a single vehicle: identity, registration, specs,
/// statutory documents, assigned driver, GPS and recent trips.
class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;
  final ModVehiclesService service;

  /// The list-row summary, shown immediately while the full record loads.
  final Vehicle? initial;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    required this.service,
    this.initial,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<Vehicle> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchVehicle(widget.vehicleId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchVehicle(widget.vehicleId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Vehicle>(
      future: _future,
      builder: (context, snapshot) {
        final vehicle = snapshot.data ?? widget.initial;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(vehicle),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(Vehicle? vehicle) {
    return AppGradientHeader(
      eyebrow: 'Fleet',
      title: vehicle?.plate ?? 'Vehicle',
      subtitle: vehicle?.statusLabel,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _body(AsyncSnapshot<Vehicle> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && widget.initial == null) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null && widget.initial == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final v = snapshot.data ?? widget.initial!;
    final loading = snapshot.connectionState == ConnectionState.waiting;
    final hasGps = v.gpsLat != null && v.gpsLng != null;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _statusCard(v)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _documentsCard(v)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _registrationCard(v)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 180, child: _specsCard(v)),
            if (v.driverName != null && v.driverName!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 240, child: _driverCard(v)),
            ],
            if (hasGps) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 280, child: _gpsCard(v)),
            ],
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 320, child: _tripsCard(v, loading)),
            if (v.notes != null && v.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 360,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(v.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 90, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
        ],
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _statusCard(Vehicle v) {
    final color = v.statusColor;
    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(iconForVehicleType(v.type), size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.plate,
                    style: AppType.number(20, color: AppColors.textNavy(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (v.description != v.plate) ...[
                  const SizedBox(height: 2),
                  Text(v.description, style: AppType.body(13, color: kMuted)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(label: v.statusLabel, color: color),
                    if (v.type != null && v.type!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      StatusPill(label: v.type!, color: kPrimary),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsCard(Vehicle v) {
    return _SectionCard(
      title: 'Compliance (${v.documents.length})',
      eyebrow: 'Statutory documents',
      icon: Icons.verified_outlined,
      children: v.documents.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No statutory documents recorded.',
                    style: AppType.body(14, color: kMuted)),
              )
            ]
          : [
              for (var i = 0; i < v.documents.length; i++) ...[
                _DocumentRow(doc: v.documents[i]),
                if (i != v.documents.length - 1) const Divider(height: 18),
              ],
            ],
    );
  }

  Widget _registrationCard(Vehicle v) {
    return _SectionCard(
      title: 'Registration & Identity',
      eyebrow: 'Details',
      icon: Icons.badge_outlined,
      children: [
        _InfoRow(label: 'Make', value: v.make ?? '—'),
        _InfoRow(label: 'Model', value: v.modelName ?? '—'),
        if (v.year != null) _InfoRow(label: 'Year', value: v.year.toString()),
        if (v.type != null && v.type!.isNotEmpty) _InfoRow(label: 'Type', value: v.type!),
        if (v.color != null && v.color!.isNotEmpty) _InfoRow(label: 'Colour', value: v.color!),
        if (v.chassisNumber != null && v.chassisNumber!.isNotEmpty)
          _InfoRow(label: 'Chassis no.', value: v.chassisNumber!),
        if (v.engineNumber != null && v.engineNumber!.isNotEmpty)
          _InfoRow(label: 'Engine no.', value: v.engineNumber!),
        if (v.ownerName != null && v.ownerName!.isNotEmpty)
          _InfoRow(label: 'Owner', value: v.ownerName!),
      ],
    );
  }

  Widget _specsCard(Vehicle v) {
    final fuel = v.fuelType == null
        ? null
        : '${_titleCase(v.fuelType!)}'
            '${v.fuelTankCapacityL != null ? ' · ${v.fuelTankCapacityL} L tank' : ''}';
    return _SectionCard(
      title: 'Specifications',
      eyebrow: 'Capacity & service',
      icon: Icons.tune_rounded,
      children: [
        if (v.mileageKm != null) _InfoRow(label: 'Mileage', value: '${_thousands(v.mileageKm!)} km'),
        if (v.payloadTons != null)
          _InfoRow(label: 'Payload', value: '${_trimDouble(v.payloadTons!)} t'),
        if (fuel != null) _InfoRow(label: 'Fuel', value: fuel),
        if (v.nextServiceDate != null) ...[
          const Divider(height: 22),
          _InfoRow(label: 'Next service', value: formatDate(v.nextServiceDate)),
        ],
      ],
    );
  }

  Widget _driverCard(Vehicle v) {
    return _SectionCard(
      title: 'Assigned Driver',
      eyebrow: 'Personnel',
      icon: Icons.person_outline_rounded,
      children: [
        _InfoRow(label: 'Name', value: v.driverName!),
        if (v.driverPhone != null && v.driverPhone!.isNotEmpty)
          _InfoRow(label: 'Phone', value: v.driverPhone!),
      ],
    );
  }

  Widget _gpsCard(Vehicle v) {
    return _SectionCard(
      title: 'Last Known Position',
      eyebrow: 'GPS',
      icon: Icons.location_on_outlined,
      children: [
        if (v.gpsLocationName != null && v.gpsLocationName!.isNotEmpty)
          _InfoRow(label: 'Location', value: v.gpsLocationName!),
        _InfoRow(
          label: 'Coordinates',
          value: '${v.gpsLat!.toStringAsFixed(5)}, ${v.gpsLng!.toStringAsFixed(5)}',
        ),
        if (v.gpsLastSeen != null)
          _InfoRow(label: 'Last seen', value: formatDateTime(v.gpsLastSeen!)),
      ],
    );
  }

  Widget _tripsCard(Vehicle v, bool loading) {
    return _SectionCard(
      title: 'Recent Trips (${v.trips.length})',
      eyebrow: 'History',
      icon: Icons.route_outlined,
      children: v.trips.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  loading ? 'Loading trips…' : 'No recent trips for this vehicle.',
                  style: AppType.body(14, color: kMuted),
                ),
              )
            ]
          : v.trips.map((t) {
              final color = statusColor(t.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.tripNumber ?? 'Trip #${t.id}',
                              style: AppType.body(13,
                                  weight: FontWeight.w700,
                                  color: AppColors.textPrimary(context))),
                          const SizedBox(height: 2),
                          if (t.routeFrom != null || t.routeTo != null)
                            Text('${t.routeFrom ?? '—'} → ${t.routeTo ?? '—'}',
                                style: AppType.body(11.5, color: kMuted)),
                          Text(formatDate(t.departureDate),
                              style: AppType.body(11, color: kMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(label: _titleCase(t.status), color: color),
                  ],
                ),
              );
            }).toList(),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Group digits with thousands separators (e.g. 124500 → "124,500").
  static String _thousands(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Drop a trailing ".0" so payloads read "30" not "30.0", keep "12.5".
  static String _trimDouble(double d) =>
      d == d.roundToDouble() ? d.toInt().toString() : d.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail widgets
// ─────────────────────────────────────────────────────────────────────────────

/// One statutory document row: label + expiry date, with a tinted days-to-expiry
/// pill that turns amber when due soon and red when overdue.
class _DocumentRow extends StatelessWidget {
  final VehicleDocument doc;
  const _DocumentRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final color = doc.expired
        ? kDanger
        : doc.expiringSoon
            ? kWarning
            : kSuccess;
    final days = doc.days;
    final pill = doc.expired
        ? '${days.abs()}d overdue'
        : days == 0
            ? 'Today'
            : '${days}d left';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.label,
                    style: AppType.body(13.5,
                        weight: FontWeight.w600, color: AppColors.textPrimary(context))),
                const SizedBox(height: 2),
                Text(formatDate(doc.expiry), style: AppType.body(12, color: kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: pill, color: color),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, this.eyebrow, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.brand),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label,
                style: AppType.body(12.5, color: kMuted, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppType.body(13.5,
                  weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}
