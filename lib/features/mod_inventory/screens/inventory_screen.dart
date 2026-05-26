import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../inventory_service.dart';
import '../models/inventory_item.dart';
import 'inventory_detail_screen.dart';

/// Inventory feature entry point (Module 16) — a searchable list of stock
/// items with low-stock highlighting and tap-through to a detail screen.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _service;
  late Future<List<InventoryItem>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _service = InventoryService(widget.apiClient);
    _future = _service.fetchItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchItems());

  List<InventoryItem> _filter(List<InventoryItem> items) {
    final q = _query.trim().toLowerCase();
    return items.where((it) {
      if (_lowStockOnly && !it.isLowStock) return false;
      if (q.isEmpty) return true;
      return it.name.toLowerCase().contains(q) ||
          (it.sku ?? '').toLowerCase().contains(q) ||
          (it.categoryName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Stock',
            title: 'Inventory',
            subtitle: 'Items · Stock levels',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Search name, SKU or category',
                hintStyle: AppType.body(13.5, color: kMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: kMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceVariant(context),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _LowStockToggle(
            active: _lowStockOnly,
            onTap: () => setState(() => _lowStockOnly = !_lowStockOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder<List<InventoryItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }

        final all = snapshot.data ?? [];
        final items = _filter(all);

        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: items.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: AppEmpty(
                        icon: Icons.inventory_2_outlined,
                        message: all.isEmpty
                            ? 'No inventory items\nStock items will appear here.'
                            : 'No matching items\nTry a different search or filter.',
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    if (all.isNotEmpty) _buildSummary(all),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (_, i) => RevealOnLoad(
                          delayMs: (i * 60).clamp(0, 300),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InventoryCard(
                              item: items[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InventoryDetailScreen(
                                    itemId: items[i].id,
                                    service: _service,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSummary(List<InventoryItem> all) {
    final lowCount = all.where((i) => i.isLowStock).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Items',
              value: all.length.toString(),
              icon: Icons.inventory_2_rounded,
              accent: ModuleAccent.ops,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Low stock',
              value: lowCount.toString(),
              icon: Icons.warning_amber_rounded,
              accent: ModuleAccent.ops,
              danger: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 104, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Small toggle button used in the search bar to filter to low-stock items.
class _LowStockToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _LowStockToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? kDanger.withValues(alpha: 0.12) : AppColors.surfaceVariant(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            children: [
              Icon(
                active ? Icons.warning_amber_rounded : Icons.warning_amber_outlined,
                size: 18,
                color: active ? kDanger : kMuted,
              ),
              const SizedBox(width: 6),
              Text('Low',
                  style: AppType.body(13,
                      weight: FontWeight.w600, color: active ? kDanger : kMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  const _InventoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = item.isLowStock ? kDanger : ModuleAccent.ops.base;
    return AppCard(
      accentColor: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (item.isLowStock)
                const StatusPill(label: 'Low stock', color: kDanger)
              else if (!item.isActive)
                const StatusPill(label: 'Inactive', color: kMuted),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (item.sku != null && item.sku!.isNotEmpty) ...[
                const Icon(Icons.qr_code_2_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(item.sku!,
                      style: AppType.body(12, color: kMuted, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
              ],
              if (item.categoryName != null) ...[
                const Icon(Icons.folder_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(item.categoryName!,
                      style: AppType.body(12, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: item.quantityLabel,
                      style: AppType.number(20,
                          color: item.isLowStock ? kDanger : AppColors.textPrimary(context)),
                    ),
                    if (item.unit != null && item.unit!.isNotEmpty)
                      TextSpan(
                        text: ' ${item.unit}',
                        style: AppType.body(12, color: kMuted, weight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              if (item.reorderLevel > 0) ...[
                const SizedBox(width: 10),
                Text('· reorder at ${item.reorderLabel}',
                    style: AppType.body(11, color: kMuted)),
              ],
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 18, color: ModuleAccent.ops.base),
            ],
          ),
        ],
      ),
    );
  }
}
