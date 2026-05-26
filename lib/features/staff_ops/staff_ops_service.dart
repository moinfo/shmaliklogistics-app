import '../../core/api/api_client.dart';
import '../../core/models/driver_alert.dart';
import '../../core/models/trip.dart';
import 'models/fleet_vehicle.dart';

/// Talks to the staff Operations endpoints (`/staff/ops/*`).
///
/// Mirrors the structure of the driver-facing services (see
/// `features/trips/trip_service.dart` and `features/dashboard/dashboard_service.dart`).
class StaffOpsService {
  final ApiClient _api;
  StaffOpsService(this._api);

  /// Live / active trips for ops dispatch — `GET /staff/ops/trips`.
  ///
  /// Response: `{ "trips": [ {...}, ... ] }` (also accepts a paginated
  /// `{ "trips": { "data": [...] } }` shape, like the driver endpoints).
  Future<List<Trip>> fetchTrips() async {
    final json = await _api.get('/staff/ops/trips') as Map<String, dynamic>;
    final raw = json['trips'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fleet status — `GET /staff/ops/fleet`.
  ///
  /// Response: `{ "vehicles": [ {...}, ... ] }`.
  Future<List<FleetVehicle>> fetchFleet() async {
    final json = await _api.get('/staff/ops/fleet') as Map<String, dynamic>;
    final raw = json['vehicles'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data.map((e) => FleetVehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Operational alerts — `GET /staff/ops/alerts`.
  ///
  /// Response: `{ "alerts": { "items": [...], "count": n, "has_alert": bool } }`.
  Future<AlertBundle> fetchAlerts() async {
    final json = await _api.get('/staff/ops/alerts') as Map<String, dynamic>;
    final alerts = json['alerts'] as Map<String, dynamic>?;
    if (alerts == null) return AlertBundle.empty();
    return AlertBundle.fromJson(alerts);
  }
}
