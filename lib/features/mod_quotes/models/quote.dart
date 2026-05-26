/// A single line item on a quote (mirrors `billing_items` columns).
class QuoteItem {
  final int id;
  final String description;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double total;

  QuoteItem({
    required this.id,
    required this.description,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> j) => QuoteItem(
        id: j['id'] ?? 0,
        description: j['description'] ?? '',
        quantity: double.tryParse((j['quantity'] ?? 1).toString()) ?? 0,
        unit: j['unit'],
        unitPrice: double.tryParse((j['unit_price'] ?? 0).toString()) ?? 0,
        total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      );
}

/// A billing quote (`billing_documents` row of type `quote`).
///
/// The list endpoint returns a flattened shape (`client_name`, `total`, …);
/// the detail endpoint adds line `items`, trip context and client contact.
/// [Quote.fromJson] handles both — falling back to nested `client`/`trip`
/// objects when the flattened keys are absent.
class Quote {
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
  final DateTime? issueDate;
  final DateTime? dueDate;
  final DateTime? validUntil;
  final String? notes;
  final String? termsConditions;
  final String? tripNumber;
  final String? tripRouteFrom;
  final String? tripRouteTo;
  final List<QuoteItem> items;

  Quote({
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

  factory Quote.fromJson(Map<String, dynamic> j) {
    final client = j['client'] as Map<String, dynamic>?;
    final trip = j['trip'] as Map<String, dynamic>?;
    final rawItems = j['items'] as List? ?? [];

    return Quote(
      id: j['id'] ?? 0,
      documentNumber: j['document_number'] ?? '',
      clientId: j['client_id'] ?? client?['id'],
      clientName: j['client_name'] ?? client?['name'],
      clientCompany: j['client_company'] ?? client?['company_name'],
      clientEmail: j['client_email'] ?? client?['email'],
      clientPhone: j['client_phone'] ?? client?['phone'],
      currency: (j['currency'] ?? 'TZS').toString(),
      subtotal: double.tryParse((j['subtotal'] ?? 0).toString()) ?? 0,
      discountAmount: double.tryParse((j['discount_amount'] ?? 0).toString()) ?? 0,
      taxRate: double.tryParse((j['tax_rate'] ?? 0).toString()) ?? 0,
      taxAmount: double.tryParse((j['tax_amount'] ?? 0).toString()) ?? 0,
      total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      status: (j['status'] ?? 'draft').toString(),
      issueDate: _date(j['issue_date']),
      dueDate: _date(j['due_date']),
      validUntil: _date(j['valid_until']),
      notes: j['notes'],
      termsConditions: j['terms_conditions'],
      tripNumber: j['trip_number'] ?? trip?['trip_number'],
      tripRouteFrom: j['trip_route_from'] ?? trip?['route_from'],
      tripRouteTo: j['trip_route_to'] ?? trip?['route_to'],
      items: rawItems.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// Human label for the quote status (mirrors `BillingDocument::$quoteStatuses`).
  String get statusLabel {
    const labels = {
      'draft': 'Draft',
      'sent': 'Sent',
      'accepted': 'Accepted',
      'rejected': 'Rejected',
      'expired': 'Expired',
    };
    return labels[status] ?? status;
  }
}
