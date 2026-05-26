/// A single checklist line within an inspection section.
///
/// `status` is `'ok'`, `'issue'`, or `null` (not recorded / pending).
class InspectionItem {
  final String key;
  final String label;
  final String? status;
  final String okLabel;
  final String issueLabel;

  InspectionItem({
    required this.key,
    required this.label,
    this.status,
    this.okLabel = 'Good',
    this.issueLabel = 'Needs Attention',
  });

  bool get isOk => status == 'ok';
  bool get isIssue => status == 'issue';
  bool get isPending => status == null;

  /// Human label for this item's recorded status.
  String get statusLabel {
    if (isOk) return okLabel;
    if (isIssue) return issueLabel;
    return 'Not Checked';
  }

  factory InspectionItem.fromJson(Map<String, dynamic> j) => InspectionItem(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        status: j['status'] as String?,
        okLabel: (j['ok_label'] ?? 'Good').toString(),
        issueLabel: (j['issue_label'] ?? 'Needs Attention').toString(),
      );
}

/// A grouped checklist section (e.g. "Engine & Fluids").
class InspectionSection {
  final String key;
  final String title;
  final List<InspectionItem> items;

  InspectionSection({required this.key, required this.title, this.items = const []});

  int get issueCount => items.where((i) => i.isIssue).length;

  factory InspectionSection.fromJson(Map<String, dynamic> j) => InspectionSection(
        key: (j['key'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        items: (j['items'] as List? ?? const [])
            .map((e) => InspectionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A vehicle inspection (`vehicle_inspections` row).
///
/// The list endpoint returns a flattened summary; the detail endpoint adds the
/// grouped `items` sections plus trip / inspector metadata. [Inspection.fromJson]
/// handles both shapes.
class Inspection {
  final int id;
  final int? vehicleId;
  final String? vehiclePlate;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? driverId;
  final String? inspectorName;
  final String? inspectorPhone;
  final String type;
  final String typeLabel;
  final String? typeColor;
  final String overallStatus;
  final String overallStatusLabel;
  final String? overallStatusColor;
  final int? odometerKm;
  final String? location;
  final DateTime? inspectedAt;
  final String? notes;

  // Detail-only fields.
  final List<InspectionSection> sections;
  final int okCount;
  final int issueCount;
  final String? tripNumber;
  final String? routeFrom;
  final String? routeTo;
  final String? createdByName;

  Inspection({
    required this.id,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleMake,
    this.vehicleModel,
    this.driverId,
    this.inspectorName,
    this.inspectorPhone,
    required this.type,
    required this.typeLabel,
    this.typeColor,
    required this.overallStatus,
    required this.overallStatusLabel,
    this.overallStatusColor,
    this.odometerKm,
    this.location,
    this.inspectedAt,
    this.notes,
    this.sections = const [],
    this.okCount = 0,
    this.issueCount = 0,
    this.tripNumber,
    this.routeFrom,
    this.routeTo,
    this.createdByName,
  });

  String get vehicleDescription {
    final parts = <String>[
      if (vehicleMake != null && vehicleMake!.isNotEmpty) vehicleMake!,
      if (vehicleModel != null && vehicleModel!.isNotEmpty) vehicleModel!,
    ];
    return parts.join(' ');
  }

  factory Inspection.fromJson(Map<String, dynamic> j) {
    return Inspection(
      id: j['id'] ?? 0,
      vehicleId: j['vehicle_id'],
      vehiclePlate: j['vehicle_plate'] as String?,
      vehicleMake: j['vehicle_make'] as String?,
      vehicleModel: j['vehicle_model'] as String?,
      driverId: j['driver_id'],
      inspectorName: j['inspector_name'] as String?,
      inspectorPhone: j['inspector_phone'] as String?,
      type: (j['inspection_type'] ?? '').toString(),
      typeLabel: (j['inspection_type_label'] ?? j['inspection_type'] ?? '').toString(),
      typeColor: j['inspection_type_color'] as String?,
      overallStatus: (j['overall_status'] ?? '').toString(),
      overallStatusLabel: (j['overall_status_label'] ?? j['overall_status'] ?? '').toString(),
      overallStatusColor: j['overall_status_color'] as String?,
      odometerKm: j['odometer_km'] is int
          ? j['odometer_km'] as int
          : int.tryParse((j['odometer_km'] ?? '').toString()),
      location: j['location'] as String?,
      inspectedAt: _date(j['inspected_at']),
      notes: j['notes'] as String?,
      sections: (j['items'] as List? ?? const [])
          .map((e) => InspectionSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      okCount: j['ok_count'] is int ? j['ok_count'] as int : int.tryParse((j['ok_count'] ?? '0').toString()) ?? 0,
      issueCount: j['issue_count'] is int ? j['issue_count'] as int : int.tryParse((j['issue_count'] ?? '0').toString()) ?? 0,
      tripNumber: j['trip_number'] as String?,
      routeFrom: j['route_from'] as String?,
      routeTo: j['route_to'] as String?,
      createdByName: j['created_by_name'] as String?,
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
