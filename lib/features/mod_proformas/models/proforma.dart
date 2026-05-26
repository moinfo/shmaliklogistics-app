/// A single line item on a proforma (mirrors `billing_items` columns).
class ProformaItem {
  final int id;
  final String description;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double total;

  ProformaItem({
    required this.id,
    required this.description,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory ProformaItem.fromJson(Map<String, dynamic> j) => ProformaItem(
        id: j['id'] ?? 0,
        description: j['description'] ?? '',
        quantity: double.tryParse((j['quantity'] ?? 1).toString()) ?? 0,
        unit: j['unit'],
        unitPrice: double.tryParse((j['unit_price'] ?? 0).toString()) ?? 0,
        total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      );
}

/// A proforma (`billing_documents` row of type `proforma`).
///
/// The list endpoint returns the flattened summary shape (`client_name`,
/// `total`, `status_label`, …); the detail endpoint adds line items, trip
/// context and ledger fields. [Proforma.fromJson] handles both.
class Proforma {
  final int id;
  final String documentNumber;
  final int? clientId;
  final String? clientName;
  final String? clientCompany;
  final String? clientEmail;
  final String? clientPhone;
  final String currency;
  final double subtotal;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String status;
  final String statusLabel;
  final String? statusColor;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? validUntil;
  final String? notes;
  final String? termsConditions;
  final String? tripNumber;
  final String? tripRouteFrom;
  final String? tripRouteTo;
  final List<ProformaItem> items;

  Proforma({
    required this.id,
    required this.documentNumber,
    this.clientId,
    this.clientName,
    this.clientCompany,
    this.clientEmail,
    this.clientPhone,
    required this.currency,
    required this.subtotal,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.status,
    required this.statusLabel,
    this.statusColor,
    this.issueDate,
    this.dueDate,
    this.validUntil,
    this.notes,
    this.termsConditions,
    this.tripNumber,
    this.tripRouteFrom,
    this.tripRouteTo,
    this.items = const [],
  });

  factory Proforma.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List? ?? [];
    final status = (j['status'] ?? 'draft').toString();

    return Proforma(
      id: j['id'] ?? 0,
      documentNumber: j['document_number'] ?? '',
      clientId: j['client_id'],
      clientName: j['client_name'],
      clientCompany: j['client_company'],
      clientEmail: j['client_email'],
      clientPhone: j['client_phone'],
      currency: (j['currency'] ?? 'TZS').toString(),
      subtotal: double.tryParse((j['subtotal'] ?? 0).toString()) ?? 0,
      discountAmount: double.tryParse((j['discount_amount'] ?? 0).toString()) ?? 0,
      taxRate: double.tryParse((j['tax_rate'] ?? 0).toString()) ?? 0,
      taxAmount: double.tryParse((j['tax_amount'] ?? 0).toString()) ?? 0,
      total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      status: status,
      statusLabel: (j['status_label'] ?? _defaultLabel(status)).toString(),
      statusColor: j['status_color'],
      issueDate: _date(j['issue_date']),
      dueDate: _date(j['due_date']),
      validUntil: _date(j['valid_until']),
      notes: j['notes'],
      termsConditions: j['terms_conditions'],
      tripNumber: j['trip_number'],
      tripRouteFrom: j['trip_route_from'],
      tripRouteTo: j['trip_route_to'],
      items: rawItems.map((e) => ProformaItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String _defaultLabel(String status) {
    const labels = {
      'draft': 'Draft',
      'sent': 'Sent',
      'accepted': 'Accepted',
      'expired': 'Expired',
    };
    return labels[status] ?? status;
  }
}
