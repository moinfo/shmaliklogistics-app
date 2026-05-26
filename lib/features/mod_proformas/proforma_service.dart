import '../../core/api/api_client.dart';
import 'models/proforma.dart';

/// Talks to the read-only `/staff/modules/proformas` endpoints
/// (Api\Staff\Modules\ProformaController).
class ProformaService {
  ProformaService(this._api);

  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`) or
  /// wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Proforma>> fetchProformas() async {
    final json = await _api.get('/staff/modules/proformas') as Map<String, dynamic>;
    return _unwrapList(json['proformas'])
        .map((e) => Proforma.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Proforma> fetchProforma(int id) async {
    final json = await _api.get('/staff/modules/proformas/$id') as Map<String, dynamic>;
    return Proforma.fromJson(json['proforma'] as Map<String, dynamic>);
  }
}
