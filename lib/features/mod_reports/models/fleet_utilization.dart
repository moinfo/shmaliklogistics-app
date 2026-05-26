/// Models for the Fleet Utilization report.
///
/// Mirrors `GET /staff/modules/reports/fleet-utilization` →
/// `{ "report": { ...summary, "rows": [ per-vehicle ] } }`.

double _d(dynamic v) => double.tryParse(v.toString()) ?? 0;
int _i(dynamic v) => int.tryParse(v.toString()) ?? 0;

class FleetUtilizationReport {
  final int year;
  final int? month;
  final int totalTrips;
  final double totalRevenue;
  final int totalFleet;
  final int activeVehicles;
  final int idleVehicles;
  final double utilizationRate;
  final List<FleetVehicleRow> rows;

  FleetUtilizationReport({
    required this.year,
    required this.month,
    required this.totalTrips,
    required this.totalRevenue,
    required this.totalFleet,
    required this.activeVehicles,
    required this.idleVehicles,
    required this.utilizationRate,
    required this.rows,
  });

  factory FleetUtilizationReport.fromJson(Map<String, dynamic> json) {
    final rows = (json['rows'] as List? ?? [])
        .map((e) => FleetVehicleRow.fromJson(e as Map<String, dynamic>))
        .toList();
    return FleetUtilizationReport(
      year: _i(json['year']),
      month: json['month'] == null ? null : _i(json['month']),
      totalTrips: _i(json['total_trips']),
      totalRevenue: _d(json['total_revenue']),
      totalFleet: _i(json['total_fleet']),
      activeVehicles: _i(json['active_vehicles']),
      idleVehicles: _i(json['idle_vehicles']),
      utilizationRate: _d(json['utilization_rate']),
      rows: rows,
    );
  }
}

class FleetVehicleRow {
  final String? vehiclePlate;
  final int tripCount;
  final double totalRevenue;
  final double totalCosts;
  final double totalProfit;
  final double totalCargoTons;
  final double avgRevenuePerTrip;

  FleetVehicleRow({
    required this.vehiclePlate,
    required this.tripCount,
    required this.totalRevenue,
    required this.totalCosts,
    required this.totalProfit,
    required this.totalCargoTons,
    required this.avgRevenuePerTrip,
  });

  String get plateLabel {
    final p = (vehiclePlate ?? '').trim();
    return p.isEmpty ? 'Unassigned' : p;
  }

  factory FleetVehicleRow.fromJson(Map<String, dynamic> json) => FleetVehicleRow(
        vehiclePlate: json['vehicle_plate'] as String?,
        tripCount: _i(json['trip_count']),
        totalRevenue: _d(json['total_revenue']),
        totalCosts: _d(json['total_costs']),
        totalProfit: _d(json['total_profit']),
        totalCargoTons: _d(json['total_cargo_tons']),
        avgRevenuePerTrip: _d(json['avg_revenue_per_trip']),
      );
}
