/// HR approval inbox models — leave requests, employee advances and loans.
///
/// Each mirrors the corresponding section of `GET /staff/hr/approvals`
/// (see web `Api/Staff/HrController@approvals`). Money fields are parsed
/// leniently because the API may return them as numeric or string.
library;

double _money(dynamic v) => double.tryParse((v ?? 0).toString()) ?? 0;

DateTime? _date(dynamic v) =>
    v != null ? DateTime.tryParse(v.toString()) : null;

/// A pending leave request awaiting approval.
class LeaveApproval {
  final int id;
  final String employeeName;
  final String type;
  final String typeLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final int days;
  final String? reason;
  final String status;

  LeaveApproval({
    required this.id,
    required this.employeeName,
    required this.type,
    required this.typeLabel,
    this.startDate,
    this.endDate,
    required this.days,
    this.reason,
    required this.status,
  });

  factory LeaveApproval.fromJson(Map<String, dynamic> j) => LeaveApproval(
        id: j['id'] as int,
        employeeName: (j['employee_name'] ?? '—').toString(),
        type: (j['type'] ?? '').toString(),
        typeLabel: (j['type_label'] ?? j['type'] ?? '').toString(),
        startDate: _date(j['start_date']),
        endDate: _date(j['end_date']),
        days: int.tryParse((j['days'] ?? 0).toString()) ?? 0,
        reason: j['reason'] as String?,
        status: (j['status'] ?? 'pending').toString(),
      );
}

/// A pending salary advance request awaiting approval.
class AdvanceApproval {
  final int id;
  final String employeeName;
  final double amount;
  final String? purpose;
  final DateTime? requestedDate;
  final String status;

  AdvanceApproval({
    required this.id,
    required this.employeeName,
    required this.amount,
    this.purpose,
    this.requestedDate,
    required this.status,
  });

  factory AdvanceApproval.fromJson(Map<String, dynamic> j) => AdvanceApproval(
        id: j['id'] as int,
        employeeName: (j['employee_name'] ?? '—').toString(),
        amount: _money(j['amount']),
        purpose: j['purpose'] as String?,
        requestedDate: _date(j['requested_date']),
        status: (j['status'] ?? 'pending').toString(),
      );
}

/// A pending staff loan request awaiting approval.
class LoanApproval {
  final int id;
  final String employeeName;
  final String? loanNumber;
  final double principal;
  final double monthlyInstallment;
  final int totalMonths;
  final DateTime? startDate;
  final String? purpose;
  final String status;

  LoanApproval({
    required this.id,
    required this.employeeName,
    this.loanNumber,
    required this.principal,
    required this.monthlyInstallment,
    required this.totalMonths,
    this.startDate,
    this.purpose,
    required this.status,
  });

  factory LoanApproval.fromJson(Map<String, dynamic> j) => LoanApproval(
        id: j['id'] as int,
        employeeName: (j['employee_name'] ?? '—').toString(),
        loanNumber: j['loan_number'] as String?,
        principal: _money(j['principal']),
        monthlyInstallment: _money(j['monthly_installment']),
        totalMonths: int.tryParse((j['total_months'] ?? 0).toString()) ?? 0,
        startDate: _date(j['start_date']),
        purpose: j['purpose'] as String?,
        status: (j['status'] ?? 'pending').toString(),
      );
}

/// The full approvals inbox payload returned by `GET /staff/hr/approvals`.
///
/// Sections the user lacks permission to view are simply absent from the
/// response, so each list defaults to empty.
class HrApprovals {
  final List<LeaveApproval> leave;
  final List<AdvanceApproval> advances;
  final List<LoanApproval> loans;

  HrApprovals({
    required this.leave,
    required this.advances,
    required this.loans,
  });

  factory HrApprovals.fromJson(Map<String, dynamic> j) => HrApprovals(
        leave: ((j['leave'] as List?) ?? [])
            .map((e) => LeaveApproval.fromJson(e as Map<String, dynamic>))
            .toList(),
        advances: ((j['advances'] as List?) ?? [])
            .map((e) => AdvanceApproval.fromJson(e as Map<String, dynamic>))
            .toList(),
        loans: ((j['loans'] as List?) ?? [])
            .map((e) => LoanApproval.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
