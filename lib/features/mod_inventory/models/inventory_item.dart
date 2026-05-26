import 'inventory_movement.dart';

/// An inventory stock item (`inventory_items` row, flattened by the staff API).
///
/// The list endpoint returns the flat shape (`sku`, `quantity`,
/// `category_name`, `is_low_stock`, …); the detail endpoint returns the same
/// shape plus a `movements` array. [InventoryItem.fromJson] handles both.
class InventoryItem {
  final int id;
  final String name;
  final String? sku;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final double quantity;
  final String? unit;
  final double reorderLevel;
  final double unitCost;
  final String? location;
  final bool tracksSerials;
  final bool tracksBatch;
  final bool isActive;
  final bool isLowStock;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final List<InventoryMovement> movements;

  InventoryItem({
    required this.id,
    required this.name,
    this.sku,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.quantity,
    this.unit,
    required this.reorderLevel,
    required this.unitCost,
    this.location,
    required this.tracksSerials,
    required this.tracksBatch,
    required this.isActive,
    required this.isLowStock,
    required this.status,
    this.notes,
    this.createdAt,
    this.movements = const [],
  });

  factory InventoryItem.fromJson(Map<String, dynamic> j) {
    final rawMovements = j['movements'] as List? ?? const [];
    final quantity = _num(j['quantity'] ?? j['current_stock']);
    final reorder = _num(j['reorder_level']);

    return InventoryItem(
      id: j['id'] ?? 0,
      name: (j['name'] ?? '').toString(),
      sku: j['sku'] ?? j['part_number'],
      categoryId: j['category_id'],
      categoryName: j['category_name'],
      categoryColor: j['category_color'],
      quantity: quantity,
      unit: j['unit'],
      reorderLevel: reorder,
      unitCost: _num(j['unit_cost']),
      location: j['location'],
      tracksSerials: j['tracks_serials'] == true,
      tracksBatch: j['tracks_batch'] == true,
      isActive: j['is_active'] == null ? true : j['is_active'] == true,
      // Trust the server flag when present, otherwise derive it locally.
      isLowStock: j['is_low_stock'] == true ||
          (j['is_low_stock'] == null && reorder > 0 && quantity <= reorder),
      status: (j['status'] ?? 'active').toString(),
      notes: j['notes'],
      createdAt: _date(j['created_at']),
      movements: rawMovements
          .map((e) => InventoryMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _num(dynamic v) => double.tryParse((v ?? 0).toString()) ?? 0;

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Quantity rendered without trailing zeros when it is a whole number.
  String get quantityLabel => _fmtQty(quantity);

  /// Reorder threshold rendered the same way.
  String get reorderLabel => _fmtQty(reorderLevel);

  static String _fmtQty(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
