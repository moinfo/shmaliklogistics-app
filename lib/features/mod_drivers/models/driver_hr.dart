import '../../mod_payroll/models/hr_profile.dart';

/// The driver's linked HR/payroll profile, present only when an employee record
/// matches the driver's national ID. Carries employment terms (which a driver
/// record lacks natively) plus the shared [HrPayroll] bundle (bank, allowances,
/// advances, loans and recent payslips).
class DriverHr {
  final int employeeId;
  final String? employeeNumber;
  final String? department;
  final String? position;
  final String? status;
  final DateTime? hireDate;
  final double? salary;
  final String? salaryCurrency;
  final double? bonus;
  final HrPayroll payroll;

  DriverHr({
    required this.employeeId,
    this.employeeNumber,
    this.department,
    this.position,
    this.status,
    this.hireDate,
    this.salary,
    this.salaryCurrency,
    this.bonus,
    required this.payroll,
  });

  factory DriverHr.fromJson(Map<String, dynamic> j) => DriverHr(
        employeeId: j['employee_id'] ?? 0,
        employeeNumber: j['employee_number']?.toString(),
        department: j['department']?.toString(),
        position: j['position']?.toString(),
        status: j['status']?.toString(),
        hireDate: _date(j['hire_date']),
        salary: j['salary'] == null ? null : hrMoney(j['salary']),
        salaryCurrency: j['salary_currency']?.toString(),
        bonus: j['bonus'] == null ? null : hrMoney(j['bonus']),
        payroll: HrPayroll.fromJson(j),
      );

  bool get hasPackage => (salary != null && salary! > 0) || (bonus != null && bonus! > 0);

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}
