import 'package:flutter/material.dart';

import '../../../core/utils/colors.dart';

/// Parses a backend hex colour string (e.g. `"#22C55E"`) into a [Color],
/// falling back to a slate grey when null/malformed. Shared across the
/// Properties models so list + detail render consistent status rails.
Color hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return kMuted;
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse('FF$cleaned', radix: 16);
  return value == null ? kMuted : Color(value);
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

double _money(dynamic v) => v == null ? 0 : (double.tryParse(v.toString()) ?? 0);

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

/// A single property summary row from `GET /properties` (list endpoint).
class PropertyRow {
  final int id;
  final String code;
  final String name;
  final String? type;
  final String? typeLabel;
  final String? typeColorHex;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? ownership;
  final String? address;
  final String? region;
  final String? district;
  final int unitsCount;
  final int occupiedUnitsCount;
  final double monthlyRentRoll;

  PropertyRow({
    required this.id,
    required this.code,
    required this.name,
    this.type,
    this.typeLabel,
    this.typeColorHex,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.ownership,
    this.address,
    this.region,
    this.district,
    required this.unitsCount,
    required this.occupiedUnitsCount,
    required this.monthlyRentRoll,
  });

  factory PropertyRow.fromJson(Map<String, dynamic> j) => PropertyRow(
        id: _int(j['id']),
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? 'Unnamed').toString(),
        type: j['type'] as String?,
        typeLabel: j['type_label'] as String?,
        typeColorHex: j['type_color']?.toString(),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? '').toString(),
        statusColorHex: j['status_color']?.toString(),
        ownership: j['ownership'] as String?,
        address: j['address'] as String?,
        region: j['region'] as String?,
        district: j['district'] as String?,
        unitsCount: _int(j['units_count']),
        occupiedUnitsCount: _int(j['occupied_units_count']),
        monthlyRentRoll: _money(j['monthly_rent_roll']),
      );

  Color get statusColor => hexColor(statusColorHex);
}

/// The active lease nested inside a unit (or null when vacant).
class ActiveLeaseInfo {
  final int id;
  final String? leaseNumber;
  final String? tenantName;
  final double rentAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  ActiveLeaseInfo({
    required this.id,
    this.leaseNumber,
    this.tenantName,
    required this.rentAmount,
    this.startDate,
    this.endDate,
  });

  factory ActiveLeaseInfo.fromJson(Map<String, dynamic> j) => ActiveLeaseInfo(
        id: _int(j['id']),
        leaseNumber: j['lease_number'] as String?,
        tenantName: j['tenant_name'] as String?,
        rentAmount: _money(j['rent_amount']),
        startDate: _date(j['start_date']),
        endDate: _date(j['end_date']),
      );
}

/// A unit within a property (from the detail endpoint).
class PropertyUnitInfo {
  final int id;
  final String unitNumber;
  final String? type;
  final String? typeLabel;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final double rentAmount;
  final String? rentCurrency;
  final int? bedrooms;
  final int? bathrooms;
  final double? sizeSqm;
  final ActiveLeaseInfo? activeLease;

  PropertyUnitInfo({
    required this.id,
    required this.unitNumber,
    this.type,
    this.typeLabel,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    required this.rentAmount,
    this.rentCurrency,
    this.bedrooms,
    this.bathrooms,
    this.sizeSqm,
    this.activeLease,
  });

  factory PropertyUnitInfo.fromJson(Map<String, dynamic> j) {
    final rawLease = j['active_lease'];
    return PropertyUnitInfo(
      id: _int(j['id']),
      unitNumber: (j['unit_number'] ?? '').toString(),
      type: j['type'] as String?,
      typeLabel: j['type_label'] as String?,
      status: (j['status'] ?? '').toString(),
      statusLabel: (j['status_label'] ?? '').toString(),
      statusColorHex: j['status_color']?.toString(),
      rentAmount: _money(j['rent_amount']),
      rentCurrency: j['rent_currency'] as String?,
      bedrooms: j['bedrooms'] == null ? null : _int(j['bedrooms']),
      bathrooms: j['bathrooms'] == null ? null : _int(j['bathrooms']),
      sizeSqm:
          j['size_sqm'] == null ? null : double.tryParse(j['size_sqm'].toString()),
      activeLease: rawLease is Map<String, dynamic>
          ? ActiveLeaseInfo.fromJson(rawLease)
          : null,
    );
  }

  Color get statusColor => hexColor(statusColorHex);
}

/// A recent expense logged against a property (from the detail endpoint).
class PropertyExpenseInfo {
  final int id;
  final String? category;
  final String? categoryLabel;
  final String? categoryIcon;
  final String? description;
  final double amount;
  final String? currency;
  final double amountTzs;
  final DateTime? expenseDate;
  final String? phase;
  final String? vendor;
  final String? unitLabel;

  PropertyExpenseInfo({
    required this.id,
    this.category,
    this.categoryLabel,
    this.categoryIcon,
    this.description,
    required this.amount,
    this.currency,
    required this.amountTzs,
    this.expenseDate,
    this.phase,
    this.vendor,
    this.unitLabel,
  });

  factory PropertyExpenseInfo.fromJson(Map<String, dynamic> j) =>
      PropertyExpenseInfo(
        id: _int(j['id']),
        category: j['category'] as String?,
        categoryLabel: j['category_label'] as String?,
        categoryIcon: j['category_icon'] as String?,
        description: j['description'] as String?,
        amount: _money(j['amount']),
        currency: j['currency'] as String?,
        amountTzs: _money(j['amount_tzs']),
        expenseDate: _date(j['expense_date']),
        phase: j['phase'] as String?,
        vendor: j['vendor'] as String?,
        unitLabel: j['unit_label'] as String?,
      );
}

/// Aggregate money figures for a property (from the detail endpoint).
class Financials {
  final double purchasePrice;
  final double renovationTotal;
  final double totalInvested;
  final double annualRentRoll;
  final double expenseTotal;

  Financials({
    required this.purchasePrice,
    required this.renovationTotal,
    required this.totalInvested,
    required this.annualRentRoll,
    required this.expenseTotal,
  });

  factory Financials.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const <String, dynamic>{};
    return Financials(
      purchasePrice: _money(m['purchase_price']),
      renovationTotal: _money(m['renovation_total']),
      totalInvested: _money(m['total_invested']),
      annualRentRoll: _money(m['annual_rent_roll']),
      expenseTotal: _money(m['expense_total']),
    );
  }
}

/// The full property record from `GET /properties/{id}`: the property fields
/// plus its [units], recent [expenses] and aggregate [financials].
class PropertyDetail {
  final int id;
  final String code;
  final String name;
  final String? type;
  final String? typeLabel;
  final String? typeColorHex;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? ownership;
  final String? address;
  final String? region;
  final String? district;
  final DateTime? acquisitionDate;
  final String? purchaseCurrency;
  final double? marketValue;
  final String? titleDeedNumber;
  final String? titleDeedUrl;
  final String? description;
  final String? notes;
  final int unitsCount;
  final int occupiedUnitsCount;

  final List<PropertyUnitInfo> units;
  final List<PropertyExpenseInfo> expenses;
  final Financials financials;

  PropertyDetail({
    required this.id,
    required this.code,
    required this.name,
    this.type,
    this.typeLabel,
    this.typeColorHex,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.ownership,
    this.address,
    this.region,
    this.district,
    this.acquisitionDate,
    this.purchaseCurrency,
    this.marketValue,
    this.titleDeedNumber,
    this.titleDeedUrl,
    this.description,
    this.notes,
    required this.unitsCount,
    required this.occupiedUnitsCount,
    required this.units,
    required this.expenses,
    required this.financials,
  });

  factory PropertyDetail.fromJson({
    required Map<String, dynamic> property,
    required List<dynamic> units,
    required List<dynamic> expenses,
    Map<String, dynamic>? financials,
  }) {
    return PropertyDetail(
      id: _int(property['id']),
      code: (property['code'] ?? '').toString(),
      name: (property['name'] ?? 'Unnamed').toString(),
      type: property['type'] as String?,
      typeLabel: property['type_label'] as String?,
      typeColorHex: property['type_color']?.toString(),
      status: (property['status'] ?? '').toString(),
      statusLabel: (property['status_label'] ?? '').toString(),
      statusColorHex: property['status_color']?.toString(),
      ownership: property['ownership'] as String?,
      address: property['address'] as String?,
      region: property['region'] as String?,
      district: property['district'] as String?,
      acquisitionDate: _date(property['acquisition_date']),
      purchaseCurrency: property['purchase_currency'] as String?,
      marketValue: property['market_value'] == null
          ? null
          : double.tryParse(property['market_value'].toString()),
      titleDeedNumber: property['title_deed_number'] as String?,
      titleDeedUrl: property['title_deed_url'] as String?,
      description: property['description'] as String?,
      notes: property['notes'] as String?,
      unitsCount: _int(property['units_count']),
      occupiedUnitsCount: _int(property['occupied_units_count']),
      units: units
          .map((e) => PropertyUnitInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: expenses
          .map((e) => PropertyExpenseInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      financials: Financials.fromJson(financials),
    );
  }

  Color get statusColor => hexColor(statusColorHex);
}