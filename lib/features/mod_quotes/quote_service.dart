import '../../core/api/api_client.dart';
import 'models/quote.dart';

/// Talks to the `/staff/modules/quotes` endpoints (Module #11 QuoteController).
class QuoteService {
  QuoteService(this._api);

  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `staff_finance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Quote>> fetchQuotes() async {
    final json = await _api.get('/staff/modules/quotes') as Map<String, dynamic>;
    return _unwrapList(json['quotes'])
        .map((e) => Quote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Quote> fetchQuote(int id) async {
    final json = await _api.get('/staff/modules/quotes/$id') as Map<String, dynamic>;
    return Quote.fromJson(json['quote'] as Map<String, dynamic>);
  }
}
