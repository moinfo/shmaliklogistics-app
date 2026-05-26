import '../../core/api/api_client.dart';
import 'models/payroll_run.dart';
import 'models/salary_slip.dart';

/// Talks to the `/staff/modules/payroll` + `/salary-slips` endpoints
/// (Module 18's [PayrollController]). Read-only.
class PayrollService {
  PayrollService(this._api);

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

  /// GET `/staff/modules/payroll` → `{ payroll_runs: [...] }`.
  Future<List<PayrollRun>> fetchRuns() async {
    final json = await _api.get('/staff/modules/payroll') as Map<String, dynamic>;
    return _unwrapList(json['payroll_runs'])
        .map((e) => PayrollRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET `/staff/modules/payroll/{id}` → `{ payroll_run: {...} }` (with slips + totals).
  Future<PayrollRun> fetchRun(int id) async {
    final json = await _api.get('/staff/modules/payroll/$id') as Map<String, dynamic>;
    return PayrollRun.fromJson(json['payroll_run'] as Map<String, dynamic>);
  }

  /// GET `/staff/modules/salary-slips` → `{ salary_slips: [...] }`.
  Future<List<SalarySlip>> fetchSalarySlips() async {
    final json = await _api.get('/staff/modules/salary-slips') as Map<String, dynamic>;
    return _unwrapList(json['salary_slips'])
        .map((e) => SalarySlip.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
