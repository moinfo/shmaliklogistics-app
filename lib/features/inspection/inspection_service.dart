import '../../core/api/api_client.dart';
import '../../core/models/inspection.dart';

class InspectionService {
  final ApiClient _api;
  InspectionService(this._api);

  Future<List<Inspection>> fetchList() async {
    final json = await _api.get('/driver/inspections') as Map<String, dynamic>;
    final raw = json['inspections'];
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Inspection.fromJson(e as Map<String, dynamic>)).toList();
    }
    final data = (raw as Map<String, dynamic>)['data'] as List? ?? [];
    return data.map((e) => Inspection.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Inspection> submit({
    required String inspectionType,
    required String overallStatus,
    required List<InspectionItem> items,
    int? tripId,
    int? odometerKm,
    String? location,
    double? lat,
    double? lng,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'inspection_type': inspectionType,
      'overall_status': overallStatus,
      'items': items.map((i) => i.toJson()).toList(),
      'trip_id': ?tripId,
      'odometer_km': ?odometerKm,
      'location': ?location,
      'lat': ?lat,
      'lng': ?lng,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final json = await _api.post('/driver/inspections', body) as Map<String, dynamic>;
    return Inspection.fromJson(json['inspection'] as Map<String, dynamic>);
  }
}
