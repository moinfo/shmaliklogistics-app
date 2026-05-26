/// Models for the Real Estate "Rent" module (rent invoices & collection).
///
/// The list endpoint (`/staff/modules/real-estate/rent-invoices`) returns a
/// paginated set of flat invoice rows plus a sibling `stats` block. This module
/// is list-only — there is no detail endpoint — so a single [RentInvoiceRow]
/// shape backed by [RentInvoiceRow.fromJson] is all that is needed.
library;

/// A single rent invoice row as flattened by the backend.
class RentInvoiceRow {
  final int id;
  final String invoiceNumber;
  final String tenantName;
  final String propertyLabel;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? dueDate;
  final double amount;
  final String currency;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final double amountPaid;
  final double balanceDue;

  RentInvoiceRow({
    required this.id,
    required this.invoiceNumber,
    required this.tenantName,
    required this.propertyLabel,
    this.periodStart,
    this.periodEnd,
    this.dueDate,
    required this.amount,
    required this.currency,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    required this.amountPaid,
    required this.balanceDue,
  });

  factory RentInvoiceRow.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? '').toString();
    return RentInvoiceRow(
      id: (j['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: (j['invoice_number'] ?? '—').toString(),
      tenantName: (j['tenant_name'] ?? '—').toString(),
      propertyLabel: (j['property_label'] ?? '—').toString(),
      periodStart: _date(j['period_start']),
      periodEnd: _date(j['period_end']),
      dueDate: _date(j['due_date']),
      amount: double.tryParse(j['amount'].toString()) ?? 0,
      currency: (j['currency'] ?? 'TZS').toString(),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color'] as String?,
      amountPaid: double.tryParse(j['amount_paid'].toString()) ?? 0,
      balanceDue: double.tryParse(j['balance_due'].toString()) ?? 0,
    );
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Collection summary returned alongside the invoice list (`stats` key).
class RentStats {
  final double totalBilled;
  final double totalCollected;
  final double outstanding;
  final int overdueCount;

  RentStats({
    required this.totalBilled,
    required this.totalCollected,
    required this.outstanding,
    required this.overdueCount,
  });

  factory RentStats.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const {};
    return RentStats(
      totalBilled: double.tryParse(m['total_billed'].toString()) ?? 0,
      totalCollected: double.tryParse(m['total_collected'].toString()) ?? 0,
      outstanding: double.tryParse(m['outstanding'].toString()) ?? 0,
      overdueCount: (m['overdue_count'] as num?)?.toInt() ?? 0,
    );
  }
}