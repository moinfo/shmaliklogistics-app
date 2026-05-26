import '../../core/api/api_client.dart';
import 'models/check_in.dart';

/// Read-only Trip Check-Ins API client for the staff mobile app.
///
/// Hits `/staff/modules/check-ins`. Unwraps both the plain list shape
/// (`{ "check_ins": [...] }`) and the paginated wrapper
/// (`{ "check_ins": {"data": [...]} }`), like `trip_service.dart`.
class CheckInService {
  CheckInService(this._api);

  final ApiClient _api;

  Future<CheckInBundle> fetchCheckIns() async {
    final json =
        await _api.get('/staff/modules/check-ins') as Map<String, dynamic>;

    final raw = json['check_ins'];
    final List list = raw is Map<String, dynamic>
        ? (raw['data'] as List? ?? [])
        : (raw as List? ?? []);

    final checkIns =
        list.map((e) => CheckIn.fromJson(e as Map<String, dynamic>)).toList();

    final statsJson = json['stats'] as Map<String, dynamic>?;
    final stats = statsJson != null
        ? CheckInStats.fromJson(statsJson)
        : _fallbackStats(checkIns);

    return CheckInBundle(checkIns: checkIns, stats: stats);
  }

  /// Derives tallies from the page when the server omits a `stats` block.
  CheckInStats _fallbackStats(List<CheckIn> checkIns) {
    return CheckInStats(
      today: checkIns.length,
      issues: checkIns.where((c) => c.status == 'issue').length,
      emergency: checkIns.where((c) => c.status == 'emergency').length,
      total: checkIns.length,
    );
  }
}
