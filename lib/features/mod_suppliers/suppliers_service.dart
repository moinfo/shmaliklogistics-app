import '../../core/api/api_client.dart';
import 'models/supplier.dart';

/// Talks to the staff Suppliers module endpoints
/// (`/staff/modules/suppliers`).
///
/// Mirrors the structure of the other module services (see
/// `features/mod_purchase_orders/purchase_orders_service.dart`): unwraps both
/// the plain list shape `{ "suppliers": [...] }` and the paginated
/// `{ "suppliers": { "data": [...] } }`.
class SuppliersService {
  final ApiClient _api;
  SuppliersService(this._api);

  static const String _base = '/staff/modules/suppliers';

  /// All suppliers, newest first — `GET /staff/modules/suppliers`.
  Future<List<Supplier>> fetchSuppliers() async {
    final json = await _api.get(_base) as Map<String, dynamic>;
    final raw = json['suppliers'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data
        .map((e) => Supplier.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A single supplier — `GET /staff/modules/suppliers/{id}`.
  Future<Supplier> fetchSupplier(int id) async {
    final json = await _api.get('$_base/$id') as Map<String, dynamic>;
    return Supplier.fromJson(json['supplier'] as Map<String, dynamic>);
  }
}
