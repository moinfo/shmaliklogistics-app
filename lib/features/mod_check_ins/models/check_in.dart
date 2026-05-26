import 'package:flutter/material.dart';

import '../../../core/utils/colors.dart';

/// A single trip check-in (`trip_check_ins` row).
///
/// The list endpoint returns related names flattened inline (`trip_number`,
/// `route_from`/`route_to`, `driver_name`) and a recorded `status`
/// (`ok` / `issue` / `emergency`).
class CheckIn {
  final int id;
  final int? tripId;
  final String? tripNumber;
  final String? routeFrom;
  final String? routeTo;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final int? vehicleId;
  final String? vehiclePlate;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final double? lat;
  final double? lng;
  final String? location;
  final int? odometerKm;
  final String? notes;
  final DateTime? checkedInAt;

  CheckIn({
    required this.id,
    this.tripId,
    this.tripNumber,
    this.routeFrom,
    this.routeTo,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleId,
    this.vehiclePlate,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.lat,
    this.lng,
    this.location,
    this.odometerKm,
    this.notes,
    this.checkedInAt,
  });

  /// Pill colour for the check-in status: ok → green, issue → amber,
  /// emergency → red. Falls back to muted for anything unexpected.
  Color get statusColor {
    switch (status) {
      case 'ok':
        return kSuccess;
      case 'issue':
        return kWarning;
      case 'emergency':
        return kDanger;
      default:
        return kMuted;
    }
  }

  /// "Mwanza → Dar es Salaam" when both ends are known.
  String get routeDescription {
    final parts = <String>[
      if (routeFrom != null && routeFrom!.isNotEmpty) routeFrom!,
      if (routeTo != null && routeTo!.isNotEmpty) routeTo!,
    ];
    return parts.join(' → ');
  }

  factory CheckIn.fromJson(Map<String, dynamic> j) {
    return CheckIn(
      id: j['id'] ?? 0,
      tripId: j['trip_id'],
      tripNumber: j['trip_number'] as String?,
      routeFrom: j['route_from'] as String?,
      routeTo: j['route_to'] as String?,
      driverId: j['driver_id'],
      driverName: j['driver_name'] as String?,
      driverPhone: j['driver_phone'] as String?,
      vehicleId: j['vehicle_id'],
      vehiclePlate: j['vehicle_plate'] as String?,
      status: (j['status'] ?? '').toString(),
      statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
      statusColorHex: j['status_color'] as String?,
      lat: _toDouble(j['lat']),
      lng: _toDouble(j['lng']),
      location: j['location'] as String?,
      odometerKm: j['odometer_km'] is int
          ? j['odometer_km'] as int
          : int.tryParse((j['odometer_km'] ?? '').toString()),
      notes: j['notes'] as String?,
      checkedInAt: _date(j['checked_in_at']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// Check-in activity tallies returned alongside the list.
class CheckInStats {
  final int today;
  final int issues;
  final int emergency;
  final int total;

  CheckInStats({
    required this.today,
    required this.issues,
    required this.emergency,
    required this.total,
  });

  factory CheckInStats.fromJson(Map<String, dynamic> j) => CheckInStats(
        today: _toInt(j['today']),
        issues: _toInt(j['issues']),
        emergency: _toInt(j['emergency']),
        total: _toInt(j['total']),
      );

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse((v ?? 0).toString()) ?? 0;
}

/// Bundle of the check-in list plus its summary stats.
class CheckInBundle {
  final List<CheckIn> checkIns;
  final CheckInStats stats;

  CheckInBundle({required this.checkIns, required this.stats});
}
