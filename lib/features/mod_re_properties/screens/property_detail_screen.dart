import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/property.dart';
import '../mod_re_properties_service.dart';
import 'properties_screen.dart' show iconForPropertyType, tzs;

/// Read-only detail for a single property: identity, financial headline,
/// acquisition record, its units (with active-lease tenants) and recent
/// expenses.
class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;
  final ModRePropertiesService service;

  /// The list-row summary, shown immediately while the full record loads.
  final PropertyRow? initial;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.service,
    this.initial,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Future<PropertyDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchProperty(widget.propertyId);
  }

  void _reload() =>
      setState(() => _future = widget.service.fetchProperty(widget.propertyId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PropertyDetail>(
      future: _future,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final title = detail?.name ?? widget.initial?.name ?? 'Property';
        final subtitle = detail?.code ?? widget.initial?.code;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _header(title, subtitle),
              Expanded(child: _body(snapshot)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _header(String title, String? subtitle) {
    return AppGradientHeader(
      eyebrow: 'Real Estate',
      title: title,
      subtitle: subtitle,
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

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _body(AsyncSnapshot<PropertyDetail> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _skeleton();
    }
    if (snapshot.hasError && snapshot.data == null) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final p = snapshot.data!;

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _statusCard(p)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _financialsRow(p.financials)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _acquisitionCard(p)),
            const SizedBox(height: 18),
            RevealOnLoad(delayMs: 180, child: _unitsSection(p)),
            const SizedBox(height: 18),
            RevealOnLoad(delayMs: 240, child: _expensesSection(p)),
            if (p.description != null && p.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 300,
                child: _SectionCard(
                  title: 'Description',
                  eyebrow: 'About',
                  icon: Icons.notes_outlined,
                  children: [
                    Text(p.description!, style: AppType.body(14, height: 1.5))
                  ],
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
          AppSkeleton.box(context, height: 96, radius: 20),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 160, radius: 18),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 200, radius: 18),
        ],
      ),
    );
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  Widget _statusCard(PropertyDetail p) {
    final color = p.statusColor;
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
            child: Icon(iconForPropertyType(p.type), size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style:
                        AppType.display(19, color: AppColors.textNavy(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (p.code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(p.code, style: AppType.number(12.5, color: kMuted)),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(label: p.statusLabel, color: color),
                    if (p.typeLabel != null && p.typeLabel!.isNotEmpty)
                      StatusPill(label: p.typeLabel!, color: kPrimary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialsRow(Financials f) {
    final cards = [
      StatCard(
        label: 'Total Invested',
        value: tzs(f.totalInvested),
        icon: Icons.account_balance_wallet_rounded,
        accent: ModuleAccent.brand,
      ),
      StatCard(
        label: 'Renovation',
        value: tzs(f.renovationTotal),
        icon: Icons.construction_rounded,
        accent: ModuleAccent.ops,
      ),
      StatCard(
        label: 'Annual Rent Roll',
        value: tzs(f.annualRentRoll),
        icon: Icons.payments_rounded,
        accent: ModuleAccent.finance,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: cards,
    );
  }

  Widget _acquisitionCard(PropertyDetail p) {
    return _SectionCard(
      title: 'Acquisition',
      eyebrow: 'Title & purchase',
      icon: Icons.gavel_rounded,
      children: [
        _InfoRow(
          label: 'Purchase price',
          value: p.financials.purchasePrice > 0
              ? tzs(p.financials.purchasePrice)
              : '—',
        ),
        _InfoRow(
          label: 'Market value',
          value: p.marketValue != null && p.marketValue! > 0
              ? tzs(p.marketValue!)
              : '—',
        ),
        _InfoRow(
            label: 'Acquired', value: formatDate(p.acquisitionDate)),
        _InfoRow(
          label: 'Title deed no.',
          value: (p.titleDeedNumber == null || p.titleDeedNumber!.isEmpty)
              ? '—'
              : p.titleDeedNumber!,
        ),
        if (p.ownership != null && p.ownership!.isNotEmpty)
          _InfoRow(label: 'Ownership', value: p.ownership!),
        if (p.district != null && p.district!.isNotEmpty)
          _InfoRow(label: 'District', value: p.district!),
      ],
    );
  }

  Widget _unitsSection(PropertyDetail p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Units (${p.units.length})',
          eyebrow: '${p.occupiedUnitsCount} occupied',
          icon: Icons.meeting_room_rounded,
          accent: ModuleAccent.brand,
        ),
        if (p.units.isEmpty)
          AppCard(
            child: Text('No units recorded for this property.',
                style: AppType.body(14, color: kMuted)),
          )
        else
          for (var i = 0; i < p.units.length; i++) ...[
            _UnitCard(unit: p.units[i]),
            if (i != p.units.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _expensesSection(PropertyDetail p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Expenses (${p.expenses.length})',
          eyebrow: 'Spend',
          icon: Icons.receipt_long_rounded,
          accent: ModuleAccent.danger,
        ),
        if (p.expenses.isEmpty)
          AppCard(
            child: Text('No expenses logged for this property.',
                style: AppType.body(14, color: kMuted)),
          )
        else
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < p.expenses.length; i++) ...[
                  _ExpenseRow(expense: p.expenses[i]),
                  if (i != p.expenses.length - 1) const Divider(height: 18),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unit card
// ─────────────────────────────────────────────────────────────────────────────

class _UnitCard extends StatelessWidget {
  final PropertyUnitInfo unit;
  const _UnitCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    final color = unit.statusColor;
    final lease = unit.activeLease;
    final rent = unit.rentAmount > 0
        ? '${unit.rentCurrency ?? 'TZS'} ${_thousands(unit.rentAmount)}'
        : null;

    return AppCard(
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit ${unit.unitNumber}',
                      style: AppType.number(15,
                          color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (unit.typeLabel != null && unit.typeLabel!.isNotEmpty)
                      Text(unit.typeLabel!,
                          style: AppType.body(12, color: kMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: unit.statusLabel, color: color),
            ],
          ),
          if (rent != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Text(rent,
                    style: AppType.number(13,
                        color: AppColors.textPrimary(context))),
              ],
            ),
          ],
          if (lease != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 14, color: kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lease.tenantName ?? 'Tenant',
                      style: AppType.body(12.5,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimary(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lease.leaseNumber != null &&
                      lease.leaseNumber!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(lease.leaseNumber!,
                        style: AppType.number(11.5, color: kMuted)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _thousands(double n) {
    final i = n.round();
    final s = i.abs().toString();
    final buf = StringBuffer(i < 0 ? '-' : '');
    for (var k = 0; k < s.length; k++) {
      if (k != 0 && (s.length - k) % 3 == 0) buf.write(',');
      buf.write(s[k]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense row
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseRow extends StatelessWidget {
  final PropertyExpenseInfo expense;
  const _ExpenseRow({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kMuted.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(_iconForCategory(expense.categoryIcon),
                size: 18, color: kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.categoryLabel ?? expense.category ?? 'Expense',
                  style: AppType.body(13.5,
                      weight: FontWeight.w700,
                      color: AppColors.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expense.description != null &&
                    expense.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(expense.description!,
                      style: AppType.body(12, color: kMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 2),
                Text(formatDate(expense.expenseDate),
                    style: AppType.body(11, color: kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(tzs(expense.amountTzs),
              style: AppType.number(13, color: kDanger)),
        ],
      ),
    );
  }

  /// Best-effort map from a backend category-icon hint to a Material icon.
  /// The backend may send Material/FontAwesome-style names; we degrade to a
  /// generic receipt glyph for anything unrecognised.
  IconData _iconForCategory(String? hint) {
    switch ((hint ?? '').toLowerCase().replaceAll('-', '_')) {
      case 'build':
      case 'construction':
      case 'hammer':
      case 'renovation':
        return Icons.construction_rounded;
      case 'bolt':
      case 'power':
      case 'electricity':
        return Icons.bolt_rounded;
      case 'water':
      case 'water_drop':
      case 'droplet':
        return Icons.water_drop_rounded;
      case 'cleaning':
      case 'broom':
        return Icons.cleaning_services_rounded;
      case 'security':
      case 'shield':
        return Icons.shield_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'tax':
      case 'gavel':
        return Icons.gavel_rounded;
      case 'maintenance':
      case 'wrench':
      case 'tools':
        return Icons.handyman_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
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
              accent: ModuleAccent.brand),
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
            child: Text(label,
                style:
                    AppType.body(12.5, color: kMuted, weight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppType.body(13.5,
                  weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}