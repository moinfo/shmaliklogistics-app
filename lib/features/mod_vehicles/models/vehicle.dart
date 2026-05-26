import 'package:flutter/material.dart';

/// A statutory document expiry (insurance, road licence, fitness, …).
///
/// [days] is signed: negative means overdue. Flattened by the backend so the
/// mobile screen can render a compliance checklist with expiry warnings.
class VehicleDocument {
  final String key;
  final String label;
  final DateTime? expiry;
  final int days;

  VehicleDocument({
    required this.key,
    required this.label,
    this.expiry,
    required this.days,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> j) => VehicleDocument(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        expiry: _date(j['expiry']),
        days: j['days'] == null ? 0 : int.tryParse(j['days'].toString()) ?? 0,
      );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  bool get expired => days < 0;

  /// Expired or due within 30 days — the threshold the web portal flags on.
  bool get expiringSoon => days <= 30;
}

/// A single recent trip flattened by the detail endpoint.
class VehicleTrip {
  final int id;
  final String? tripNumber;
  final String status;
  final String? routeFrom;
  final String? routeTo;
  final DateTime? departureDate;
  final DateTime? arrivalDate;

  VehicleTrip({
    required this.id,
    this.tripNumber,
    required this.status,
    this.routeFrom,
    this.routeTo,
    this.departureDate,
    this.arrivalDate,
  });

  factory VehicleTrip.fromJson(Map<String, dynamic> j) => VehicleTrip(
        id: j['id'] ?? 0,
        tripNumber: j['trip_number'],
        status: (j['status'] ?? '').toString(),
        routeFrom: j['route_from'],
        routeTo: j['route_to'],
        departureDate: _date(j['departure_date']),
        arrivalDate: _date(j['arrival_date']),
      );

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

/// A fleet vehicle (`vehicles` row).
///
/// The list endpoint returns a flat summary (`plate`, `status`, `make`,
/// `model_name`, assigned `driver_name`, statutory `documents`, …); the detail
/// endpoint adds registration identifiers, specs, GPS and recent `trips`.
/// [Vehicle.fromJson] handles both shapes.
class Vehicle {
  final int id;
  final String plate;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? make;
  final String? modelName;
  final int? year;
  final String? type;
  final String? color;
  final int? driverId;
  final String? driverName;
  final int? mileageKm;
  final double? payloadTons;
  final String? fuelType;
  final DateTime? nextServiceDate;
  final List<VehicleDocument> documents;

  // Detail-only fields.
  final String? chassisNumber;
  final String? engineNumber;
  final int? fuelTankCapacityL;
  final String? ownerName;
  final String? notes;
  final String? driverPhone;
  final double? gpsLat;
  final double? gpsLng;
  final DateTime? gpsLastSeen;
  final String? gpsLocationName;
  final List<VehicleTrip> trips;

  Vehicle({
    required this.id,
    required this.plate,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.make,
    this.modelName,
    this.year,
    this.type,
    this.color,
    this.driverId,
    this.driverName,
    this.mileageKm,
    this.payloadTons,
    this.fuelType,
    this.nextServiceDate,
    this.documents = const [],
    this.chassisNumber,
    this.engineNumber,
    this.fuelTankCapacityL,
    this.ownerName,
    this.notes,
    this.driverPhone,
    this.gpsLat,
    this.gpsLng,
    this.gpsLastSeen,
    this.gpsLocationName,
    this.trips = const [],
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) {
    final rawDocs = j['documents'] as List? ?? const [];
    final rawTrips = j['trips'] as List? ?? const [];
    final status = (j['status'] ?? 'idle').toString();

    return Vehicle(
      id: j['id'] ?? 0,
      plate: (j['plate'] ?? 'Unknown').toString(),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
      make: j['make'],
      modelName: j['model_name'],
      year: j['year'] == null ? null : int.tryParse(j['year'].toString()),
      type: j['type'],
      color: j['color'],
      driverId: j['driver_id'],
      driverName: j['driver_name'],
      mileageKm:
          j['mileage_km'] == null ? null : int.tryParse(j['mileage_km'].toString()),
      payloadTons: j['payload_tons'] == null
          ? null
          : double.tryParse(j['payload_tons'].toString()),
      fuelType: j['fuel_type'],
      nextServiceDate: _date(j['next_service_date']),
      documents: rawDocs
          .map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      chassisNumber: j['chassis_number'],
      engineNumber: j['engine_number'],
      fuelTankCapacityL: j['fuel_tank_capacity_l'] == null
          ? null
          : int.tryParse(j['fuel_tank_capacity_l'].toString()),
      ownerName: j['owner_name'],
      notes: j['notes'],
      driverPhone: j['driver_phone'],
      gpsLat:
          j['gps_lat'] == null ? null : double.tryParse(j['gps_lat'].toString()),
      gpsLng:
          j['gps_lng'] == null ? null : double.tryParse(j['gps_lng'].toString()),
      gpsLastSeen: _date(j['gps_last_seen']),
      gpsLocationName: j['gps_location_name'],
      trips: rawTrips
          .map((e) => VehicleTrip.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Status colour parsed from the backend hex (falls back to a slate grey).
  Color get statusColor {
    final hex = statusColorHex;
    if (hex == null) return const Color(0xFF475569);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF475569);
    return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
  }

  /// "Make Model" joined for display, falling back gracefully to the plate.
  String get description {
    final parts =
        [make, modelName].where((s) => s != null && s.isNotEmpty).cast<String>();
    final joined = parts.join(' ');
    return joined.isEmpty ? plate : joined;
  }

  /// The most urgent statutory document (soonest to expire / most overdue),
  /// or null when none are recorded.
  VehicleDocument? get soonestDocument {
    if (documents.isEmpty) return null;
    final sorted = [...documents]..sort((a, b) => a.days.compareTo(b.days));
    return sorted.first;
  }

  /// True when any statutory document is expired or expiring within 30 days.
  bool get hasDocumentWarning => soonestDocument?.expiringSoon ?? false;
}
