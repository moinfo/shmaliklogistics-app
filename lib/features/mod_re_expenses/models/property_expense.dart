/// A single property expense (`matumizi` / `ukarabati`) row, flattened by the
/// `/staff/modules/real-estate/expenses` list endpoint.
///
/// [categoryIcon] is an emoji string supplied by the API (e.g. "🔨"); render it
/// with a [Text] in the leading badge, falling back to a Material icon when null.
class PropertyExpenseRow {
  final int id;
  final int? propertyId;
  final String? propertyLabel;
  final String? unitLabel;
  final String category;
  final String? categoryLabel;
  final String? categoryIcon;
  final String? description;
  final double amount;
  final String? currency;
  final double amountTzs;
  final DateTime? expenseDate;
  final String? phase;
  final String? phaseLabel;
  final String? vendor;
  final String? receiptNumber;

  PropertyExpenseRow({
    required this.id,
    this.propertyId,
    this.propertyLabel,
    this.unitLabel,
    required this.category,
    this.categoryLabel,
    this.categoryIcon,
    this.description,
    required this.amount,
    this.currency,
    required this.amountTzs,
    this.expenseDate,
    this.phase,
    this.phaseLabel,
    this.vendor,
    this.receiptNumber,
  });

  factory PropertyExpenseRow.fromJson(Map<String, dynamic> j) => PropertyExpenseRow(
        id: (j['id'] as num?)?.toInt() ?? 0,
        propertyId: (j['property_id'] as num?)?.toInt(),
        propertyLabel: j['property_label'] as String?,
        unitLabel: j['unit_label'] as String?,
        category: (j['category'] ?? '').toString(),
        categoryLabel: j['category_label'] as String?,
        categoryIcon: j['category_icon'] as String?,
        description: j['description'] as String?,
        amount: double.tryParse(j['amount']?.toString() ?? '') ?? 0,
        currency: j['currency'] as String?,
        amountTzs: double.tryParse(j['amount_tzs']?.toString() ?? '') ?? 0,
        expenseDate: _date(j['expense_date']),
        phase: j['phase'] as String?,
        phaseLabel: j['phase_label'] as String?,
        vendor: j['vendor'] as String?,
        receiptNumber: j['receipt_number'] as String?,
      );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

/// Aggregate totals shown as [StatCard]s above the expense list.
class ExpenseStats {
  final double totalTzs;
  final double thisMonthTzs;
  final double renovationTzs;

  ExpenseStats({
    required this.totalTzs,
    required this.thisMonthTzs,
    required this.renovationTzs,
  });

  factory ExpenseStats.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const {};
    return ExpenseStats(
      totalTzs: double.tryParse(m['total_tzs']?.toString() ?? '') ?? 0,
      thisMonthTzs: double.tryParse(m['this_month_tzs']?.toString() ?? '') ?? 0,
      renovationTzs: double.tryParse(m['renovation_tzs']?.toString() ?? '') ?? 0,
    );
  }
}