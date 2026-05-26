import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/approval_item.dart';
import '../models/attendance_log.dart';
import '../staff_hr_service.dart';

/// HR officer / admin home: an approvals inbox (Leave / Advances / Loans) with
/// approve & reject actions, plus a weekly attendance view.
///
/// Self-contained feature entry widget — Agent 6's shell hosts it as a tab, so
/// it provides its own internal navigation (top tabs + segmented inbox) and
/// does NOT render the driver bottom nav.
class HrHomeScreen extends StatefulWidget {
  const HrHomeScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<HrHomeScreen> createState() => _HrHomeScreenState();
}

class _HrHomeScreenState extends State<HrHomeScreen> {
  late final StaffHrService _service;

  // Top-level view: approvals inbox vs. attendance.
  int _tab = 0;

  // Approvals state.
  HrApprovals? _approvals;
  bool _approvalsLoading = true;
  String? _approvalsError;
  int _segment = 0; // 0 = leave, 1 = advances, 2 = loans
  final Set<String> _busy = {}; // keys like 'leave-12' currently submitting

  // Attendance state.
  List<AttendanceLog>? _attendance;
  bool _attendanceLoading = false; // lazily loaded on first visit
  String? _attendanceError;
  bool _attendanceLoaded = false;

  @override
  void initState() {
    super.initState();
    _service = StaffHrService(widget.apiClient);
    _loadApprovals();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadApprovals() async {
    setState(() {
      _approvalsLoading = true;
      _approvalsError = null;
    });
    try {
      final data = await _service.fetchApprovals();
      if (mounted) setState(() => _approvals = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _approvalsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _approvalsError = 'Unable to load approvals.');
    } finally {
      if (mounted) setState(() => _approvalsLoading = false);
    }
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
    });
    try {
      final data = await _service.fetchAttendance();
      if (mounted) setState(() => _attendance = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _attendanceError = e.message);
    } catch (_) {
      if (mounted) setState(() => _attendanceError = 'Unable to load attendance.');
    } finally {
      if (mounted) {
        setState(() {
          _attendanceLoading = false;
          _attendanceLoaded = true;
        });
      }
    }
  }

  void _onTabChanged(int tab) {
    setState(() => _tab = tab);
    if (tab == 1 && !_attendanceLoaded) _loadAttendance();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'People & approvals',
            title: 'Human Resources',
            subtitle: _tab == 0 ? 'Pending approvals' : 'Attendance this week',
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: _tab == 0 ? _loadApprovals : _loadAttendance,
              ),
            ],
          ),
          _buildTabBar(),
          Expanded(child: _tab == 0 ? _buildApprovalsTab() : _buildAttendanceTab()),
        ],
      ),
    );
  }

  // ── Top tab bar (Approvals / Attendance) ──────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _topTab('Approvals', Icons.inbox_rounded, 0),
          const SizedBox(width: 8),
          _topTab('Attendance', Icons.fact_check_rounded, 1),
        ],
      ),
    );
  }

  Widget _topTab(String label, IconData icon, int index) {
    final selected = _tab == index;
    final pending = index == 0 ? _pendingCount() : null;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: ModuleAccent.hr.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.border(context),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: ModuleAccent.hr.base.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : kMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppType.body(
                  13,
                  weight: FontWeight.w600,
                  color: selected ? Colors.white : kMuted,
                ),
              ),
              if (pending != null && pending > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : ModuleAccent.hr.base.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pending',
                    style: AppType.number(
                      10,
                      weight: FontWeight.w700,
                      color: selected ? Colors.white : ModuleAccent.hr.base,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _pendingCount() {
    final a = _approvals;
    if (a == null) return 0;
    return a.leave.length + a.advances.length + a.loans.length;
  }

  // ── Approvals tab ─────────────────────────────────────────────────────────────

  Widget _buildApprovalsTab() {
    if (_approvalsLoading) return _buildSkeleton();
    if (_approvalsError != null) {
      return _buildErrorState(_approvalsError!, _loadApprovals);
    }

    return Column(
      children: [
        _buildSegmented(),
        Expanded(
          child: RefreshIndicator(
            color: ModuleAccent.hr.base,
            onRefresh: _loadApprovals,
            child: _buildSegmentList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmented() {
    final a = _approvals;
    final segments = [
      ('Leave', a?.leave.length ?? 0),
      ('Advances', a?.advances.length ?? 0),
      ('Loans', a?.loans.length ?? 0),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: List.generate(segments.length, (i) {
          final (label, count) = segments[i];
          final selected = _segment == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < segments.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _segment = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? ModuleAccent.hr.base.withValues(alpha: 0.12)
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? ModuleAccent.hr.base : AppColors.border(context),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count > 0 ? '$label ($count)' : label,
                      style: AppType.body(
                        12,
                        weight: FontWeight.w600,
                        color: selected ? ModuleAccent.hr.base : kMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSegmentList() {
    final a = _approvals!;
    switch (_segment) {
      case 1:
        return _list(
          a.advances,
          empty: 'No pending approvals',
          builder: (adv) => _AdvanceCard(
            advance: adv,
            busy: _busy.contains('advance-${adv.id}'),
            canEdit: AppSession.instance.can('hr_advances.edit'),
            onApprove: () => _runAction(kind: 'advance', id: adv.id, approve: true),
            onReject: () => _runAction(kind: 'advance', id: adv.id, approve: false),
          ),
        );
      case 2:
        return _list(
          a.loans,
          empty: 'No pending approvals',
          builder: (loan) => _LoanCard(
            loan: loan,
            busy: _busy.contains('loan-${loan.id}'),
            canEdit: AppSession.instance.can('hr_loans.edit'),
            onApprove: () => _runAction(kind: 'loan', id: loan.id, approve: true),
            onReject: () => _runAction(kind: 'loan', id: loan.id, approve: false),
          ),
        );
      default:
        return _list(
          a.leave,
          empty: 'No pending approvals',
          builder: (leave) => _LeaveCard(
            leave: leave,
            busy: _busy.contains('leave-${leave.id}'),
            canEdit: AppSession.instance.can('hr_leave.edit'),
            onApprove: () => _runAction(kind: 'leave', id: leave.id, approve: true),
            onReject: () => _runAction(kind: 'leave', id: leave.id, approve: false),
          ),
        );
    }
  }

  Widget _list<T>(
    List<T> items, {
    required String empty,
    required Widget Function(T) builder,
  }) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: AppEmpty(icon: Icons.how_to_reg_rounded, message: empty),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RevealOnLoad(
          delayMs: (i * 60).clamp(0, 300),
          child: builder(items[i]),
        ),
      ),
    );
  }

  // ── Action runner: confirm → call → optimistic remove → snackbar ──────────────

  Future<void> _runAction({
    required String kind, // 'leave' | 'advance' | 'loan'
    required int id,
    required bool approve,
  }) async {
    final verb = approve ? 'Approve' : 'Reject';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$verb request', style: AppType.display(18)),
        content: Text(
          'Are you sure you want to ${verb.toLowerCase()} this $kind request?',
          style: AppType.body(14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? kSuccess : kDanger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(verb),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final key = '$kind-$id';
    setState(() => _busy.add(key));
    try {
      switch (kind) {
        case 'advance':
          approve ? await _service.approveAdvance(id) : await _service.rejectAdvance(id);
          break;
        case 'loan':
          approve ? await _service.approveLoan(id) : await _service.rejectLoan(id);
          break;
        default:
          approve ? await _service.approveLeave(id) : await _service.rejectLeave(id);
      }
      // Optimistic refresh: drop the resolved item from the inbox immediately.
      if (mounted) {
        setState(() {
          final a = _approvals;
          if (a != null) {
            switch (kind) {
              case 'advance':
                a.advances.removeWhere((e) => e.id == id);
                break;
              case 'loan':
                a.loans.removeWhere((e) => e.id == id);
                break;
              default:
                a.leave.removeWhere((e) => e.id == id);
            }
          }
        });
        _showSnack('${_label(kind)} request ${approve ? 'approved' : 'rejected'}.', kSuccess);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, kDanger);
    } catch (_) {
      if (mounted) _showSnack('Action failed. Please try again.', kDanger);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  String _label(String kind) {
    switch (kind) {
      case 'advance':
        return 'Advance';
      case 'loan':
        return 'Loan';
      default:
        return 'Leave';
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppType.body(13.5, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Attendance tab ────────────────────────────────────────────────────────────

  Widget _buildAttendanceTab() {
    if (_attendanceLoading) return _buildSkeleton();
    if (_attendanceError != null) {
      return _buildErrorState(_attendanceError!, _loadAttendance);
    }

    final logs = _attendance ?? [];
    return RefreshIndicator(
      color: ModuleAccent.hr.base,
      onRefresh: _loadAttendance,
      child: logs.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: const AppEmpty(
                    icon: Icons.fact_check_rounded,
                    message: 'No attendance records',
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: logs.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RevealOnLoad(
                  delayMs: (i * 60).clamp(0, 300),
                  child: _AttendanceCard(log: logs[i]),
                ),
              ),
            ),
    );
  }

  // ── Shared states ─────────────────────────────────────────────────────────────

  Widget _buildErrorState(String message, Future<void> Function() retry) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: AppError(message: message, onRetry: () => retry()),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 4; i++) ...[
            AppSkeleton.box(context, height: 150, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Local time-of-day formatter (e.g. `08:05`). Kept here rather than touching
/// the shared `core/utils/formatters.dart`, which is owned by another agent.
String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ── Card: shared shell ──────────────────────────────────────────────────────────

class _ApprovalCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> rows;
  final bool busy;
  final bool canEdit;
  final Color accentColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.title,
    this.trailing,
    required this.rows,
    required this.busy,
    required this.canEdit,
    required this.accentColor,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppType.display(15.5, color: AppColors.textNavy(context)),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
          if (canEdit) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: busy ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: kDanger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: busy ? null : onApprove,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kSuccess),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kSuccess.withValues(alpha: 0.14),
                      foregroundColor: kSuccess,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: kMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppType.body(13, color: AppColors.textPrimary(context))),
          ),
        ],
      ),
    );
  }
}

// ── Card: leave ──────────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final LeaveApproval leave;
  final bool busy;
  final bool canEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveCard({
    required this.leave,
    required this.busy,
    required this.canEdit,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _ApprovalCard(
      title: leave.employeeName,
      busy: busy,
      canEdit: canEdit,
      accentColor: ModuleAccent.hr.base,
      onApprove: onApprove,
      onReject: onReject,
      trailing: StatusPill(label: leave.typeLabel, color: ModuleAccent.hr.base),
      rows: [
        _InfoRow(
          icon: Icons.date_range_rounded,
          text: '${formatDate(leave.startDate)} → ${formatDate(leave.endDate)}'
              '  ·  ${leave.days} day${leave.days == 1 ? '' : 's'}',
        ),
        if (leave.reason != null && leave.reason!.isNotEmpty)
          _InfoRow(icon: Icons.notes_rounded, text: leave.reason!),
      ],
    );
  }
}

// ── Card: advance ──────────────────────────────────────────────────────────────

class _AdvanceCard extends StatelessWidget {
  final AdvanceApproval advance;
  final bool busy;
  final bool canEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdvanceCard({
    required this.advance,
    required this.busy,
    required this.canEdit,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _ApprovalCard(
      title: advance.employeeName,
      busy: busy,
      canEdit: canEdit,
      accentColor: ModuleAccent.finance.base,
      onApprove: onApprove,
      onReject: onReject,
      trailing: _AmountBadge(amount: advance.amount),
      rows: [
        if (advance.purpose != null && advance.purpose!.isNotEmpty)
          _InfoRow(icon: Icons.notes_rounded, text: advance.purpose!),
        _InfoRow(icon: Icons.event_rounded, text: 'Requested ${formatDate(advance.requestedDate)}'),
      ],
    );
  }
}

// ── Card: loan ──────────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final LoanApproval loan;
  final bool busy;
  final bool canEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LoanCard({
    required this.loan,
    required this.busy,
    required this.canEdit,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _ApprovalCard(
      title: loan.employeeName,
      busy: busy,
      canEdit: canEdit,
      accentColor: ModuleAccent.finance.base,
      onApprove: onApprove,
      onReject: onReject,
      trailing: _AmountBadge(amount: loan.principal),
      rows: [
        if (loan.loanNumber != null && loan.loanNumber!.isNotEmpty)
          _InfoRow(icon: Icons.tag_rounded, text: loan.loanNumber!),
        _InfoRow(
          icon: Icons.calendar_month_rounded,
          text: '${formatCurrency(loan.monthlyInstallment)} / mo · ${loan.totalMonths} months',
        ),
        if (loan.startDate != null)
          _InfoRow(icon: Icons.event_rounded, text: 'Starts ${formatDate(loan.startDate)}'),
        if (loan.purpose != null && loan.purpose!.isNotEmpty)
          _InfoRow(icon: Icons.notes_rounded, text: loan.purpose!),
      ],
    );
  }
}

// ── Card: attendance ──────────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final AttendanceLog log;
  const _AttendanceCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final present = log.status == 'present';
    final color = present ? kSuccess : kWarning;
    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(present ? Icons.check_circle_rounded : Icons.login_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.employeeName,
                    style: AppType.display(14.5, color: AppColors.textNavy(context))),
                const SizedBox(height: 4),
                Text(
                  formatDate(log.date),
                  style: AppType.body(12, color: kMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Punch(label: 'In', time: log.checkIn),
                    const SizedBox(width: 16),
                    _Punch(label: 'Out', time: log.checkOut),
                  ],
                ),
              ],
            ),
          ),
          StatusPill(label: log.statusLabel, color: color),
        ],
      ),
    );
  }
}

class _Punch extends StatelessWidget {
  final String label;
  final DateTime? time;
  const _Punch({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label ', style: AppType.body(11, color: kMuted, weight: FontWeight.w500)),
        Text(
          time != null ? _formatTime(time!) : '—',
          style: AppType.number(12, weight: FontWeight.w700, color: AppColors.textPrimary(context)),
        ),
      ],
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────────

class _AmountBadge extends StatelessWidget {
  final double amount;
  const _AmountBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCurrency(amount),
      style: AppType.number(15, color: ModuleAccent.finance.base),
    );
  }
}
