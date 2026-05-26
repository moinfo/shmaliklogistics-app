/// A single overdue/outstanding invoice belonging to a debtor.
class DebtorInvoice {
  final int id;
  final String documentNumber;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String currency;
  final double total;
  final double amountPaid;
  final double balanceDue;
  final int daysOverdue;
  final String status;
  final String? tripNumber;

  DebtorInvoice({
    required this.id,
    required this.documentNumber,
    this.issueDate,
    this.dueDate,
    required this.currency,
    required this.total,
    required this.amountPaid,
    required this.balanceDue,
    required this.daysOverdue,
    required this.status,
    this.tripNumber,
  });

  factory DebtorInvoice.fromJson(Map<String, dynamic> j) => DebtorInvoice(
        id: j['id'] ?? 0,
        documentNumber: j['document_number'] ?? '',
        issueDate: j['issue_date'] != null ? DateTime.tryParse(j['issue_date'].toString()) : null,
        dueDate: j['due_date'] != null ? DateTime.tryParse(j['due_date'].toString()) : null,
        currency: (j['currency'] ?? 'TZS').toString(),
        total: double.tryParse((j['total'] ?? 0).toString()) ?? 0,
        amountPaid: double.tryParse((j['amount_paid'] ?? 0).toString()) ?? 0,
        balanceDue: double.tryParse((j['balance_due'] ?? 0).toString()) ?? 0,
        daysOverdue: int.tryParse((j['days_overdue'] ?? 0).toString()) ?? 0,
        status: (j['status'] ?? '').toString(),
        tripNumber: j['trip_number'],
      );
}

/// A debtor — a client with one or more outstanding invoices, grouped server-side.
class Debtor {
  final int? clientId;
  final String? clientName;
  final String? clientCompany;
  final double totalInvoiced;
  final double totalPaid;
  final double balanceDue;
  final int maxDays;
  final List<DebtorInvoice> invoices;

  Debtor({
    this.clientId,
    this.clientName,
    this.clientCompany,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.balanceDue,
    required this.maxDays,
    this.invoices = const [],
  });

  factory Debtor.fromJson(Map<String, dynamic> j) {
    final rawInvoices = j['invoices'] as List? ?? [];
    return Debtor(
      clientId: j['client_id'] != null ? int.tryParse(j['client_id'].toString()) : null,
      clientName: j['client_name'],
      clientCompany: j['client_company'],
      totalInvoiced: double.tryParse((j['total_invoiced'] ?? 0).toString()) ?? 0,
      totalPaid: double.tryParse((j['total_paid'] ?? 0).toString()) ?? 0,
      balanceDue: double.tryParse((j['balance_due'] ?? 0).toString()) ?? 0,
      maxDays: int.tryParse((j['max_days'] ?? 0).toString()) ?? 0,
      invoices: rawInvoices.map((e) => DebtorInvoice.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
