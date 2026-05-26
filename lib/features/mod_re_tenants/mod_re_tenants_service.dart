import '../../core/api/api_client.dart';
import 'models/tenant.dart';

/// The tenants list payload: rows plus the sibling stats/enum maps the backend
/// returns alongside the paginator (`stats`, `types`, `statuses`).
class TenantsPayload {
  final List<TenantRow> tenants;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> types;
  final Map<String, dynamic> statuses;

  TenantsPayload({
    required this.tenants,
    this.stats = const {},
    this.types = const {},
    this.statuses = const {},
  });

  int get total => (stats['total'] as num?)?.toInt() ?? tenants.length;
  int get active => (stats['active'] as num?)?.toInt() ?? 0;
  int get companies => (stats['companies'] as num?)?.toInt() ?? 0;
}

/// Talks to the `/staff/modules/real-estate/tenants` endpoints
/// (RealEstateController). Read-only.
class ModReTenantsService {
  final ApiClient _api;
  ModReTenantsService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `mod_vehicles` / `mod_drivers` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic raw) =>
      raw is Map<String, dynamic> ? raw : const {};

  Future<TenantsPayload> fetchTenants({
    String? search,
    String? status,
    String? type,
  }) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (type != null && type.isNotEmpty) query['type'] = type;

    final path = query.isEmpty
        ? '/staff/modules/real-estate/tenants'
        : '/staff/modules/real-estate/tenants?'
            '${query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final json = await _api.get(path) as Map<String, dynamic>;
    return TenantsPayload(
      tenants: _unwrapList(json['tenants'])
          .map((e) => TenantRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: _asMap(json['stats']),
      types: _asMap(json['types']),
      statuses: _asMap(json['statuses']),
    );
  }

  Future<TenantDetail> fetchTenant(int id) async {
    final json =
        await _api.get('/staff/modules/real-estate/tenants/$id') as Map<String, dynamic>;
    return TenantDetail.fromJson(
      json['tenant'] as Map<String, dynamic>,
      leases: _unwrapList(json['leases']),
    );
  }
}