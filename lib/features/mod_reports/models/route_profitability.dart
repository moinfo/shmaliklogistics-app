/// Models for the Route Profitability report.
///
/// Mirrors the JSON returned by
/// `GET /staff/modules/reports/route-profitability` →
/// `{ "report": { ...summary, "rows": [...] } }`.
library;

double _d(dynamic v) => double.tryParse(v.toString()) ?? 0;
int _i(dynamic v) => int.tryParse(v.toString()) ?? 0;

class RouteProfitabilityReport {
  final int year;
  final int? month;
  final int totalTrips;
  final double totalRevenue;
  final double totalCosts;
  final double totalProfit;
  final double margin;
  final int routeCount;
  final List<RouteRow> rows;

  RouteProfitabilityReport({
    required this.year,
    required this.month,
    required this.totalTrips,
    required this.totalRevenue,
    required this.totalCosts,
    required this.totalProfit,
    required this.margin,
    required this.routeCount,
    required this.rows,
  });

  factory RouteProfitabilityReport.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List? ?? [])
        .map((e) => RouteRow.fromJson(e as Map<String, dynamic>))
        .toList();
    return RouteProfitabilityReport(
      year: _i(json['year']),
      month: json['month'] == null ? null : _i(json['month']),
      totalTrips: _i(json['total_trips']),
      totalRevenue: _d(json['total_revenue']),
      totalCosts: _d(json['total_costs']),
      totalProfit: _d(json['total_profit']),
      margin: _d(json['margin']),
      routeCount: _i(json['route_count']),
      rows: rows,
    );
  }
}

class RouteRow {
  final String? routeFrom;
  final String? routeTo;
  final int tripCount;
  final double totalRevenue;
  final double totalCosts;
  final double totalProfit;
  final double avgRevenue;
  final double avgCosts;
  final double totalCargoTons;
  final double margin;

  RouteRow({
    required this.routeFrom,
    required this.routeTo,
    required this.tripCount,
    required this.totalRevenue,
    required this.totalCosts,
    required this.totalProfit,
    required this.avgRevenue,
    required this.avgCosts,
    required this.totalCargoTons,
    required this.margin,
  });

  String get routeLabel {
    final from = (routeFrom ?? '').trim();
    final to = (routeTo ?? '').trim();
    if (from.isEmpty && to.isEmpty) return 'Unspecified route';
    return '$from → $to';
  }

  factory RouteRow.fromJson(Map<String, dynamic> json) => RouteRow(
        routeFrom: json['route_from'] as String?,
        routeTo: json['route_to'] as String?,
        tripCount: _i(json['trip_count']),
        totalRevenue: _d(json['total_revenue']),
        totalCosts: _d(json['total_costs']),
        totalProfit: _d(json['total_profit']),
        avgRevenue: _d(json['avg_revenue']),
        avgCosts: _d(json['avg_costs']),
        totalCargoTons: _d(json['total_cargo_tons']),
        margin: _d(json['margin']),
      );
}
