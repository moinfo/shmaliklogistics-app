/// Models for the Real Estate "Tenants" module.
///
/// [TenantRow] is the flat list-row summary returned by
/// `GET /staff/modules/real-estate/tenants`; [TenantDetail] is the richer
/// record returned by `GET /staff/modules/real-estate/tenants/{id}`, carrying
/// a nested list of [TenantLeaseInfo]. Both are read-only.
library;

/// One row in the tenants list.
class TenantRow {
  final int id;
  final String code;
  final String name;
  final String type; // e.g. "individual" | "company"
  final String typeLabel;
  final String? typeColorHex;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? phone;
  final String? email;
  final String? companyName;
  final int activeLeasesCount;

  TenantRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.typeLabel,
    this.typeColorHex,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.phone,
    this.email,
    this.companyName,
    this.activeLeasesCount = 0,
  });

  bool get isCompany => type.toLowerCase() == 'company';

  factory TenantRow.fromJson(Map<String, dynamic> j) {
    final type = (j['type'] ?? '').toString();
    final status = (j['status'] ?? '').toString();
    return TenantRow(
      id: (j['id'] as num?)?.toInt() ?? 0,
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? 'Unknown').toString(),
      type: type,
      typeLabel: (j['type_label'] ?? _titleCase(type)).toString(),
      typeColorHex: j['type_color']?.toString(),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
      phone: j['phone'] as String?,
      email: j['email'] as String?,
      companyName: j['company_name'] as String?,
      activeLeasesCount: (j['active_leases_count'] as num?)?.toInt() ?? 0,
    );
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// A lease nested inside a tenant detail payload.
class TenantLeaseInfo {
  final int id;
  final String leaseNumber;
  final String? propertyLabel;
  final double rentAmount;
  final String? rentCurrency;
  final String? billingCycle;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String statusLabel;
  final String? statusColorHex;

  TenantLeaseInfo({
    required this.id,
    required this.leaseNumber,
    this.propertyLabel,
    this.rentAmount = 0,
    this.rentCurrency,
    this.billingCycle,
    this.startDate,
    this.endDate,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
  });

  factory TenantLeaseInfo.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? '').toString();
    return TenantLeaseInfo(
      id: (j['id'] as num?)?.toInt() ?? 0,
      leaseNumber: (j['lease_number'] ?? 'Lease #${j['id'] ?? ''}').toString(),
      propertyLabel: j['property_label'] as String?,
      rentAmount: double.tryParse(j['rent_amount'].toString()) ?? 0,
      rentCurrency: j['rent_currency'] as String?,
      billingCycle: j['billing_cycle'] as String?,
      startDate: _date(j['start_date']),
      endDate: _date(j['end_date']),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
    );
  }

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Full tenant record plus its leases.
class TenantDetail {
  final int id;
  final String code;
  final String name;
  final String type;
  final String typeLabel;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? phone;
  final String? phoneAlt;
  final String? email;
  final String? nationalId;
  final String? companyName;
  final String? tin;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? notes;
  final List<TenantLeaseInfo> leases;

  TenantDetail({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.phone,
    this.phoneAlt,
    this.email,
    this.nationalId,
    this.companyName,
    this.tin,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.notes,
    this.leases = const [],
  });

  bool get isCompany => type.toLowerCase() == 'company';

  factory TenantDetail.fromJson(
    Map<String, dynamic> tenant, {
    List<dynamic> leases = const [],
  }) {
    final type = (tenant['type'] ?? '').toString();
    final status = (tenant['status'] ?? '').toString();
    return TenantDetail(
      id: (tenant['id'] as num?)?.toInt() ?? 0,
      code: (tenant['code'] ?? '').toString(),
      name: (tenant['name'] ?? 'Unknown').toString(),
      type: type,
      typeLabel: (tenant['type_label'] ?? _titleCase(type)).toString(),
      status: status,
      statusLabel: (tenant['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: tenant['status_color']?.toString(),
      phone: tenant['phone'] as String?,
      phoneAlt: tenant['phone_alt'] as String?,
      email: tenant['email'] as String?,
      nationalId: tenant['national_id'] as String?,
      companyName: tenant['company_name'] as String?,
      tin: tenant['tin'] as String?,
      address: tenant['address'] as String?,
      emergencyContactName: tenant['emergency_contact_name'] as String?,
      emergencyContactPhone: tenant['emergency_contact_phone'] as String?,
      notes: tenant['notes'] as String?,
      leases: leases
          .map((e) => TenantLeaseInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}