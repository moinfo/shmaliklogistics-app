import '../../core/api/api_client.dart';
import '../../core/models/trip.dart';
import 'models/cargo.dart';
import 'models/customer_invoice.dart';
import 'models/quote_request.dart';

/// Headline counts shown on the customer Overview tab.
class CustomerStats {
  final int activeTrips;
  final int totalTrips;
  final double pendingAmount;
  final int paidInvoices;

  const CustomerStats({
    required this.activeTrips,
    required this.totalTrips,
    required this.pendingAmount,
    required this.paidInvoices,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> j) => CustomerStats(
        activeTrips: j['active_trips'] ?? 0,
        totalTrips: j['total_trips'] ?? 0,
        pendingAmount: double.tryParse((j['pending_amount'] ?? 0).toString()) ?? 0,
        paidInvoices: j['paid_invoices'] ?? 0,
      );
}

/// Aggregated payload backing the customer Overview tab.
class CustomerDashboard {
  final String name;
  final String? companyName;
  final CustomerStats stats;
  final List<Trip> activeTrips;
  final List<Cargo> recentCargo;
  final List<CustomerInvoice> recentInvoices;

  const CustomerDashboard({
    required this.name,
    this.companyName,
    required this.stats,
    this.activeTrips = const [],
    this.recentCargo = const [],
    this.recentInvoices = const [],
  });
}

/// Detail bundle returned for a single customer trip.
class CustomerTripDetail {
  final Trip trip;
  final List<Cargo> cargo;

  const CustomerTripDetail({required this.trip, this.cargo = const []});
}

class CustomerService {
  final ApiClient _api;
  CustomerService(this._api);

  /// Unwraps a list payload that may be a plain array or a paginator
  /// (`{ "data": [...] }`) under [key]. Mirrors existing driver-side handling.
  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<CustomerDashboard> fetchDashboard() async {
    final json = await _api.get('/customer/dashboard') as Map<String, dynamic>;
    final d = json['dashboard'] as Map<String, dynamic>;

    final client = (d['client'] as Map<String, dynamic>?) ?? const {};

    return CustomerDashboard(
      name: client['name'] ?? '',
      companyName: client['company_name'],
      stats: CustomerStats.fromJson((d['stats'] as Map<String, dynamic>?) ?? const {}),
      activeTrips: _asMapList(d['active_trips']).map(Trip.fromJson).toList(),
      recentCargo: _asMapList(d['recent_cargo']).map(Cargo.fromJson).toList(),
      recentInvoices:
          _asMapList(d['recent_invoices']).map(CustomerInvoice.fromJson).toList(),
    );
  }

  Future<List<Trip>> fetchTrips() async {
    final json = await _api.get('/customer/trips') as Map<String, dynamic>;
    return _unwrapList(json, 'trips').map(Trip.fromJson).toList();
  }

  Future<CustomerTripDetail> fetchTrip(int id) async {
    final json = await _api.get('/customer/trips/$id') as Map<String, dynamic>;
    return CustomerTripDetail(
      trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
      cargo: _asMapList(json['cargo']).map(Cargo.fromJson).toList(),
    );
  }

  Future<List<CustomerInvoice>> fetchInvoices() async {
    final json = await _api.get('/customer/invoices') as Map<String, dynamic>;
    return _unwrapList(json, 'invoices').map(CustomerInvoice.fromJson).toList();
  }

  Future<CustomerInvoice> fetchInvoice(int id) async {
    final json = await _api.get('/customer/invoices/$id') as Map<String, dynamic>;
    return CustomerInvoice.fromJson(json['invoice'] as Map<String, dynamic>);
  }

  Future<List<Cargo>> fetchCargo() async {
    final json = await _api.get('/customer/cargo') as Map<String, dynamic>;
    return _unwrapList(json, 'cargo').map(Cargo.fromJson).toList();
  }

  Future<List<QuoteRequest>> fetchQuoteRequests() async {
    final json = await _api.get('/customer/quote-requests') as Map<String, dynamic>;
    return _unwrapList(json, 'quote_requests').map(QuoteRequest.fromJson).toList();
  }

  /// Submits a new quote request. Optional numeric/date fields are omitted when
  /// null so the server applies its own `nullable` validation cleanly.
  Future<QuoteRequest> submitQuoteRequest({
    required String routeFrom,
    required String routeTo,
    required String cargoDescription,
    double? cargoWeightKg,
    int? cargoVolumeM3,
    DateTime? preferredDate,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'route_from': routeFrom,
      'route_to': routeTo,
      'cargo_description': cargoDescription,
      if (cargoWeightKg != null) 'cargo_weight_kg': cargoWeightKg,
      if (cargoVolumeM3 != null) 'cargo_volume_m3': cargoVolumeM3,
      if (preferredDate != null)
        'preferred_date': preferredDate.toIso8601String().split('T').first,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final json =
        await _api.post('/customer/quote-requests', body) as Map<String, dynamic>;
    return QuoteRequest.fromJson(json['quote_request'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // Proceed with local logout even if the server call fails.
    }
  }
}
