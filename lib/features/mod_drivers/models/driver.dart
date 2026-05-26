import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import 'driver_hr.dart';

/// A single recent trip flattened by the detail endpoint.
class DriverTrip {
  final int id;
  final String? tripNumber;
  final String status;
  final String? routeFrom;
  final String? routeTo;
  final DateTime? departureDate;
  final DateTime? arrivalDate;

  DriverTrip({
    required this.id,
    this.tripNumber,
    required this.status,
    this.routeFrom,
    this.routeTo,
    this.departureDate,
    this.arrivalDate,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> j) => DriverTrip(
        id: j['id'] ?? 0,
        tripNumber: j['trip_number'],
        status: (j['status'] ?? '').toString(),
        routeFrom: j['route_from'],
        routeTo: j['route_to'],
        departureDate: _date(j['departure_date']),
        arrivalDate: _date(j['arrival_date']),
      );

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// A driver (`drivers` row).
///
/// The list endpoint returns a flat summary (`name`, `status`, `phone`,
/// `license_expiry`, `vehicle_plate`, …); the detail endpoint adds personal
/// details, license classes and recent `trips`. [Driver.fromJson] handles both.
class Driver {
  final int id;
  final String name;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? phone;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final int? licenseDays;
  final String? vehiclePlate;

  // Detail-only fields.
  final String? phoneAlt;
  final String? email;
  final String? nationalId;
  final String? cardId;
  final String? address;
  final String? birthRegion;
  final String? birthDistrict;
  final List<String> licenseClasses;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? visaExpiry;
  final String? notes;
  final String? photoUrl;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleType;
  final List<DriverTrip> trips;

  /// Linked HR/payroll profile (detail endpoint only; null when the driver has
  /// no matching employee record).
  final DriverHr? hr;

  Driver({
    required this.id,
    required this.name,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.phone,
    this.licenseNumber,
    this.licenseExpiry,
    this.licenseDays,
    this.vehiclePlate,
    this.phoneAlt,
    this.email,
    this.nationalId,
    this.cardId,
    this.address,
    this.birthRegion,
    this.birthDistrict,
    this.licenseClasses = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.visaExpiry,
    this.notes,
    this.photoUrl,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleType,
    this.trips = const [],
    this.hr,
  });

  factory Driver.fromJson(Map<String, dynamic> j) {
    final rawClasses = j['license_classes'] as List? ?? const [];
    final rawTrips = j['trips'] as List? ?? const [];
    final rawHr = j['hr'];
    final status = (j['status'] ?? 'inactive').toString();

    return Driver(
      id: j['id'] ?? 0,
      name: (j['name'] ?? 'Unknown').toString(),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
      phone: j['phone'],
      licenseNumber: j['license_number'],
      licenseExpiry: _date(j['license_expiry']),
      licenseDays: j['license_days'] == null
          ? null
          : int.tryParse(j['license_days'].toString()),
      vehiclePlate: j['vehicle_plate'],
      phoneAlt: j['phone_alt'],
      email: j['email'],
      nationalId: j['national_id'],
      cardId: j['card_id'],
      address: j['address'],
      birthRegion: j['birth_region'],
      birthDistrict: j['birth_district'],
      licenseClasses: rawClasses.map((e) => e.toString()).toList(),
      emergencyContactName: j['emergency_contact_name'],
      emergencyContactPhone: j['emergency_contact_phone'],
      visaExpiry: _date(j['visa_expiry']),
      notes: j['notes'],
      photoUrl: j['photo_url'],
      vehicleMake: j['vehicle_make'],
      vehicleModel: j['vehicle_model'],
      vehicleType: j['vehicle_type'],
      trips: rawTrips
          .map((e) => DriverTrip.fromJson(e as Map<String, dynamic>))
          .toList(),
      hr: rawHr is Map<String, dynamic> ? DriverHr.fromJson(rawHr) : null,
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

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

  /// Absolute URL for the driver's photo, or null when none is set.
  ///
  /// The backend serves a host-relative `/storage/...` path; we prefix it with
  /// the environment's [ApiClient.storageUrl] (already `/api`-stripped) so the
  /// same record resolves on both the local and live servers. Already-absolute
  /// URLs are passed through untouched.
  String? get photoFullUrl {
    final p = photoUrl;
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    return '${ApiClient.storageUrl}${p.startsWith('/') ? '' : '/'}$p';
  }

  /// True when the licence has expired or expires within 30 days.
  bool get licenseExpiringSoon =>
      licenseDays != null && licenseDays! <= 30;

  bool get licenseExpired => licenseDays != null && licenseDays! < 0;
}
