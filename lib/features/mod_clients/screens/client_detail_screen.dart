import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/client.dart';
import '../clients_service.dart';

/// Read-only detail for a single client: identity, contact, tax (TIN/VRN)
/// and a light billing summary.
class ClientDetailScreen extends StatefulWidget {
  final int clientId;
  final ClientsService service;

  /// The list-row summary, shown immediately while the full record loads.
  final Client? initial;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
    required this.service,
    this.initial,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Future<Client> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchClient(widget.clientId);
  }

  void _reload() => setState(() => _future = widget.service.fetchClient(widget.clientId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Client>(
      future: _future,
      builder: (context, snapshot) {
        final client = snapshot.data ?? widget.initial;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(client),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(Client? client) {
    return AppGradientHeader(
      eyebrow: 'Customers',
      title: client?.name ?? 'Client',
      subtitle: client?.hasCompany == true ? client!.companyName : client?.statusLabel,
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

  Widget _body(AsyncSnapshot<Client> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting && widget.initial == null) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null && widget.initial == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final c = snapshot.data ?? widget.initial!;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _statusCard(c)),
            if (c.stats != null) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 60, child: _statsRow(c.stats!)),
            ],
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _contactCard(c)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 180, child: _taxCard(c)),
            if (c.notes != null && c.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(c.notes!, style: AppType.body(14, height: 1.5))],
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
          AppSkeleton.box(context, height: 96, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 18),
        ],
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _statusCard(Client c) {
    final color = c.statusColor;
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
              _initials(c.hasCompany ? c.companyName! : c.name),
              style: AppType.number(18, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: AppType.display(18, color: AppColors.textNavy(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (c.hasCompany) ...[
                  const SizedBox(height: 2),
                  Text(c.companyName!,
                      style: AppType.body(13, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                StatusPill(label: c.statusLabel, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(ClientStats s) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Quotes',
            value: s.quotes.toString(),
            icon: Icons.request_quote_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Invoices',
            value: s.invoices.toString(),
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }

  Widget _contactCard(Client c) {
    return _SectionCard(
      title: 'Contact',
      eyebrow: 'Details',
      icon: Icons.contact_phone_outlined,
      children: [
        _InfoRow(label: 'Phone', value: c.phone?.isNotEmpty == true ? c.phone! : '—'),
        if (c.phoneAlt != null && c.phoneAlt!.isNotEmpty)
          _InfoRow(label: 'Alt. phone', value: c.phoneAlt!),
        _InfoRow(label: 'Email', value: c.email?.isNotEmpty == true ? c.email! : '—'),
        if (c.address != null && c.address!.isNotEmpty)
          _InfoRow(label: 'Address', value: c.address!),
        if (c.createdAt != null) ...[
          const Divider(height: 22),
          _InfoRow(label: 'Client since', value: formatDate(c.createdAt)),
        ],
      ],
    );
  }

  Widget _taxCard(Client c) {
    final billed = c.stats?.totalBilled;
    return _SectionCard(
      title: 'Tax & Billing',
      eyebrow: 'Compliance',
      icon: Icons.receipt_long_outlined,
      children: [
        _InfoRow(label: 'TIN', value: c.tinNumber?.isNotEmpty == true ? c.tinNumber! : '—'),
        _InfoRow(label: 'VRN', value: c.vrnNumber?.isNotEmpty == true ? c.vrnNumber! : '—'),
        if (billed != null) ...[
          const Divider(height: 22),
          _InfoRow(label: 'Total billed', value: formatCurrency(billed)),
        ],
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

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
