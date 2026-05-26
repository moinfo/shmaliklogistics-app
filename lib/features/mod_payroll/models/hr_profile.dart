import 'package:flutter/material.dart';

import 'salary_slip.dart';

/// Shared HR/payroll value-objects emitted by the `BuildsHrPayroll` backend
/// trait. Consumed by both the Employees module screen and the Drivers screen
/// (a driver is matched to an employee by national ID). Keeping these here, in
/// the payroll feature, lets both screens render identical HR cards.

/// Parses a backend status hex (e.g. "#F59E0B") into a [Color], falling back to
/// slate grey when absent/malformed.
Color hrHexColor(String? hex) {
  if (hex == null) return const Color(0xFF475569);
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return const Color(0xFF475569);
  return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
}

double hrMoney(dynamic v) => v == null ? 0 : double.tryParse(v.toString()) ?? 0;

/// Whole-shilling money formatter (payroll amounts are effectively whole),
/// prefixed with the package currency or TZS.
String hrFormatMoney(double v, [String? currency]) {
  final whole = v.round();
  final s = whole.abs().toString();
  final b = StringBuffer(whole < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${currency ?? 'TZS'} $b';
}

/// A recurring allowance line on the employee's package.
class HrAllowance {
  final int id;
  final String name;
  final String? type;
  final double amount;
  final bool isTaxable;

  HrAllowance({
    required this.id,
    required this.name,
    this.type,
    required this.amount,
    this.isTaxable = false,
  });

  factory HrAllowance.fromJson(Map<String, dynamic> j) => HrAllowance(
        id: j['id'] ?? 0,
        name: (j['name'] ?? '—').toString(),
        type: j['type']?.toString(),
        amount: hrMoney(j['amount']),
        isTaxable: j['is_taxable'] == true,
      );
}

/// A salary advance (pending or approved, awaiting deduction).
class HrAdvance {
  final int id;
  final double amount;
  final String? purpose;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final DateTime? requestedDate;

  HrAdvance({
    required this.id,
    required this.amount,
    this.purpose,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.requestedDate,
  });

  factory HrAdvance.fromJson(Map<String, dynamic> j) => HrAdvance(
        id: j['id'] ?? 0,
        amount: hrMoney(j['amount']),
        purpose: j['purpose']?.toString(),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColorHex: j['status_color']?.toString(),
        requestedDate: _date(j['requested_date']),
      );

  Color get statusColor => hrHexColor(statusColorHex);

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

/// An active or pending staff loan with its repayment progress.
class HrLoan {
  final int id;
  final String? loanNumber;
  final double principal;
  final double balanceRemaining;
  final double monthlyInstallment;
  final int? monthsPaid;
  final int? totalMonths;
  final String status;
  final String statusLabel;
  final String? statusColorHex;

  HrLoan({
    required this.id,
    this.loanNumber,
    required this.principal,
    required this.balanceRemaining,
    required this.monthlyInstallment,
    this.monthsPaid,
    this.totalMonths,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
  });

  factory HrLoan.fromJson(Map<String, dynamic> j) => HrLoan(
        id: j['id'] ?? 0,
        loanNumber: j['loan_number']?.toString(),
        principal: hrMoney(j['principal']),
        balanceRemaining: hrMoney(j['balance_remaining']),
        monthlyInstallment: hrMoney(j['monthly_installment']),
        monthsPaid: j['months_paid'] == null
            ? null
            : int.tryParse(j['months_paid'].toString()),
        totalMonths: j['total_months'] == null
            ? null
            : int.tryParse(j['total_months'].toString()),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColorHex: j['status_color']?.toString(),
      );

  Color get statusColor => hrHexColor(statusColorHex);

  /// Fraction repaid (0–1) based on principal vs. remaining balance.
  double get progress {
    if (principal <= 0) return 0;
    return ((principal - balanceRemaining) / principal).clamp(0, 1);
  }
}

/// Employee bank account on file (primary preferred).
class HrBank {
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? branch;

  HrBank({this.bankName, this.accountNumber, this.accountName, this.branch});

  factory HrBank.fromJson(Map<String, dynamic> j) => HrBank(
        bankName: j['bank_name']?.toString(),
        accountNumber: j['account_number']?.toString(),
        accountName: j['account_name']?.toString(),
        branch: j['branch']?.toString(),
      );
}

/// A recorded infraction (*kosa*) that penalises the performance bonus.
class HrInfraction {
  final int id;
  final String? ruleName;
  final double amount;
  final DateTime? occurredOn;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? notes;

  HrInfraction({
    required this.id,
    this.ruleName,
    required this.amount,
    this.occurredOn,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.notes,
  });

  factory HrInfraction.fromJson(Map<String, dynamic> j) => HrInfraction(
        id: j['id'] ?? 0,
        ruleName: j['rule_name']?.toString(),
        amount: hrMoney(j['amount']),
        occurredOn: _date(j['occurred_on']),
        status: (j['status'] ?? '').toString(),
        statusLabel: (j['status_label'] ?? j['status'] ?? '').toString(),
        statusColorHex: j['status_color']?.toString(),
        notes: j['notes']?.toString(),
      );

  Color get statusColor => hrHexColor(statusColorHex);

  /// Waived infractions are forgiven and do not reduce the bonus.
  bool get waived => status == 'waived';

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

/// The performance-bonus picture: the effective bonus (employee standing bonus
/// or department policy), recorded infractions and the resulting net bonus.
class HrBonus {
  final String? department;
  final double? policyAmount;
  final double? standingBonus;
  final double effectiveBonus;
  final List<HrInfraction> infractions;
  final double penaltiesTotal;
  final double netBonus;

  HrBonus({
    this.department,
    this.policyAmount,
    this.standingBonus,
    this.effectiveBonus = 0,
    this.infractions = const [],
    this.penaltiesTotal = 0,
    this.netBonus = 0,
  });

  factory HrBonus.fromJson(Map<String, dynamic> j) => HrBonus(
        department: j['department']?.toString(),
        policyAmount: j['policy_amount'] == null ? null : hrMoney(j['policy_amount']),
        standingBonus: j['standing_bonus'] == null ? null : hrMoney(j['standing_bonus']),
        effectiveBonus: hrMoney(j['effective_bonus']),
        infractions: (j['infractions'] as List? ?? const [])
            .map((e) => HrInfraction.fromJson(e as Map<String, dynamic>))
            .toList(),
        penaltiesTotal: hrMoney(j['penalties_total']),
        netBonus: hrMoney(j['net_bonus']),
      );

  /// Worth rendering when there's any bonus figure or infraction history.
  bool get hasContent =>
      effectiveBonus > 0 || netBonus > 0 || infractions.isNotEmpty;
}

/// The shared payroll bundle: bank, active allowances, open advances/loans,
/// recent payslips and the performance-bonus picture. Sub-sections arrive empty
/// or null when the viewer lacks the corresponding HR permission.
class HrPayroll {
  final HrBank? bank;
  final List<HrAllowance> allowances;
  final double allowancesTotal;
  final List<HrAdvance> advances;
  final List<HrLoan> loans;
  final double loanBalanceTotal;
  final List<SalarySlip> slips;
  final HrBonus? bonus;

  HrPayroll({
    this.bank,
    this.allowances = const [],
    this.allowancesTotal = 0,
    this.advances = const [],
    this.loans = const [],
    this.loanBalanceTotal = 0,
    this.slips = const [],
    this.bonus,
  });

  factory HrPayroll.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
        (j[key] as List? ?? const [])
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();

    final bank = j['bank'];
    return HrPayroll(
      bank: bank is Map<String, dynamic> ? HrBank.fromJson(bank) : null,
      allowances: list('allowances', HrAllowance.fromJson),
      allowancesTotal: hrMoney(j['allowances_total']),
      advances: list('advances', HrAdvance.fromJson),
      loans: list('loans', HrLoan.fromJson),
      loanBalanceTotal: hrMoney(j['loan_balance_total']),
      slips: list('slips', SalarySlip.fromJson),
      bonus: j['bonus_summary'] is Map<String, dynamic>
          ? HrBonus.fromJson(j['bonus_summary'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Most recent payslip (the backend returns slips newest-period first).
  SalarySlip? get latestSlip => slips.isEmpty ? null : slips.first;

  bool get hasLiabilities => advances.isNotEmpty || loans.isNotEmpty;

  /// True when there is anything worth rendering beyond the base record.
  bool get isEmpty =>
      allowances.isEmpty && advances.isEmpty && loans.isEmpty && slips.isEmpty;
}
