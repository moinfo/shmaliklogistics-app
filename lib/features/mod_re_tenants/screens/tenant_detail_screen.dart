import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/tenant.dart';
import '../mod_re_tenants_service.dart';
import 'tenants_screen.dart' show tenantHexColor;

/// Read-only detail for a single tenant: contact information and the tenant's
/// leases. The list row ([initial]) is shown immediately while the full record
/// (which adds contact details + leases) loads.
class TenantDetailScreen extends StatefulWidget {
  final int tenantId;
  final ModReTenantsService service;

  /// The list-row summary, shown immediately while the full record loads.
  final TenantRow? initial;

  const TenantDetailScreen({
    super.key,
    required this.tenantId,
    required this.service,
    this.initial,
  });

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  late Future<TenantDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchTenant(widget.tenantId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchTenant(widget.tenantId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TenantDetail>(
      future: _future,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(detail),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(TenantDetail? detail) {
    final title = detail?.name ?? widget.initial?.name ?? 'Tenant';
    final code = detail?.code ?? widget.initial?.code;
    return AppGradientHeader(
      eyebrow: 'Real Estate',
      title: title,
      subtitle: code != null && code.isNotEmpty ? 'Tenant · $code' : 'Tenant',
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
          icon: Icons.refresh_rounded,
          onTap: _reload,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _body(AsyncSnapshot<TenantDetail> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final t = snapshot.data!;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _identityCard(t)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _contactCard(t)),
            if (t.notes != null && t.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 120,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [
                    Text(t.notes!, style: AppType.body(14, height: 1.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            RevealOnLoad(
              delayMs: 160,
              child: SectionHeader(
                title: 'Leases (${t.leases.length})',
                eyebrow: 'Agreements',
                icon: Icons.description_outlined,
                accent: ModuleAccent.brand,
              ),
            ),
            const SizedBox(height: 4),
            if (t.leases.isEmpty)
              RevealOnLoad(
                delayMs: 200,
                child: AppCard(
                  child: AppEmpty(
                    icon: Icons.description_outlined,
                    message: 'No leases recorded for this tenant.',
                  ),
                ),
              )
            else
              for (var i = 0; i < t.leases.length; i++) ...[
                RevealOnLoad(
                  delayMs: (200 + i * 60).clamp(0, 460),
                  child: _LeaseCard(lease: t.leases[i]),
                ),
                if (i != t.leases.length - 1) const SizedBox(height: 12),
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
          AppSkeleton.box(context, height: 200, radius: 18),
          const SizedBox(height: 22),
          AppSkeleton.box(context, height: 120, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
        ],
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _identityCard(TenantDetail t) {
    final statusColor = tenantHexColor(t.statusColorHex);
    return AppCard(
      accentColor: statusColor,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              t.isCompany ? Icons.business_rounded : Icons.person_rounded,
              size: 26,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: AppType.number(20, color: AppColors.textNavy(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (t.code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(t.code, style: AppType.body(13, color: kMuted)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusPill(label: t.statusLabel, color: statusColor),
                    if (t.typeLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      StatusPill(label: t.typeLabel, color: kPrimary),
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

  Widget _contactCard(TenantDetail t) {
    final rows = <Widget>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) {
        rows.add(_InfoRow(label: label, value: value));
      }
    }

    add('Phone', t.phone);
    add('Alt. phone', t.phoneAlt);
    add('Email', t.email);
    add('National ID', t.nationalId);
    if (t.isCompany) {
      add('Company', t.companyName);
      add('TIN', t.tin);
    }
    add('Address', t.address);
    add('Emergency', t.emergencyContactName);
    add('Emergency phone', t.emergencyContactPhone);

    return _SectionCard(
      title: 'Contact',
      eyebrow: 'Details',
      icon: Icons.contact_phone_outlined,
      children: rows.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No contact details recorded.',
                    style: AppType.body(14, color: kMuted)),
              )
            ]
          : rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lease card
// ─────────────────────────────────────────────────────────────────────────────

class _LeaseCard extends StatelessWidget {
  final TenantLeaseInfo lease;
  const _LeaseCard({required this.lease});

  @override
  Widget build(BuildContext context) {
    final color = tenantHexColor(lease.statusColorHex);
    final currency = (lease.rentCurrency == null || lease.rentCurrency!.isEmpty)
        ? 'TZS'
        : lease.rentCurrency!;
    final rent = '$currency ${_thousands(lease.rentAmount)}';
    final period =
        '${formatDate(lease.startDate)} → ${formatDate(lease.endDate)}';

    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lease.leaseNumber,
                      style: AppType.number(15.5,
                          color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lease.propertyLabel != null &&
                        lease.propertyLabel!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lease.propertyLabel!,
                        style: AppType.body(12, color: kMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: lease.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: kMuted),
              const SizedBox(width: 5),
              Text(
                rent,
                style: AppType.number(13.5,
                    color: AppColors.textPrimary(context)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: kMuted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  period,
                  style: AppType.body(12, color: kMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Group digits with thousands separators (e.g. 124500 → "124,500").
  static String _thousands(double value) {
    final n = value.round();
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
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
  const _SectionCard({
    required this.title,
    this.eyebrow,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            eyebrow: eyebrow,
            icon: icon,
            accent: ModuleAccent.brand,
          ),
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
            child: Text(label,
                style:
                    AppType.body(12.5, color: kMuted, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppType.body(13.5,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}