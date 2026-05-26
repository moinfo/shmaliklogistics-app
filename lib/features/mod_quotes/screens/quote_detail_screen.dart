import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/quote.dart';
import '../quote_service.dart';
import 'quotes_screen.dart' show quoteStatusColor, formatQuoteMoney;

/// Read-only detail for a single billing quote: client/trip context, line
/// items and a totals ledger.
class QuoteDetailScreen extends StatefulWidget {
  final int quoteId;
  final QuoteService service;

  const QuoteDetailScreen({
    super.key,
    required this.quoteId,
    required this.service,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  late Future<Quote> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchQuote(widget.quoteId);
  }

  void _reload() => setState(() => _future = widget.service.fetchQuote(widget.quoteId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Quote>(
      future: _future,
      builder: (context, snapshot) {
        final quote = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(quote),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Quote? quote) {
    return AppGradientHeader(
      eyebrow: 'Quote',
      title: quote?.documentNumber ?? 'Quote',
      subtitle: quote?.statusLabel,
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

  Widget _buildBody(AsyncSnapshot<Quote> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final q = snapshot.data!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildClientCard(q)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildLineItemsCard(q)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _buildTotalsCard(q)),
            if (q.termsConditions != null && q.termsConditions!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 180,
                child: _SectionCard(
                  title: 'Terms & Conditions',
                  eyebrow: 'Agreement',
                  icon: Icons.gavel_outlined,
                  children: [Text(q.termsConditions!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
            if (q.notes != null && q.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(q.notes!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppSkeleton.box(context, height: 150, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 180, radius: 16),
        ],
      ),
    );
  }

  Widget _buildClientCard(Quote q) {
    return _SectionCard(
      title: 'Quote For',
      eyebrow: 'Client',
      icon: Icons.business_rounded,
      children: [
        Text(q.clientName ?? q.clientCompany ?? 'Unknown client',
            style: AppType.display(16, color: AppColors.textPrimary(context))),
        if (q.clientCompany != null && q.clientCompany != q.clientName) ...[
          const SizedBox(height: 2),
          Text(q.clientCompany!, style: AppType.body(13, color: kMuted)),
        ],
        if (q.clientEmail != null && q.clientEmail!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.email_outlined, text: q.clientEmail!),
        ],
        if (q.clientPhone != null && q.clientPhone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _IconLine(icon: Icons.phone_outlined, text: q.clientPhone!),
        ],
        const Divider(height: 20),
        Row(
          children: [
            Expanded(child: _IconLine(icon: Icons.event_available_outlined, text: 'Issued ${formatDate(q.issueDate)}')),
            Expanded(
              child: _IconLine(
                icon: Icons.timer_outlined,
                text: q.validUntil != null ? 'Valid to ${formatDate(q.validUntil)}' : 'No expiry',
              ),
            ),
          ],
        ),
        if (q.tripNumber != null) ...[
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.local_shipping_outlined,
            text: [
              q.tripNumber,
              if (q.tripRouteFrom != null) '${q.tripRouteFrom} → ${q.tripRouteTo}',
            ].whereType<String>().join('  ·  '),
          ),
        ],
      ],
    );
  }

  Widget _buildLineItemsCard(Quote q) {
    return _SectionCard(
      title: 'Line Items (${q.items.length})',
      eyebrow: 'Breakdown',
      icon: Icons.list_alt_outlined,
      children: q.items.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No line items.', style: AppType.body(14, color: kMuted)),
              )
            ]
          : q.items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.description,
                                  style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context))),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'
                                '${item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : ''}'
                                ' × ${formatQuoteMoney(item.unitPrice, q.currency)}',
                                style: AppType.body(11, color: kMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(formatQuoteMoney(item.total, q.currency),
                            style: AppType.number(13, color: AppColors.textPrimary(context))),
                      ],
                    ),
                  ))
              .toList(),
    );
  }

  Widget _buildTotalsCard(Quote q) {
    return _SectionCard(
      title: 'Totals',
      eyebrow: 'Ledger',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _FinRow(label: 'Subtotal', value: formatQuoteMoney(q.subtotal, q.currency)),
        if (q.discountAmount > 0) _FinRow(label: 'Discount', value: '- ${formatQuoteMoney(q.discountAmount, q.currency)}'),
        if (q.taxAmount > 0)
          _FinRow(
            label: 'Tax${q.taxRate > 0 ? ' (${q.taxRate.toStringAsFixed(q.taxRate == q.taxRate.roundToDouble() ? 0 : 2)}%)' : ''}',
            value: formatQuoteMoney(q.taxAmount, q.currency),
          ),
        const _Divider(),
        _FinRow(label: 'Total', value: formatQuoteMoney(q.total, q.currency), isBold: true, isHighlight: true),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail widgets (section card / financial rows)
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
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.finance),
          ...children,
        ],
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isHighlight;
  const _FinRow({required this.label, required this.value, this.isBold = false, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppType.body(
                13,
                color: isBold ? AppColors.textPrimary(context) : kMuted,
                weight: isBold ? FontWeight.w600 : FontWeight.w400,
              )),
          Text(value,
              style: AppType.number(
                13,
                weight: isBold || isHighlight ? FontWeight.w800 : FontWeight.w500,
                color: isHighlight ? ModuleAccent.finance.base : AppColors.textPrimary(context),
              )),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Divider(height: 14, thickness: 0.5);
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppType.body(12, color: kMuted))),
      ],
    );
  }
}
