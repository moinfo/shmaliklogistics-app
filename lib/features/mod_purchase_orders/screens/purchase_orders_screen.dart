import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/purchase_order.dart';
import '../purchase_orders_service.dart';
import 'purchase_order_detail_screen.dart';

/// Procurement → Purchase Orders. Entry screen wired into the app shell by the
/// orchestrator. A searchable, status-filterable list of purchase orders with
/// tap-through detail (line items + totals).
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  late final PurchaseOrdersService _service;
  late Future<List<PurchaseOrder>> _future;

  final _searchCtrl = TextEditingController();
  String _search = '';
  String _statusFilter = 'all';

  // Mirrors PurchaseOrder::$statuses on the backend.
  static const _statusOptions = <(String, String)>[
    ('all', 'All'),
    ('draft', 'Draft'),
    ('sent', 'Sent'),
    ('partial', 'Partial'),
    ('received', 'Received'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _service = PurchaseOrdersService(widget.apiClient);
    _future = _service.fetchPurchaseOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = _service.fetchPurchaseOrders());
  }

  List<PurchaseOrder> _apply(List<PurchaseOrder> orders) {
    final q = _search.trim().toLowerCase();
    return orders.where((po) {
      if (_statusFilter != 'all' && po.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return po.poNumber.toLowerCase().contains(q) ||
          (po.supplierName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Procurement',
            title: 'Purchase Orders',
            subtitle: 'Supplier orders & goods receipt',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildSearchBar(),
          _buildStatusChips(),
          Expanded(
            child: FutureBuilder<List<PurchaseOrder>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeleton();
                }
                if (snapshot.hasError) {
                  return AppError(
                      message: snapshot.error.toString(), onRetry: _reload);
                }
                final all = snapshot.data ?? [];
                final orders = _apply(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: orders.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.5,
                              child: AppEmpty(
                                icon: Icons.shopping_cart_outlined,
                                message: all.isEmpty
                                    ? 'No purchase orders yet.'
                                    : 'No purchase orders match your filters.',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: orders.length,
                          itemBuilder: (_, i) => RevealOnLoad(
                            delayMs: (i * 60).clamp(0, 300),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PurchaseOrderCard(
                                order: orders[i],
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PurchaseOrderDetailScreen(
                                        orderId: orders[i].id,
                                        service: _service,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search PO number or supplier',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.surface(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _statusOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _statusOptions[i];
          final selected = _statusFilter == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _statusFilter = value),
            labelStyle: AppType.body(12.5,
                weight: FontWeight.w600,
                color: selected ? Colors.white : kMuted),
            selectedColor: ModuleAccent.ops.base,
            backgroundColor: AppColors.surface(context),
            side: BorderSide(color: AppColors.border(context)),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 120, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;
  final VoidCallback onTap;
  const _PurchaseOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(order.statusColorValue);
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.poNumber,
                  style: AppType.display(15, color: AppColors.textNavy(context))),
              StatusPill(label: order.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.supplierName ?? 'Unknown supplier',
            style: AppType.body(13,
                weight: FontWeight.w600,
                color: AppColors.textPrimary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total',
                      style: AppType.body(10,
                          color: kMuted, weight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(formatCurrency(order.total),
                      style: AppType.number(15,
                          color: AppColors.textNavy(context))),
                ],
              ),
              const Spacer(),
              if (order.orderDate != null) ...[
                const Icon(Icons.event_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text(formatDate(order.orderDate),
                    style: AppType.body(11, color: kMuted)),
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: ModuleAccent.ops.base),
            ],
          ),
        ],
      ),
    );
  }
}
