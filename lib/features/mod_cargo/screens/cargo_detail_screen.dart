import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../cargo_service.dart';
import '../models/cargo.dart';
import 'cargo_screen.dart' show cargoStatusColor, cargoTypeColor, hexColor, formatWeight;

/// Detail view for a single cargo consignment. Shows an overview card, a
/// freight-details card, the consignee, and — when present — a status-change
/// timeline built from `cargo_status_logs`.
class CargoDetailScreen extends StatefulWidget {
  final int cargoId;
  final CargoService service;

  const CargoDetailScreen({
    super.key,
    required this.cargoId,
    required this.service,
  });

  @override
  State<CargoDetailScreen> createState() => _CargoDetailScreenState();
}

class _CargoDetailScreenState extends State<CargoDetailScreen> {
  late Future<Cargo> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchCargoItem(widget.cargoId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchCargoItem(widget.cargoId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cargo>(
      future: _future,
      builder: (context, snapshot) {
        final cargo = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(cargo),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Cargo? cargo) {
    return AppGradientHeader(
      eyebrow: 'Cargo',
      title: cargo?.cargoNumber ?? 'Cargo',
      subtitle: cargo?.description,
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

  Widget _buildBody(AsyncSnapshot<Cargo> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final c = snapshot.data!;
    var delay = 0;
    int nextDelay() => (delay++ * 70).clamp(0, 300);

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: nextDelay(), child: _buildOverviewCard(c)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: nextDelay(), child: _buildFreightCard(c)),
            if (_hasConsignee(c)) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: nextDelay(), child: _buildConsigneeCard(c)),
            ],
            if (c.statusLogs.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: nextDelay(), child: _buildTimelineCard(c)),
            ],
            if (_hasNotes(c)) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: nextDelay(), child: _buildNotesCard(c)),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasConsignee(Cargo c) =>
      (c.consigneeName != null && c.consigneeName!.isNotEmpty) ||
      (c.consigneeContact != null && c.consigneeContact!.isNotEmpty) ||
      (c.clientName != null && c.clientName!.isNotEmpty);

  bool _hasNotes(Cargo c) =>
      (c.notes != null && c.notes!.isNotEmpty) ||
      (c.specialInstructions != null && c.specialInstructions!.isNotEmpty);

  Widget _buildOverviewCard(Cargo c) {
    final statusColor = cargoStatusColor(c);
    final typeColor = cargoTypeColor(c);
    return _SectionCard(
      title: 'Overview',
      eyebrow: 'Consignment',
      icon: Icons.inventory_2_outlined,
      children: [
        Row(
          children: [
            StatusPill(label: c.statusLabel, color: statusColor),
            const SizedBox(width: 8),
            StatusPill(label: c.typeLabel, color: typeColor),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                label: 'Weight',
                value: '${formatWeight(c.weightKg)} kg',
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Pieces',
                value: c.pieces != null ? c.pieces.toString() : '—',
              ),
            ),
            Expanded(
              child: _MiniStat(
                label: 'Volume',
                value: c.volumeM3 != null ? '${formatWeight(c.volumeM3!)} m³' : '—',
              ),
            ),
          ],
        ),
        const Divider(height: 22),
        _IconLine(icon: Icons.description_outlined, text: c.description),
        if (c.routeDescription.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.route_outlined, text: c.routeDescription),
        ],
        if (c.tripNumber != null && c.tripNumber!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.local_shipping_outlined,
            text: [
              c.tripNumber,
              if (c.driverName != null && c.driverName!.isNotEmpty) c.driverName,
              if (c.vehiclePlate != null && c.vehiclePlate!.isNotEmpty) c.vehiclePlate,
            ].whereType<String>().join('  ·  '),
          ),
        ],
        if (c.createdByName != null && c.createdByName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.badge_outlined, text: 'Logged by ${c.createdByName}'),
        ],
        if (c.createdAt != null) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.schedule_outlined, text: formatDateTime(c.createdAt!)),
        ],
      ],
    );
  }

  Widget _buildFreightCard(Cargo c) {
    final hasValue = c.declaredValue != null && c.declaredValue! > 0;
    return _SectionCard(
      title: 'Freight Details',
      eyebrow: 'Cargo',
      icon: Icons.scale_outlined,
      children: [
        if (c.packingType != null && c.packingType!.isNotEmpty)
          _IconLine(icon: Icons.inventory_outlined, text: 'Packing: ${c.packingType}'),
        if (c.origin != null && c.origin!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.trip_origin_outlined, text: 'Origin: ${c.origin}'),
        ],
        if (c.destination != null && c.destination!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.place_outlined, text: 'Destination: ${c.destination}'),
        ],
        if (hasValue) ...[
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.payments_outlined,
            text: 'Declared: ${c.currency ?? ''} ${formatWeight(c.declaredValue!)}'.trim(),
          ),
        ],
        if (c.packingType == null &&
            (c.origin == null || c.origin!.isEmpty) &&
            (c.destination == null || c.destination!.isEmpty) &&
            !hasValue)
          Text('No additional freight details recorded.',
              style: AppType.body(13, color: kMuted)),
      ],
    );
  }

  Widget _buildConsigneeCard(Cargo c) {
    return _SectionCard(
      title: 'Client & Consignee',
      eyebrow: 'Parties',
      icon: Icons.business_outlined,
      children: [
        if (c.clientName != null && c.clientName!.isNotEmpty)
          _IconLine(icon: Icons.apartment_outlined, text: c.clientName!),
        if (c.clientPhone != null && c.clientPhone!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.phone_outlined, text: c.clientPhone!),
        ],
        if (c.clientEmail != null && c.clientEmail!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.mail_outline_rounded, text: c.clientEmail!),
        ],
        if (c.consigneeName != null && c.consigneeName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.person_outline_rounded,
            text: 'Consignee: ${c.consigneeName}',
          ),
        ],
        if (c.consigneeContact != null && c.consigneeContact!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.contact_phone_outlined, text: c.consigneeContact!),
        ],
      ],
    );
  }

  Widget _buildTimelineCard(Cargo c) {
    return _SectionCard(
      title: 'Status Timeline',
      eyebrow: 'History',
      icon: Icons.timeline_outlined,
      children: List.generate(c.statusLogs.length, (i) {
        return _TimelineRow(
          log: c.statusLogs[i],
          isFirst: i == 0,
          isLast: i == c.statusLogs.length - 1,
        );
      }),
    );
  }

  Widget _buildNotesCard(Cargo c) {
    return _SectionCard(
      title: 'Notes',
      eyebrow: 'Memo',
      icon: Icons.notes_outlined,
      children: [
        if (c.specialInstructions != null && c.specialInstructions!.isNotEmpty) ...[
          Text('Special Instructions',
              style: AppType.body(12, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(c.specialInstructions!, style: AppType.body(14, height: 1.5)),
          if (c.notes != null && c.notes!.isNotEmpty) const SizedBox(height: 12),
        ],
        if (c.notes != null && c.notes!.isNotEmpty)
          Text(c.notes!, style: AppType.body(14, height: 1.5)),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 200, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 150, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 180, radius: 16),
        ],
      ),
    );
  }
}

/// A single node in the status-change timeline, with a connecting rail.
class _TimelineRow extends StatelessWidget {
  final CargoStatusLog log;
  final bool isFirst;
  final bool isLast;
  const _TimelineRow({required this.log, required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = (log.statusColor != null && log.statusColor!.isNotEmpty)
        ? hexColor(log.statusColor!)
        : kPrimary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(label: log.statusLabel, color: color),
                      const Spacer(),
                      if (log.createdAt != null)
                        Text(formatDate(log.createdAt),
                            style: AppType.body(11.5, color: kMuted)),
                    ],
                  ),
                  if (log.location != null && log.location!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: kMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(log.location!,
                              style: AppType.body(12.5, color: kMuted)),
                        ),
                      ],
                    ),
                  ],
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(log.notes!,
                        style: AppType.body(12.5,
                            color: AppColors.textPrimary(context), height: 1.4)),
                  ],
                  if (log.userName != null && log.userName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('by ${log.userName}',
                        style: AppType.body(11, color: kMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared detail widgets ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    this.eyebrow,
    required this.icon,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            eyebrow: eyebrow,
            icon: icon,
            accent: ModuleAccent.ops,
            trailing: trailing,
          ),
          ...children,
        ],
      ),
    );
  }
}

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
        Text(label, style: AppType.body(10.5, color: kMuted, weight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: AppType.number(15, color: valueColor ?? AppColors.textPrimary(context))),
      ],
    );
  }
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: kMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppType.body(13, color: kMuted))),
      ],
    );
  }
}
