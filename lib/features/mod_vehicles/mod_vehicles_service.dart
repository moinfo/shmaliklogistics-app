import '../../core/api/api_client.dart';
import 'models/vehicle.dart';

/// Talks to the `/staff/modules/vehicles` endpoints (VehicleController — the
/// "All Vehicles" fleet module). Read-only.
class ModVehiclesService {
  final ApiClient _api;
  ModVehiclesService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `mod_drivers` / `staff_finance` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final json = await _api.get('/staff/modules/vehicles') as Map<String, dynamic>;
    return _unwrapList(json['vehicles'])
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> fetchVehicle(int id) async {
    final json = await _api.get('/staff/modules/vehicles/$id') as Map<String, dynamic>;
    return Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>);
  }
}
