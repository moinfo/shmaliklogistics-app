import 'package:flutter/material.dart';

import '../../../core/utils/colors.dart';

/// Parses a backend hex colour string (e.g. `"#22C55E"`) into a [Color],
/// falling back to a slate grey when null/invalid. Shared by list & detail.
Color hexColor(String? hex) {
  if (hex == null || hex.isEmpty) return kMuted;
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return kMuted;
  return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
}

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

double _toDouble(dynamic v) =>
    v == null ? 0 : double.tryParse(v.toString()) ?? 0;

int? _toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

/// A lease (tenancy / *mkataba*) summary row from
/// `GET /staff/modules/real-estate/leases`.
class LeaseRow {
  final int id;
  final String leaseNumber;
  final String? tenantName;
  final String? propertyLabel;
  final double rentAmount;
  final String? rentCurrency;
  final String? billingCycle;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final bool hasContract;

  LeaseRow({
    required this.id,
    required this.leaseNumber,
    this.tenantName,
    this.propertyLabel,
    required this.rentAmount,
    this.rentCurrency,
    this.billingCycle,
    this.startDate,
    this.endDate,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    required this.hasContract,
  });

  factory LeaseRow.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? '').toString();
    return LeaseRow(
      id: _toInt(j['id']) ?? 0,
      leaseNumber: (j['lease_number'] ?? 'Lease #${j['id'] ?? ''}').toString(),
      tenantName: j['tenant_name'] as String?,
      propertyLabel: j['property_label'] as String?,
      rentAmount: _toDouble(j['rent_amount']),
      rentCurrency: j['rent_currency'] as String?,
      billingCycle: j['billing_cycle'] as String?,
      startDate: _date(j['start_date']),
      endDate: _date(j['end_date']),
      status: status,
      statusLabel: (j['status_label'] ?? status).toString(),
      statusColorHex: j['status_color']?.toString(),
      hasContract: j['has_contract'] == true,
    );
  }

  Color get statusColor => hexColor(statusColorHex);
}

/// A single rent invoice flattened onto a lease detail.
class LeaseInvoiceInfo {
  final int id;
  final String invoiceNumber;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? dueDate;
  final double amount;
  final String? currency;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final double amountPaid;
  final double balanceDue;

  LeaseInvoiceInfo({
    required this.id,
    required this.invoiceNumber,
    this.periodStart,
    this.periodEnd,
    this.dueDate,
    required this.amount,
    this.currency,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    required this.amountPaid,
    required this.balanceDue,
  });

  factory LeaseInvoiceInfo.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? '').toString();
    return LeaseInvoiceInfo(
      id: _toInt(j['id']) ?? 0,
      invoiceNumber:
          (j['invoice_number'] ?? 'Invoice #${j['id'] ?? ''}').toString(),
      periodStart: _date(j['period_start']),
      periodEnd: _date(j['period_end']),
      dueDate: _date(j['due_date']),
      amount: _toDouble(j['amount']),
      currency: j['currency'] as String?,
      status: status,
      statusLabel: (j['status_label'] ?? status).toString(),
      statusColorHex: j['status_color']?.toString(),
      amountPaid: _toDouble(j['amount_paid']),
      balanceDue: _toDouble(j['balance_due']),
    );
  }

  Color get statusColor => hexColor(statusColorHex);
}

/// A full lease record from `GET /staff/modules/real-estate/leases/{id}`.
class LeaseDetail {
  final int id;
  final String leaseNumber;
  final String? propertyLabel;
  final int? propertyId;
  final String? propertyName;
  final int? unitId;
  final String? unitNumber;
  final int? tenantId;
  final String? tenantName;
  final String? tenantPhone;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? billingCycle;
  final double rentAmount;
  final String? rentCurrency;
  final double? depositAmount;
  final int? paymentDay;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final bool hasContract;
  final String? contractUrl;
  final DateTime? contractUploadedAt;
  final String? terms;
  final String? notes;
  final List<LeaseInvoiceInfo> invoices;

  LeaseDetail({
    required this.id,
    required this.leaseNumber,
    this.propertyLabel,
    this.propertyId,
    this.propertyName,
    this.unitId,
    this.unitNumber,
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.startDate,
    this.endDate,
    this.billingCycle,
    required this.rentAmount,
    this.rentCurrency,
    this.depositAmount,
    this.paymentDay,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    required this.hasContract,
    this.contractUrl,
    this.contractUploadedAt,
    this.terms,
    this.notes,
    this.invoices = const [],
  });

  factory LeaseDetail.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? '').toString();
    final rawInvoices = j['invoices'] as List? ?? const [];
    return LeaseDetail(
      id: _toInt(j['id']) ?? 0,
      leaseNumber: (j['lease_number'] ?? 'Lease #${j['id'] ?? ''}').toString(),
      propertyLabel: j['property_label'] as String?,
      propertyId: _toInt(j['property_id']),
      propertyName: j['property_name'] as String?,
      unitId: _toInt(j['unit_id']),
      unitNumber: j['unit_number'] as String?,
      tenantId: _toInt(j['tenant_id']),
      tenantName: j['tenant_name'] as String?,
      tenantPhone: j['tenant_phone'] as String?,
      startDate: _date(j['start_date']),
      endDate: _date(j['end_date']),
      billingCycle: j['billing_cycle'] as String?,
      rentAmount: _toDouble(j['rent_amount']),
      rentCurrency: j['rent_currency'] as String?,
      depositAmount:
          j['deposit_amount'] == null ? null : _toDouble(j['deposit_amount']),
      paymentDay: _toInt(j['payment_day']),
      status: status,
      statusLabel: (j['status_label'] ?? status).toString(),
      statusColorHex: j['status_color']?.toString(),
      hasContract: j['has_contract'] == true,
      contractUrl: j['contract_url'] as String?,
      contractUploadedAt: _date(j['contract_uploaded_at']),
      terms: j['terms'] as String?,
      notes: j['notes'] as String?,
      invoices: rawInvoices
          .map((e) => LeaseInvoiceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Color get statusColor => hexColor(statusColorHex);
}