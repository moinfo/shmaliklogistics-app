import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../customer_service.dart';
import '../models/customer_invoice.dart';
import 'customer_status_colors.dart';
import 'customer_widgets.dart';

/// Read-only invoice detail for the customer portal.
class CustomerInvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  final CustomerService service;

  const CustomerInvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.service,
  });

  @override
  State<CustomerInvoiceDetailScreen> createState() => _CustomerInvoiceDetailScreenState();
}

class _CustomerInvoiceDetailScreenState extends State<CustomerInvoiceDetailScreen> {
  late Future<CustomerInvoice> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchInvoice(widget.invoiceId);
  }

  void _reload() => setState(() => _future = widget.service.fetchInvoice(widget.invoiceId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerInvoice>(
      future: _future,
      builder: (context, snapshot) {
        final inv = snapshot.data;
        final color = inv != null ? invoiceStatusColor(inv.status) : kPrimary;

        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              CustomerDetailHeader(
                title: inv?.documentNumber ?? 'Invoice',
                onRefresh: _reload,
                subtitle: inv != null
                    ? CustomerStatusBadge(label: inv.statusLabel, color: color, small: true)
                    : null,
              ),
              Expanded(child: () {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _InvoiceDetailSkeleton();
                }
                if (snapshot.hasError) {
                  return CustomerErrorView(message: snapshot.error.toString(), onRetry: _reload);
                }
                final i = snapshot.data!;
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RevealOnLoad(
                          delayMs: 0,
                          child: _BalanceCard(invoice: i),
                        ),
                        const SizedBox(height: 14),
                        RevealOnLoad(
                          delayMs: 80,
                          child: CustomerSectionCard(
                            title: 'Details',
                            eyebrow: 'Invoice',
                            icon: Icons.receipt_long_outlined,
                            children: [
                              CustomerInfoRow(label: 'Invoice #', value: i.documentNumber),
                              CustomerInfoRow(label: 'Status', value: i.statusLabel),
                              CustomerInfoRow(label: 'Issue date', value: formatDate(i.issueDate)),
                              CustomerInfoRow(label: 'Due date', value: formatDate(i.dueDate)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        RevealOnLoad(
                          delayMs: 160,
                          child: CustomerSectionCard(
                            title: 'Line Items (${i.items.length})',
                            eyebrow: 'Breakdown',
                            icon: Icons.list_alt_outlined,
                            children: i.items.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text('No line items.',
                                          style: AppType.body(14, color: kMuted)),
                                    )
                                  ]
                                : [
                                    for (final item in i.items) ...[
                                      _ItemRow(item: item),
                                      if (item != i.items.last) const Divider(height: 14, thickness: 0.5),
                                    ],
                                  ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        RevealOnLoad(
                          delayMs: 240,
                          child: CustomerSectionCard(
                            title: 'Summary',
                            eyebrow: 'Totals',
                            icon: Icons.calculate_outlined,
                            children: [
                              CustomerInfoRow(label: 'Subtotal', value: formatCurrency(i.subtotal)),
                              if (i.discountAmount > 0)
                                CustomerInfoRow(label: 'Discount', value: '- ${formatCurrency(i.discountAmount)}'),
                              if (i.taxAmount > 0)
                                CustomerInfoRow(label: 'Tax', value: formatCurrency(i.taxAmount)),
                              const Divider(height: 14, thickness: 0.5),
                              CustomerInfoRow(label: 'Total', value: formatCurrency(i.total), isBold: true),
                              CustomerInfoRow(
                                  label: 'Amount paid', value: formatCurrency(i.amountPaid), valueColor: kSuccess),
                              CustomerInfoRow(
                                label: 'Balance due',
                                value: formatCurrency(i.balanceDue),
                                isBold: true,
                                valueColor: i.balanceDue > 0 ? kDanger : kSuccess,
                              ),
                            ],
                          ),
                        ),
                        if (i.payments.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          RevealOnLoad(
                            delayMs: 300,
                            child: CustomerSectionCard(
                              title: 'Payments (${i.payments.length})',
                              eyebrow: 'Received',
                              icon: Icons.payments_outlined,
                              children: [
                                for (final p in i.payments) ...[
                                  _PaymentRow(payment: p),
                                  if (p != i.payments.last) const Divider(height: 14, thickness: 0.5),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (i.notes != null && i.notes!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          RevealOnLoad(
                            delayMs: 300,
                            child: CustomerSectionCard(
                              title: 'Notes',
                              eyebrow: 'Notes',
                              icon: Icons.notes_rounded,
                              children: [
                                Text(i.notes!, style: AppType.body(14, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }()),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final CustomerInvoice invoice;
  const _BalanceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final outstanding = invoice.balanceDue > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ModuleAccent.brand.colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ModuleAccent.brand.colors.last.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(outstanding ? 'BALANCE DUE' : 'FULLY PAID',
              style: AppType.eyebrow(size: 10.5, color: Colors.white70)),
          const SizedBox(height: 7),
          Text(formatCurrency(outstanding ? invoice.balanceDue : invoice.total),
              style: AppType.number(28, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Total ${formatCurrency(invoice.total)} • Paid ${formatCurrency(invoice.amountPaid)}',
              style: AppType.body(12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final InvoiceItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toStringAsFixed(0)
        : item.quantity.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description, style: AppType.body(13, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('$qty ${item.unit ?? ''} × ${formatCurrency(item.unitPrice)}',
                    style: AppType.body(11, color: kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatCurrency(item.total),
              style: AppType.number(13, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final InvoicePayment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment.method ?? 'Payment', style: AppType.body(13, weight: FontWeight.w500)),
                if (payment.paidAt != null)
                  Text(formatDate(payment.paidAt), style: AppType.body(11, color: kMuted)),
              ],
            ),
          ),
          Text(formatCurrency(payment.amount),
              style: AppType.number(13, weight: FontWeight.w700, color: kSuccess)),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching the invoice-detail layout.
class _InvoiceDetailSkeleton extends StatelessWidget {
  const _InvoiceDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          AppSkeleton.box(context, height: 120, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 150, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 170, radius: 16),
        ],
      ),
    );
  }
}
