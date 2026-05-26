import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../mod_payroll/widgets/hr_cards.dart';
import '../models/employee.dart';
import '../mod_employees_service.dart';

/// Read-only detail for a single employee: identity, role, contact,
/// compensation and emergency contact.
class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final ModEmployeesService service;

  /// The list-row summary, shown immediately while the full record loads.
  final Employee? initial;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.service,
    this.initial,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late Future<Employee> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchEmployee(widget.employeeId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchEmployee(widget.employeeId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Employee>(
      future: _future,
      builder: (context, snapshot) {
        final employee = snapshot.data ?? widget.initial;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(employee),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(Employee? employee) {
    return AppGradientHeader(
      eyebrow: 'People',
      title: employee?.name ?? 'Employee',
      subtitle: employee?.statusLabel,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _body(AsyncSnapshot<Employee> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && widget.initial == null) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null && widget.initial == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final e = snapshot.data ?? widget.initial!;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _statusCard(e)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _roleCard(e)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _contactCard(e)),
            if (_hasCompensation(e) || e.hr?.bank != null) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 180, child: _compensationCard(e)),
            ],
            if (e.hr != null)
              ...hrPayrollCards(context, e.hr!,
                  currency: e.salaryCurrency, startDelayMs: 210),
            if (e.emergencyContactName != null &&
                e.emergencyContactName!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 240, child: _emergencyCard(e)),
            ],
            if (e.notes != null && e.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 300,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(e.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 90, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 140, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
        ],
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _statusCard(Employee e) {
    final color = e.statusColor;
    return AppCard(
      accentColor: color,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(e.name),
              style: AppType.number(18, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: AppType.display(18, color: AppColors.textNavy(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(label: e.statusLabel, color: color),
                    if (e.employeeNumber != null && e.employeeNumber!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          e.employeeNumber!,
                          style: AppType.number(13, color: kMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard(Employee e) {
    return _SectionCard(
      title: 'Role',
      eyebrow: 'Employment',
      icon: Icons.work_outline_rounded,
      children: [
        _InfoRow(label: 'Position', value: e.position ?? '—'),
        _InfoRow(label: 'Department', value: e.department ?? '—'),
        _InfoRow(label: 'Employee no.', value: e.employeeNumber ?? '—'),
        _InfoRow(label: 'Hire date', value: formatDate(e.hireDate)),
      ],
    );
  }

  Widget _contactCard(Employee e) {
    return _SectionCard(
      title: 'Contact & Identity',
      eyebrow: 'Details',
      icon: Icons.person_outline_rounded,
      children: [
        _InfoRow(label: 'Phone', value: e.phone ?? '—'),
        if (e.email != null && e.email!.isNotEmpty)
          _InfoRow(label: 'Email', value: e.email!),
        if (e.nationalId != null && e.nationalId!.isNotEmpty)
          _InfoRow(label: 'National ID', value: e.nationalId!),
        if (e.birthDate != null)
          _InfoRow(label: 'Date of birth', value: formatDate(e.birthDate)),
        if (e.address != null && e.address!.isNotEmpty)
          _InfoRow(label: 'Address', value: e.address!),
      ],
    );
  }

  Widget _compensationCard(Employee e) {
    final bank = e.hr?.bank;
    return _SectionCard(
      title: 'Compensation',
      eyebrow: 'Payroll',
      icon: Icons.payments_outlined,
      children: [
        if (e.salary != null)
          _InfoRow(label: 'Salary', value: _money(e.salary, e.salaryCurrency)),
        if (e.bonus != null && e.bonus! > 0)
          _InfoRow(label: 'Bonus', value: _money(e.bonus, e.salaryCurrency)),
        if (bank?.bankName != null && bank!.bankName!.isNotEmpty) ...[
          const Divider(height: 22),
          _InfoRow(label: 'Bank', value: bank.bankName!),
          if (bank.accountNumber != null && bank.accountNumber!.isNotEmpty)
            _InfoRow(label: 'Account', value: bank.accountNumber!),
          if (bank.accountName != null && bank.accountName!.isNotEmpty)
            _InfoRow(label: 'Account name', value: bank.accountName!),
        ],
      ],
    );
  }

  Widget _emergencyCard(Employee e) {
    return _SectionCard(
      title: 'Emergency Contact',
      eyebrow: 'Next of kin',
      icon: Icons.contact_phone_outlined,
      children: [
        _InfoRow(label: 'Name', value: e.emergencyContactName ?? '—'),
        if (e.emergencyContactPhone != null && e.emergencyContactPhone!.isNotEmpty)
          _InfoRow(label: 'Phone', value: e.emergencyContactPhone!),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _hasCompensation(Employee e) =>
      (e.salary != null && e.salary! > 0) || (e.bonus != null && e.bonus! > 0);

  static String _money(double? amount, String? currency) {
    if (amount == null) return '—';
    final cur = (currency == null || currency.isEmpty) ? 'TZS' : currency;
    return '$cur ${NumberFormat('#,###').format(amount)}';
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final s = parts.map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, this.eyebrow, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.brand),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(label, style: AppType.body(12.5, color: kMuted, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppType.body(13.5, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}
