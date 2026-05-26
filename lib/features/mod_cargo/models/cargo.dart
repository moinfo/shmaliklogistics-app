/// A single cargo status-change entry (`cargo_status_logs` row), surfaced as a
/// timeline on the detail screen.
class CargoStatusLog {
  final int id;
  final String status;
  final String statusLabel;
  final String? statusColor;
  final String? location;
  final String? notes;
  final String? userName;
  final DateTime? createdAt;

  CargoStatusLog({
    required this.id,
    required this.status,
    required this.statusLabel,
    this.statusColor,
    this.location,
    this.notes,
    this.userName,
    this.createdAt,
  });

  factory CargoStatusLog.fromJson(Map<String, dynamic> j) => CargoStatusLog(
        id: j['id'] ?? 0,
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColor: j['status_color'] as String?,
        location: j['location'] as String?,
        notes: j['notes'] as String?,
        userName: j['user_name'] as String?,
        createdAt: _date(j['created_at']),
      );

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// A cargo consignment (`cargos` row).
///
/// The list endpoint returns a flattened summary; the detail endpoint adds
/// consignee / declared-value / trip metadata plus the [statusLogs] timeline.
/// [Cargo.fromJson] handles both shapes.
class Cargo {
  final int id;
  final String cargoNumber;
  final String description;
  final String type;
  final String typeLabel;
  final String? typeColor;
  final String status;
  final String statusLabel;
  final String? statusColor;
  final double weightKg;
  final double? volumeM3;
  final int? pieces;
  final String? packingType;
  final String? origin;
  final String? destination;
  final int? tripId;
  final String? tripNumber;
  final String? routeFrom;
  final String? routeTo;
  final int? clientId;
  final String? clientName;
  final DateTime? createdAt;

  // Detail-only fields.
  final String? consigneeName;
  final String? consigneeContact;
  final double? declaredValue;
  final String? currency;
  final String? specialInstructions;
  final String? notes;
  final String? clientPhone;
  final String? clientEmail;
  final String? tripStatus;
  final String? driverName;
  final String? vehiclePlate;
  final String? createdByName;
  final List<CargoStatusLog> statusLogs;

  Cargo({
    required this.id,
    required this.cargoNumber,
    required this.description,
    required this.type,
    required this.typeLabel,
    this.typeColor,
    required this.status,
    required this.statusLabel,
    this.statusColor,
    this.weightKg = 0,
    this.volumeM3,
    this.pieces,
    this.packingType,
    this.origin,
    this.destination,
    this.tripId,
    this.tripNumber,
    this.routeFrom,
    this.routeTo,
    this.clientId,
    this.clientName,
    this.createdAt,
    this.consigneeName,
    this.consigneeContact,
    this.declaredValue,
    this.currency,
    this.specialInstructions,
    this.notes,
    this.clientPhone,
    this.clientEmail,
    this.tripStatus,
    this.driverName,
    this.vehiclePlate,
    this.createdByName,
    this.statusLogs = const [],
  });

  /// "Dar es Salaam → Lusaka" when both endpoints are known, else whichever
  /// side is present.
  String get routeDescription {
    final from = routeFrom;
    final to = routeTo;
    if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
      return '$from → $to';
    }
    return from ?? to ?? '';
  }

  factory Cargo.fromJson(Map<String, dynamic> j) {
    return Cargo(
      id: j['id'] ?? 0,
      cargoNumber: (j['cargo_number'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      type: (j['type'] ?? '').toString(),
      typeLabel: (j['type_label'] ?? j['type'] ?? '').toString(),
      typeColor: j['type_color'] as String?,
      status: (j['status'] ?? '').toString(),
      statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
      statusColor: j['status_color'] as String?,
      weightKg: double.tryParse((j['weight_kg'] ?? 0).toString()) ?? 0,
      volumeM3: j['volume_m3'] == null
          ? null
          : double.tryParse(j['volume_m3'].toString()),
      pieces: j['pieces'] is int
          ? j['pieces'] as int
          : int.tryParse((j['pieces'] ?? '').toString()),
      packingType: j['packing_type'] as String?,
      origin: j['origin'] as String?,
      destination: j['destination'] as String?,
      tripId: j['trip_id'],
      tripNumber: j['trip_number'] as String?,
      routeFrom: j['route_from'] as String?,
      routeTo: j['route_to'] as String?,
      clientId: j['client_id'],
      clientName: j['client_name'] as String?,
      createdAt: CargoStatusLog._date(j['created_at']),
      consigneeName: j['consignee_name'] as String?,
      consigneeContact: j['consignee_contact'] as String?,
      declaredValue: j['declared_value'] == null
          ? null
          : double.tryParse(j['declared_value'].toString()),
      currency: j['currency'] as String?,
      specialInstructions: j['special_instructions'] as String?,
      notes: j['notes'] as String?,
      clientPhone: j['client_phone'] as String?,
      clientEmail: j['client_email'] as String?,
      tripStatus: j['trip_status'] as String?,
      driverName: j['driver_name'] as String?,
      vehiclePlate: j['vehicle_plate'] as String?,
      createdByName: j['created_by_name'] as String?,
      statusLogs: (j['status_logs'] as List? ?? const [])
          .map((e) => CargoStatusLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
