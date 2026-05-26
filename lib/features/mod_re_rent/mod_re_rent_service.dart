import '../../core/api/api_client.dart';
import 'models/rent_invoice.dart';

/// Bundles a rent-invoices list response: the flattened invoice [rows], the
/// collection [stats] summary, and the raw [statuses] enum map used to build
/// status filter chips.
class RentInvoicesPayload {
  final List<RentInvoiceRow> rows;
  final RentStats stats;

  /// Status enum map keyed by status code. Values are either a plain label
  /// string or a `{label, color}` object, mirroring the web portal.
  final Map<String, dynamic> statuses;

  /// Payment-method enum map keyed by method code. Each value is a
  /// `{label, color}` object, used to populate the "Record Payment" form.
  final Map<String, dynamic> paymentMethods;

  RentInvoicesPayload({
    required this.rows,
    required this.stats,
    required this.statuses,
    required this.paymentMethods,
  });
}

/// Talks to the `/staff/modules/real-estate/rent-invoices` endpoint
/// (RealEstateController — the "Rent" module). Read-only, list-only.
class ModReRentService {
  ModReRentService(this._api);
  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `mod_vehicles` / `staff_finance` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  /// Fetches rent invoices, optionally filtered by [search] and [status].
  /// Only non-empty query params are appended.
  Future<RentInvoicesPayload> fetchInvoices({String? search, String? status}) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (status != null && status.trim().isNotEmpty) params['status'] = status.trim();

    var path = '/staff/modules/real-estate/rent-invoices';
    if (params.isNotEmpty) {
      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      path = '$path?$query';
    }

    final json = await _api.get(path) as Map<String, dynamic>;

    final rows = _unwrapList(json['invoices'])
        .map((e) => RentInvoiceRow.fromJson(e as Map<String, dynamic>))
        .toList();

    final stats = RentStats.fromJson(json['stats'] as Map<String, dynamic>?);

    final statuses = (json['statuses'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    final paymentMethods =
        (json['paymentMethods'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

    return RentInvoicesPayload(
      rows: rows,
      stats: stats,
      statuses: statuses,
      paymentMethods: paymentMethods,
    );
  }

  /// Records a payment against rent invoice [invoiceId].
  ///
  /// `POST /staff/modules/real-estate/rent-invoices/{id}/payments`
  /// (permission `realestate_rent.create`). When [receiptPath] is provided the
  /// request is sent as multipart so the receipt file is attached; otherwise a
  /// plain JSON body is posted. Returns the decoded response map, which
  /// contains `message` and an updated `invoice` block.
  Future<Map<String, dynamic>> recordPayment({
    required int invoiceId,
    required double amount,
    required String paymentDate,
    required String method,
    String? reference,
    String? notes,
    String? receiptPath,
    String? mimeType,
  }) async {
    final path = '/staff/modules/real-estate/rent-invoices/$invoiceId/payments';

    if (receiptPath != null) {
      final fields = <String, String>{
        'amount': amount.toString(),
        'payment_date': paymentDate,
        'payment_method': method,
      };
      if (reference != null && reference.trim().isNotEmpty) {
        fields['reference_number'] = reference.trim();
      }
      if (notes != null && notes.trim().isNotEmpty) {
        fields['notes'] = notes.trim();
      }
      final json = await _api.postMultipart(
        path,
        fields,
        filePath: receiptPath,
        fileField: 'receipt',
        mimeType: mimeType,
      ) as Map<String, dynamic>;
      return json;
    }

    final body = <String, dynamic>{
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': method,
    };
    if (reference != null && reference.trim().isNotEmpty) {
      body['reference_number'] = reference.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }
    final json = await _api.post(path, body) as Map<String, dynamic>;
    return json;
  }
}