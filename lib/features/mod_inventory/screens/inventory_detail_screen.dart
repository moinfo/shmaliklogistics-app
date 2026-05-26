import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../inventory_service.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';

/// Detail view for a single stock item (Module 16). Shows the item overview
/// plus its recent stock movements.
class InventoryDetailScreen extends StatefulWidget {
  const InventoryDetailScreen({super.key, required this.itemId, required this.service});

  final int itemId;
  final InventoryService service;

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  late Future<InventoryItem> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchItem(widget.itemId);
  }

  void _reload() => setState(() => _future = widget.service.fetchItem(widget.itemId));

  static Color? _hex(String? h) {
    if (h == null || h.isEmpty) return null;
    final v = h.replaceFirst('#', '');
    final n = int.tryParse(v.length == 6 ? 'FF$v' : v, radix: 16);
    return n == null ? null : Color(n);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InventoryItem>(
      future: _future,
      builder: (context, snap) {
        final item = snap.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              AppGradientHeader(
                eyebrow: 'Stock',
                title: item?.name ?? 'Item',
                subtitle: item?.sku,
                actions: [
                  HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                ],
              ),
              Expanded(child: _body(snap, item)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<InventoryItem> snap, InventoryItem? item) {
    if (snap.connectionState == ConnectionState.waiting) {
      return AppSkeleton(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            AppSkeleton.box(context, height: 150, radius: 18),
            const SizedBox(height: 14),
            AppSkeleton.box(context, height: 220, radius: 18),
          ],
        ),
      );
    }
    if (snap.hasError) {
      return AppError(message: snap.error.toString(), onRetry: _reload);
    }
    final it = item!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          RevealOnLoad(
            child: AppCard(
              accentColor: it.isLowStock ? kDanger : kSuccess,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(it.quantityLabel + (it.unit != null ? ' ${it.unit}' : ''),
                            style: AppType.number(30, color: AppColors.textNavy(context))),
                      ),
                      StatusPill(
                        label: it.isLowStock ? 'Low stock' : it.status,
                        color: it.isLowStock ? kDanger : kSuccess,
                        icon: it.isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Reorder at ${it.reorderLabel}${it.unit != null ? ' ${it.unit}' : ''}',
                      style: AppType.body(12.5, color: kMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          RevealOnLoad(
            delayMs: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Details', icon: Icons.inventory_2_rounded, eyebrow: 'Item'),
                AppCard(
                  child: Column(
                    children: [
                      if (it.sku != null) _row('SKU', it.sku!),
                      _row('Category', it.categoryName ?? '—', color: _hex(it.categoryColor)),
                      _row('Unit cost', formatCurrency(it.unitCost)),
                      if (it.location != null) _row('Location', it.location!),
                      _row('Tracking', [
                        if (it.tracksSerials) 'Serials',
                        if (it.tracksBatch) 'Batch',
                      ].join(' · ').ifEmptyDash()),
                      _row('Status', it.status, last: it.notes == null),
                      if (it.notes != null) _row('Notes', it.notes!, last: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (it.movements.isNotEmpty) ...[
            const SizedBox(height: 14),
            RevealOnLoad(
              delayMs: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Movements',
                    icon: Icons.swap_vert_rounded,
                    eyebrow: 'Recent',
                    trailing: Text('${it.movements.length}', style: AppType.number(14, color: kMuted)),
                  ),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < it.movements.length; i++) ...[
                          if (i > 0) const Divider(height: 18),
                          _movementRow(it.movements[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _movementRow(InventoryMovement m) {
    final color = _hex(m.typeColor) ?? (m.isInbound ? kSuccess : kDanger);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(m.isInbound ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.typeLabel, style: AppType.body(13.5, weight: FontWeight.w600, color: AppColors.textNavy(context))),
              if (m.reference != null)
                Text(m.reference!, style: AppType.body(11.5, color: kMuted)),
              if (m.createdAt != null)
                Text(formatDate(m.createdAt!), style: AppType.body(11.5, color: kMuted)),
            ],
          ),
        ),
        Text('${m.isInbound ? '+' : '-'}${m.quantity.toStringAsFixed(m.quantity == m.quantity.roundToDouble() ? 0 : 2)}',
            style: AppType.number(15, color: color)),
      ],
    );
  }

  Widget _row(String label, String value, {Color? color, bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppType.body(13, color: kMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppType.body(13.5, weight: FontWeight.w600, color: color ?? AppColors.textNavy(context))),
          ),
        ],
      ),
    );
  }
}

extension _Dash on String {
  String ifEmptyDash() => trim().isEmpty ? '—' : this;
}
