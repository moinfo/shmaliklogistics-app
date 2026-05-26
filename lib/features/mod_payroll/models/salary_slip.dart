/// A salary slip (`payroll_slips` row) flattened for the mobile app.
///
/// The related employee and period names are flattened inline by the API
/// (`employee_name`, `period_label`, …); all money fields arrive as numbers.
class SalarySlip {
  final int id;
  final int payrollRunId;
  final int employeeId;
  final String employeeName;
  final String? employeeNumber;
  final String? department;
  final String? position;
  final int? periodYear;
  final int? periodMonth;
  final String? periodLabel;
  final String? runStatus;
  final String? runDocument;

  final double basicSalary;
  final double allowances;
  final double overtime;
  final double bonus;
  final double bonusPenalty;
  final double grossSalary;
  final double paye;
  final double nssfEmployee;
  final double nhifEmployee;
  final double heslb;
  final double otherDeductions;
  final double advanceDeduction;
  final double loanDeduction;
  final double loanBalance;
  final double adjustment;
  final double totalDeductions;
  final double netSalary;
  final String? notes;

  SalarySlip({
    required this.id,
    required this.payrollRunId,
    required this.employeeId,
    required this.employeeName,
    this.employeeNumber,
    this.department,
    this.position,
    this.periodYear,
    this.periodMonth,
    this.periodLabel,
    this.runStatus,
    this.runDocument,
    required this.basicSalary,
    required this.allowances,
    required this.overtime,
    required this.bonus,
    required this.bonusPenalty,
    required this.grossSalary,
    required this.paye,
    required this.nssfEmployee,
    required this.nhifEmployee,
    required this.heslb,
    required this.otherDeductions,
    required this.advanceDeduction,
    required this.loanDeduction,
    required this.loanBalance,
    required this.adjustment,
    required this.totalDeductions,
    required this.netSalary,
    this.notes,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> j) => SalarySlip(
        id: j['id'] ?? 0,
        payrollRunId: _int(j['payroll_run_id']),
        employeeId: _int(j['employee_id']),
        employeeName: (j['employee_name'] ?? 'Unknown').toString(),
        employeeNumber: j['employee_number']?.toString(),
        department: j['department']?.toString(),
        position: j['position']?.toString(),
        periodYear: j['period_year'] == null ? null : _int(j['period_year']),
        periodMonth: j['period_month'] == null ? null : _int(j['period_month']),
        periodLabel: j['period_label']?.toString(),
        runStatus: j['run_status']?.toString(),
        runDocument: j['run_document']?.toString(),
        basicSalary: _money(j['basic_salary']),
        allowances: _money(j['allowances']),
        overtime: _money(j['overtime']),
        bonus: _money(j['bonus']),
        bonusPenalty: _money(j['bonus_penalty']),
        grossSalary: _money(j['gross_salary']),
        paye: _money(j['paye']),
        nssfEmployee: _money(j['nssf_employee']),
        nhifEmployee: _money(j['nhif_employee']),
        heslb: _money(j['heslb']),
        otherDeductions: _money(j['other_deductions']),
        advanceDeduction: _money(j['advance_deduction']),
        loanDeduction: _money(j['loan_deduction']),
        loanBalance: _money(j['loan_balance']),
        adjustment: _money(j['adjustment']),
        totalDeductions: _money(j['total_deductions']),
        netSalary: _money(j['net_salary']),
        notes: j['notes']?.toString(),
      );

  /// Net-bonus actually paid (bonus less any penalty), clamped at zero.
  double get netBonus =>
      (bonus - bonusPenalty) < 0 ? 0 : (bonus - bonusPenalty);

  static int _int(dynamic v) =>
      v == null ? 0 : int.tryParse(v.toString()) ?? 0;

  static double _money(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;
}
