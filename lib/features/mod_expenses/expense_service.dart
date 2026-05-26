import '../../core/api/api_client.dart';
import 'models/expense.dart';

/// Talks to the staff `/staff/modules/expenses` endpoints
/// (Module #4 — recorded expenses). Read-only.
class ExpenseService {
  ExpenseService(this._api);
  final ApiClient _api;

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`), mirroring the
  /// existing `trip_service` / `maintenance_service` handling.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<List<Expense>> fetchExpenses() async {
    final json = await _api.get('/staff/modules/expenses') as Map<String, dynamic>;
    return _unwrapList(json['expenses'])
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> fetchExpense(int id) async {
    final json = await _api.get('/staff/modules/expenses/$id') as Map<String, dynamic>;
    return Expense.fromJson(json['expense'] as Map<String, dynamic>);
  }
}
