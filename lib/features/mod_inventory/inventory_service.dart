import '../../core/api/api_client.dart';
import 'models/inventory_item.dart';

/// Talks to the `/staff/modules/inventory` endpoints (Module 16 —
/// InventoryController).
class InventoryService {
  final ApiClient _api;
  InventoryService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<InventoryItem>> fetchItems() async {
    final json = await _api.get('/staff/modules/inventory') as Map<String, dynamic>;
    return _unwrapList(json['items'])
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryItem> fetchItem(int id) async {
    final json = await _api.get('/staff/modules/inventory/$id') as Map<String, dynamic>;
    return InventoryItem.fromJson(json['item'] as Map<String, dynamic>);
  }
}
