import '../../core/api/api_client.dart';
import '../../core/models/check_in.dart';
import '../../core/models/trip.dart';

class TripService {
  final ApiClient _api;
  TripService(this._api);

  /// Fetches the paginated list of trips for the authenticated driver.
  Future<List<Trip>> fetchTrips() async {
    final json = await _api.get('/driver/trips') as Map<String, dynamic>;
    final data = (json['trips']?['data'] as List? ?? []);
    return data.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetches the full detail for a single trip, including check-ins.
  ///
  /// Returns a map with keys:
  ///   - `'trip'`      → [Trip]
  ///   - `'checkIns'`  → `List<CheckIn>`
  Future<Map<String, dynamic>> fetchTrip(int id) async {
    final json = await _api.get('/driver/trips/$id') as Map<String, dynamic>;
    final tripJson = json['trip'] as Map<String, dynamic>;

    final trip = Trip.fromJson(tripJson);

    final rawCheckIns = tripJson['check_ins'] as List? ?? [];
    final checkIns = rawCheckIns
        .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
        .toList();

    return {'trip': trip, 'checkIns': checkIns};
  }

  /// Submits driver-editable expense fields for a trip and returns the
  /// updated [Trip] returned by the server.
  Future<Trip> updateExpenses(
    int tripId, {
    required double roadFines,
    required double guardFees,
    required double borderCosts,
    required double otherCosts,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'road_fines': roadFines,
      'guard_fees': guardFees,
      'border_costs': borderCosts,
      'other_costs': otherCosts,
      'notes': notes,
    };
    final json =
        await _api.patch('/driver/trips/$tripId/expenses', body) as Map<String, dynamic>;
    return Trip.fromJson(json['trip'] as Map<String, dynamic>);
  }

  Future<String> uploadExpenseReceipt(int tripId, String filePath, String mimeType) async {
    final json = await _api.postMultipart(
      '/driver/trips/$tripId/expenses/receipt',
      {},
      filePath: filePath,
      fileField: 'receipt',
      mimeType: mimeType,
    ) as Map<String, dynamic>;
    return json['receipt_url'] as String;
  }
}