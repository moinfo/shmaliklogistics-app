class Trip {
  final int id;
  final String tripNumber;
  final String status;
  final String routeFrom;
  final String routeTo;
  final DateTime? departureDate;
  final DateTime? arrivalDate;
  final String? vehiclePlate;
  final double freightAmount;
  final double fuelCost;
  final double driverAllowance;
  final double borderCosts;
  final double roadFines;
  final double guardFees;
  final double? totalCosts;
  final String? cargoDescription;
  final String? notes;
  final String? expenseReceiptUrl;
  final double otherCosts;

  Trip({
    required this.id,
    required this.tripNumber,
    required this.status,
    required this.routeFrom,
    required this.routeTo,
    this.departureDate,
    this.arrivalDate,
    this.vehiclePlate,
    required this.freightAmount,
    required this.fuelCost,
    required this.driverAllowance,
    required this.borderCosts,
    required this.roadFines,
    required this.guardFees,
    this.totalCosts,
    this.cargoDescription,
    this.notes,
    this.expenseReceiptUrl,
    required this.otherCosts,
  });

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'],
        tripNumber: j['trip_number'],
        status: j['status'],
        routeFrom: j['route_from'],
        routeTo: j['route_to'],
        departureDate: j['departure_date'] != null ? DateTime.parse(j['departure_date']) : null,
        arrivalDate: j['arrival_date'] != null ? DateTime.parse(j['arrival_date']) : null,
        vehiclePlate: j['vehicle_plate'] ?? j['vehicle']?['plate'],
        freightAmount: double.tryParse(j['freight_amount'].toString()) ?? 0,
        fuelCost: double.tryParse(j['fuel_cost'].toString()) ?? 0,
        driverAllowance: double.tryParse(j['driver_allowance'].toString()) ?? 0,
        borderCosts: double.tryParse(j['border_costs'].toString()) ?? 0,
        roadFines: double.tryParse(j['road_fines'].toString()) ?? 0,
        guardFees: double.tryParse(j['guard_fees'].toString()) ?? 0,
        totalCosts: j['total_costs'] != null ? double.tryParse(j['total_costs'].toString()) : null,
        cargoDescription: j['cargo_description'],
        notes: j['notes'],
        expenseReceiptUrl: j['expense_receipt_url'] as String?,
        otherCosts: double.tryParse((j['other_costs'] ?? 0).toString()) ?? 0,
      );

  String get statusLabel {
    const labels = {
      'planned': 'Planned',
      'loading': 'Loading',
      'in_transit': 'In Transit',
      'at_border': 'At Border',
      'delivered': 'Delivered',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    return labels[status] ?? status;
  }
}