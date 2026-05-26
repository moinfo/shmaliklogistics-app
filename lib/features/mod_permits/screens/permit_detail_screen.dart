import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/permit.dart';
import '../permits_service.dart';
import 'permits_screen.dart' show permitColor;

/// Read-only detail for a single permit, pushed from [PermitsScreen].
class PermitDetailScreen extends StatefulWidget {
  final int permitId;
  final PermitsService service;

  const PermitDetailScreen({
    super.key,
    required this.permitId,
    required this.service,
  });

  @override
  State<PermitDetailScreen> createState() => _PermitDetailScreenState();
}

class _PermitDetailScreenState extends State<PermitDetailScreen> {
  late Future<Permit> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchPermit(widget.permitId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchPermit(widget.permitId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Permit>(
      future: _future,
      builder: (context, snapshot) {
        final permit = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(permit),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Permit? permit) {
    return AppGradientHeader(
      eyebrow: 'Compliance · Permit',
      title: permit?.permitNumber ?? permit?.permitType ?? 'Permit',
      subtitle: permit?.statusLabel,
      gradient: ModuleAccent.danger.colors,
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

  Widget _buildBody(AsyncSnapshot<Permit> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final p = snapshot.data!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildExpiryBanner(p)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildPermitCard(p)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _buildIssuingCard(p)),
            if (p.tripNumber != null || p.route.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 180, child: _buildTripCard(p)),
            ],
            if (p.notes != null && p.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(p.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Expiry banner — the primary emphasis of this screen ─────────────────────

  Widget _buildExpiryBanner(Permit p) {
    final color = permitColor(p);
    final flag = p.isExpired || p.isExpiringSoon;
    final icon = p.isExpired
        ? Icons.event_busy_rounded
        : (p.isExpiringSoon ? Icons.warning_amber_rounded : Icons.verified_rounded);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.expiryLabel,
                  style: AppType.display(16,
                      color: flag ? color : AppColors.textNavy(context)),
                ),
                if (p.expiryDate != null) ...[
                  const SizedBox(height: 2),
                  Text('Expiry date · ${formatDate(p.expiryDate)}',
                      style: AppType.body(12.5, color: kMuted)),
                ],
              ],
            ),
          ),
          StatusPill(label: p.statusLabel, color: Color(p.statusColorValue)),
        ],
      ),
    );
  }

  Widget _buildPermitCard(Permit p) {
    return _SectionCard(
      title: 'Permit',
      eyebrow: 'Details',
      icon: Icons.description_outlined,
      children: [
        _InfoRow(label: 'Type', value: p.permitType),
        if (p.permitNumber != null) _InfoRow(label: 'Number', value: p.permitNumber!),
        _InfoRow(label: 'Vehicle', value: p.vehiclePlate),
        if (p.issueDate != null) _InfoRow(label: 'Issued', value: formatDate(p.issueDate)),
        if (p.expiryDate != null) _InfoRow(label: 'Expires', value: formatDate(p.expiryDate)),
        if (p.hasMoney)
          _InfoRow(
            label: 'Cost',
            value: '${p.currency ?? ''} ${NumberFormatThousands.of(p.cost!)}'.trim(),
          ),
      ],
    );
  }

  Widget _buildIssuingCard(Permit p) {
    final hasCountry = p.issuingCountry != null && p.issuingCountry!.isNotEmpty;
    final hasAuthority = p.issuingAuthority != null && p.issuingAuthority!.isNotEmpty;
    if (!hasCountry && !hasAuthority) {
      return _SectionCard(
        title: 'Issuing',
        eyebrow: 'Authority',
        icon: Icons.public_outlined,
        children: [Text('No issuing details recorded.', style: AppType.body(14, color: kMuted))],
      );
    }
    return _SectionCard(
      title: 'Issuing',
      eyebrow: 'Authority',
      icon: Icons.public_outlined,
      children: [
        if (hasCountry) _InfoRow(label: 'Country', value: p.issuingCountry!),
        if (hasAuthority) _InfoRow(label: 'Authority', value: p.issuingAuthority!),
      ],
    );
  }

  Widget _buildTripCard(Permit p) {
    return _SectionCard(
      title: 'Linked Trip',
      eyebrow: 'Operations',
      icon: Icons.local_shipping_outlined,
      children: [
        if (p.tripNumber != null) _InfoRow(label: 'Trip', value: p.tripNumber!),
        if (p.route.isNotEmpty) _InfoRow(label: 'Route', value: p.route),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 78, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 180, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 110, radius: 16),
        ],
      ),
    );
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
  const _SectionCard({required this.title, this.eyebrow, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.danger),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: AppType.body(13, color: kMuted, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: AppType.body(13.5,
                    weight: FontWeight.w600, color: AppColors.textPrimary(context))),
          ),
        ],
      ),
    );
  }
}

/// Local thousands grouping for permit cost (currency may be USD/TZS/ZMW…),
/// matching the finance feature's number presentation without coupling to it.
class NumberFormatThousands {
  static String of(double amount) {
    final whole = amount.round();
    final s = whole.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${whole < 0 ? '-' : ''}$buf';
  }
}
