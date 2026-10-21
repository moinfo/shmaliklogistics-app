import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/proforma.dart';
import '../proforma_service.dart';

/// Detail view for a single proforma (Module 12): client, line items and ledger.
class ProformaDetailScreen extends StatefulWidget {
  const ProformaDetailScreen({super.key, required this.proformaId, required this.service});

  final int proformaId;
  final ProformaService service;

  @override
  State<ProformaDetailScreen> createState() => _ProformaDetailScreenState();
}

class _ProformaDetailScreenState extends State<ProformaDetailScreen> {
  late Future<Proforma> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchProforma(widget.proformaId);
  }

  void _reload() => setState(() => _future = widget.service.fetchProforma(widget.proformaId));

  static Color _statusColor(Proforma p) {
    final h = p.statusColor;
    if (h != null && h.isNotEmpty) {
      final v = h.replaceFirst('#', '');
      final n = int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
      if (n != null) return Color(n);
    }
    return statusColor(p.status);
  }

  String _money(double v, String currency) => '$currency ${_grp(v)}';

  static String _grp(double v) {
    final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Proforma>(
      future: _future,
      builder: (context, snap) {
        final p = snap.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              AppGradientHeader(
                eyebrow: 'Proforma',
                title: p?.documentNumber ?? 'Proforma',
                subtitle: p?.statusLabel,
                actions: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                ],
              ),
              Expanded(child: _body(snap, p)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<Proforma> snap, Proforma? p) {
    if (snap.connectionState == ConnectionState.waiting) {
      return AppSkeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            AppSkeleton.box(context, height: 130, radius: 18),
            const SizedBox(height: 14),
            AppSkeleton.box(context, height: 200, radius: 18),
            const SizedBox(height: 14),
            AppSkeleton.box(context, height: 140, radius: 18),
          ],
        ),
      );
    }
    if (snap.hasError) {
      return AppError(message: snap.error.toString(), onRetry: _reload);
    }
    final pf = snap.data!;
    final color = _statusColor(pf);
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Total hero
          RevealOnLoad(
            child: AppCard(
              accentColor: color,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL', style: AppType.eyebrow(size: 10, color: kMuted)),
                        const SizedBox(height: 4),
                        Text(_money(pf.total, pf.currency),
                            style: AppType.number(26, color: AppColors.textNavy(context))),
                      ],
                    ),
                  ),
                  StatusPill(label: pf.statusLabel, color: color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Client
          RevealOnLoad(
            delayMs: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Bill To', icon: Icons.business_rounded, eyebrow: 'Client'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pf.clientName ?? pf.clientCompany ?? 'Unknown client',
                          style: AppType.body(15, weight: FontWeight.w700, color: AppColors.textNavy(context))),
                      if (pf.clientEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(pf.clientEmail!, style: AppType.body(13, color: kMuted)),
                      ],
                      if (pf.clientPhone != null) ...[
                        const SizedBox(height: 2),
                        Text(pf.clientPhone!, style: AppType.body(13, color: kMuted)),
                      ],
                      if (pf.issueDate != null || pf.validUntil != null) ...[
                        const Divider(height: 18),
                        Row(
                          children: [
                            if (pf.issueDate != null)
                              Expanded(child: _mini('Issued', formatDate(pf.issueDate!))),
                            if (pf.validUntil != null)
                              Expanded(child: _mini('Valid until', formatDate(pf.validUntil!))),
                          ],
                        ),
                      ],
                      if (pf.tripNumber != null) ...[
                        const SizedBox(height: 6),
                        Text('Trip ${pf.tripNumber}'
                            '${pf.tripRouteFrom != null ? '  ·  ${pf.tripRouteFrom} → ${pf.tripRouteTo}' : ''}',
                            style: AppType.body(12.5, color: kMuted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Line items
          RevealOnLoad(
            delayMs: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Line Items',
                  icon: Icons.list_alt_rounded,
                  eyebrow: 'Breakdown',
                  trailing: Text('${pf.items.length}', style: AppType.number(14, color: kMuted)),
                ),
                AppCard(
                  child: pf.items.isEmpty
                      ? Text('No line items.', style: AppType.body(13.5, color: kMuted))
                      : Column(
                          children: [
                            for (var i = 0; i < pf.items.length; i++) ...[
                              if (i > 0) const Divider(height: 18),
                              _itemRow(pf.items[i], pf.currency),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Totals
          RevealOnLoad(
            delayMs: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Totals', icon: Icons.calculate_rounded, eyebrow: 'Ledger'),
                AppCard(
                  child: Column(
                    children: [
                      _totalRow('Subtotal', _money(pf.subtotal, pf.currency)),
                      if (pf.discountAmount > 0) _totalRow('Discount', '- ${_money(pf.discountAmount, pf.currency)}'),
                      if (pf.taxAmount > 0) _totalRow('Tax (${pf.taxRate.toStringAsFixed(0)}%)', _money(pf.taxAmount, pf.currency)),
                      const Divider(height: 18),
                      _totalRow('Total', _money(pf.total, pf.currency), strong: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (pf.notes != null && pf.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            RevealOnLoad(
              delayMs: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Notes', icon: Icons.notes_rounded, eyebrow: 'Memo'),
                  AppCard(child: Text(pf.notes!, style: AppType.body(13.5, height: 1.5, color: AppColors.textNavy(context)))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(ProformaItem it, String currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.description,
                  style: AppType.body(13.5, weight: FontWeight.w600, color: AppColors.textNavy(context))),
              const SizedBox(height: 2),
              Text('${it.quantity.toStringAsFixed(it.quantity == it.quantity.roundToDouble() ? 0 : 2)}'
                  '${it.unit != null ? ' ${it.unit}' : ''} × ${_money(it.unitPrice, currency)}',
                  style: AppType.body(11.5, color: kMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(_money(it.total, currency), style: AppType.number(14, color: AppColors.textNavy(context))),
      ],
    );
  }

  Widget _mini(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(11.5, color: kMuted)),
        Text(value, style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textNavy(context))),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppType.body(strong ? 14.5 : 13, weight: strong ? FontWeight.w700 : FontWeight.w500, color: strong ? AppColors.textNavy(context) : kMuted)),
          Text(value, style: AppType.number(strong ? 18 : 14, color: AppColors.textNavy(context))),
        ],
      ),
    );
  }
}
