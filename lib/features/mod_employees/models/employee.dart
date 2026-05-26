import 'package:flutter/material.dart';

import '../../mod_payroll/models/hr_profile.dart';

/// An employee (`employees` row).
///
/// The list endpoint returns a flat summary (`name`, `employee_number`,
/// `department`, `position`, `status`, `phone`, `email`, `hire_date`); the
/// detail endpoint adds personal details, salary and emergency contact.
/// [Employee.fromJson] handles both shapes.
class Employee {
  final int id;
  final String name;
  final String? employeeNumber;
  final String? department;
  final String? position;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? phone;
  final String? email;
  final DateTime? hireDate;

  // Detail-only fields.
  final String? nationalId;
  final String? address;
  final DateTime? birthDate;
  final double? salary;
  final String? salaryCurrency;
  final double? bonus;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? notes;

  /// HR payroll bundle (detail endpoint only): bank, allowances, advances,
  /// loans and recent payslips. Sub-sections honour the viewer's HR permissions.
  final HrPayroll? hr;

  Employee({
    required this.id,
    required this.name,
    this.employeeNumber,
    this.department,
    this.position,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.phone,
    this.email,
    this.hireDate,
    this.nationalId,
    this.address,
    this.birthDate,
    this.salary,
    this.salaryCurrency,
    this.bonus,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.notes,
    this.hr,
  });

  factory Employee.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? 'active').toString();
    final rawHr = j['hr'];
    // Prefer a flattened relational name when present, else the raw column.
    final dept = (j['department_name'] ?? j['department'])?.toString();

    return Employee(
      id: j['id'] ?? 0,
      name: (j['name'] ?? 'Unknown').toString(),
      employeeNumber: j['employee_number']?.toString(),
      department: (dept == null || dept.isEmpty) ? null : dept,
      position: j['position']?.toString(),
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
      phone: j['phone']?.toString(),
      email: j['email']?.toString(),
      hireDate: _date(j['hire_date']),
      nationalId: j['national_id']?.toString(),
      address: j['address']?.toString(),
      birthDate: _date(j['birth_date']),
      salary: _money(j['salary']),
      salaryCurrency: j['salary_currency']?.toString(),
      bonus: _money(j['bonus']),
      emergencyContactName: j['emergency_contact_name']?.toString(),
      emergencyContactPhone: j['emergency_contact_phone']?.toString(),
      notes: j['notes']?.toString(),
      hr: rawHr is Map<String, dynamic> ? HrPayroll.fromJson(rawHr) : null,
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static double? _money(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString()) ?? 0;
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Status colour parsed from the backend hex (falls back to a slate grey).
  Color get statusColor {
    final hex = statusColorHex;
    if (hex == null) return const Color(0xFF475569);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF475569);
    return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
  }
}
