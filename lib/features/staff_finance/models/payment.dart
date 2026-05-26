/// A payment recorded against an invoice (`payments` table).
///
/// The payments list endpoint returns a flattened shape (`document_number`,
/// `client_name`, …) while the invoice-detail endpoint nests the raw
/// `payments` relation rows. [Payment.fromJson] handles both.
class Payment {
  final int id;
  final int? invoiceId;
  final String? documentNumber;
  final String? clientName;
  final String? clientCompany;
  final double amount;
  final double? usdAmount;
  final String paymentMethod;
  final String? paymentStage;
  final String? referenceNumber;
  final String? notes;
  final DateTime? paymentDate;

  Payment({
    required this.id,
    this.invoiceId,
    this.documentNumber,
    this.clientName,
    this.clientCompany,
    required this.amount,
    this.usdAmount,
    required this.paymentMethod,
    this.paymentStage,
    this.referenceNumber,
    this.notes,
    this.paymentDate,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] ?? 0,
        invoiceId: j['invoice_id'] ?? j['billing_document_id'],
        documentNumber: j['document_number'],
        clientName: j['client_name'],
        clientCompany: j['client_company'],
        amount: double.tryParse((j['amount'] ?? 0).toString()) ?? 0,
        usdAmount: j['usd_amount'] != null
            ? double.tryParse(j['usd_amount'].toString())
            : null,
        paymentMethod: (j['payment_method'] ?? '').toString(),
        paymentStage: j['payment_stage'],
        referenceNumber: j['reference_number'],
        notes: j['notes'],
        paymentDate: j['payment_date'] != null
            ? DateTime.tryParse(j['payment_date'].toString())
            : null,
      );

  /// Human-readable label for the payment method (mirrors `Payment::$methods`).
  String get methodLabel {
    const labels = {
      'bank_transfer': 'Bank Transfer',
      'cash': 'Cash',
      'mobile_money': 'Mobile Money',
      'cheque': 'Cheque',
      'rtgs': 'RTGS',
    };
    return labels[paymentMethod] ?? paymentMethod;
  }
}
