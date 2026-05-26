import '../../core/api/api_client.dart';
import '../../core/models/driver.dart';
import '../../core/models/driver_alert.dart';
import '../../core/models/trip.dart';

class DashboardStats {
  final int activeTrips;
  final int upcomingTrips;
  final int completedMonth;

  const DashboardStats({
    required this.activeTrips,
    required this.upcomingTrips,
    required this.completedMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        activeTrips: j['active_trips'] ?? 0,
        upcomingTrips: j['upcoming_trips'] ?? 0,
        completedMonth: j['completed_month'] ?? 0,
      );
}

class DashboardData {
  final Driver driver;
  final List<Trip> activeTrips;
  final List<Trip> upcomingTrips;
  final List<Trip> recentTrips;
  final DashboardStats stats;
  final AlertBundle alerts;
  final bool todayInspected;

  const DashboardData({
    required this.driver,
    required this.activeTrips,
    required this.upcomingTrips,
    required this.recentTrips,
    required this.stats,
    this.alerts = const AlertBundle(items: [], count: 0, hasAlert: false),
    this.todayInspected = false,
  });
}

class DashboardService {
  final ApiClient _api;
  DashboardService(this._api);

  Future<DashboardData> fetchDashboard() async {
    final json = await _api.get('/driver/dashboard') as Map<String, dynamic>;

    final driver = Driver.fromJson(json['driver'] as Map<String, dynamic>);

    List<Trip> parseTrips(dynamic raw) {
      if (raw == null) return [];
      return (raw as List).map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    }

    return DashboardData(
      driver: driver,
      activeTrips: parseTrips(json['active_trips']),
      upcomingTrips: parseTrips(json['upcoming_trips']),
      recentTrips: parseTrips(json['recent_trips']),
      stats: DashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      alerts: json['alerts'] != null
          ? AlertBundle.fromJson(json['alerts'] as Map<String, dynamic>)
          : AlertBundle.empty(),
      todayInspected: json['today_inspection'] != null,
    );
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // Always proceed with local logout even if the server call fails.
    }
  }
}