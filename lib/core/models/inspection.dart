class InspectionItem {
  final String key;
  final String status; // ok | issue | na
  final String? note;

  const InspectionItem({required this.key, required this.status, this.note});

  factory InspectionItem.fromJson(Map<String, dynamic> j) => InspectionItem(
        key: j['key'] as String,
        status: j['status'] as String,
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'status': status,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  InspectionItem copyWith({String? status, Object? note = const Object()}) =>
      InspectionItem(
        key: key,
        status: status ?? this.status,
        note: note == const Object() ? this.note : note as String?,
      );
}

class Inspection {
  final int id;
  final String inspectionType;
  final String overallStatus;
  final DateTime inspectedAt;
  final List<InspectionItem> items;
  final int? odometerKm;
  final String? location;
  final double? lat;
  final double? lng;
  final String? notes;

  const Inspection({
    required this.id,
    required this.inspectionType,
    required this.overallStatus,
    required this.inspectedAt,
    required this.items,
    this.odometerKm,
    this.location,
    this.lat,
    this.lng,
    this.notes,
  });

  factory Inspection.fromJson(Map<String, dynamic> j) => Inspection(
        id: j['id'] as int,
        inspectionType: j['inspection_type'] as String,
        overallStatus: j['overall_status'] as String,
        inspectedAt: DateTime.parse(j['inspected_at'] as String),
        items: (j['items'] as List? ?? [])
            .map((e) => InspectionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        odometerKm: j['odometer_km'] != null ? (j['odometer_km'] as num).toInt() : null,
        location: j['location'] as String?,
        lat: j['lat'] != null ? double.tryParse(j['lat'].toString()) : null,
        lng: j['lng'] != null ? double.tryParse(j['lng'].toString()) : null,
        notes: j['notes'] as String?,
      );

  String get typeLabel => const {
        'pre_trip': 'Pre-Trip',
        'periodic': 'On-Route',
        'post_trip': 'Post-Trip',
      }[inspectionType] ?? inspectionType;

  String get statusLabel => const {
        'ok': 'All Good',
        'minor_issues': 'Minor Issues',
        'critical': 'Critical',
      }[overallStatus] ?? overallStatus;
}

// Checklist structure matching the backend VehicleInspection model
const inspectionSections = [
  InspectionSection('A', 'Engine & Fluids', [
    InspectionCheckItem('engine_oil', 'Engine Oil Level'),
    InspectionCheckItem('coolant', 'Coolant / Radiator Water'),
    InspectionCheckItem('brake_fluid', 'Brake Fluid'),
    InspectionCheckItem('power_steering', 'Power Steering Fluid'),
    InspectionCheckItem('fuel', 'Fuel Level'),
    InspectionCheckItem('leakage', 'Leakage Check'),
  ]),
  InspectionSection('B', 'Tyres & Wheels', [
    InspectionCheckItem('front_tyres', 'Front Tyres'),
    InspectionCheckItem('rear_tyres', 'Rear Tyres'),
    InspectionCheckItem('spare_tyre', 'Spare Tyre'),
    InspectionCheckItem('tyre_pressure', 'Tyre Pressure'),
    InspectionCheckItem('wheel_nuts', 'Wheel Nuts Tight'),
  ]),
  InspectionSection('C', 'Lights & Electricals', [
    InspectionCheckItem('headlights', 'Headlights'),
    InspectionCheckItem('brake_lights', 'Brake Lights'),
    InspectionCheckItem('indicators', 'Indicators'),
    InspectionCheckItem('hazard_lights', 'Hazard Lights'),
    InspectionCheckItem('horn', 'Horn'),
    InspectionCheckItem('battery', 'Battery Condition'),
  ]),
  InspectionSection('D', 'Safety & Emergency', [
    InspectionCheckItem('fire_extinguisher', 'Fire Extinguisher'),
    InspectionCheckItem('reflectors', 'Reflector Triangles'),
    InspectionCheckItem('first_aid', 'First Aid Kit'),
    InspectionCheckItem('jack_spanner', 'Jack & Wheel Spanner'),
    InspectionCheckItem('seat_belt', 'Seat Belt'),
  ]),
  InspectionSection('E', 'Cargo & Documents', [
    InspectionCheckItem('cargo_secured', 'Cargo Secured Properly'),
    InspectionCheckItem('cargo_balanced', 'Cargo Weight Balanced'),
    InspectionCheckItem('driving_license', 'Driving License Available'),
    InspectionCheckItem('insurance', 'Insurance Available'),
    InspectionCheckItem('delivery_note', 'Delivery Note Available'),
  ]),
];

class InspectionSection {
  final String letter;
  final String title;
  final List<InspectionCheckItem> items;
  const InspectionSection(this.letter, this.title, this.items);
}

class InspectionCheckItem {
  final String key;
  final String label;
  const InspectionCheckItem(this.key, this.label);
}
