import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/purchase_order.dart';
import '../purchase_orders_service.dart';

/// Detail view for a single purchase order: supplier, line items and totals.
class PurchaseOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final PurchaseOrdersService service;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.service,
  });

  @override
  State<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  late Future<PurchaseOrder> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchPurchaseOrder(widget.orderId);
  }

  void _reload() => setState(
      () => _future = widget.service.fetchPurchaseOrder(widget.orderId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PurchaseOrder>(
      future: _future,
      builder: (context, snapshot) {
        final order = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(order),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(PurchaseOrder? order) {
    return AppGradientHeader(
      eyebrow: 'Purchase Order',
      title: order?.poNumber ?? 'Purchase Order',
      subtitle: order?.statusLabel,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(
            icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
    );
  }

  Widget _buildBody(AsyncSnapshot<PurchaseOrder> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final po = snapshot.data!;
    final color = Color(po.statusColorValue);
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildOverviewCard(po, color)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildSupplierCard(po)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _buildLineItemsCard(po)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 180, child: _buildTotalsCard(po)),
            if (po.notes != null && po.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(po.notes!, style: AppType.body(14, height: 1.5))],
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
          AppSkeleton.box(context, height: 110, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 130, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 180, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 150, radius: 16),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(PurchaseOrder po, Color color) {
    return _SectionCard(
      title: 'Overview',
      eyebrow: 'Order',
      icon: Icons.shopping_cart_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(po.poNumber,
                  style: AppType.display(18, color: AppColors.textNavy(context))),
            ),
            StatusPill(label: po.statusLabel, color: color),
          ],
        ),
        const Divider(height: 20),
        Row(
          children: [
            Expanded(
              child: _IconLine(
                icon: Icons.event_available_outlined,
                text: 'Ordered ${formatDate(po.orderDate)}',
              ),
            ),
            Expanded(
              child: _IconLine(
                icon: Icons.local_shipping_outlined,
                text: po.expectedDate != null
                    ? 'Expected ${formatDate(po.expectedDate)}'
                    : 'No expected date',
              ),
            ),
          ],
        ),
        if (po.createdByName != null) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.person_outline_rounded, text: 'By ${po.createdByName}'),
        ],
      ],
    );
  }

  Widget _buildSupplierCard(PurchaseOrder po) {
    return _SectionCard(
      title: 'Supplier',
      eyebrow: 'Vendor',
      icon: Icons.business_rounded,
      children: [
        Text(po.supplierName ?? 'Unknown supplier',
            style: AppType.display(16, color: AppColors.textPrimary(context))),
        if (po.supplierCategory != null && po.supplierCategory!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(po.supplierCategory!, style: AppType.body(13, color: kMuted)),
        ],
        if (po.supplierContact != null && po.supplierContact!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.person_outline_rounded, text: po.supplierContact!),
        ],
        if (po.supplierPhone != null && po.supplierPhone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _IconLine(icon: Icons.phone_outlined, text: po.supplierPhone!),
        ],
        if (po.supplierEmail != null && po.supplierEmail!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _IconLine(icon: Icons.email_outlined, text: po.supplierEmail!),
        ],
      ],
    );
  }

  Widget _buildLineItemsCard(PurchaseOrder po) {
    return _SectionCard(
      title: 'Line Items (${po.items.length})',
      eyebrow: 'Breakdown',
      icon: Icons.list_alt_outlined,
      children: po.items.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No line items.', style: AppType.body(14, color: kMuted)),
              )
            ]
          : po.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description,
                              style: AppType.body(13,
                                  weight: FontWeight.w600,
                                  color: AppColors.textPrimary(context))),
                          const SizedBox(height: 2),
                          Text(
                            '${_qty(item.quantity)}'
                            '${item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : ''}'
                            ' × ${formatCurrency(item.unitPrice)}',
                            style: AppType.body(11, color: kMuted),
                          ),
                          if (item.receivedQty > 0) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.isFullyReceived
                                  ? 'Received in full'
                                  : 'Received ${_qty(item.receivedQty)} of ${_qty(item.quantity)}',
                              style: AppType.body(10,
                                  color: item.isFullyReceived ? kSuccess : kWarning,
                                  weight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(formatCurrency(item.total),
                        style: AppType.number(13,
                            color: AppColors.textPrimary(context))),
                  ],
                ),
              )).toList(),
    );
  }

  Widget _buildTotalsCard(PurchaseOrder po) {
    return _SectionCard(
      title: 'Totals',
      eyebrow: 'Ledger',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _FinRow(label: 'Subtotal', value: formatCurrency(po.subtotal)),
        if (po.taxAmount > 0) _FinRow(label: 'Tax (18% VAT)', value: formatCurrency(po.taxAmount)),
        const _Divider(),
        _FinRow(
            label: 'Total',
            value: formatCurrency(po.total),
            isBold: true,
            isHighlight: true),
      ],
    );
  }

  static String _qty(double q) =>
      q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

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
          SectionHeader(
              title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.ops),
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
  const _FinRow(
      {required this.label,
      required this.value,
      this.isBold = false,
      this.isHighlight = false});

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
                color: isHighlight
                    ? ModuleAccent.ops.base
                    : AppColors.textPrimary(context),
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
