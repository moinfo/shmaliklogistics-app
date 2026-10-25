import 'package:flutter/material.dart';

import '../auth/app_session.dart';
import '../ui/typography.dart';
import '../utils/app_theme.dart';
import '../utils/colors.dart';

/// One navigation entry, ported from `web/.../layouts/DashboardLayout.jsx`.
///
/// A leaf carries either [perm] (single permission) or [anyPerm] (visible if the
/// user has ANY). A parent carries [children] and is visible only when at least
/// one child is visible. [shellTab] names a real bottom-nav destination the
/// drawer should switch to; otherwise the leaf pushes a [ModulePlaceholderScreen].
class _MenuItem {
  final String label;
  final IconData icon;
  final String? perm;
  final List<String>? anyPerm;
  final List<_MenuItem>? children;

  /// If set, tapping switches the shell to this bottom-nav tab label
  /// ('Overview', 'Ops', 'Finance', 'HR', 'Home', 'Account').
  final String? shellTab;

  const _MenuItem({
    required this.label,
    required this.icon,
    this.perm,
    this.anyPerm,
    this.children,
    this.shellTab,
  });

  bool get isGroup => children != null;
}

/// Staff menu tree mirroring the web sidebar. Emojis from the web are mapped to
/// Material icons. Items whose destination already exists in the shell carry a
/// [shellTab]; everything else opens a clean placeholder screen.
const List<_MenuItem> _staffMenu = [
  _MenuItem(label: 'Dashboard', icon: Icons.dashboard_rounded, shellTab: 'Overview'),

  _MenuItem(label: 'Trips', icon: Icons.local_shipping_rounded, perm: 'trips.view', shellTab: 'Ops'),

  // ── Fleet ──────────────────────────────────────────────────────────────
  _MenuItem(
    label: 'Fleet',
    icon: Icons.directions_car_rounded,
    anyPerm: ['fleet.view', 'fleet_fuel_logs.view', 'inspections.view', 'trip_check_ins.view'],
    children: [
      _MenuItem(label: 'All Vehicles', icon: Icons.directions_car_rounded, perm: 'fleet.view'),
      _MenuItem(label: 'Fuel Logs', icon: Icons.local_gas_station_rounded, perm: 'fleet_fuel_logs.view'),
      _MenuItem(label: 'Inspections', icon: Icons.build_rounded, perm: 'inspections.view'),
      _MenuItem(label: 'Check-Ins', icon: Icons.location_on_rounded, perm: 'trip_check_ins.view'),
    ],
  ),

  _MenuItem(label: 'Drivers', icon: Icons.person_rounded, perm: 'drivers.view'),
  _MenuItem(label: 'Permits', icon: Icons.badge_rounded, perm: 'permits.view'),
  _MenuItem(label: 'Clients', icon: Icons.groups_rounded, perm: 'clients.view'),

  // ── Billing ────────────────────────────────────────────────────────────
  _MenuItem(
    label: 'Billing',
    icon: Icons.receipt_rounded,
    anyPerm: ['billing_quotes.view', 'billing_proformas.view', 'billing_invoices.view', 'billing_payments.view', 'billing_quote_requests.view'],
    children: [
      _MenuItem(label: 'Quotes', icon: Icons.chat_bubble_outline_rounded, perm: 'billing_quotes.view'),
      _MenuItem(label: 'Proforma', icon: Icons.description_rounded, perm: 'billing_proformas.view'),
      _MenuItem(label: 'Invoices', icon: Icons.receipt_long_rounded, perm: 'billing_invoices.view', shellTab: 'Finance'),
      _MenuItem(label: 'Payments', icon: Icons.credit_card_rounded, perm: 'billing_payments.view', shellTab: 'Finance'),
      _MenuItem(label: 'Debtors', icon: Icons.error_outline_rounded, perm: 'billing_invoices.view', shellTab: 'Finance'),
      _MenuItem(label: 'Quote Requests', icon: Icons.inbox_rounded, perm: 'billing_quote_requests.view'),
    ],
  ),

  _MenuItem(label: 'Expenses', icon: Icons.payments_rounded, perm: 'expenses.view'),
  _MenuItem(label: 'Maintenance', icon: Icons.handyman_rounded, perm: 'maintenance.view'),
  _MenuItem(label: 'Documents', icon: Icons.folder_rounded, perm: 'documents.view'),
  _MenuItem(label: 'Cargo', icon: Icons.inventory_2_rounded, perm: 'cargo.view'),

  // ── HR ─────────────────────────────────────────────────────────────────
  _MenuItem(
    label: 'HR',
    icon: Icons.groups_2_rounded,
    anyPerm: ['hr_employees.view', 'hr_leave.view', 'hr_payroll.view', 'hr_advances.view', 'hr_loans.view', 'hr_allowances.view', 'hr_bonus.view', 'hr_attendance.view', 'hr_salary_slips.view', 'hr_appraisals.view', 'hr_recruitment.view'],
    children: [
      _MenuItem(label: 'Employees', icon: Icons.badge_rounded, perm: 'hr_employees.view'),
      _MenuItem(label: 'Leave', icon: Icons.beach_access_rounded, perm: 'hr_leave.view', shellTab: 'HR'),
      _MenuItem(label: 'Payroll', icon: Icons.account_balance_wallet_rounded, perm: 'hr_payroll.view'),
      _MenuItem(label: 'Advances', icon: Icons.attach_money_rounded, perm: 'hr_advances.view', shellTab: 'HR'),
      _MenuItem(label: 'Loans', icon: Icons.account_balance_rounded, perm: 'hr_loans.view', shellTab: 'HR'),
      _MenuItem(label: 'Allowances', icon: Icons.card_giftcard_rounded, perm: 'hr_allowances.view'),
      _MenuItem(label: 'Bonus', icon: Icons.emoji_events_rounded, perm: 'hr_bonus.view'),
      _MenuItem(label: 'Attendance', icon: Icons.schedule_rounded, perm: 'hr_attendance.view'),
      _MenuItem(label: 'Salary Slip', icon: Icons.article_rounded, perm: 'hr_salary_slips.view'),
      _MenuItem(label: 'Appraisals', icon: Icons.star_rounded, perm: 'hr_appraisals.view'),
      _MenuItem(label: 'Recruitment', icon: Icons.person_search_rounded, perm: 'hr_recruitment.view'),
    ],
  ),

  // ── Procurement & Inventory ──────────────────────────────────────────────
  _MenuItem(
    label: 'Procurement',
    icon: Icons.shopping_cart_rounded,
    anyPerm: ['procurement_suppliers.view', 'procurement_orders.view'],
    children: [
      _MenuItem(label: 'Suppliers', icon: Icons.factory_rounded, perm: 'procurement_suppliers.view'),
      _MenuItem(label: 'Purchase Orders', icon: Icons.list_alt_rounded, perm: 'procurement_orders.view'),
    ],
  ),
  _MenuItem(label: 'Inventory', icon: Icons.warehouse_rounded, perm: 'inventory.view'),

  // ── Real Estate ──────────────────────────────────────────────────────────
  _MenuItem(
    label: 'Real Estate',
    icon: Icons.home_work_rounded,
    anyPerm: ['realestate_properties.view', 'realestate_tenants.view', 'realestate_leases.view', 'realestate_rent.view', 'realestate_expenses.view'],
    children: [
      _MenuItem(label: 'Properties', icon: Icons.apartment_rounded, perm: 'realestate_properties.view'),
      _MenuItem(label: 'Tenants', icon: Icons.people_alt_rounded, perm: 'realestate_tenants.view'),
      _MenuItem(label: 'Leases', icon: Icons.description_rounded, perm: 'realestate_leases.view'),
      _MenuItem(label: 'Rent', icon: Icons.payments_rounded, perm: 'realestate_rent.view'),
      _MenuItem(label: 'Property Expenses', icon: Icons.construction_rounded, perm: 'realestate_expenses.view'),
    ],
  ),

  // ── Reports ──────────────────────────────────────────────────────────────
  _MenuItem(
    label: 'Reports',
    icon: Icons.trending_up_rounded,
    anyPerm: ['reports_route_profitability.view', 'reports_financial_summary.view', 'reports_fleet_utilization.view', 'billing_invoices.view'],
    children: [
      _MenuItem(label: 'Route Profitability', icon: Icons.bar_chart_rounded, perm: 'reports_route_profitability.view'),
      _MenuItem(label: 'Financial Summary', icon: Icons.show_chart_rounded, perm: 'reports_financial_summary.view'),
      _MenuItem(label: 'Fleet Utilization', icon: Icons.local_shipping_rounded, perm: 'reports_fleet_utilization.view'),
      _MenuItem(label: 'Debtors / AR', icon: Icons.error_outline_rounded, perm: 'billing_invoices.view'),
    ],
  ),

  // ── Settings ─────────────────────────────────────────────────────────────
  _MenuItem(
    label: 'Settings',
    icon: Icons.settings_rounded,
    perm: 'settings.view',
    children: [
      _MenuItem(label: 'Company Settings', icon: Icons.business_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Licence Classes', icon: Icons.credit_card_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Document Types', icon: Icons.description_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Payroll Settings', icon: Icons.account_balance_wallet_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Deductions', icon: Icons.list_alt_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Deduction Subscriptions', icon: Icons.link_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Staff Bank Details', icon: Icons.account_balance_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Departments', icon: Icons.apartment_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Roles & Permissions', icon: Icons.vpn_key_rounded, perm: 'settings.view'),
      _MenuItem(label: 'Users', icon: Icons.person_rounded, perm: 'settings.view'),
    ],
  ),

  _MenuItem(label: 'Notifications', icon: Icons.notifications_rounded),
];

/// Customer menu — always visible to a signed-in customer (no perm gating).
/// Maps to the single 'Home' shell tab (the customer portal has internal tabs).
const List<_MenuItem> _customerMenu = [
  _MenuItem(label: 'Dashboard', icon: Icons.dashboard_rounded, shellTab: 'Home'),
  _MenuItem(label: 'My Trips', icon: Icons.local_shipping_rounded, shellTab: 'Home'),
  _MenuItem(label: 'Invoices', icon: Icons.receipt_long_rounded, shellTab: 'Home'),
  _MenuItem(label: 'Cargo', icon: Icons.inventory_2_rounded, shellTab: 'Home'),
  _MenuItem(label: 'Quote Requests', icon: Icons.request_quote_rounded, shellTab: 'Home'),
];

/// Full navigation drawer mirroring the web sidebar, permission-filtered.
///
/// [availableTabs] are the bottom-nav tab labels currently mounted in the shell;
/// a menu item only switches tabs when its [shellTab] is in this set, otherwise
/// it pushes a [ModulePlaceholderScreen]. [activeTabLabel] highlights the active
/// destination. [onSelectTab] asks the shell to switch the active bottom tab.
class AppDrawer extends StatelessWidget {
  final String activeTabLabel;
  final Set<String> availableTabs;
  final void Function(String tabLabel) onSelectTab;
  final void Function(String label, IconData icon) onOpenModule;

  const AppDrawer({
    super.key,
    required this.activeTabLabel,
    required this.availableTabs,
    required this.onSelectTab,
    required this.onOpenModule,
  });

  bool _visible(_MenuItem item) {
    final s = AppSession.instance;
    if (item.perm != null) return s.can(item.perm!);
    if (item.anyPerm != null) return s.canAny(item.anyPerm!);
    return true; // always-visible (Dashboard, Notifications, customer items)
  }

  List<_MenuItem> _visibleChildren(_MenuItem parent) =>
      parent.children!.where(_visible).toList();

  void _activate(BuildContext context, _MenuItem item) {
    Navigator.of(context).pop(); // close the drawer first
    final tab = item.shellTab;
    if (tab != null && availableTabs.contains(tab)) {
      onSelectTab(tab);
      return;
    }
    // Everything else opens inside the shell (real module screen or a clean
    // placeholder) so the bottom nav + back arrow persist.
    onOpenModule(item.label, item.icon);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    final isCustomer = session.accountType == 'customer';
    final source = isCustomer ? _customerMenu : _staffMenu;

    // Filter: leaves by perm; groups visible only if ≥1 child visible.
    final items = <_MenuItem>[];
    for (final item in source) {
      if (item.isGroup) {
        final kids = _visibleChildren(item);
        if (kids.isEmpty) continue;
        items.add(_MenuItem(
          label: item.label,
          icon: item.icon,
          perm: item.perm,
          anyPerm: item.anyPerm,
          children: kids,
        ));
      } else if (_visible(item)) {
        items.add(item);
      }
    }

    return Drawer(
      backgroundColor: AppColors.surfaceVariant(context),
      child: Column(
        children: [
          const _DrawerHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MAIN MENU', style: AppType.eyebrow(size: 10, color: kMuted)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                8,
                4,
                8,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                for (final item in items)
                  if (item.isGroup)
                    _GroupTile(
                      item: item,
                      activeTabLabel: activeTabLabel,
                      isChildActive: (c) => _isLeafActive(c),
                      onTapChild: (c) => _activate(context, c),
                    )
                  else
                    _LeafTile(
                      item: item,
                      active: _isLeafActive(item),
                      onTap: () => _activate(context, item),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isLeafActive(_MenuItem leaf) =>
      leaf.shellTab != null &&
      availableTabs.contains(leaf.shellTab) &&
      leaf.shellTab == activeTabLabel;
}

/// Navy gradient band with the Trans-Mas logo + wordmark.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7A2800), Color(0xFFEA580C), Color(0xFF7A2800)],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                ),
                child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TRANS-MAS',
                        style: AppType.display(18, color: Colors.white, letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Text(session.name.isEmpty ? 'Logistics Platform' : session.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body(12.5,
                            color: Colors.white.withValues(alpha: 0.72),
                            weight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A leaf navigation row.
class _LeafTile extends StatelessWidget {
  final _MenuItem item;
  final bool active;
  final VoidCallback onTap;
  const _LeafTile({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = kPrimary;
    final color = active ? activeColor : AppColors.textPrimary(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: active ? kPrimary.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: active ? kPrimary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(item.icon, size: 21, color: active ? activeColor : kMuted),
        title: Text(item.label,
            style: AppType.body(14,
                color: color, weight: active ? FontWeight.w700 : FontWeight.w500)),
        trailing: active
            ? Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// An expandable parent row + its child rows.
class _GroupTile extends StatelessWidget {
  final _MenuItem item;
  final String activeTabLabel;
  final bool Function(_MenuItem child) isChildActive;
  final void Function(_MenuItem child) onTapChild;

  const _GroupTile({
    required this.item,
    required this.activeTabLabel,
    required this.isChildActive,
    required this.onTapChild,
  });

  @override
  Widget build(BuildContext context) {
    final children = item.children!;
    final hasActiveChild = children.any(isChildActive);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: hasActiveChild,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(item.icon, size: 21, color: hasActiveChild ? kPrimary : kMuted),
        title: Text(item.label,
            style: AppType.body(14,
                color: hasActiveChild ? kPrimary : AppColors.textPrimary(context),
                weight: hasActiveChild ? FontWeight.w700 : FontWeight.w600)),
        children: [
          for (final child in children)
            Container(
              margin: const EdgeInsets.only(left: 12, right: 4, top: 1, bottom: 1),
              decoration: BoxDecoration(
                color: isChildActive(child)
                    ? kPrimary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border(
                  left: BorderSide(
                    color: isChildActive(child)
                        ? kPrimary
                        : kPrimary.withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
              ),
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(child.icon,
                    size: 18,
                    color: isChildActive(child) ? kPrimary : kMuted.withValues(alpha: 0.8)),
                title: Text(child.label,
                    style: AppType.body(13,
                        color: isChildActive(child)
                            ? kPrimary
                            : AppColors.textPrimary(context),
                        weight: isChildActive(child) ? FontWeight.w700 : FontWeight.w500)),
                onTap: () => onTapChild(child),
              ),
            ),
        ],
      ),
    );
  }
}
