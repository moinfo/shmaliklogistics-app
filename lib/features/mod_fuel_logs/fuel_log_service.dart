import '../../core/api/api_client.dart';
import 'models/fuel_log.dart';

/// Read-only Fuel Logs API client for the staff mobile app.
///
/// Hits `/staff/modules/fuel-logs`. Unwraps both the plain list shape
/// (`{ "fuel_logs": [...] }`) and the paginated wrapper
/// (`{ "fuel_logs": {"data": [...]} }`), like `trip_service.dart`.
class FuelLogService {
  FuelLogService(this._api);

  final ApiClient _api;

  Future<FuelLogBundle> fetchFuelLogs() async {
    final json = await _api.get('/staff/modules/fuel-logs') as Map<String, dynamic>;

    final raw = json['fuel_logs'];
    final List list = raw is Map<String, dynamic> ? (raw['data'] as List? ?? []) : (raw as List? ?? []);

    final logs = list.map((e) => FuelLog.fromJson(e as Map<String, dynamic>)).toList();

    final statsJson = json['stats'] as Map<String, dynamic>?;
    final stats = statsJson != null
        ? FuelStats.fromJson(statsJson)
        : _fallbackStats(logs);

    return FuelLogBundle(logs: logs, stats: stats);
  }

  /// Derives totals from the page when the server omits a `stats` block.
  FuelStats _fallbackStats(List<FuelLog> logs) {
    double liters = 0;
    double cost = 0;
    for (final l in logs) {
      liters += l.liters;
      cost += l.totalCost;
    }
    return FuelStats(
      totalLiters: liters,
      totalCost: cost,
      monthLiters: liters,
      monthCost: cost,
      logCount: logs.length,
    );
  }
}
