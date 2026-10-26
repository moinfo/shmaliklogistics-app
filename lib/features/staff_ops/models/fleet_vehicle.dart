/// A vehicle in the fleet, as returned by `GET /staff/ops/fleet`.
///
/// Mirrors the payload shaped by `Api\Staff\OpsController@fleet`.
class FleetVehicle {
  final int id;
  final String plate;
  final String status;
  final String? make;
  final String? modelName;
  final String? type;
  final num? mileageKm;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final num? lastOdometerKm;
  final DateTime? lastFuelDate;
  final double? lastFuelLiters;

  const FleetVehicle({
    required this.id,
    required this.plate,
    required this.status,
    this.make,
    this.modelName,
    this.type,
    this.mileageKm,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.lastOdometerKm,
    this.lastFuelDate,
    this.lastFuelLiters,
  });

  factory FleetVehicle.fromJson(Map<String, dynamic> j) => FleetVehicle(
        id: j['id'],
        plate: j['plate'] as String? ?? '',
        status: j['status'] as String? ?? 'idle',
        make: j['make'] as String?,
        modelName: j['model_name'] as String?,
        type: j['type'] as String?,
        mileageKm: j['mileage_km'] as num?,
        driverId: j['driver_id'] as int?,
        driverName: j['driver_name'] as String?,
        driverPhone: j['driver_phone'] as String?,
        lastOdometerKm: j['last_odometer_km'] as num?,
        lastFuelDate: j['last_fuel_date'] != null ? DateTime.tryParse(j['last_fuel_date'].toString()) : null,
        lastFuelLiters: j['last_fuel_liters'] != null ? double.tryParse(j['last_fuel_liters'].toString()) : null,
      );

  /// Friendly "Make Model" description, falling back to the type or plate.
  String get description {
    final parts = [make, modelName].where((p) => p != null && p.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return type ?? plate;
  }

  bool get hasDriver => driverName != null && driverName!.isNotEmpty;

  String get statusLabel {
    const labels = {
      'active': 'Active',
      'on_road': 'On Road',
      'at_border': 'At Border',
      'loading': 'Loading',
      'idle': 'Idle',
      'maintenance': 'Maintenance',
      'retired': 'Retired',
    };
    return labels[status] ?? status;
  }

  /// Status colour matching the web fleet palette (`Vehicle::$statuses`).
  static const _statusColors = {
    'active': 0xFF22C55E,
    'on_road': 0xFF3B82F6,
    'at_border': 0xFFF59E0B,
    'loading': 0xFFEA580C,
    'idle': 0xFF64748B,
    'maintenance': 0xFFEF4444,
    'retired': 0xFF475569,
  };

  int get statusColorValue => _statusColors[status] ?? 0xFF94A3B8;
}
