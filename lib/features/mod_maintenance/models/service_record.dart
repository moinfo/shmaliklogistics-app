/// A vehicle service / maintenance record.
///
/// Mirrors the flattened JSON returned by the staff `MaintenanceController`
/// (`vehicle_plate`, derived `status`, money as a string/number). The same
/// [ServiceRecord.fromJson] handles both the list and detail shapes.
class ServiceRecord {
  final int id;
  final int? vehicleId;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final String serviceType;
  final DateTime? serviceDate;
  final int? odometerKm;
  final String? workshopName;
  final String? description;
  final double cost;
  final String currency;
  final DateTime? nextServiceDate;
  final int? nextServiceMileage;
  final String status;
  final String? notes;

  ServiceRecord({
    required this.id,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    required this.serviceType,
    this.serviceDate,
    this.odometerKm,
    this.workshopName,
    this.description,
    required this.cost,
    required this.currency,
    this.nextServiceDate,
    this.nextServiceMileage,
    required this.status,
    this.notes,
  });

  factory ServiceRecord.fromJson(Map<String, dynamic> j) {
    final vehicle = j['vehicle'] as Map<String, dynamic>?;
    return ServiceRecord(
      id: j['id'] ?? 0,
      vehicleId: j['vehicle_id'] ?? vehicle?['id'],
      vehiclePlate: j['vehicle_plate'] ?? vehicle?['plate'],
      vehicleMake: j['vehicle_make'] ?? vehicle?['make'],
      vehicleModel: j['vehicle_model'] ?? vehicle?['model_name'],
      serviceType: (j['service_type'] ?? '').toString(),
      serviceDate: _date(j['service_date']),
      odometerKm: _int(j['odometer_km'] ?? j['mileage_km']),
      workshopName: j['workshop_name'],
      description: j['description'],
      cost: double.tryParse((j['cost'] ?? 0).toString()) ?? 0,
      currency: (j['currency'] ?? 'TZS').toString(),
      nextServiceDate: _date(j['next_service_date']),
      nextServiceMileage: _int(j['next_service_mileage']),
      status: (j['status'] ?? 'completed').toString(),
      notes: j['notes'],
    );
  }

  /// Vehicle make + model joined for display, falling back gracefully.
  String? get vehicleDescription {
    final parts = [vehicleMake, vehicleModel].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }

  String get statusLabel {
    const labels = {
      'completed': 'Completed',
      'scheduled': 'Scheduled',
      'due_soon': 'Due soon',
      'overdue': 'Overdue',
    };
    return labels[status] ?? status;
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
