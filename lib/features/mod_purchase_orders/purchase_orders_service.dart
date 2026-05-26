import '../../core/api/api_client.dart';
import 'models/purchase_order.dart';

/// Talks to the staff Purchase Orders module endpoints
/// (`/staff/modules/purchase-orders`).
///
/// Mirrors the structure of the other module services (see
/// `features/mod_permits/permits_service.dart`): unwraps both the plain list
/// shape `{ "purchase_orders": [...] }` and the paginated
/// `{ "purchase_orders": { "data": [...] } }`.
class PurchaseOrdersService {
  final ApiClient _api;
  PurchaseOrdersService(this._api);

  static const String _base = '/staff/modules/purchase-orders';

  /// All purchase orders, newest first — `GET /staff/modules/purchase-orders`.
  Future<List<PurchaseOrder>> fetchPurchaseOrders() async {
    final json = await _api.get(_base) as Map<String, dynamic>;
    final raw = json['purchase_orders'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data
        .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A single purchase order with its line items —
  /// `GET /staff/modules/purchase-orders/{id}`.
  Future<PurchaseOrder> fetchPurchaseOrder(int id) async {
    final json = await _api.get('$_base/$id') as Map<String, dynamic>;
    return PurchaseOrder.fromJson(
        json['purchase_order'] as Map<String, dynamic>);
  }
}
