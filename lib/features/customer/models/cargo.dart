/// A shipment/cargo record belonging to the authenticated customer.
class Cargo {
  final int id;
  final String cargoNumber;
  final int? tripId;
  final String? tripNumber;
  final String? tripRouteFrom;
  final String? tripRouteTo;
  final String? description;
  final String? type;
  final String status;
  final double? weightKg;
  final double? volumeM3;
  final int? pieces;
  final String? packingType;
  final String? origin;
  final String? destination;
  final String? consigneeName;
  final String? consigneeContact;
  final double? declaredValue;
  final String? currency;
  final String? specialInstructions;
  final String? notes;

  Cargo({
    required this.id,
    required this.cargoNumber,
    this.tripId,
    this.tripNumber,
    this.tripRouteFrom,
    this.tripRouteTo,
    this.description,
    this.type,
    required this.status,
    this.weightKg,
    this.volumeM3,
    this.pieces,
    this.packingType,
    this.origin,
    this.destination,
    this.consigneeName,
    this.consigneeContact,
    this.declaredValue,
    this.currency,
    this.specialInstructions,
    this.notes,
  });

  factory Cargo.fromJson(Map<String, dynamic> j) {
    final trip = j['trip'] as Map<String, dynamic>?;
    return Cargo(
      id: j['id'],
      cargoNumber: j['cargo_number'] ?? '',
      tripId: j['trip_id'] ?? trip?['id'],
      tripNumber: trip?['trip_number'],
      tripRouteFrom: trip?['route_from'],
      tripRouteTo: trip?['route_to'],
      description: j['description'],
      type: j['type'],
      status: j['status'] ?? 'registered',
      weightKg: j['weight_kg'] != null ? double.tryParse(j['weight_kg'].toString()) : null,
      volumeM3: j['volume_m3'] != null ? double.tryParse(j['volume_m3'].toString()) : null,
      pieces: j['pieces'],
      packingType: j['packing_type'],
      origin: j['origin'],
      destination: j['destination'],
      consigneeName: j['consignee_name'],
      consigneeContact: j['consignee_contact'],
      declaredValue: j['declared_value'] != null ? double.tryParse(j['declared_value'].toString()) : null,
      currency: j['currency'],
      specialInstructions: j['special_instructions'],
      notes: j['notes'],
    );
  }

  String get statusLabel {
    const labels = {
      'registered': 'Registered',
      'loaded': 'Loaded',
      'in_transit': 'In Transit',
      'at_border': 'At Border',
      'cleared': 'Cleared',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
    };
    return labels[status] ?? status;
  }

  String? get typeLabel {
    if (type == null) return null;
    const labels = {
      'general': 'General Goods',
      'refrigerated': 'Refrigerated',
      'hazardous': 'Hazardous',
      'bulk': 'Bulk',
      'oversized': 'Oversized',
      'perishable': 'Perishable',
      'livestock': 'Livestock',
    };
    return labels[type] ?? type;
  }
}
