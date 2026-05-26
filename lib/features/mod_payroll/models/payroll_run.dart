import 'package:flutter/material.dart';

import 'salary_slip.dart';

/// A payroll run (`payroll_runs` row) — one monthly batch of salary slips.
///
/// The list endpoint returns a flat summary (period, status, slip count and
/// run totals); the detail endpoint adds `notes`, a `totals` breakdown and the
/// full list of `slips`. [PayrollRun.fromJson] handles both shapes.
class PayrollRun {
  final int id;
  final int year;
  final int month;
  final String monthName;
  final String periodLabel;
  final String? documentNumber;
  final String? payrollNumber;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final int slipsCount;
  final double grossTotal;
  final double deductionsTotal;
  final double netTotal;

  // Detail-only fields.
  final String? notes;
  final DateTime? createdAt;
  final PayrollTotals? totals;
  final List<SalarySlip> slips;

  PayrollRun({
    required this.id,
    required this.year,
    required this.month,
    required this.monthName,
    required this.periodLabel,
    this.documentNumber,
    this.payrollNumber,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    required this.slipsCount,
    required this.grossTotal,
    required this.deductionsTotal,
    required this.netTotal,
    this.notes,
    this.createdAt,
    this.totals,
    this.slips = const [],
  });

  factory PayrollRun.fromJson(Map<String, dynamic> j) {
    final rawSlips = j['slips'] as List? ?? const [];
    final status = (j['status'] ?? 'draft').toString();

    return PayrollRun(
      id: j['id'] ?? 0,
      year: _int(j['year']),
      month: _int(j['month']),
      monthName: (j['month_name'] ?? '').toString(),
      periodLabel: (j['period_label'] ?? '').toString(),
      documentNumber: j['document_number']?.toString(),
      payrollNumber: j['payroll_number']?.toString(),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
      slipsCount: _int(j['slips_count']),
      grossTotal: _money(j['gross_total']),
      deductionsTotal: _money(j['deductions_total']),
      netTotal: _money(j['net_total']),
      notes: j['notes']?.toString(),
      createdAt: _date(j['created_at']),
      totals: j['totals'] is Map<String, dynamic>
          ? PayrollTotals.fromJson(j['totals'] as Map<String, dynamic>)
          : null,
      slips: rawSlips
          .map((e) => SalarySlip.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Status colour parsed from the backend hex (falls back to a slate grey).
  Color get statusColor {
    final hex = statusColorHex;
    if (hex == null) return const Color(0xFF94A3B8);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF94A3B8);
    return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
  }

  static int _int(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  static double _money(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Aggregated money totals attached to a run-detail response.
class PayrollTotals {
  final double gross;
  final double bonus;
  final double paye;
  final double nssfEmployee;
  final double nhif;
  final double heslb;
  final double advances;
  final double loans;
  final double deductions;
  final double net;
  final double sdl;
  final double nssfEmployer;
  final double wcf;
  final double employerCost;

  PayrollTotals({
    required this.gross,
    required this.bonus,
    required this.paye,
    required this.nssfEmployee,
    required this.nhif,
    required this.heslb,
    required this.advances,
    required this.loans,
    required this.deductions,
    required this.net,
    required this.sdl,
    required this.nssfEmployer,
    required this.wcf,
    required this.employerCost,
  });

  factory PayrollTotals.fromJson(Map<String, dynamic> j) => PayrollTotals(
        gross: _m(j['gross']),
        bonus: _m(j['bonus']),
        paye: _m(j['paye']),
        nssfEmployee: _m(j['nssf_emp']),
        nhif: _m(j['nhif']),
        heslb: _m(j['heslb']),
        advances: _m(j['advances']),
        loans: _m(j['loans']),
        deductions: _m(j['deductions']),
        net: _m(j['net']),
        sdl: _m(j['sdl']),
        nssfEmployer: _m(j['nssf_er']),
        wcf: _m(j['wcf']),
        employerCost: _m(j['employer_cost']),
      );

  static double _m(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;
}
