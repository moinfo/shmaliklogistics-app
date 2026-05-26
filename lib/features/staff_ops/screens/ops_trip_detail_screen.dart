import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';

/// Read-only trip detail for ops staff.
///
/// Staff Ops has no dedicated trip-detail endpoint (see the implementation
/// contract); the live-trips list already carries everything we need, so this
/// screen renders the [Trip] passed in directly. No edit affordances are shown.
class OpsTripDetailScreen extends StatelessWidget {
  final Trip trip;
  const OpsTripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Trip detail',
            subtitle: 'Trip',
            title: trip.tripNumber,
            actions: [
              HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RevealOnLoad(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusPill(label: trip.statusLabel, color: color),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SectionHeader(title: 'Route', eyebrow: 'Lane', icon: Icons.route_rounded, accent: ModuleAccent.ops),
                        AppCard(
                          accentColor: color,
                          child: _RouteBody(trip: trip, color: color),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  RevealOnLoad(
                    delayMs: 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Trip Details', eyebrow: 'Manifest', icon: Icons.info_outline_rounded, accent: ModuleAccent.ops),
                        AppCard(
                          child: Column(
                            children: [
                              _InfoRow(label: 'Status', value: trip.statusLabel),
                              const _Divider(),
                              _InfoRow(label: 'Departure', value: formatDate(trip.departureDate)),
                              _InfoRow(label: 'Arrival', value: formatDate(trip.arrivalDate)),
                              if (trip.vehiclePlate != null) ...[
                                const _Divider(),
                                _InfoRow(label: 'Vehicle', value: trip.vehiclePlate!),
                              ],
                              if (trip.cargoDescription != null && trip.cargoDescription!.isNotEmpty) ...[
                                const _Divider(),
                                _InfoRow(label: 'Cargo', value: trip.cargoDescription!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trip.notes != null && trip.notes!.isNotEmpty)
                    RevealOnLoad(
                      delayMs: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 22),
                          SectionHeader(title: 'Notes', eyebrow: 'Remarks', icon: Icons.notes_rounded, accent: ModuleAccent.ops),
                          AppCard(
                            child: Text(
                              trip.notes!,
                              style: AppType.body(13, color: AppColors.textPrimary(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route body ─────────────────────────────────────────────────────────────────

class _RouteBody extends StatelessWidget {
  final Trip trip;
  final Color color;
  const _RouteBody({required this.trip, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(width: 14, height: 14, decoration: const BoxDecoration(shape: BoxShape.circle, color: kPrimary)),
            Container(width: 1.5, height: 26, color: AppColors.border(context)),
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface(context), border: Border.all(color: color, width: 2)),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FROM', style: AppType.eyebrow(size: 10, color: kMuted)),
              Text(trip.routeFrom, style: AppType.body(15, weight: FontWeight.w600, color: AppColors.textPrimary(context))),
              const SizedBox(height: 14),
              Text('TO', style: AppType.eyebrow(size: 10, color: kMuted)),
              Text(trip.routeTo, style: AppType.body(15, weight: FontWeight.w600, color: AppColors.textPrimary(context))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info row ─────────────────────────────────────────────────────────────────

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
          Text(label, style: AppType.body(13, color: kMuted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: AppColors.border(context)),
    );
  }
}
