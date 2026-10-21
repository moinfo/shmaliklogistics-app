import '../../core/api/api_client.dart';
import 'models/debtor.dart';
import 'models/invoice.dart';
import 'models/payment.dart';

/// Talks to the `/staff/finance/*` endpoints (Agent 3's FinanceController).
class StaffFinanceService {
  final ApiClient _api;
  StaffFinanceService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Invoice>> fetchInvoices() async {
    final json = await _api.get('/staff/finance/invoices') as Map<String, dynamic>;
    return _unwrapList(json['invoices'])
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Invoice> fetchInvoice(int id) async {
    final json = await _api.get('/staff/finance/invoices/$id') as Map<String, dynamic>;
    return Invoice.fromJson(json['invoice'] as Map<String, dynamic>);
  }

  Future<List<Payment>> fetchPayments() async {
    final json = await _api.get('/staff/finance/payments') as Map<String, dynamic>;
    return _unwrapList(json['payments'])
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Debtor>> fetchDebtors() async {
    final json = await _api.get('/staff/finance/debtors') as Map<String, dynamic>;
    return _unwrapList(json['debtors'])
        .map((e) => Debtor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Records a payment against an invoice and returns the updated [Invoice]
  /// (same shape as [fetchInvoice]).
  Future<Invoice> recordPayment(
    int invoiceId, {
    required double amount,
    required String method,
    required DateTime date,
    String? stage,
    String? referenceNumber,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'payment_method': method,
      'payment_date': date.toIso8601String().split('T').first,
      'payment_stage': ?stage,
      if (referenceNumber != null && referenceNumber.isNotEmpty) 'reference_number': referenceNumber,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final json = await _api.post('/staff/finance/invoices/$invoiceId/payments', body)
        as Map<String, dynamic>;
    return Invoice.fromJson(json['invoice'] as Map<String, dynamic>);
  }
}
