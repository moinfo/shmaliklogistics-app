import '../../core/api/api_client.dart';
import 'models/employee.dart';

/// Talks to the `/staff/modules/employees` endpoints (Module 17 — EmployeeController).
class ModEmployeesService {
  final ApiClient _api;
  ModEmployeesService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `mod_drivers_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Employee>> fetchEmployees() async {
    final json = await _api.get('/staff/modules/employees') as Map<String, dynamic>;
    return _unwrapList(json['employees'])
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Employee> fetchEmployee(int id) async {
    final json = await _api.get('/staff/modules/employees/$id') as Map<String, dynamic>;
    return Employee.fromJson(json['employee'] as Map<String, dynamic>);
  }
}
