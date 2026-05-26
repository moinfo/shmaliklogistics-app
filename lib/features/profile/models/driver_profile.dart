import '../../../core/models/driver.dart';
import '../../mod_payroll/models/hr_profile.dart';

/// The driver's own profile: their [Driver] record plus, when matched to an HR
/// employee record (by national ID), their pay package and the shared
/// [HrPayroll] bundle (allowances, bonus, payslips, advances, loans).
class DriverProfile {
  final Driver driver;
  final double? salary;
  final String? salaryCurrency;
  final double? bonus;
  final String? position;
  final String? department;
  final HrPayroll? payroll;

  DriverProfile({
    required this.driver,
    this.salary,
    this.salaryCurrency,
    this.bonus,
    this.position,
    this.department,
    this.payroll,
  });

  /// Parses the `driver` envelope, which embeds an optional `hr` sub-object.
  factory DriverProfile.fromJson(Map<String, dynamic> j) {
    final driver = Driver.fromJson(j);
    final hr = j['hr'];
    if (hr is! Map<String, dynamic>) return DriverProfile(driver: driver);

    return DriverProfile(
      driver: driver,
      salary: hr['salary'] == null ? null : hrMoney(hr['salary']),
      salaryCurrency: hr['salary_currency']?.toString(),
      bonus: hr['bonus'] == null ? null : hrMoney(hr['bonus']),
      position: hr['position']?.toString(),
      department: hr['department']?.toString(),
      payroll: HrPayroll.fromJson(hr),
    );
  }

  bool get hasPay => salary != null || (payroll != null && !payroll!.isEmpty);
}
