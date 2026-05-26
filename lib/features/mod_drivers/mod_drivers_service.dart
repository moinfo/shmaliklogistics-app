import '../../core/api/api_client.dart';
import 'models/driver.dart';

/// Talks to the `/staff/modules/drivers` endpoints (Module 1 — DriverController).
class ModDriversService {
  final ApiClient _api;
  ModDriversService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Driver>> fetchDrivers() async {
    final json = await _api.get('/staff/modules/drivers') as Map<String, dynamic>;
    return _unwrapList(json['drivers'])
        .map((e) => Driver.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Driver> fetchDriver(int id) async {
    final json = await _api.get('/staff/modules/drivers/$id') as Map<String, dynamic>;
    return Driver.fromJson(json['driver'] as Map<String, dynamic>);
  }
}
