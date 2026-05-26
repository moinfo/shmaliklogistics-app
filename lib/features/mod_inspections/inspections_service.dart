import '../../core/api/api_client.dart';
import 'models/inspection.dart';

/// Talks to the `/staff/modules/inspections` endpoints (Module #9 —
/// `Api\Staff\Modules\InspectionController`).
class InspectionsService {
  final ApiClient _api;
  InspectionsService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Inspection>> fetchInspections() async {
    final json = await _api.get('/staff/modules/inspections') as Map<String, dynamic>;
    return _unwrapList(json['inspections'])
        .map((e) => Inspection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Inspection> fetchInspection(int id) async {
    final json = await _api.get('/staff/modules/inspections/$id') as Map<String, dynamic>;
    return Inspection.fromJson(json['inspection'] as Map<String, dynamic>);
  }
}
