import '../../core/api/api_client.dart';
import '../../core/models/check_in.dart';
import '../../core/models/trip.dart';

class CheckInService {
  final ApiClient _api;
  CheckInService(this._api);

  /// Returns active trips from the dashboard endpoint.
  Future<List<Trip>> fetchActiveTrips() async {
    final json = await _api.get('/driver/dashboard') as Map<String, dynamic>;
    final raw = json['active_trips'];
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Submits a check-in for the given trip.
  Future<CheckIn> submitCheckIn({
    required int tripId,
    required String status,
    double? lat,
    double? lng,
    String? location,
    int? odometerKm,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'trip_id': tripId,
      'status': status,
      'lat': ?lat,
      'lng': ?lng,
      if (location != null && location.isNotEmpty) 'location': location,
      'odometer_km': ?odometerKm,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final json =
        await _api.post('/driver/trips/$tripId/check-ins', body) as Map<String, dynamic>;

    return CheckIn.fromJson(json['check_in'] as Map<String, dynamic>);
  }
}
