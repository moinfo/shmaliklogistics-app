import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/driver_alert.dart';
import '../../../core/models/trip.dart';
import '../../../core/services/auth_storage.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/theme_notifier.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service;
  late final AuthStorage _storage;

  DashboardData? _data;
  bool _loading = true;
  String? _error;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _storage = AuthStorage();
    _service = DashboardService(ApiClient(_storage));
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.fetchDashboard();
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load dashboard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.manrope()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E0800),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.logout();
    await _storage.clearToken();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildShimmer()
                : _error != null
                    ? _buildError()
                    : _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final driver = _data?.driver;
    final initials = driver != null
        ? driver.name.split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '';

    final vehicleLine = driver?.vehicle != null
        ? '${driver!.vehicle!.plate}  ·  ${driver.vehicle!.make}'
        : 'Driver Portal';

    return AppGradientHeader(
      eyebrow: 'Driver',
      subtitle: 'Welcome back,',
      title: driver != null ? driver.name : _greeting(),
      trailing: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: _DriverAvatar(photoUrl: driver?.photoUrl, initials: initials),
        ),
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (_, mode, child) => HeaderIconButton(
            icon: mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: mode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            onTap: toggleTheme,
          ),
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Log out',
          onTap: _logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final data = _data!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          if (data.alerts.hasAlert)
            RevealOnLoad(
              child: Column(children: _buildAlertBanners(data.alerts.items)),
            ),
          RevealOnLoad(
            delayMs: data.alerts.hasAlert ? 60 : 0,
            child: _buildStatsRow(data.stats),
          ),
          const SizedBox(height: 24),
          RevealOnLoad(
            delayMs: 120,
            child: _buildTripSection(
              title: 'Active Trips',
              eyebrow: 'On the road',
              icon: Icons.local_shipping_rounded,
              trips: data.activeTrips,
              emptyMessage: 'No trips currently in progress.',
            ),
          ),
          const SizedBox(height: 8),
          RevealOnLoad(
            delayMs: 180,
            child: _buildTripSection(
              title: 'Upcoming Trips',
              eyebrow: 'Scheduled',
              icon: Icons.schedule_rounded,
              trips: data.upcomingTrips,
              emptyMessage: 'No trips scheduled for the near future.',
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTripSection({
    required String title,
    required String eyebrow,
    required IconData icon,
    required List<Trip> trips,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          eyebrow: eyebrow,
          icon: icon,
          accent: ModuleAccent.ops,
          trailing: _CountBadge(count: trips.length),
        ),
        if (trips.isEmpty)
          AppCard(child: AppEmpty(message: emptyMessage))
        else
          ...trips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TripCard(trip: t),
              )),
      ],
    );
  }

  List<Widget> _buildAlertBanners(List<DriverAlert> alerts) {
    return alerts.map((alert) {
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

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          accentColor: severityColor,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(severityIcon, color: severityColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: AppType.body(14, color: severityColor, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: AppType.body(12, color: kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  final route = switch (alert.kind) {
                    'inspection'    => '/inspection',
                    'check_in'      => '/check_in',
                    'trip_assigned' => '/trips',
                    _               => '/trips',
                  };
                  Navigator.pushNamed(context, route);
                },
                style: TextButton.styleFrom(
                  foregroundColor: severityColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: Text(alert.cta),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatsRow(DashboardStats stats) {
    final w = MediaQuery.sizeOf(context).width;
    final cardWidth = (w - 32 - 20) / 3;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: cardWidth,
          child: StatCard(
            label: 'Active',
            value: stats.activeTrips.toString(),
            icon: Icons.local_shipping_rounded,
            accent: ModuleAccent.ops,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: StatCard(
            label: 'Upcoming',
            value: stats.upcomingTrips.toString(),
            icon: Icons.schedule_rounded,
            accent: ModuleAccent.ops,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: StatCard(
            label: 'This Month',
            value: stats.completedMonth.toString(),
            icon: Icons.check_circle_rounded,
            accent: ModuleAccent.ops,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: AppError(message: _error!, onRetry: _load),
        ),
      ],
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() => const AppBottomNav(currentIndex: 0);

  // ── Shimmer ──────────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    final w = MediaQuery.sizeOf(context).width;
    final statWidth = (w - 32 - 20) / 3;
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < 3; i++)
                AppSkeleton.box(context, height: 96, width: statWidth, radius: 20),
            ],
          ),
          const SizedBox(height: 24),
          AppSkeleton.box(context, height: 22, width: 150, radius: 6),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 132, radius: 18),
          const SizedBox(height: 24),
          AppSkeleton.box(context, height: 22, width: 150, radius: 6),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 132, radius: 18),
        ],
      ),
    );
  }
}

// ── Section count badge ───────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: AppType.number(12, color: kPrimary),
      ),
    );
  }
}

// ── Trip card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(trip.status);

    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  trip.tripNumber,
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: trip.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RouteDot(color: kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.routeFrom,
                  style: AppType.body(13, color: AppColors.textPrimary(context), weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(width: 1.5, height: 12, color: AppColors.border(context)),
          ),
          Row(
            children: [
              _RouteDot(color: color, hollow: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.routeTo,
                  style: AppType.body(13, color: AppColors.textPrimary(context), weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (trip.departureDate != null) ...[
                Icon(Icons.calendar_today_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(trip.departureDate), style: AppType.body(11, color: kMuted)),
              ],
              if (trip.vehiclePlate != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.directions_car_rounded, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(trip.vehiclePlate!, style: AppType.body(11, color: kMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  final Color color;
  final bool hollow;
  const _RouteDot({required this.color, this.hollow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hollow ? AppColors.surface(context) : color,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  const _DriverAvatar({required this.photoUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    const border = BorderSide(color: Colors.white, width: 1.5);

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final fullUrl = '${ApiClient.storageUrl}$photoUrl';
      return ClipOval(
        child: Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(size, border),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _initialsCircle(size, border),
        ),
      );
    }
    return _initialsCircle(size, border);
  }

  Widget _initialsCircle(double size, BorderSide border) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.fromBorderSide(border.copyWith(
            color: Colors.white.withValues(alpha: 0.3))),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppType.display(16, color: Colors.white),
        ),
      ),
    );
  }
}
