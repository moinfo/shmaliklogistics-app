import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/rent_invoice.dart';
import '../mod_re_rent_service.dart';

/// "Rent" — a read-only, searchable list of rent invoices with a collection
/// summary. List-only (no detail screen). Wired into the app drawer via
/// [RealEstateRentScreen]. Search and status filters are applied server-side.
class RealEstateRentScreen extends StatefulWidget {
  const RealEstateRentScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<RealEstateRentScreen> createState() => _RealEstateRentScreenState();
}

class _RealEstateRentScreenState extends State<RealEstateRentScreen> {
  late final ModReRentService _service;
  late Future<RentInvoicesPayload> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _statusFilter; // null == all
  Timer? _debounce;

  // Status enum map from the most recent successful load, kept so the filter
  // chips stay stable while a filtered re-fetch is in flight.
  Map<String, dynamic> _statuses = const {};

  // Payment-method enum map from the most recent successful load, used to
  // populate the "Record Payment" form's method dropdown.
  Map<String, dynamic> _paymentMethods = const {};

  // Whether the current staff user may record payments.
  final bool _canRecordPayment =
      AppSession.instance.can('realestate_rent.create');

  @override
  void initState() {
    super.initState();
    _service = ModReRentService(widget.apiClient);
    _future = _service.fetchInvoices();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q == _query) return;
    _query = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  void _reload() {
    setState(() {
      _future = _service.fetchInvoices(search: _query, status: _statusFilter);
    });
  }

  void _selectStatus(String? key) {
    if (_statusFilter == key) return;
    setState(() {
      _statusFilter = key;
      _future = _service.fetchInvoices(search: _query, status: _statusFilter);
    });
  }

  /// Opens the "Record Payment" bottom sheet for [row]. On a successful
  /// submission the list is re-fetched and a confirmation SnackBar is shown.
  Future<void> _openPaymentSheet(RentInvoiceRow row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(
        service: _service,
        row: row,
        paymentMethods: _paymentMethods,
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded')),
      );
      _reload();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Parses a backend hex colour (e.g. "#22C55E"), falling back to [kMuted].
  Color _hex(String? s) {
    if (s == null || s.isEmpty) return kMuted;
    final value = int.tryParse('FF${s.replaceAll('#', '')}', radix: 16);
    return value == null ? kMuted : Color(value);
  }

  /// Resolves the display label for a status enum key from the [_statuses] map,
  /// whose values may be a plain string or a `{label, color}` object.
  String _statusLabel(String key, dynamic value) {
    if (value is String) return value;
    if (value is Map && value['label'] != null) return value['label'].toString();
    return _titleCase(key);
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Real Estate',
            title: 'Rent',
            subtitle: 'Rent invoices & collection',
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
            actions: [
              HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: _reload,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<RentInvoicesPayload>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }
                final payload = snapshot.data;
                final rows = payload?.rows ?? const <RentInvoiceRow>[];
                if (payload != null && payload.statuses.isNotEmpty) {
                  _statuses = payload.statuses;
                }
                if (payload != null && payload.paymentMethods.isNotEmpty) {
                  _paymentMethods = payload.paymentMethods;
                }
                final stats = payload?.stats ??
                    RentStats(
                      totalBilled: 0,
                      totalCollected: 0,
                      outstanding: 0,
                      overdueCount: 0,
                    );

                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _statsRow(stats)),
                      SliverToBoxAdapter(child: _statsRowB(stats)),
                      SliverToBoxAdapter(child: _searchBar()),
                      SliverToBoxAdapter(child: _statusChips()),
                      if (rows.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.receipt_long_outlined,
                            message: (_query.isEmpty && _statusFilter == null)
                                ? 'No rent invoices yet.'
                                : 'No invoices match your filters.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: rows.length,
                            itemBuilder: (_, i) => RevealOnLoad(
                              delayMs: (i * 60).clamp(0, 300),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RentInvoiceCard(
                                  row: rows[i],
                                  accent: _hex(rows[i].statusColorHex),
                                  canRecordPayment: _canRecordPayment,
                                  onRecordPayment: () =>
                                      _openPaymentSheet(rows[i]),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat cards ───────────────────────────────────────────────────────────

  Widget _statsRow(RentStats s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total Billed',
              value: _money(s.totalBilled),
              icon: Icons.request_quote_rounded,
              accent: ModuleAccent.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Collected',
              value: _money(s.totalCollected),
              icon: Icons.payments_rounded,
              accent: ModuleAccent.finance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRowB(RentStats s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Outstanding',
              value: _money(s.outstanding),
              icon: Icons.account_balance_wallet_rounded,
              accent: ModuleAccent.danger,
              danger: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Overdue',
              value: NumberFormat('#,##0', 'en').format(s.overdueCount),
              icon: Icons.warning_amber_rounded,
              accent: ModuleAccent.danger,
              danger: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a money value with thousands separators (TZS / plain number).
  String _money(double v) => NumberFormat('#,##0', 'en').format(v);

  // ── Search field ───────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search invoice, tenant, property…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: kMuted),
                  onPressed: () => _searchCtrl.clear(),
                ),
          filled: true,
          fillColor: AppColors.surface(context),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        ),
      ),
    );
  }

  // ── Status filter chips ──────────────────────────────────────────────────

  Widget _statusChips() {
    if (_statuses.isEmpty) return const SizedBox.shrink();
    final entries = _statuses.entries.toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        children: [
          _chip('All', _statusFilter == null, () => _selectStatus(null)),
          for (final e in entries)
            _chip(
              _statusLabel(e.key, e.value),
              _statusFilter == e.key,
              () => _selectStatus(e.key),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: AppType.body(
          12.5,
          weight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textPrimary(context),
        ),
        selectedColor: kPrimary,
        backgroundColor: AppColors.surface(context),
        showCheckmark: false,
        side: BorderSide(color: selected ? kPrimary : AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _skeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 104, radius: 20)),
            ],
          ),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 48, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 5; i++) ...[
            AppSkeleton.box(context, height: 128, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rent invoice list card
// ─────────────────────────────────────────────────────────────────────────────

class _RentInvoiceCard extends StatelessWidget {
  final RentInvoiceRow row;
  final Color accent;
  final bool canRecordPayment;
  final VoidCallback onRecordPayment;
  const _RentInvoiceCard({
    required this.row,
    required this.accent,
    required this.canRecordPayment,
    required this.onRecordPayment,
  });

  static final NumberFormat _money = NumberFormat('#,##0', 'en');

  @override
  Widget build(BuildContext context) {
    final hasBalance = row.balanceDue > 0;
    final period = _periodLabel();

    return AppCard(
      accentColor: accent,
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
                      row.invoiceNumber,
                      style: AppType.number(15.5,
                          color: AppColors.textNavy(context)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.tenantName,
                      style: AppType.body(13,
                          color: AppColors.textPrimary(context),
                          weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: row.statusLabel, color: accent),
            ],
          ),
          const SizedBox(height: 10),
          _metaRow(
            context,
            icon: Icons.apartment_rounded,
            text: row.propertyLabel,
          ),
          if (period.isNotEmpty) ...[
            const SizedBox(height: 6),
            _metaRow(
              context,
              icon: Icons.calendar_month_rounded,
              text: period,
            ),
          ],
          if (row.dueDate != null) ...[
            const SizedBox(height: 6),
            _metaRow(
              context,
              icon: Icons.event_busy_rounded,
              text: 'Due ${formatDate(row.dueDate)}',
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border(context)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paid ${_money.format(row.amountPaid)}  ·  '
                      'Balance ${_money.format(row.balanceDue)}',
                      style: AppType.body(
                        12,
                        color: hasBalance ? kDanger : kMuted,
                        weight: hasBalance ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${row.currency} ${_money.format(row.amount)}',
                style: AppType.number(16, color: AppColors.textNavy(context)),
              ),
            ],
          ),
          if (_showRecordPayment) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRecordPayment,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: const Text('Record Payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: const BorderSide(color: kPrimary, width: 1.4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppType.body(13.5, weight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Whether the compact "Record Payment" action should be shown: the user has
  /// the permission, the invoice still has an outstanding balance, and it is
  /// not cancelled.
  bool get _showRecordPayment =>
      canRecordPayment && row.balanceDue > 0 && row.status != 'cancelled';

  String _periodLabel() {
    final s = row.periodStart, e = row.periodEnd;
    if (s == null && e == null) return '';
    return '${formatDate(s)} – ${formatDate(e)}';
  }

  Widget _metaRow(BuildContext context,
      {required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: kMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppType.body(12, color: kMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Record Payment bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

/// A scrollable, theme-aware bottom sheet that records a payment against a rent
/// invoice. Pops with `true` once the payment is saved so the caller can
/// refresh and confirm.
class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({
    required this.service,
    required this.row,
    required this.paymentMethods,
  });

  final ModReRentService service;
  final RentInvoiceRow row;
  final Map<String, dynamic> paymentMethods;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  String? _method;

  String? _pickedFilePath;
  String? _pickedFileName;
  String? _pickedMimeType;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default the amount to the outstanding balance.
    final bal = widget.row.balanceDue;
    _amountCtrl = TextEditingController(
      text: bal > 0 ? bal.toStringAsFixed(bal.truncateToDouble() == bal ? 0 : 2) : '',
    );
    // Default to the first available payment method, if any.
    if (widget.paymentMethods.isNotEmpty) {
      _method = widget.paymentMethods.keys.first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _paymentDateStr => DateFormat('yyyy-MM-dd').format(_paymentDate);

  /// Resolves a payment-method value's display label (value is `{label,color}`).
  String _methodLabel(String key, dynamic value) {
    if (value is Map && value['label'] != null) return value['label'].toString();
    if (value is String) return value;
    return key;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
      withReadStream: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path;
        _pickedFileName = result.files.single.name;
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        _pickedMimeType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
      });
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a payment method')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    setState(() => _saving = true);
    try {
      await widget.service.recordPayment(
        invoiceId: widget.row.id,
        amount: amount,
        paymentDate: _paymentDateStr,
        method: _method!,
        reference: _referenceCtrl.text,
        notes: _notesCtrl.text,
        receiptPath: _pickedFilePath,
        mimeType: _pickedFilePath != null ? _pickedMimeType : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kDanger),
        );
      }
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
    final methods = widget.paymentMethods.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Record Payment',
                style: AppType.display(19, color: AppColors.textNavy(context)),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.row.invoiceNumber} · ${widget.row.tenantName}',
                style: AppType.body(13, color: kMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: AppType.number(15, color: AppColors.textPrimary(context)),
                decoration: _fieldDecoration(
                  context,
                  label: 'Amount (${widget.row.currency})',
                  hint: '0',
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Enter an amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Payment date (date picker)
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: _fieldDecoration(
                    context,
                    label: 'Payment Date',
                  ).copyWith(
                    suffixIcon: const Icon(Icons.calendar_month_rounded,
                        size: 18, color: kMuted),
                  ),
                  child: Text(
                    _paymentDateStr,
                    style: AppType.number(
                        15, color: AppColors.textPrimary(context)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Payment method dropdown
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: _fieldDecoration(context, label: 'Payment Method'),
                style: AppType.body(14, color: AppColors.textPrimary(context)),
                dropdownColor: AppColors.surface(context),
                items: [
                  for (final e in methods)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(_methodLabel(e.key, e.value)),
                    ),
                ],
                onChanged:
                    _saving ? null : (v) => setState(() => _method = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select a method' : null,
              ),
              const SizedBox(height: 12),

              // Reference number (optional)
              TextFormField(
                controller: _referenceCtrl,
                textInputAction: TextInputAction.next,
                style: AppType.body(14, color: AppColors.textPrimary(context)),
                decoration: _fieldDecoration(
                  context,
                  label: 'Reference Number (optional)',
                  hint: 'e.g. txn / cheque no.',
                ),
              ),
              const SizedBox(height: 12),

              // Notes (optional)
              TextFormField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                style: AppType.body(14, color: AppColors.textPrimary(context)),
                decoration: _fieldDecoration(
                  context,
                  label: 'Notes (optional)',
                  hint: 'Any additional remarks...',
                ),
              ),
              const SizedBox(height: 16),

              // Optional receipt attachment
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: _pickedFilePath != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: kSuccess),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pickedFileName ?? 'File selected',
                                overflow: TextOverflow.ellipsis,
                                style: AppType.body(13, color: kMuted),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: kMuted),
                              onPressed: _saving
                                  ? null
                                  : () => setState(() {
                                        _pickedFilePath = null;
                                        _pickedFileName = null;
                                        _pickedMimeType = null;
                                      }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    : InkWell(
                        onTap: _saving ? null : _pickFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.upload_file_rounded,
                                  size: 20, color: kMuted),
                              const SizedBox(width: 8),
                              Text(
                                'Attach receipt',
                                style: AppType.body(14,
                                    color: kMuted, weight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppType.body(15, weight: FontWeight.w700),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Record Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppType.body(13, color: kMuted),
      hintText: hint,
      hintStyle: AppType.body(13.5, color: kMuted),
      filled: true,
      fillColor: AppColors.surfaceVariant(context),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
    );
  }
}