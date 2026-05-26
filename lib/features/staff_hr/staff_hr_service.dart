import '../../core/api/api_client.dart';
import 'models/approval_item.dart';
import 'models/attendance_log.dart';

/// Talks to the staff HR endpoints (`/staff/hr/*`).
///
/// All approve/reject actions return after the server confirms the update so
/// the caller can refresh its inbox optimistically.
class StaffHrService {
  final ApiClient _api;
  StaffHrService(this._api);

  /// Pending approvals inbox across leave, advances and loans. Sections the
  /// user cannot view are omitted by the server and parse to empty lists.
  Future<HrApprovals> fetchApprovals() async {
    final json = await _api.get('/staff/hr/approvals') as Map<String, dynamic>;
    return HrApprovals.fromJson(json);
  }

  // ── Leave ─────────────────────────────────────────────────────────────────

  Future<void> approveLeave(int id) async {
    await _api.post('/staff/hr/leave/$id/approve', {});
  }

  Future<void> rejectLeave(int id) async {
    await _api.post('/staff/hr/leave/$id/reject', {});
  }

  // ── Advances ────────────────────────────────────────────────────────────────

  Future<void> approveAdvance(int id) async {
    await _api.post('/staff/hr/advances/$id/approve', {});
  }

  Future<void> rejectAdvance(int id) async {
    await _api.post('/staff/hr/advances/$id/reject', {});
  }

  // ── Loans ─────────────────────────────────────────────────────────────────

  Future<void> approveLoan(int id) async {
    await _api.post('/staff/hr/loans/$id/approve', {});
  }

  Future<void> rejectLoan(int id) async {
    await _api.post('/staff/hr/loans/$id/reject', {});
  }

  // ── Attendance ──────────────────────────────────────────────────────────────

  /// Daily attendance summary for the current week.
  Future<List<AttendanceLog>> fetchAttendance() async {
    final json = await _api.get('/staff/hr/attendance') as Map<String, dynamic>;
    final data = (json['attendance'] as List? ?? []);
    return data
        .map((e) => AttendanceLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
