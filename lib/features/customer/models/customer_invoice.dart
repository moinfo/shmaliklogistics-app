/// A billing-document line item attached to an invoice.
class InvoiceItem {
  final int? id;
  final String description;
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double total;

  InvoiceItem({
    this.id,
    required this.description,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.total,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        id: j['id'],
        description: j['description'] ?? '',
        quantity: double.tryParse((j['quantity'] ?? 0).toString()) ?? 0,
        unit: j['unit'],
        unitPrice: double.tryParse((j['unit_price'] ?? 0).toString()) ?? 0,
        total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
      );
}

/// A payment recorded against an invoice.
class InvoicePayment {
  final int? id;
  final double amount;
  final String? method;
  final String? reference;
  final DateTime? paidAt;

  InvoicePayment({
    this.id,
    required this.amount,
    this.method,
    this.reference,
    this.paidAt,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> j) => InvoicePayment(
        id: j['id'],
        amount: double.tryParse((j['amount'] ?? 0).toString()) ?? 0,
        method: j['method'] ?? j['payment_method'],
        reference: j['reference'] ?? j['reference_no'],
        paidAt: _parseDate(j['paid_at'] ?? j['payment_date'] ?? j['created_at']),
      );
}

/// A customer-facing billing invoice (`BillingDocument` of type `invoice`).
class CustomerInvoice {
  final int id;
  final String documentNumber;
  final String status;
  final String? currency;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final double amountPaid;
  final double balanceDue;
  final String? notes;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  CustomerInvoice({
    required this.id,
    required this.documentNumber,
    required this.status,
    this.currency,
    this.issueDate,
    this.dueDate,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    this.notes,
    this.items = const [],
    this.payments = const [],
  });

  factory CustomerInvoice.fromJson(Map<String, dynamic> j) {
    final total = double.tryParse((j['total'] ?? 0).toString()) ?? 0;
    final paid = double.tryParse((j['amount_paid'] ?? 0).toString()) ?? 0;
    return CustomerInvoice(
      id: j['id'],
      documentNumber: j['document_number'] ?? '',
      status: j['status'] ?? 'draft',
      currency: j['currency'],
      issueDate: _parseDate(j['issue_date']),
      dueDate: _parseDate(j['due_date']),
      subtotal: double.tryParse((j['subtotal'] ?? 0).toString()) ?? 0,
      taxAmount: double.tryParse((j['tax_amount'] ?? 0).toString()) ?? 0,
      discountAmount: double.tryParse((j['discount_amount'] ?? 0).toString()) ?? 0,
      total: total,
      amountPaid: paid,
      balanceDue: j['balance_due'] != null
          ? (double.tryParse(j['balance_due'].toString()) ?? (total - paid))
          : (total - paid),
      notes: j['notes'],
      items: (j['items'] as List? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (j['payments'] as List? ?? [])
          .map((e) => InvoicePayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

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

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
