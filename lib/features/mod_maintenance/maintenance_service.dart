import '../../core/api/api_client.dart';
import 'models/service_record.dart';

/// Talks to the staff `/staff/modules/maintenance` endpoints
/// (Module #5 — vehicle servicing records). Read-only.
class MaintenanceService {
  MaintenanceService(this._api);
  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<ServiceRecord>> fetchRecords() async {
    final json = await _api.get('/staff/modules/maintenance') as Map<String, dynamic>;
    return _unwrapList(json['maintenance'])
        .map((e) => ServiceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceRecord> fetchRecord(int id) async {
    final json = await _api.get('/staff/modules/maintenance/$id') as Map<String, dynamic>;
    return ServiceRecord.fromJson(json['record'] as Map<String, dynamic>);
  }
}
