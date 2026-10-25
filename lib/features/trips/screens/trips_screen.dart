import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../trip_service.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  late final TripService _service;
  late Future<List<Trip>> _future;
  String _filter = 'all';
  final int _navIndex = 1;

  static const _filters = [
    ('all',        'All'),
    ('in_transit', 'In Transit'),
    ('planned',    'Planned'),
    ('delivered',  'Delivered'),
    ('completed',  'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _service = TripService(ApiClient(AuthStorage()));
    _future = _service.fetchTrips();
  }

  void _refresh() => setState(() => _future = _service.fetchTrips());

  List<Trip> _applyFilter(List<Trip> trips) {
    if (_filter == 'all') return trips;
    return trips.where((t) => t.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterChips(),
          Expanded(child: _buildList()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AppGradientHeader(
      eyebrow: 'My trips',
      title: 'Trips',
      gradient: ModuleAccent.ops.colors,
      trailing: FutureBuilder<List<Trip>>(
        future: _future,
        builder: (_, snap) {
          final count = snap.data?.length ?? 0;
          final label = snap.hasData
              ? '$count trip${count == 1 ? '' : 's'}'
              : '...';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: AppType.number(13, color: Colors.white)),
            ),
          );
        },
      ),
      actions: [
        HeaderIconButton(
            icon: Icons.refresh_rounded, onTap: _refresh, tooltip: 'Refresh'),
      ],
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filters.map((f) {
            final (value, label) = f;
            final selected = _filter == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: ModuleAccent.ops.colors,
                          )
                        : null,
                    color: selected ? null : AppColors.chipUnselected(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : AppColors.border(context),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppType.body(12.5,
                        weight: FontWeight.w700,
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

  // ── Trip list ─────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return FutureBuilder<List<Trip>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _refresh);
        }

        final trips = _applyFilter(snapshot.data ?? []);

        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _refresh(),
          child: trips.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: trips.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RevealOnLoad(
                      delayMs: (i * 60).clamp(0, 300),
                      child: _TripCard(trip: trips[i], service: _service),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 132, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: AppEmpty(
            icon: Icons.local_shipping_outlined,
            message: _filter == 'all'
                ? 'No trips found.\nYour assigned trips will appear here.'
                : 'No $_filter trips at the moment.',
          ),
        ),
      ],
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() => const AppBottomNav(currentIndex: 1);
}

// ── Trip card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  final TripService service;
  const _TripCard({required this.trip, required this.service});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);

    return AppCard(
      accentColor: color,
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => TripDetailScreen(tripId: trip.id, service: service),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip.tripNumber,
                  style: AppType.number(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
                Text(formatDate(trip.departureDate),
                    style: AppType.body(11.5, color: kMuted)),
              ],
              if (trip.vehiclePlate != null) ...[
                const SizedBox(width: 14),
                const Icon(Icons.directions_car_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(trip.vehiclePlate!, style: AppType.body(11.5, color: kMuted)),
              ],
              const Spacer(),
              Text(
                'View details',
                style: AppType.body(11.5,
                    color: kPrimary, weight: FontWeight.w700),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, size: 14, color: kPrimary),
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
              Text(from,
                  style: AppType.body(13,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Text(to,
                  style: AppType.body(13,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
