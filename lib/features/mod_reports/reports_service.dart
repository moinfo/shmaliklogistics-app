import '../../core/api/api_client.dart';
import 'models/financial_summary.dart';
import 'models/fleet_utilization.dart';
import 'models/route_profitability.dart';

/// Talks to the read-only analytics endpoints under
/// `/staff/modules/reports/*` (Module 20 — Reports).
///
/// Each endpoint returns a `{ "report": { ...summary, "rows": [...] } }`
/// envelope which is unwrapped here into the typed report models.
class ReportsService {
  ReportsService(this._api);

  final ApiClient _api;

  /// GET /staff/modules/reports/route-profitability
  Future<RouteProfitabilityReport> fetchRouteProfitability() async {
    final json =
        await _api.get('/staff/modules/reports/route-profitability') as Map<String, dynamic>;
    return RouteProfitabilityReport.fromJson(json['report'] as Map<String, dynamic>);
  }

  /// GET /staff/modules/reports/financial-summary
  Future<FinancialSummaryReport> fetchFinancialSummary() async {
    final json =
        await _api.get('/staff/modules/reports/financial-summary') as Map<String, dynamic>;
    return FinancialSummaryReport.fromJson(json['report'] as Map<String, dynamic>);
  }

  /// GET /staff/modules/reports/fleet-utilization
  Future<FleetUtilizationReport> fetchFleetUtilization() async {
    final json =
        await _api.get('/staff/modules/reports/fleet-utilization') as Map<String, dynamic>;
    return FleetUtilizationReport.fromJson(json['report'] as Map<String, dynamic>);
  }
}
