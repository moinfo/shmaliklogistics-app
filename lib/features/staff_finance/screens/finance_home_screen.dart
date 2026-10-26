import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/debtor.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../staff_finance_service.dart';
import 'invoice_detail_screen.dart';

/// Maps a billing-document status to its display colour (mirrors the web
/// `BillingDocument::$invoiceStatuses` palette).
Color invoiceStatusColor(String status) {
  switch (status) {
    case 'draft':     return const Color(0xFF94A3B8);
    case 'sent':      return const Color(0xFF60A5FA);
    case 'partial':   return const Color(0xFFF59E0B);
    case 'paid':      return const Color(0xFF22C55E);
    case 'overdue':   return const Color(0xFFEF4444);
    case 'cancelled': return const Color(0xFF475569);
    default:          return const Color(0xFF94A3B8);
  }
}

/// Formats an amount with an explicit currency code (invoices may be USD/TZS).
String formatMoney(double amount, String currency) {
  return '$currency ${NumberFormatHelper.thousands(amount)}';
}

/// Thin wrapper so we don't depend on intl directly here; reuses the app's
/// existing TZS formatter style for the thousands grouping.
class NumberFormatHelper {
  static String thousands(double amount) {
    final whole = amount.round();
    final s = whole.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${whole < 0 ? '-' : ''}$buf';
  }
}

/// Staff Finance feature entry point — embedded into the permission-driven
/// app shell (Agent 6). Internally exposes Invoices, Payments and Debtors
/// sections via a top tab bar. Detail screens are pushed via [Navigator].
/// Lets the navigation drawer ask the Finance screen to open a specific tab
/// (0 = Invoices, 1 = Payments, 2 = Debtors). Cleared once consumed.
final ValueNotifier<int?> financeTabRequest = ValueNotifier<int?>(null);

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen>
    with SingleTickerProviderStateMixin {
  late final StaffFinanceService _service;
  late final TabController _tabController;

  late Future<List<Invoice>> _invoicesFuture;
  late Future<List<Payment>> _paymentsFuture;
  late Future<List<Debtor>> _debtorsFuture;

  @override
  void initState() {
    super.initState();
    _service = StaffFinanceService(widget.apiClient);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: (financeTabRequest.value ?? 0).clamp(0, 2),
    );
    financeTabRequest.value = null;
    financeTabRequest.addListener(_onTabRequest);
    _invoicesFuture = _service.fetchInvoices();
    _paymentsFuture = _service.fetchPayments();
    _debtorsFuture = _service.fetchDebtors();
    // Tabs build lazily, so a failed request for a tab nobody has opened yet
    // would otherwise be reported as an unhandled exception. FutureBuilder
    // still receives the error once its tab is shown.
    _invoicesFuture.ignore();
    _paymentsFuture.ignore();
    _debtorsFuture.ignore();
  }

  void _onTabRequest() {
    final i = financeTabRequest.value;
    if (i == null) return;
    _tabController.animateTo(i.clamp(0, 2));
    financeTabRequest.value = null;
  }

  @override
  void dispose() {
    financeTabRequest.removeListener(_onTabRequest);
    _tabController.dispose();
    super.dispose();
  }

  void _reloadCurrent() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _invoicesFuture = _service.fetchInvoices()..ignore();
        case 1:
          _paymentsFuture = _service.fetchPayments()..ignore();
        case 2:
          _debtorsFuture = _service.fetchDebtors()..ignore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Billing & cash',
            title: 'Finance',
            subtitle: 'Invoices · Payments · Debtors',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reloadCurrent,
                tooltip: 'Refresh',
              ),
            ],
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _InvoicesTab(service: _service, future: _invoicesFuture, onReload: _reloadCurrent),
                _PaymentsTab(service: _service, future: _paymentsFuture, onReload: _reloadCurrent),
                _DebtorsTab(service: _service, future: _debtorsFuture, onReload: _reloadCurrent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar (clean bar under the gradient header) ─────────────────────────

  Widget _buildTabBar() {
    return Material(
      color: AppColors.surface(context),
      child: TabBar(
        controller: _tabController,
        indicatorColor: ModuleAccent.finance.base,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: ModuleAccent.finance.base,
        unselectedLabelColor: kMuted,
        labelStyle: AppType.body(13, weight: FontWeight.w700),
        unselectedLabelStyle: AppType.body(13, weight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Invoices'),
          Tab(text: 'Payments'),
          Tab(text: 'Debtors'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared loading / error / empty helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget financeError(BuildContext context, String message, VoidCallback onRetry) {
  return AppError(message: message, onRetry: onRetry);
}

Widget financeEmpty(BuildContext context, IconData icon, String title, String subtitle) {
  return ListView(
    children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.45,
        child: AppEmpty(icon: icon, message: '$title\n$subtitle'),
      ),
    ],
  );
}

/// Shimmer placeholder list shown while a tab's future is resolving.
Widget financeListSkeleton(BuildContext context, {double height = 116}) {
  return AppSkeleton(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (var i = 0; i < 5; i++) ...[
          AppSkeleton.box(context, height: height, radius: 16),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoices tab
// ─────────────────────────────────────────────────────────────────────────────

class _InvoicesTab extends StatelessWidget {
  final StaffFinanceService service;
  final Future<List<Invoice>> future;
  final VoidCallback onReload;
  const _InvoicesTab({required this.service, required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Invoice>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return financeListSkeleton(context, height: 132);
        }
        if (snapshot.hasError) {
          return financeError(context, snapshot.error.toString(), onReload);
        }
        final invoices = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onReload(),
          child: invoices.isEmpty
              ? financeEmpty(context, Icons.receipt_long_outlined, 'No invoices', 'Invoices will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: invoices.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InvoiceCard(
                        invoice: invoices[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoiceDetailScreen(invoiceId: invoices[i].id, service: service),
                            ),
                          );
                          onReload();
                        },
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  const _InvoiceCard({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = invoiceStatusColor(invoice.status);
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(invoice.documentNumber,
                  style: AppType.display(15, color: AppColors.textNavy(context))),
              StatusPill(label: invoice.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            invoice.clientName ?? invoice.clientCompany ?? 'Unknown client',
            style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Total', value: formatMoney(invoice.total, invoice.currency)),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Balance',
                  value: formatMoney(invoice.balanceDue, invoice.currency),
                  valueColor: invoice.balanceDue > 0.01 ? kDanger : kSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (invoice.dueDate != null) ...[
                const Icon(Icons.event_outlined, size: 12, color: kMuted),
                const SizedBox(width: 4),
                Text('Due ${formatDate(invoice.dueDate)}', style: AppType.body(11, color: kMuted)),
              ],
              const Spacer(),
              Text('View', style: AppType.body(11, color: ModuleAccent.finance.base, weight: FontWeight.w600)),
              Icon(Icons.chevron_right_rounded, size: 14, color: ModuleAccent.finance.base),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payments tab
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final StaffFinanceService service;
  final Future<List<Payment>> future;
  final VoidCallback onReload;
  const _PaymentsTab({required this.service, required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return financeListSkeleton(context, height: 84);
        }
        if (snapshot.hasError) {
          return financeError(context, snapshot.error.toString(), onReload);
        }
        final payments = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onReload(),
          child: payments.isEmpty
              ? financeEmpty(context, Icons.payments_outlined, 'No payments', 'Recorded payments will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: payments.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PaymentCard(payment: payments[i]),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: kSuccess,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded, size: 20, color: kSuccess),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment.clientName ?? payment.clientCompany ?? 'Payment',
                        style: AppType.display(14.5, color: AppColors.textNavy(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('+ ${formatCurrency(payment.amount)}',
                        style: AppType.number(14, color: kSuccess)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (payment.documentNumber != null) ...[
                      Text(payment.documentNumber!, style: AppType.body(11, color: kMuted, weight: FontWeight.w600)),
                      const SizedBox(width: 8),
                    ],
                    StatusPill(label: payment.methodLabel, color: ModuleAccent.finance.base),
                    const Spacer(),
                    if (payment.paymentDate != null)
                      Text(formatDate(payment.paymentDate), style: AppType.body(11, color: kMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Debtors tab
// ─────────────────────────────────────────────────────────────────────────────

class _DebtorsTab extends StatelessWidget {
  final StaffFinanceService service;
  final Future<List<Debtor>> future;
  final VoidCallback onReload;
  const _DebtorsTab({required this.service, required this.future, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Debtor>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return financeListSkeleton(context, height: 72);
        }
        if (snapshot.hasError) {
          return financeError(context, snapshot.error.toString(), onReload);
        }
        final debtors = snapshot.data ?? [];
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => onReload(),
          child: debtors.isEmpty
              ? financeEmpty(context, Icons.account_balance_outlined, 'No debtors', 'Outstanding balances will appear here.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: debtors.length,
                  itemBuilder: (_, i) => RevealOnLoad(
                    delayMs: (i * 60).clamp(0, 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DebtorCard(debtor: debtors[i]),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _DebtorCard extends StatelessWidget {
  final Debtor debtor;
  const _DebtorCard({required this.debtor});

  @override
  Widget build(BuildContext context) {
    final overdue = debtor.maxDays > 0;
    final color = overdue ? kDanger : kWarning;
    return AppCard(
      accentColor: color,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.business_rounded, size: 20, color: color),
          ),
          title: Text(
            debtor.clientName ?? debtor.clientCompany ?? 'Unknown',
            style: AppType.display(14.5, color: AppColors.textNavy(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(formatCurrency(debtor.balanceDue),
                    style: AppType.number(13, color: kDanger)),
                const SizedBox(width: 8),
                StatusPill(
                  label: overdue ? '${debtor.maxDays}d overdue' : 'Due soon',
                  color: color,
                ),
              ],
            ),
          ),
          children: [
            _MiniStat(label: 'Total invoiced', value: formatCurrency(debtor.totalInvoiced)),
            const SizedBox(height: 6),
            _MiniStat(label: 'Total paid', value: formatCurrency(debtor.totalPaid)),
            const Divider(height: 18),
            ...debtor.invoices.map((inv) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.documentNumber, style: AppType.body(12, weight: FontWeight.w600, color: AppColors.textPrimary(context))),
                            Text(
                              inv.dueDate != null ? 'Due ${formatDate(inv.dueDate)}' : 'No due date',
                              style: AppType.body(10, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(formatMoney(inv.balanceDue, inv.currency),
                          style: AppType.number(12, color: kDanger)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _MiniStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(10, color: kMuted, weight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: AppType.number(13.5, color: valueColor ?? AppColors.textPrimary(context))),
      ],
    );
  }
}

