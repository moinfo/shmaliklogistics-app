/// A procurement supplier, as returned by `GET /staff/modules/suppliers`
/// and `/suppliers/{id}`.
///
/// Mirrors the payload shaped by `Api\Staff\Modules\SupplierController`
/// (which flattens the `Supplier` model, adds a category label/color and a
/// derived active/inactive status, and on detail includes notes + creator).
class Supplier {
  final int id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? tinNumber;
  final String? category;
  final String? categoryLabel;
  final int categoryColorValue;
  final bool isActive;
  final String status;
  final String statusLabel;
  final int purchaseOrdersCount;
  final String? notes;
  final String? createdByName;
  final DateTime? createdAt;

  const Supplier({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.tinNumber,
    this.category,
    this.categoryLabel,
    required this.categoryColorValue,
    required this.isActive,
    required this.status,
    required this.statusLabel,
    required this.purchaseOrdersCount,
    this.notes,
    this.createdByName,
    this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        id: j['id'] as int? ?? 0,
        name: j['name'] as String? ?? '—',
        contactName: j['contact_name'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
        tinNumber: j['tin_number'] as String?,
        category: j['category'] as String?,
        categoryLabel: j['category_label'] as String?,
        categoryColorValue: _hexColor(j['category_color'] as String?),
        isActive: j['is_active'] as bool? ?? false,
        status: j['status'] as String? ?? 'inactive',
        statusLabel: j['status_label'] as String? ??
            ((j['is_active'] as bool? ?? false) ? 'Active' : 'Inactive'),
        purchaseOrdersCount:
            int.tryParse((j['purchase_orders_count'] ?? 0).toString()) ?? 0,
        notes: j['notes'] as String?,
        createdByName: j['created_by_name'] as String?,
        createdAt: _date(j['created_at']),
      );

  /// Status pill color: green when active, neutral slate when inactive.
  int get statusColorValue => isActive ? 0xFF0E9F6E : 0xFF94A3B8;

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  /// Parses a `#RRGGBB` hex string into an ARGB int (opaque). Falls back to the
  /// neutral slate used by the "other" category.
  static int _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return 0xFF94A3B8;
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return 0xFF94A3B8;
    return cleaned.length <= 6 ? 0xFF000000 | value : value;
  }
}
