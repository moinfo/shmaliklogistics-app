/// A cross-border / vehicle permit, as returned by
/// `GET /staff/modules/permits` and `/permits/{id}`.
///
/// Mirrors the payload shaped by `Api\Staff\Modules\PermitController` (which
/// in turn flattens the `Permit` model + its trip).
class Permit {
  final int id;
  final int? tripId;
  final String? tripNumber;
  final String? tripRouteFrom;
  final String? tripRouteTo;
  final String vehiclePlate;
  final String permitType;
  final String? permitNumber;
  final String? issuingCountry;
  final String? issuingAuthority;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final int? daysUntilExpiry;
  final double? cost;
  final String? currency;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const Permit({
    required this.id,
    this.tripId,
    this.tripNumber,
    this.tripRouteFrom,
    this.tripRouteTo,
    required this.vehiclePlate,
    required this.permitType,
    this.permitNumber,
    this.issuingCountry,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
    this.daysUntilExpiry,
    this.cost,
    this.currency,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory Permit.fromJson(Map<String, dynamic> j) => Permit(
        id: j['id'] as int,
        tripId: j['trip_id'] as int?,
        tripNumber: j['trip_number'] as String?,
        tripRouteFrom: j['trip_route_from'] as String?,
        tripRouteTo: j['trip_route_to'] as String?,
        vehiclePlate: j['vehicle_plate'] as String? ?? '—',
        permitType: j['permit_type'] as String? ?? 'Permit',
        permitNumber: j['permit_number'] as String?,
        issuingCountry: j['issuing_country'] as String?,
        issuingAuthority: j['issuing_authority'] as String?,
        issueDate: _date(j['issue_date']),
        expiryDate: _date(j['expiry_date']),
        daysUntilExpiry: j['days_until_expiry'] as int?,
        cost: j['cost'] != null ? double.tryParse(j['cost'].toString()) ?? 0 : null,
        currency: j['currency'] as String?,
        status: j['status'] as String? ?? 'pending',
        notes: j['notes'] as String?,
        createdAt: _date(j['created_at']),
      );

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  // ── Derived display helpers ────────────────────────────────────────────────

  /// Status palette mirrors `Permit::$statuses` on the backend.
  static const _statusLabels = {
    'pending': 'Pending',
    'active': 'Active',
    'expired': 'Expired',
    'cancelled': 'Cancelled',
  };

  static const _statusColors = {
    'pending': 0xFFF59E0B,
    'active': 0xFF22C55E,
    'expired': 0xFFEF4444,
    'cancelled': 0xFF94A3B8,
  };

  String get statusLabel => _statusLabels[status] ?? status;

  int get statusColorValue => _statusColors[status] ?? 0xFF94A3B8;

  /// True when expired by status or by a past expiry date.
  bool get isExpired =>
      status == 'expired' || (daysUntilExpiry != null && daysUntilExpiry! < 0);

  /// True when active and within 14 days of expiring (the web "expiring soon"
  /// window).
  bool get isExpiringSoon =>
      !isExpired &&
      status == 'active' &&
      daysUntilExpiry != null &&
      daysUntilExpiry! <= 14;

  /// A short, human label for the expiry urgency (used on the cards/detail).
  String get expiryLabel {
    final d = daysUntilExpiry;
    if (expiryDate == null) return 'No expiry';
    if (d == null) return 'Expiry set';
    if (d < 0) return 'Expired ${-d}d ago';
    if (d == 0) return 'Expires today';
    if (d == 1) return 'Expires tomorrow';
    return 'Expires in ${d}d';
  }

  bool get hasMoney => cost != null && cost! > 0;

  String get route {
    final from = tripRouteFrom;
    final to = tripRouteTo;
    if (from != null && to != null) return '$from → $to';
    return from ?? to ?? '';
  }
}
