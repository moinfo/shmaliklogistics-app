import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../models/supplier.dart';
import '../suppliers_service.dart';
import 'supplier_detail_screen.dart';

/// Procurement → Suppliers. Entry screen wired into the app shell by the
/// orchestrator. A searchable, category-filterable list of suppliers with
/// tap-through detail.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final SuppliersService _service;
  late Future<List<Supplier>> _future;

  final _searchCtrl = TextEditingController();
  String _search = '';
  String _categoryFilter = 'all';

  // Mirrors Supplier::$categories on the backend.
  static const _categoryOptions = <(String, String)>[
    ('all', 'All'),
    ('fuel', 'Fuel'),
    ('spare_parts', 'Spare Parts'),
    ('office', 'Office'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _service = SuppliersService(widget.apiClient);
    _future = _service.fetchSuppliers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = _service.fetchSuppliers());
  }

  List<Supplier> _apply(List<Supplier> suppliers) {
    final q = _search.trim().toLowerCase();
    return suppliers.where((s) {
      if (_categoryFilter != 'all' && s.category != _categoryFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          (s.contactName?.toLowerCase().contains(q) ?? false) ||
          (s.phone?.toLowerCase().contains(q) ?? false) ||
          (s.email?.toLowerCase().contains(q) ?? false);
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
            title: 'Suppliers',
            subtitle: 'Vendors & supply partners',
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
          _buildCategoryChips(),
          Expanded(
            child: FutureBuilder<List<Supplier>>(
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
                final suppliers = _apply(all);
                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: suppliers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.5,
                              child: AppEmpty(
                                icon: Icons.business_outlined,
                                message: all.isEmpty
                                    ? 'No suppliers yet.'
                                    : 'No suppliers match your filters.',
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: suppliers.length,
                          itemBuilder: (_, i) => RevealOnLoad(
                            delayMs: (i * 60).clamp(0, 300),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SupplierCard(
                                supplier: suppliers[i],
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SupplierDetailScreen(
                                        supplierId: suppliers[i].id,
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
          hintText: 'Search name, contact, phone or email',
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

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categoryOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = _categoryOptions[i];
          final selected = _categoryFilter == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _categoryFilter = value),
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
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 108, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  const _SupplierCard({required this.supplier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = Color(supplier.statusColorValue);
    final categoryColor = Color(supplier.categoryColorValue);
    return AppCard(
      accentColor: categoryColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  supplier.name,
                  style:
                      AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: supplier.statusLabel, color: statusColor),
            ],
          ),
          if (supplier.categoryLabel != null &&
              supplier.categoryLabel!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _CategoryTag(label: supplier.categoryLabel!, color: categoryColor),
          ],
          const SizedBox(height: 12),
          if (supplier.phone != null && supplier.phone!.isNotEmpty)
            _ContactLine(icon: Icons.phone_outlined, text: supplier.phone!),
          if (supplier.email != null && supplier.email!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _ContactLine(icon: Icons.email_outlined, text: supplier.email!),
          ],
          if ((supplier.phone == null || supplier.phone!.isEmpty) &&
              (supplier.email == null || supplier.email!.isEmpty))
            _ContactLine(
                icon: Icons.info_outline_rounded, text: 'No contact details'),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(
                '${supplier.purchaseOrdersCount} order'
                '${supplier.purchaseOrdersCount == 1 ? '' : 's'}',
                style: AppType.body(11, color: kMuted),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: ModuleAccent.ops.base),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppType.body(10.5, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppType.body(12.5, color: AppColors.textPrimary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
