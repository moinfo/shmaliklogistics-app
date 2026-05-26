import '../../core/api/api_client.dart';
import 'models/cargo.dart';

/// Talks to the `/staff/modules/cargo` endpoints (Module #7 —
/// `Api\Staff\Modules\CargoController`).
class CargoService {
  final ApiClient _api;
  CargoService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Cargo>> fetchCargo() async {
    final json = await _api.get('/staff/modules/cargo') as Map<String, dynamic>;
    return _unwrapList(json['cargo'])
        .map((e) => Cargo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cargo> fetchCargoItem(int id) async {
    final json = await _api.get('/staff/modules/cargo/$id') as Map<String, dynamic>;
    return Cargo.fromJson(json['cargo'] as Map<String, dynamic>);
  }
}
