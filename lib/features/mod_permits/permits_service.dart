import '../../core/api/api_client.dart';
import 'models/permit.dart';

/// Talks to the staff Permits module endpoints (`/staff/modules/permits`).
///
/// Mirrors the structure of the other module services (see
/// `features/staff_ops/staff_ops_service.dart`): unwraps both the plain list
/// shape `{ "permits": [...] }` and the paginated `{ "permits": { "data": [...] } }`.
class PermitsService {
  final ApiClient _api;
  PermitsService(this._api);

  static const String _base = '/staff/modules/permits';

  /// All permits, newest first — `GET /staff/modules/permits`.
  Future<List<Permit>> fetchPermits() async {
    final json = await _api.get(_base) as Map<String, dynamic>;
    final raw = json['permits'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data.map((e) => Permit.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// A single permit — `GET /staff/modules/permits/{id}`.
  Future<Permit> fetchPermit(int id) async {
    final json = await _api.get('$_base/$id') as Map<String, dynamic>;
    return Permit.fromJson(json['permit'] as Map<String, dynamic>);
  }
}
