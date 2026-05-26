import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../customer_service.dart';
import '../models/cargo.dart';
import 'customer_status_colors.dart';
import 'customer_widgets.dart';

/// Read-only trip detail for the customer portal.
class CustomerTripDetailScreen extends StatefulWidget {
  final int tripId;
  final CustomerService service;

  const CustomerTripDetailScreen({
    super.key,
    required this.tripId,
    required this.service,
  });

  @override
  State<CustomerTripDetailScreen> createState() => _CustomerTripDetailScreenState();
}

class _CustomerTripDetailScreenState extends State<CustomerTripDetailScreen> {
  late Future<CustomerTripDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchTrip(widget.tripId);
  }

  void _reload() => setState(() => _future = widget.service.fetchTrip(widget.tripId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerTripDetail>(
      future: _future,
      builder: (context, snapshot) {
        final trip = snapshot.data?.trip;
        final color = trip != null ? statusColor(trip.status) : kPrimary;

        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              CustomerDetailHeader(
                title: trip?.tripNumber ?? 'Trip Detail',
                onRefresh: _reload,
                subtitle: trip != null
                    ? CustomerStatusBadge(label: trip.statusLabel, color: color, small: true)
                    : null,
              ),
              Expanded(child: () {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _DetailSkeleton();
                }
                if (snapshot.hasError) {
                  return CustomerErrorView(message: snapshot.error.toString(), onRetry: _reload);
                }
                final detail = snapshot.data!;
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RevealOnLoad(
                          delayMs: 0,
                          child: _RouteCard(trip: detail.trip),
                        ),
                        const SizedBox(height: 14),
                        RevealOnLoad(
                          delayMs: 80,
                          child: CustomerSectionCard(
                            title: 'Trip Details',
                            eyebrow: 'Overview',
                            icon: Icons.info_outline_rounded,
                            children: [
                              CustomerInfoRow(label: 'Status', value: detail.trip.statusLabel),
                              CustomerInfoRow(label: 'Departure', value: formatDate(detail.trip.departureDate)),
                              CustomerInfoRow(label: 'Arrival', value: formatDate(detail.trip.arrivalDate)),
                              if (detail.trip.vehiclePlate != null)
                                CustomerInfoRow(label: 'Vehicle', value: detail.trip.vehiclePlate!),
                            ],
                          ),
                        ),
                        if (detail.trip.cargoDescription != null &&
                            detail.trip.cargoDescription!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          RevealOnLoad(
                            delayMs: 160,
                            child: CustomerSectionCard(
                              title: 'Cargo Notes',
                              eyebrow: 'Notes',
                              icon: Icons.notes_rounded,
                              children: [
                                Text(detail.trip.cargoDescription!,
                                    style: AppType.body(14, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        RevealOnLoad(
                          delayMs: 240,
                          child: CustomerSectionCard(
                            title: 'My Cargo (${detail.cargo.length})',
                            eyebrow: 'Shipment',
                            icon: Icons.inventory_2_outlined,
                            children: detail.cargo.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text('No cargo recorded for this trip.',
                                          style: AppType.body(14, color: kMuted)),
                                    )
                                  ]
                                : detail.cargo.map((c) => _CargoTile(cargo: c)).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }()),
            ],
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Trip trip;
  const _RouteCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);
    return AppCard(
      accentColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: StatusPill(label: trip.statusLabel, color: color),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FROM', style: AppType.eyebrow(size: 9.5, color: kMuted)),
                    const SizedBox(height: 3),
                    Text(trip.routeFrom,
                        style: AppType.display(18, color: AppColors.textNavy(context))),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward_rounded, color: kPrimary, size: 20),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TO', style: AppType.eyebrow(size: 9.5, color: kMuted)),
                    const SizedBox(height: 3),
                    Text(trip.routeTo,
                        textAlign: TextAlign.right,
                        style: AppType.display(18, color: AppColors.textNavy(context))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching the trip-detail layout.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          AppSkeleton.box(context, height: 110, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 150, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 130, radius: 16),
        ],
      ),
    );
  }
}

class _CargoTile extends StatelessWidget {
  final Cargo cargo;
  const _CargoTile({required this.cargo});

  @override
  Widget build(BuildContext context) {
    final color = cargoStatusColor(cargo.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(cargo.cargoNumber,
                          style: AppType.body(13, weight: FontWeight.w600)),
                    ),
                    CustomerStatusBadge(label: cargo.statusLabel, color: color, small: true),
                  ],
                ),
                if (cargo.description != null && cargo.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(cargo.description!,
                      style: AppType.body(12, color: kMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
