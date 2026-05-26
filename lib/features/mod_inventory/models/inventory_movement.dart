/// A single stock movement (`inventory_movements` row, flattened by the API).
///
/// Returned inline under an item's `movements` array by the detail endpoint.
class InventoryMovement {
  final int id;
  final String type;
  final String typeLabel;
  final String? typeColor;
  final double quantity;
  final double? unitCost;
  final double? balanceAfter;
  final String? reference;
  final String? batchNumber;
  final String? vehiclePlate;
  final String? notes;
  final DateTime? createdAt;

  InventoryMovement({
    required this.id,
    required this.type,
    required this.typeLabel,
    this.typeColor,
    required this.quantity,
    this.unitCost,
    this.balanceAfter,
    this.reference,
    this.batchNumber,
    this.vehiclePlate,
    this.notes,
    this.createdAt,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> j) {
    return InventoryMovement(
      id: j['id'] ?? 0,
      type: (j['type'] ?? '').toString(),
      typeLabel: (j['type_label'] ?? j['type'] ?? '').toString(),
      typeColor: j['type_color'],
      quantity: double.tryParse((j['quantity'] ?? 0).toString()) ?? 0,
      unitCost: j['unit_cost'] != null
          ? double.tryParse(j['unit_cost'].toString())
          : null,
      balanceAfter: j['balance_after'] != null
          ? double.tryParse(j['balance_after'].toString())
          : null,
      reference: j['reference'],
      batchNumber: j['batch_number'],
      vehiclePlate: j['vehicle_plate'],
      notes: j['notes'],
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
    );
  }

  /// `true` for stock-in movements (positive balance change).
  bool get isInbound => type == 'in';
}
