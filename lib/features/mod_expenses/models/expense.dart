/// A recorded expense.
///
/// Mirrors the flattened JSON returned by the staff `ExpenseController`
/// (`category_label`, `trip_number`/`trip_route`, money as a string/number).
/// The same [Expense.fromJson] handles both the list and detail shapes.
class Expense {
  final int id;
  final int? tripId;
  final String? tripNumber;
  final String? tripRoute;
  final String? vehiclePlate;
  final String category;
  final String categoryLabel;
  final String? categoryIcon;
  final String? description;
  final double amount;
  final String currency;
  final DateTime? expenseDate;
  final String? receiptNumber;
  final String? notes;

  Expense({
    required this.id,
    this.tripId,
    this.tripNumber,
    this.tripRoute,
    this.vehiclePlate,
    required this.category,
    required this.categoryLabel,
    this.categoryIcon,
    this.description,
    required this.amount,
    required this.currency,
    this.expenseDate,
    this.receiptNumber,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> j) {
    final category = (j['category'] ?? '').toString();
    return Expense(
      id: j['id'] ?? 0,
      tripId: _int(j['trip_id']),
      tripNumber: j['trip_number'],
      tripRoute: j['trip_route'],
      vehiclePlate: j['vehicle_plate'],
      category: category,
      categoryLabel: (j['category_label'] ?? category).toString(),
      categoryIcon: j['category_icon'],
      description: j['description'],
      amount: double.tryParse((j['amount'] ?? 0).toString()) ?? 0,
      currency: (j['currency'] ?? 'TZS').toString(),
      expenseDate: _date(j['expense_date']),
      receiptNumber: j['receipt_number'],
      notes: j['notes'],
    );
  }

  /// Best one-line label for the related trip (number, then route).
  String? get tripDescription {
    final parts = [tripNumber, tripRoute].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
