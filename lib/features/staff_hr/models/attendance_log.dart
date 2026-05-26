/// A daily attendance summary row, mirroring one entry of
/// `GET /staff/hr/attendance` (`Api/Staff/HrController@attendance`).
///
/// Each row collapses an employee's punches for a single day into the first
/// check-in and (optionally) the last check-out.
class AttendanceLog {
  final int employeeId;
  final String employeeName;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // 'present' (checked out) | 'in' (still in)

  AttendanceLog({
    required this.employeeId,
    required this.employeeName,
    this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> j) => AttendanceLog(
        employeeId: int.tryParse((j['employee_id'] ?? 0).toString()) ?? 0,
        employeeName: (j['employee_name'] ?? '—').toString(),
        date: j['date'] != null ? DateTime.tryParse(j['date'].toString()) : null,
        checkIn: j['check_in'] != null ? DateTime.tryParse(j['check_in'].toString()) : null,
        checkOut: j['check_out'] != null ? DateTime.tryParse(j['check_out'].toString()) : null,
        status: (j['status'] ?? 'in').toString(),
      );

  String get statusLabel => status == 'present' ? 'Present' : 'Checked In';
}
