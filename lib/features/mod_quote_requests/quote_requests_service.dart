import '../../core/api/api_client.dart';
import 'models/quote_request.dart';

/// Talks to the staff Quote Requests module endpoints
/// (`/staff/modules/quote-requests`).
///
/// Mirrors the structure of the other module services (see
/// `features/mod_permits/permits_service.dart`): unwraps both the plain list
/// shape `{ "quote_requests": [...] }` and the paginated
/// `{ "quote_requests": { "data": [...] } }`.
class QuoteRequestsService {
  final ApiClient _api;
  QuoteRequestsService(this._api);

  static const String _base = '/staff/modules/quote-requests';

  /// All quote requests, newest first — `GET /staff/modules/quote-requests`.
  Future<List<QuoteRequest>> fetchQuoteRequests() async {
    final json = await _api.get(_base) as Map<String, dynamic>;
    final raw = json['quote_requests'];
    final data = (raw is Map ? raw['data'] : raw) as List? ?? [];
    return data
        .map((e) => QuoteRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// A single quote request — `GET /staff/modules/quote-requests/{id}`.
  Future<QuoteRequest> fetchQuoteRequest(int id) async {
    final json = await _api.get('$_base/$id') as Map<String, dynamic>;
    return QuoteRequest.fromJson(json['quote_request'] as Map<String, dynamic>);
  }
}
