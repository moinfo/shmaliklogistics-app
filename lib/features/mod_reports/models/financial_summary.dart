/// Models for the Financial Summary report.
///
/// Mirrors `GET /staff/modules/reports/financial-summary` →
/// `{ "report": { ...totals, "rows": [ per-month ] } }`.

double _d(dynamic v) => double.tryParse(v.toString()) ?? 0;
int _i(dynamic v) => int.tryParse(v.toString()) ?? 0;

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class FinancialSummaryReport {
  final int year;
  final int? month;
  final double totalRevenue;
  final double totalExpenses;
  final double totalMaintenance;
  final double totalCosts;
  final double totalProfit;
  final double margin;
  final double outstandingBilled;
  final double outstandingReceived;
  final double outstandingBalance;
  final List<MonthRow> rows;

  FinancialSummaryReport({
    required this.year,
    required this.month,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalMaintenance,
    required this.totalCosts,
    required this.totalProfit,
    required this.margin,
    required this.outstandingBilled,
    required this.outstandingReceived,
    required this.outstandingBalance,
    required this.rows,
  });

  factory FinancialSummaryReport.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List? ?? [])
        .map((e) => MonthRow.fromJson(e as Map<String, dynamic>))
        .toList();
    return FinancialSummaryReport(
      year: _i(json['year']),
      month: json['month'] == null ? null : _i(json['month']),
      totalRevenue: _d(json['total_revenue']),
      totalExpenses: _d(json['total_expenses']),
      totalMaintenance: _d(json['total_maintenance']),
      totalCosts: _d(json['total_costs']),
      totalProfit: _d(json['total_profit']),
      margin: _d(json['margin']),
      outstandingBilled: _d(json['outstanding_billed']),
      outstandingReceived: _d(json['outstanding_received']),
      outstandingBalance: _d(json['outstanding_balance']),
      rows: rows,
    );
  }
}

class MonthRow {
  final int month;
  final double revenue;
  final double expenses;
  final double maintenance;
  final double totalCosts;
  final double profit;

  MonthRow({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.maintenance,
    required this.totalCosts,
    required this.profit,
  });

  String get monthName =>
      (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Month $month';

  bool get hasActivity => revenue != 0 || expenses != 0 || maintenance != 0;

  factory MonthRow.fromJson(Map<String, dynamic> json) => MonthRow(
        month: _i(json['month']),
        revenue: _d(json['revenue']),
        expenses: _d(json['expenses']),
        maintenance: _d(json['maintenance']),
        totalCosts: _d(json['total_costs']),
        profit: _d(json['profit']),
      );
}
