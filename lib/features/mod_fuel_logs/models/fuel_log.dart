/// A single fuel log entry (mirrors the flattened `fuel_logs` API shape).
///
/// The list endpoint returns related names flattened inline
/// (`vehicle_plate`, `driver_name`, `trip_number`) and money as numbers.
class FuelLog {
  final int id;
  final int? vehicleId;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? driverId;
  final String? driverName;
  final int? tripId;
  final String? tripNumber;
  final DateTime? logDate;
  final double liters;
  final double costPerLiter;
  final double totalCost;
  final int? odometerKm;
  final String? station;
  final String? fuelType;
  final String? currency;
  final String? notes;

  FuelLog({
    required this.id,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    this.driverId,
    this.driverName,
    this.tripId,
    this.tripNumber,
    this.logDate,
    required this.liters,
    required this.costPerLiter,
    required this.totalCost,
    this.odometerKm,
    this.station,
    this.fuelType,
    this.currency,
    this.notes,
  });

  factory FuelLog.fromJson(Map<String, dynamic> j) {
    final liters = double.tryParse((j['liters'] ?? 0).toString()) ?? 0;
    final costPerLiter = double.tryParse((j['cost_per_liter'] ?? 0).toString()) ?? 0;
    final totalCost = j['total_cost'] != null
        ? double.tryParse(j['total_cost'].toString()) ?? 0
        : liters * costPerLiter;

    return FuelLog(
      id: j['id'] ?? 0,
      vehicleId: j['vehicle_id'],
      vehiclePlate: j['vehicle_plate'],
      vehicleMake: j['vehicle_make'],
      vehicleModel: j['vehicle_model'],
      driverId: j['driver_id'],
      driverName: j['driver_name'],
      tripId: j['trip_id'],
      tripNumber: j['trip_number'],
      logDate: _date(j['log_date']),
      liters: liters,
      costPerLiter: costPerLiter,
      totalCost: totalCost,
      odometerKm: j['odometer_km'] is int
          ? j['odometer_km']
          : int.tryParse((j['odometer_km'] ?? '').toString()),
      station: j['station'] ?? j['station_name'],
      fuelType: j['fuel_type'],
      currency: (j['currency'] ?? 'TZS')?.toString(),
      notes: j['notes'],
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  String get vehicleDescription {
    final parts = [vehicleMake, vehicleModel].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? '' : parts.join(' ');
  }

  String get fuelTypeLabel {
    switch (fuelType) {
      case 'diesel':
        return 'Diesel';
      case 'petrol':
        return 'Petrol';
      case 'cng':
        return 'CNG';
      default:
        return fuelType ?? '—';
    }
  }
}

/// Fleet-wide fuel totals returned alongside the list.
class FuelStats {
  final double totalLiters;
  final double totalCost;
  final double monthLiters;
  final double monthCost;
  final int logCount;

  FuelStats({
    required this.totalLiters,
    required this.totalCost,
    required this.monthLiters,
    required this.monthCost,
    required this.logCount,
  });

  factory FuelStats.fromJson(Map<String, dynamic> j) => FuelStats(
        totalLiters: double.tryParse((j['total_liters'] ?? 0).toString()) ?? 0,
        totalCost: double.tryParse((j['total_cost'] ?? 0).toString()) ?? 0,
        monthLiters: double.tryParse((j['month_liters'] ?? 0).toString()) ?? 0,
        monthCost: double.tryParse((j['month_cost'] ?? 0).toString()) ?? 0,
        logCount: j['log_count'] is int
            ? j['log_count']
            : int.tryParse((j['log_count'] ?? 0).toString()) ?? 0,
      );
}

/// Bundle of the fuel-log list plus its summary stats.
class FuelLogBundle {
  final List<FuelLog> logs;
  final FuelStats stats;

  FuelLogBundle({required this.logs, required this.stats});
}
