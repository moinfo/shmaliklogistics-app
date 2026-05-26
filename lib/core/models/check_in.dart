class CheckIn {
  final int id;
  final int tripId;
  final String status;
  final DateTime checkedInAt;
  final double? lat;
  final double? lng;
  final String? location;
  final int? odometerKm;
  final String? notes;
  // Nested trip summary (present in history list)
  final String? tripNumber;
  final String? routeFrom;
  final String? routeTo;

  CheckIn({
    required this.id,
    required this.tripId,
    required this.status,
    required this.checkedInAt,
    this.lat,
    this.lng,
    this.location,
    this.odometerKm,
    this.notes,
    this.tripNumber,
    this.routeFrom,
    this.routeTo,
  });

  factory CheckIn.fromJson(Map<String, dynamic> j) {
    final tripRaw = j['trip'];
    final trip = tripRaw is Map<String, dynamic> ? tripRaw : null;
    return CheckIn(
      id: j['id'] as int,
      tripId: j['trip_id'] as int,
      status: j['status'] as String,
      checkedInAt: DateTime.parse(j['checked_in_at'] as String),
      lat: j['lat'] != null ? double.tryParse(j['lat'].toString()) : null,
      lng: j['lng'] != null ? double.tryParse(j['lng'].toString()) : null,
      location: j['location'] as String?,
      odometerKm: j['odometer_km'] != null ? (j['odometer_km'] as num).toInt() : null,
      notes: j['notes'] as String?,
      tripNumber: trip?['trip_number'] as String?,
      routeFrom: trip?['route_from'] as String?,
      routeTo: trip?['route_to'] as String?,
    );
  }

  String get statusLabel {
    const labels = {'ok': 'All Good', 'issue': 'Issue', 'emergency': 'Emergency'};
    return labels[status] ?? status;
  }
}