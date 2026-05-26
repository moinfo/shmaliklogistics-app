import '../../core/api/api_client.dart';
import 'models/property_expense.dart';

/// A selectable property option (`{id, name}`) used to populate the
/// "Add Expense" property dropdown.
class PropertyOption {
  final int id;
  final String name;

  PropertyOption({required this.id, required this.name});

  factory PropertyOption.fromJson(Map<String, dynamic> j) => PropertyOption(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] ?? '').toString(),
      );
}

/// Bundles a single `/expenses` list response: the rows, the aggregate
/// [ExpenseStats], the `categories` map (key → {label, icon}) used to build
/// the filter chips, plus the `properties` list and `phases` map used by the
/// "Add Expense" form.
class ExpensesPayload {
  final List<PropertyExpenseRow> rows;
  final ExpenseStats stats;

  /// `categories` map keyed by category slug → `{label, icon}` metadata.
  final Map<String, dynamic> categories;

  /// Selectable properties (`{id, name}`) for the add-expense form.
  final List<PropertyOption> properties;

  /// `phases` map keyed by phase slug → `{label, color}` metadata.
  final Map<String, dynamic> phases;

  ExpensesPayload({
    required this.rows,
    required this.stats,
    required this.categories,
    required this.properties,
    required this.phases,
  });
}

/// Talks to the `/staff/modules/real-estate/expenses` endpoint (read-only
/// property-expense list — matumizi / ukarabati). Mirrors [ModVehiclesService].
class ModReExpensesService {
  final ApiClient _api;
  ModReExpensesService(this._api);

  /// Unwraps a list that may arrive either as a bare array (`{key:[...]}`)
  /// or wrapped in a Laravel paginator (`{key:{data:[...]}}`).
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) return (raw['data'] as List? ?? const []);
    return const [];
  }

  Future<ExpensesPayload> fetchExpenses({
    String? search,
    String? category,
    String? phase,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (phase != null && phase.isNotEmpty) params['phase'] = phase;

    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final json = await _api.get('/staff/modules/real-estate/expenses$query')
        as Map<String, dynamic>;

    final rows = _unwrapList(json['expenses'])
        .map((e) => PropertyExpenseRow.fromJson(e as Map<String, dynamic>))
        .toList();

    final properties = _unwrapList(json['properties'])
        .whereType<Map<String, dynamic>>()
        .map(PropertyOption.fromJson)
        .toList();

    return ExpensesPayload(
      rows: rows,
      stats: ExpenseStats.fromJson(json['stats'] as Map<String, dynamic>?),
      categories: (json['categories'] as Map<String, dynamic>?) ?? const {},
      properties: properties,
      phases: (json['phases'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Records a new property expense.
  ///
  /// Sends a multipart request when [receiptPath] is supplied (so the receipt
  /// file is attached), otherwise a plain JSON POST. Returns the decoded
  /// response map (`{message, expense:{id, amount_tzs}}`).
  Future<Map<String, dynamic>> addExpense({
    required int propertyId,
    int? unitId,
    required String category,
    required String description,
    required double amount,
    required String currency,
    double? exchangeRate,
    required String expenseDate,
    String? phase,
    String? vendor,
    String? receiptNumber,
    String? receiptPath,
    String? mimeType,
  }) async {
    final fields = <String, String>{
      'property_id': propertyId.toString(),
      'category': category,
      'description': description,
      'amount': amount.toString(),
      'currency': currency,
      'expense_date': expenseDate,
    };
    if (unitId != null) fields['property_unit_id'] = unitId.toString();
    if (exchangeRate != null) fields['exchange_rate'] = exchangeRate.toString();
    if (phase != null && phase.isNotEmpty) fields['phase'] = phase;
    if (vendor != null && vendor.isNotEmpty) fields['vendor'] = vendor;
    if (receiptNumber != null && receiptNumber.isNotEmpty) {
      fields['receipt_number'] = receiptNumber;
    }

    final dynamic json;
    if (receiptPath != null) {
      json = await _api.postMultipart(
        '/staff/modules/real-estate/expenses',
        fields,
        filePath: receiptPath,
        fileField: 'receipt',
        mimeType: mimeType,
      );
    } else {
      json = await _api.post('/staff/modules/real-estate/expenses', fields);
    }
    return (json as Map<String, dynamic>);
  }
}