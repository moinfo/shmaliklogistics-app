/// A procurement purchase order, as returned by
/// `GET /staff/modules/purchase-orders` and `/purchase-orders/{id}`.
///
/// Mirrors the payload shaped by `Api\Staff\Modules\PurchaseOrderController`
/// (which flattens the `PurchaseOrder` model + its supplier, and on detail
/// includes the `PurchaseOrderItem` line items).
class PurchaseOrderItem {
  final int id;
  final int? inventoryItemId;
  final String? inventoryItemName;
  final String description;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double total;
  final double receivedQty;

  const PurchaseOrderItem({
    required this.id,
    this.inventoryItemId,
    this.inventoryItemName,
    required this.description,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.total,
    required this.receivedQty,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> j) => PurchaseOrderItem(
        id: j['id'] as int? ?? 0,
        inventoryItemId: j['inventory_item_id'] as int?,
        inventoryItemName: j['inventory_item_name'] as String?,
        description: j['description'] as String? ?? '',
        quantity: double.tryParse((j['quantity'] ?? 0).toString()) ?? 0,
        unit: j['unit'] as String?,
        unitPrice: double.tryParse((j['unit_price'] ?? 0).toString()) ?? 0,
        total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
        receivedQty: double.tryParse((j['received_qty'] ?? 0).toString()) ?? 0,
      );

  bool get isFullyReceived => receivedQty >= quantity && quantity > 0;
  bool get isPartiallyReceived => receivedQty > 0 && receivedQty < quantity;
}

class PurchaseOrder {
  final int id;
  final String poNumber;
  final int? supplierId;
  final String? supplierName;
  final String? supplierCategory;
  final String? supplierContact;
  final String? supplierPhone;
  final String? supplierEmail;
  final String status;
  final String statusLabel;
  final int statusColorValue;
  final DateTime? orderDate;
  final DateTime? expectedDate;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String? notes;
  final String? createdByName;
  final DateTime? createdAt;
  final List<PurchaseOrderItem> items;

  const PurchaseOrder({
    required this.id,
    required this.poNumber,
    this.supplierId,
    this.supplierName,
    this.supplierCategory,
    this.supplierContact,
    this.supplierPhone,
    this.supplierEmail,
    required this.status,
    required this.statusLabel,
    required this.statusColorValue,
    this.orderDate,
    this.expectedDate,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.createdByName,
    this.createdAt,
    this.items = const [],
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List? ?? [];
    return PurchaseOrder(
      id: j['id'] as int? ?? 0,
      poNumber: j['po_number'] as String? ?? '—',
      supplierId: j['supplier_id'] as int?,
      supplierName: j['supplier_name'] as String?,
      supplierCategory: j['supplier_category'] as String?,
      supplierContact: j['supplier_contact'] as String?,
      supplierPhone: j['supplier_phone'] as String?,
      supplierEmail: j['supplier_email'] as String?,
      status: j['status'] as String? ?? 'draft',
      statusLabel: j['status_label'] as String? ?? (j['status'] as String? ?? 'Draft'),
      statusColorValue: _hexColor(j['status_color'] as String?),
      orderDate: _date(j['order_date']),
      expectedDate: _date(j['expected_date']),
      subtotal: double.tryParse((j['subtotal'] ?? 0).toString()) ?? 0,
      taxAmount: double.tryParse((j['tax_amount'] ?? 0).toString()) ?? 0,
      total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      notes: j['notes'] as String?,
      createdByName: j['created_by_name'] as String?,
      createdAt: _date(j['created_at']),
      items: rawItems
          .map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  /// Parses a `#RRGGBB` hex string into an ARGB int (opaque). Falls back to the
  /// neutral slate used by the draft state.
  static int _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return 0xFF94A3B8;
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return 0xFF94A3B8;
    return cleaned.length <= 6 ? 0xFF000000 | value : value;
  }

  int get itemCount => items.length;

  /// True when every line item has been fully received.
  bool get allReceived =>
      items.isNotEmpty && items.every((i) => i.isFullyReceived);
}
