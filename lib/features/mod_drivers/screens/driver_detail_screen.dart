import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../mod_payroll/models/hr_profile.dart';
import '../../mod_payroll/widgets/hr_cards.dart';
import '../models/driver.dart';
import '../models/driver_hr.dart';
import '../mod_drivers_service.dart';
import '../widgets/driver_avatar.dart';

/// Read-only detail for a single driver: identity, contact, licence,
/// assigned vehicle and recent trips.
class DriverDetailScreen extends StatefulWidget {
  final int driverId;
  final ModDriversService service;

  /// The list-row summary, shown immediately while the full record loads.
  final Driver? initial;

  const DriverDetailScreen({
    super.key,
    required this.driverId,
    required this.service,
    this.initial,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  late Future<Driver> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchDriver(widget.driverId);
  }

  void _reload() => setState(() => _future = widget.service.fetchDriver(widget.driverId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Driver>(
      future: _future,
      builder: (context, snapshot) {
        final driver = snapshot.data ?? widget.initial;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(driver),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(Driver? driver) {
    return AppGradientHeader(
      eyebrow: 'Personnel',
      title: driver?.name ?? 'Driver',
      subtitle: driver?.statusLabel,
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

  Widget _body(AsyncSnapshot<Driver> snapshot) {
    // While loading, show the summary card from the list if we have it.
    if (snapshot.connectionState == ConnectionState.waiting && widget.initial == null) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null && widget.initial == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final d = snapshot.data ?? widget.initial!;
    final loading = snapshot.connectionState == ConnectionState.waiting;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _statusCard(d)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _licenseCard(d)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _contactCard(d)),
            if (d.vehiclePlate != null && d.vehiclePlate!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 180, child: _vehicleCard(d)),
            ],
            if (d.hr != null) ..._hrSection(d.hr!),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 320, child: _tripsCard(d, loading)),
            if (d.notes != null && d.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 300,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(d.notes!, style: AppType.body(14, height: 1.5))],
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

  Widget _statusCard(Driver d) {
    final color = d.statusColor;
    return AppCard(
      accentColor: color,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DriverAvatar(driver: d, size: 64, radius: 18, ring: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: AppType.display(19, color: AppColors.textNavy(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                StatusPill(label: d.statusLabel, color: color),
                if (d.vehiclePlate != null && d.vehiclePlate!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 14, color: kMuted),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          d.vehiclePlate!,
                          style: AppType.body(12.5, color: kMuted, weight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _licenseCard(Driver d) {
    final expiring = d.licenseExpiringSoon;
    final expired = d.licenseExpired;
    final warnColor = expired ? kDanger : kWarning;
    return _SectionCard(
      title: 'Licence',
      eyebrow: 'Driving permit',
      icon: Icons.credit_card_outlined,
      children: [
        _InfoRow(label: 'Number', value: d.licenseNumber ?? '—'),
        _InfoRow(label: 'Expiry', value: formatDate(d.licenseExpiry)),
        if (d.licenseClasses.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: d.licenseClasses
                .map((c) => StatusPill(label: c, color: kPrimary))
                .toList(),
          ),
        ],
        if (expiring) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: warnColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warnColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: warnColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _licenseMessage(d),
                    style: AppType.body(12.5, color: warnColor, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (d.visaExpiry != null) ...[
          const Divider(height: 22),
          _InfoRow(label: 'Visa expiry', value: formatDate(d.visaExpiry)),
        ],
      ],
    );
  }

  Widget _contactCard(Driver d) {
    return _SectionCard(
      title: 'Contact & Identity',
      eyebrow: 'Details',
      icon: Icons.person_outline_rounded,
      children: [
        _InfoRow(label: 'Phone', value: d.phone ?? '—'),
        if (d.phoneAlt != null && d.phoneAlt!.isNotEmpty)
          _InfoRow(label: 'Alt. phone', value: d.phoneAlt!),
        if (d.email != null && d.email!.isNotEmpty)
          _InfoRow(label: 'Email', value: d.email!),
        if (d.nationalId != null && d.nationalId!.isNotEmpty)
          _InfoRow(label: 'National ID', value: d.nationalId!),
        if (d.cardId != null && d.cardId!.isNotEmpty)
          _InfoRow(label: 'Card ID', value: d.cardId!),
        if (d.address != null && d.address!.isNotEmpty)
          _InfoRow(label: 'Address', value: d.address!),
        if (_birthplace(d) != null) _InfoRow(label: 'Birthplace', value: _birthplace(d)!),
        if (d.emergencyContactName != null && d.emergencyContactName!.isNotEmpty) ...[
          const Divider(height: 22),
          _InfoRow(label: 'Emergency', value: d.emergencyContactName!),
          if (d.emergencyContactPhone != null && d.emergencyContactPhone!.isNotEmpty)
            _InfoRow(label: 'Emergency phone', value: d.emergencyContactPhone!),
        ],
      ],
    );
  }

  Widget _vehicleCard(Driver d) {
    final descr = [d.vehicleMake, d.vehicleModel]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    return _SectionCard(
      title: 'Assigned Vehicle',
      eyebrow: 'Fleet',
      icon: Icons.local_shipping_outlined,
      children: [
        Row(
          children: [
            Text(d.vehiclePlate!,
                style: AppType.number(18, color: AppColors.textNavy(context))),
            const Spacer(),
            if (d.vehicleType != null && d.vehicleType!.isNotEmpty)
              StatusPill(label: d.vehicleType!, color: kPrimary),
          ],
        ),
        if (descr.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(descr, style: AppType.body(13, color: kMuted)),
        ],
      ],
    );
  }

  Widget _tripsCard(Driver d, bool loading) {
    return _SectionCard(
      title: 'Recent Trips (${d.trips.length})',
      eyebrow: 'History',
      icon: Icons.route_outlined,
      children: d.trips.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  loading ? 'Loading trips…' : 'No recent trips for this driver.',
                  style: AppType.body(14, color: kMuted),
                ),
              )
            ]
          : d.trips.map((t) {
              final color = statusColor(t.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.tripNumber ?? 'Trip #${t.id}',
                              style: AppType.body(13,
                                  weight: FontWeight.w700,
                                  color: AppColors.textPrimary(context))),
                          const SizedBox(height: 2),
                          if (t.routeFrom != null || t.routeTo != null)
                            Text('${t.routeFrom ?? '—'} → ${t.routeTo ?? '—'}',
                                style: AppType.body(11.5, color: kMuted)),
                          Text(formatDate(t.departureDate),
                              style: AppType.body(11, color: kMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(label: _titleCase(t.status), color: color),
                  ],
                ),
              );
            }).toList(),
    );
  }

  // ── HR / Payroll ─────────────────────────────────────────────────────────

  /// HR/payroll cards, shown only when the driver is linked to an employee.
  /// Employment terms + remuneration are rendered here; allowances, the payslip
  /// breakdown and advances/loans come from the shared [hrPayrollCards].
  List<Widget> _hrSection(DriverHr hr) {
    return [
      const SizedBox(height: 14),
      RevealOnLoad(delayMs: 200, child: _employmentCard(hr)),
      if (hr.hasPackage) ...[
        const SizedBox(height: 14),
        RevealOnLoad(delayMs: 230, child: _packageCard(hr)),
      ],
      ...hrPayrollCards(context, hr.payroll,
          currency: hr.salaryCurrency, startDelayMs: 260),
    ];
  }

  Widget _employmentCard(DriverHr hr) {
    final bank = hr.payroll.bank;
    return _SectionCard(
      title: 'Employment',
      eyebrow: 'Human resources',
      icon: Icons.work_outline_rounded,
      children: [
        if (hr.employeeNumber != null && hr.employeeNumber!.isNotEmpty)
          _InfoRow(label: 'Employee no.', value: hr.employeeNumber!),
        if (hr.position != null && hr.position!.isNotEmpty)
          _InfoRow(label: 'Position', value: hr.position!),
        if (hr.department != null && hr.department!.isNotEmpty)
          _InfoRow(label: 'Department', value: hr.department!),
        if (hr.status != null && hr.status!.isNotEmpty)
          _InfoRow(label: 'Status', value: _titleCase(hr.status!)),
        if (hr.hireDate != null) _InfoRow(label: 'Hired', value: formatDate(hr.hireDate)),
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

  Widget _packageCard(DriverHr hr) {
    final cur = hr.salaryCurrency;
    return _SectionCard(
      title: 'Remuneration',
      eyebrow: 'Package',
      icon: Icons.payments_outlined,
      children: [
        if (hr.salary != null)
          HrHeroAmount(
              label: 'Monthly salary',
              amount: hrFormatMoney(hr.salary!, cur),
              color: kPrimary),
        if (hr.bonus != null && hr.bonus! > 0) ...[
          const SizedBox(height: 6),
          HrAmountRow(label: 'Standing bonus', value: hrFormatMoney(hr.bonus!, cur)),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String? _birthplace(Driver d) {
    final parts = [d.birthDistrict, d.birthRegion]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  String _licenseMessage(Driver d) {
    final days = d.licenseDays ?? 0;
    if (d.licenseExpired) return 'Licence expired ${days.abs()} day(s) ago.';
    if (days == 0) return 'Licence expires today.';
    return 'Licence expires in $days day(s).';
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, this.eyebrow, required this.icon, required this.children});

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

