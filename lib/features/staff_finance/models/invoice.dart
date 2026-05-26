import 'payment.dart';

/// A single line item on an invoice (mirrors `billing_items` columns).
class InvoiceItem {
  final int id;
  final String description;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double total;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        id: j['id'] ?? 0,
        description: j['description'] ?? '',
        quantity: double.tryParse((j['quantity'] ?? 1).toString()) ?? 0,
        unit: j['unit'],
        unitPrice: double.tryParse((j['unit_price'] ?? 0).toString()) ?? 0,
        total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      );
}

/// An invoice (`billing_documents` row of type `invoice`).
///
/// The list endpoint returns a flattened shape (`client_name`, `total`, …)
/// while the detail endpoint returns the full Eloquent model with nested
/// `client`, `items` and `payments`. [Invoice.fromJson] handles both.
class Invoice {
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
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double balanceDue;
  final String status;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;
  final String? termsConditions;
  final String? tripNumber;
  final String? tripRouteFrom;
  final String? tripRouteTo;
  final List<InvoiceItem> items;
  final List<Payment> payments;

  Invoice({
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
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    required this.status,
    this.issueDate,
    this.dueDate,
    this.notes,
    this.termsConditions,
    this.tripNumber,
    this.tripRouteFrom,
    this.tripRouteTo,
    this.items = const [],
    this.payments = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> j) {
    final client = j['client'] as Map<String, dynamic>?;
    final trip = j['trip'] as Map<String, dynamic>?;

    final rawItems = j['items'] as List? ?? [];
    final rawPayments = j['payments'] as List? ?? [];

    final total = double.tryParse((j['total'] ?? 0).toString()) ?? 0;
    final amountPaid = double.tryParse((j['amount_paid'] ?? 0).toString()) ?? 0;

    return Invoice(
      id: j['id'] ?? 0,
      documentNumber: j['document_number'] ?? '',
      clientId: j['client_id'] ?? client?['id'],
      clientName: j['client_name'] ?? client?['name'],
      clientCompany: j['client_company'] ?? client?['company_name'],
      clientEmail: client?['email'],
      clientPhone: client?['phone'],
      currency: (j['currency'] ?? 'TZS').toString(),
      subtotal: double.tryParse((j['subtotal'] ?? 0).toString()) ?? 0,
      discountAmount: double.tryParse((j['discount_amount'] ?? 0).toString()) ?? 0,
      taxAmount: double.tryParse((j['tax_amount'] ?? 0).toString()) ?? 0,
      total: total,
      amountPaid: amountPaid,
      balanceDue: j['balance_due'] != null
          ? double.tryParse(j['balance_due'].toString()) ?? 0
          : total - amountPaid,
      status: (j['status'] ?? 'draft').toString(),
      issueDate: _date(j['issue_date']),
      dueDate: _date(j['due_date']),
      notes: j['notes'],
      termsConditions: j['terms_conditions'],
      tripNumber: j['trip_number'] ?? trip?['trip_number'],
      tripRouteFrom: trip?['route_from'],
      tripRouteTo: trip?['route_to'],
      items: rawItems.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>)).toList(),
      payments: rawPayments.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  bool get isFullyPaid => status == 'paid' || balanceDue <= 0.01;

  String get statusLabel {
    const labels = {
      'draft': 'Draft',
      'sent': 'Sent',
      'partial': 'Partial',
      'paid': 'Paid',
      'overdue': 'Overdue',
      'cancelled': 'Cancelled',
    };
    return labels[status] ?? status;
  }
}
