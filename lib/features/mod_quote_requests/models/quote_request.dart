/// A client portal quote request (a "lead"), as returned by
/// `GET /staff/modules/quote-requests` and `/quote-requests/{id}`.
///
/// Mirrors the payload shaped by `Api\Staff\Modules\QuoteRequestController`
/// (which flattens the `PortalQuoteRequest` model + its client/reviewer).
class QuoteRequest {
  final int id;
  final int? clientId;
  final String? clientName;
  final String? clientCompany;
  final String? clientPhone;
  final String? clientEmail;
  final String routeFrom;
  final String routeTo;
  final String? cargoDescription;
  final double? cargoWeightKg;
  final int? cargoVolumeM3;
  final DateTime? preferredDate;
  final String? notes;
  final String status;
  final String? statusLabelRaw;
  final String? statusColorRaw;
  final int? reviewedBy;
  final String? reviewerName;
  final String? staffNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuoteRequest({
    required this.id,
    this.clientId,
    this.clientName,
    this.clientCompany,
    this.clientPhone,
    this.clientEmail,
    required this.routeFrom,
    required this.routeTo,
    this.cargoDescription,
    this.cargoWeightKg,
    this.cargoVolumeM3,
    this.preferredDate,
    this.notes,
    required this.status,
    this.statusLabelRaw,
    this.statusColorRaw,
    this.reviewedBy,
    this.reviewerName,
    this.staffNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory QuoteRequest.fromJson(Map<String, dynamic> j) => QuoteRequest(
        id: j['id'] as int,
        clientId: j['client_id'] as int?,
        clientName: j['client_name'] as String?,
        clientCompany: j['client_company'] as String?,
        clientPhone: j['client_phone'] as String?,
        clientEmail: j['client_email'] as String?,
        routeFrom: j['route_from'] as String? ?? '—',
        routeTo: j['route_to'] as String? ?? '—',
        cargoDescription: j['cargo_description'] as String?,
        cargoWeightKg: j['cargo_weight_kg'] != null
            ? double.tryParse(j['cargo_weight_kg'].toString()) ?? 0
            : null,
        cargoVolumeM3: j['cargo_volume_m3'] is int
            ? j['cargo_volume_m3'] as int
            : (j['cargo_volume_m3'] != null
                ? int.tryParse(j['cargo_volume_m3'].toString())
                : null),
        preferredDate: _date(j['preferred_date']),
        notes: j['notes'] as String?,
        status: j['status'] as String? ?? 'pending',
        statusLabelRaw: j['status_label'] as String?,
        statusColorRaw: j['status_color'] as String?,
        reviewedBy: j['reviewed_by'] as int?,
        reviewerName: j['reviewer_name'] as String?,
        staffNotes: j['staff_notes'] as String?,
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
      );

  static DateTime? _date(dynamic v) =>
      v != null ? DateTime.tryParse(v.toString()) : null;

  // ── Derived display helpers ────────────────────────────────────────────────

  /// Status palette mirrors `PortalQuoteRequest::$statuses` on the backend.
  static const _statusLabels = {
    'pending': 'Pending',
    'reviewed': 'Reviewed',
    'quoted': 'Quoted',
    'cancelled': 'Cancelled',
  };

  static const _statusColors = {
    'pending': 0xFFF59E0B,
    'reviewed': 0xFF3B82F6,
    'quoted': 0xFF22C55E,
    'cancelled': 0xFFEF4444,
  };

  String get statusLabel => statusLabelRaw ?? _statusLabels[status] ?? status;

  /// Prefers the backend-supplied hex (`#RRGGBB`); falls back to the local map.
  int get statusColorValue {
    final raw = statusColorRaw;
    if (raw != null && raw.startsWith('#') && raw.length == 7) {
      final v = int.tryParse(raw.substring(1), radix: 16);
      if (v != null) return 0xFF000000 | v;
    }
    return _statusColors[status] ?? 0xFF94A3B8;
  }

  bool get isPending => status == 'pending';

  /// The display name for the requesting client (name, else company).
  String get displayClient =>
      clientName ?? clientCompany ?? 'Unknown client';

  String get route => '$routeFrom → $routeTo';

  bool get hasWeight => cargoWeightKg != null && cargoWeightKg! > 0;

  bool get hasVolume => cargoVolumeM3 != null && cargoVolumeM3! > 0;
}
