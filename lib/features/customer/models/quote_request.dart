/// A quote request submitted by the customer through the portal.
class QuoteRequest {
  final int id;
  final String routeFrom;
  final String routeTo;
  final String cargoDescription;
  final double? cargoWeightKg;
  final int? cargoVolumeM3;
  final DateTime? preferredDate;
  final String? notes;
  final String status;
  final String? staffNotes;
  final DateTime? createdAt;

  QuoteRequest({
    required this.id,
    required this.routeFrom,
    required this.routeTo,
    required this.cargoDescription,
    this.cargoWeightKg,
    this.cargoVolumeM3,
    this.preferredDate,
    this.notes,
    required this.status,
    this.staffNotes,
    this.createdAt,
  });

  factory QuoteRequest.fromJson(Map<String, dynamic> j) => QuoteRequest(
        id: j['id'],
        routeFrom: j['route_from'] ?? '',
        routeTo: j['route_to'] ?? '',
        cargoDescription: j['cargo_description'] ?? '',
        cargoWeightKg: j['cargo_weight_kg'] != null
            ? double.tryParse(j['cargo_weight_kg'].toString())
            : null,
        cargoVolumeM3: j['cargo_volume_m3'] != null
            ? int.tryParse(j['cargo_volume_m3'].toString())
            : null,
        preferredDate: j['preferred_date'] != null
            ? DateTime.tryParse(j['preferred_date'].toString())
            : null,
        notes: j['notes'],
        status: j['status'] ?? 'pending',
        staffNotes: j['staff_notes'],
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  String get statusLabel {
    const labels = {
      'pending': 'Pending',
      'reviewed': 'Reviewed',
      'quoted': 'Quoted',
      'cancelled': 'Cancelled',
    };
    return labels[status] ?? status;
  }
}
