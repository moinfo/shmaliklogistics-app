import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/supplier.dart';
import '../suppliers_service.dart';

/// Detail view for a single supplier: identity, contact and procurement stats.
class SupplierDetailScreen extends StatefulWidget {
  final int supplierId;
  final SuppliersService service;

  const SupplierDetailScreen({
    super.key,
    required this.supplierId,
    required this.service,
  });

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  late Future<Supplier> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchSupplier(widget.supplierId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchSupplier(widget.supplierId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Supplier>(
      future: _future,
      builder: (context, snapshot) {
        final supplier = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(supplier),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Supplier? supplier) {
    return AppGradientHeader(
      eyebrow: 'Supplier',
      title: supplier?.name ?? 'Supplier',
      subtitle: supplier?.categoryLabel ?? supplier?.statusLabel,
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

  Widget _buildBody(AsyncSnapshot<Supplier> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final s = snapshot.data!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildOverviewCard(s)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildContactCard(s)),
            if (s.notes != null && s.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 120,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [
                    Text(s.notes!, style: AppType.body(14, height: 1.5)),
                  ],
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
          AppSkeleton.box(context, height: 120, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 170, radius: 16),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Supplier s) {
    final statusColor = Color(s.statusColorValue);
    final categoryColor = Color(s.categoryColorValue);
    return _SectionCard(
      title: 'Overview',
      eyebrow: 'Vendor',
      icon: Icons.business_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s.name,
                  style:
                      AppType.display(18, color: AppColors.textNavy(context))),
            ),
            StatusPill(label: s.statusLabel, color: statusColor),
          ],
        ),
        if (s.categoryLabel != null && s.categoryLabel!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _CategoryTag(label: s.categoryLabel!, color: categoryColor),
        ],
        const Divider(height: 22),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Purchase Orders',
                value: '${s.purchaseOrdersCount}',
                icon: Icons.shopping_cart_outlined,
              ),
            ),
            if (s.tinNumber != null && s.tinNumber!.isNotEmpty)
              Expanded(
                child: _StatTile(
                  label: 'TIN',
                  value: s.tinNumber!,
                  icon: Icons.badge_outlined,
                ),
              ),
          ],
        ),
        if (s.createdByName != null) ...[
          const SizedBox(height: 6),
          _IconLine(
              icon: Icons.person_outline_rounded,
              text: 'Added by ${s.createdByName}'),
        ],
        if (s.createdAt != null) ...[
          const SizedBox(height: 4),
          _IconLine(
              icon: Icons.event_outlined,
              text: 'Added ${formatDate(s.createdAt)}'),
        ],
      ],
    );
  }

  Widget _buildContactCard(Supplier s) {
    final lines = <Widget>[];
    void add(IconData icon, String? text) {
      if (text == null || text.isEmpty) return;
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 8));
      lines.add(_IconLine(icon: icon, text: text));
    }

    add(Icons.person_outline_rounded, s.contactName);
    add(Icons.phone_outlined, s.phone);
    add(Icons.email_outlined, s.email);
    add(Icons.location_on_outlined, s.address);

    return _SectionCard(
      title: 'Contact',
      eyebrow: 'Reach',
      icon: Icons.contact_phone_outlined,
      children: lines.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No contact details on file.',
                    style: AppType.body(14, color: kMuted)),
              )
            ]
          : lines,
    );
  }
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title,
      this.eyebrow,
      required this.icon,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: title,
              eyebrow: eyebrow,
              icon: icon,
              accent: ModuleAccent.ops),
          ...children,
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: kMuted),
            const SizedBox(width: 4),
            Text(label,
                style: AppType.body(10.5,
                    color: kMuted, weight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: AppType.number(16, color: AppColors.textNavy(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
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
        Expanded(child: Text(text, style: AppType.body(12.5, color: kMuted))),
      ],
    );
  }
}
