import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/invoice.dart';
import '../staff_finance_service.dart';
import 'finance_home_screen.dart' show formatMoney;

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  final StaffFinanceService service;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
    required this.service,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Future<Invoice> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchInvoice(widget.invoiceId);
  }

  void _reload() => setState(() => _future = widget.service.fetchInvoice(widget.invoiceId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Invoice>(
      future: _future,
      builder: (context, snapshot) {
        final invoice = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(invoice),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
          floatingActionButton: _buildRecordPaymentFab(invoice),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(Invoice? invoice) {
    return AppGradientHeader(
      eyebrow: 'Invoice',
      title: invoice?.documentNumber ?? 'Invoice',
      subtitle: invoice?.statusLabel,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 22),
      actions: [
        HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        HeaderIconButton(icon: Icons.refresh_rounded, onTap: _reload, tooltip: 'Refresh'),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(AsyncSnapshot<Invoice> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final inv = snapshot.data!;
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildClientCard(inv)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildLineItemsCard(inv)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 120, child: _buildTotalsCard(inv)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 180, child: _buildPaymentsCard(inv)),
            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(inv.notes!, style: AppType.body(14, height: 1.5))],
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          AppSkeleton.box(context, height: 150, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 120, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 180, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 110, radius: 16),
        ],
      ),
    );
  }

  Widget _buildClientCard(Invoice inv) {
    return _SectionCard(
      title: 'Bill To',
      eyebrow: 'Client',
      icon: Icons.business_rounded,
      children: [
        Text(inv.clientName ?? inv.clientCompany ?? 'Unknown client',
            style: AppType.display(16, color: AppColors.textPrimary(context))),
        if (inv.clientCompany != null && inv.clientCompany != inv.clientName) ...[
          const SizedBox(height: 2),
          Text(inv.clientCompany!, style: AppType.body(13, color: kMuted)),
        ],
        if (inv.clientEmail != null) ...[
          const SizedBox(height: 6),
          _IconLine(icon: Icons.email_outlined, text: inv.clientEmail!),
        ],
        if (inv.clientPhone != null) ...[
          const SizedBox(height: 4),
          _IconLine(icon: Icons.phone_outlined, text: inv.clientPhone!),
        ],
        const Divider(height: 20),
        Row(
          children: [
            Expanded(child: _IconLine(icon: Icons.event_available_outlined, text: 'Issued ${formatDate(inv.issueDate)}')),
            Expanded(child: _IconLine(icon: Icons.event_outlined, text: 'Due ${formatDate(inv.dueDate)}')),
          ],
        ),
        if (inv.tripNumber != null) ...[
          const SizedBox(height: 6),
          _IconLine(
            icon: Icons.local_shipping_outlined,
            text: [inv.tripNumber, if (inv.tripRouteFrom != null) '${inv.tripRouteFrom} → ${inv.tripRouteTo}'].whereType<String>().join('  ·  '),
          ),
        ],
      ],
    );
  }

  Widget _buildLineItemsCard(Invoice inv) {
    return _SectionCard(
      title: 'Line Items (${inv.items.length})',
      eyebrow: 'Breakdown',
      icon: Icons.list_alt_outlined,
      children: inv.items.isEmpty
          ? [Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No line items.', style: AppType.body(14, color: kMuted)),
            )]
          : inv.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description,
                              style: AppType.body(13, weight: FontWeight.w600, color: AppColors.textPrimary(context))),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'
                            '${item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : ''}'
                            ' × ${formatMoney(item.unitPrice, inv.currency)}',
                            style: AppType.body(11, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(formatMoney(item.total, inv.currency),
                        style: AppType.number(13, color: AppColors.textPrimary(context))),
                  ],
                ),
              )).toList(),
    );
  }

  Widget _buildTotalsCard(Invoice inv) {
    return _SectionCard(
      title: 'Totals',
      eyebrow: 'Ledger',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _FinRow(label: 'Subtotal', value: formatMoney(inv.subtotal, inv.currency)),
        if (inv.discountAmount > 0) _FinRow(label: 'Discount', value: '- ${formatMoney(inv.discountAmount, inv.currency)}'),
        if (inv.taxAmount > 0) _FinRow(label: 'Tax', value: formatMoney(inv.taxAmount, inv.currency)),
        const _Divider(),
        _FinRow(label: 'Total', value: formatMoney(inv.total, inv.currency), isBold: true, isHighlight: true),
        _FinRow(label: 'Amount paid', value: formatMoney(inv.amountPaid, inv.currency)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: (inv.isFullyPaid ? kSuccess : kDanger).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (inv.isFullyPaid ? kSuccess : kDanger).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(inv.isFullyPaid ? Icons.check_circle_rounded : Icons.account_balance_outlined,
                    size: 18, color: inv.isFullyPaid ? kSuccess : kDanger),
                const SizedBox(width: 8),
                Text(inv.isFullyPaid ? 'Fully paid' : 'Balance due',
                    style: AppType.body(14, weight: FontWeight.w700)),
              ]),
              Text(formatMoney(inv.balanceDue, inv.currency),
                  style: AppType.number(16, color: inv.isFullyPaid ? kSuccess : kDanger)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsCard(Invoice inv) {
    return _SectionCard(
      title: 'Payments (${inv.payments.length})',
      eyebrow: 'Received',
      icon: Icons.payments_outlined,
      children: inv.payments.isEmpty
          ? [Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No payments recorded yet.', style: AppType.body(14, color: kMuted)),
            )]
          : inv.payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatCurrency(p.amount),
                            style: AppType.number(13.5, color: kSuccess)),
                        Text(p.paymentDate != null ? formatDate(p.paymentDate) : '—',
                            style: AppType.body(11, color: kMuted)),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusPill(label: p.methodLabel, color: ModuleAccent.finance.base),
                        if (p.referenceNumber != null && p.referenceNumber!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(p.referenceNumber!, style: AppType.body(10, color: kMuted)),
                        ],
                      ],
                    ),
                  ],
                ),
              )).toList(),
    );
  }

  // ── Record payment action (gated) ────────────────────────────────────────────

  Widget? _buildRecordPaymentFab(Invoice? invoice) {
    if (invoice == null) return null;
    if (!AppSession.instance.can('billing_payments.create')) return null;
    if (invoice.isFullyPaid || invoice.status == 'cancelled') return null;

    return FloatingActionButton.extended(
      backgroundColor: ModuleAccent.finance.base,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_card_rounded),
      label: Text('Record Payment', style: AppType.body(15, weight: FontWeight.w600, color: Colors.white)),
      onPressed: () async {
        final saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _RecordPaymentSheet(invoice: invoice, service: widget.service),
        );
        if (saved == true) _reload();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Record payment bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RecordPaymentSheet extends StatefulWidget {
  final Invoice invoice;
  final StaffFinanceService service;
  const _RecordPaymentSheet({required this.invoice, required this.service});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _method = 'bank_transfer';
  DateTime _date = DateTime.now();
  bool _saving = false;

  // Mirrors Payment::$methods on the backend.
  static const _methods = [
    ('bank_transfer', 'Bank Transfer'),
    ('cash', 'Cash'),
    ('mobile_money', 'Mobile Money'),
    ('cheque', 'Cheque'),
    ('rtgs', 'RTGS'),
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.invoice.balanceDue.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.recordPayment(
        widget.invoice.id,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        method: _method,
        date: _date,
        referenceNumber: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Record Payment',
                  style: AppType.display(19, color: AppColors.textNavy(context))),
              const SizedBox(height: 4),
              Text('${widget.invoice.documentNumber}  ·  Balance ${formatMoney(widget.invoice.balanceDue, widget.invoice.currency)}',
                  style: AppType.body(13, color: kMuted)),
              const SizedBox(height: 20),

              _field(
                controller: _amountCtrl,
                label: 'Amount (${widget.invoice.currency})',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Payment method
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: _decoration(context, 'Payment method'),
                items: _methods
                    .map((m) => DropdownMenuItem(value: m.$1, child: Text(m.$2, style: AppType.body(14))))
                    .toList(),
                onChanged: (v) => setState(() => _method = v ?? _method),
              ),
              const SizedBox(height: 12),

              // Payment date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: _decoration(context, 'Payment date'),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: kMuted),
                      const SizedBox(width: 8),
                      Text(formatDate(_date), style: AppType.body(14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _field(controller: _refCtrl, label: 'Reference number (optional)'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: _decoration(context, 'Notes (optional)'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ModuleAccent.finance.base,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ModuleAccent.finance.base.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: _decoration(context, label),
    );
  }

  InputDecoration _decoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceVariant(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ModuleAccent.finance.base, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail widgets (section card / financial rows)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, this.eyebrow, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.finance),
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
  const _FinRow({required this.label, required this.value, this.isBold = false, this.isHighlight = false});

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
                color: isHighlight ? ModuleAccent.finance.base : AppColors.textPrimary(context),
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
