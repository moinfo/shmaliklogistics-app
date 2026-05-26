import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/app_session.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/property_expense.dart';
import '../mod_re_expenses_service.dart';

/// "Property Expenses" — a read-only, searchable list of real-estate expenses
/// (matumizi · ukarabati). Wired into the app drawer via [RealEstateExpensesScreen].
///
/// LIST-ONLY: no tap-through detail.
class RealEstateExpensesScreen extends StatefulWidget {
  const RealEstateExpensesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<RealEstateExpensesScreen> createState() =>
      _RealEstateExpensesScreenState();
}

class _RealEstateExpensesScreenState extends State<RealEstateExpensesScreen> {
  late final ModReExpensesService _service;
  late Future<ExpensesPayload> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _categoryFilter; // null == all

  /// Latest payload, captured so the "Add Expense" form can read the available
  /// properties / phases / categories without re-fetching.
  ExpensesPayload? _payload;

  bool get _canCreate =>
      AppSession.instance.can('realestate_expenses.create');

  @override
  void initState() {
    super.initState();
    _service = ModReExpensesService(widget.apiClient);
    _future = _service.fetchExpenses();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchExpenses());

  Future<void> _openAddExpenseSheet() async {
    final payload = _payload;
    if (payload == null) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(
        service: _service,
        properties: payload.properties,
        categories: payload.categories,
        phases: payload.phases,
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded'), backgroundColor: kSuccess),
      );
      _reload();
    }
  }

  List<PropertyExpenseRow> _applyFilters(List<PropertyExpenseRow> rows) {
    return rows.where((e) {
      if (_categoryFilter != null && e.category != _categoryFilter) return false;
      if (_query.isEmpty) return true;
      final hay = [
        e.description ?? '',
        e.categoryLabel ?? '',
        e.propertyLabel ?? '',
        e.unitLabel ?? '',
        e.vendor ?? '',
        e.receiptNumber ?? '',
        e.phaseLabel ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _payload == null ? null : _openAddExpenseSheet,
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Expense',
                style: AppType.body(14, weight: FontWeight.w700,
                    color: Colors.white),
              ),
            )
          : null,
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Real Estate',
            title: 'Property Expenses',
            subtitle: 'Matumizi · ukarabati',
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
            child: FutureBuilder<ExpensesPayload>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _skeleton();
                }
                if (snapshot.hasError) {
                  return AppError(
                      message: snapshot.error.toString(), onRetry: _reload);
                }
                final payload = snapshot.data;
                if (payload != null && !identical(payload, _payload)) {
                  // Capture the latest payload after this frame so the FAB can
                  // open the add-expense form with up-to-date options.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !identical(payload, _payload)) {
                      setState(() => _payload = payload);
                    }
                  });
                }
                final all = payload?.rows ?? const <PropertyExpenseRow>[];
                final stats = payload?.stats ??
                    ExpenseStats(totalTzs: 0, thisMonthTzs: 0, renovationTzs: 0);
                final categories = payload?.categories ?? const {};
                final filtered = _applyFilters(all);

                return RefreshIndicator(
                  color: kPrimary,
                  onRefresh: () async => _reload(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _statsRow(stats)),
                      SliverToBoxAdapter(child: _searchBar()),
                      SliverToBoxAdapter(child: _categoryChips(categories)),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: AppEmpty(
                            icon: Icons.receipt_long_outlined,
                            message: all.isEmpty
                                ? 'No expenses recorded yet.'
                                : 'No expenses match your search.',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          sliver: SliverList.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => RevealOnLoad(
                              delayMs: (i * 60).clamp(0, 300),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ExpenseCard(row: filtered[i]),
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

  // ── Stats row ───────────────────────────────────────────────────────────────

  Widget _statsRow(ExpenseStats stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total',
              value: formatCurrency(stats.totalTzs),
              icon: Icons.summarize_rounded,
              accent: ModuleAccent.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'This Month',
              value: formatCurrency(stats.thisMonthTzs),
              icon: Icons.calendar_month_rounded,
              accent: ModuleAccent.ops,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              label: 'Renovation',
              value: formatCurrency(stats.renovationTzs),
              icon: Icons.handyman_rounded,
              accent: ModuleAccent.danger,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search field ──────────────────────────────────────────────────────────

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        style: AppType.body(14, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: 'Search description, property, vendor…',
          hintStyle: AppType.body(13.5, color: kMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kMuted),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon:
                      const Icon(Icons.close_rounded, size: 18, color: kMuted),
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

  // ── Category filter chips (from the API `categories` map) ───────────────────

  Widget _categoryChips(Map<String, dynamic> categories) {
    if (categories.isEmpty) return const SizedBox.shrink();

    final entries = categories.entries.toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
        children: [
          _chip('All', _categoryFilter == null,
              () => setState(() => _categoryFilter = null)),
          for (final e in entries)
            _chip(
              _labelFor(e.value, e.key),
              _categoryFilter == e.key,
              () => setState(() => _categoryFilter = e.key),
            ),
        ],
      ),
    );
  }

  String _labelFor(dynamic meta, String key) {
    if (meta is Map && meta['label'] != null) return meta['label'].toString();
    return key;
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
              Expanded(child: AppSkeleton.box(context, height: 116, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 116, radius: 20)),
              const SizedBox(width: 12),
              Expanded(child: AppSkeleton.box(context, height: 116, radius: 20)),
            ],
          ),
          const SizedBox(height: 16),
          AppSkeleton.box(context, height: 48, radius: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 104, radius: 18),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense list card
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final PropertyExpenseRow row;
  const _ExpenseCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final location = [
      row.propertyLabel,
      row.unitLabel,
    ].where((s) => s != null && s.isNotEmpty).cast<String>().join(' · ');

    return AppCard(
      accentColor: kDanger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _categoryBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (row.categoryLabel != null &&
                        row.categoryLabel!.isNotEmpty)
                      Text(
                        row.categoryLabel!,
                        style: AppType.body(11.5,
                            color: kMuted, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (row.description != null &&
                        row.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.description!,
                        style: AppType.body(14.5,
                            color: AppColors.textNavy(context),
                            weight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(row.amountTzs),
                    style: AppType.number(15.5, color: kDanger),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (row.expenseDate != null) ...[
                    const SizedBox(height: 3),
                    Text(formatDate(row.expenseDate),
                        style: AppType.body(11.5, color: kMuted)),
                  ],
                ],
              ),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 13, color: kMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(location,
                      style: AppType.body(12, color: kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if ((row.vendor != null && row.vendor!.isNotEmpty) ||
              (row.phaseLabel != null && row.phaseLabel!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (row.vendor != null && row.vendor!.isNotEmpty) ...[
                  const Icon(Icons.store_outlined, size: 13, color: kMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(row.vendor!,
                        style: AppType.body(12, color: kMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
                const Spacer(),
                if (row.phaseLabel != null && row.phaseLabel!.isNotEmpty)
                  StatusPill(label: row.phaseLabel!, color: kWarning),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Leading badge: render the API-supplied emoji [categoryIcon] as text,
  /// falling back to a Material icon when none is provided.
  Widget _categoryBadge() {
    final emoji = row.categoryIcon;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: kDanger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: (emoji != null && emoji.trim().isNotEmpty)
          ? Text(emoji, style: const TextStyle(fontSize: 18))
          : const Icon(Icons.receipt_long_rounded, size: 21, color: kDanger),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Expense bottom-sheet form
// ─────────────────────────────────────────────────────────────────────────────

const _kCurrencies = ['TZS', 'USD', 'KES', 'ZMW', 'MWK', 'MZN'];

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({
    required this.service,
    required this.properties,
    required this.categories,
    required this.phases,
  });

  final ModReExpensesService service;
  final List<PropertyOption> properties;
  final Map<String, dynamic> categories;
  final Map<String, dynamic> phases;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _unitCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _receiptNoCtrl = TextEditingController();

  int? _propertyId;
  late String _category;
  String _currency = 'TZS';
  String? _phase; // null == none
  DateTime _expenseDate = DateTime.now();

  String? _filePath;
  String? _fileName;
  String? _mimeType;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Default category 'renovation' when present, else first available key.
    final keys = widget.categories.keys.toList();
    _category = keys.contains('renovation')
        ? 'renovation'
        : (keys.isNotEmpty ? keys.first : 'renovation');
    if (widget.properties.length == 1) {
      _propertyId = widget.properties.first.id;
    }
  }

  @override
  void dispose() {
    _unitCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _vendorCtrl.dispose();
    _receiptNoCtrl.dispose();
    super.dispose();
  }

  String _labelFor(dynamic meta, String key) {
    if (meta is Map && meta['label'] != null) return meta['label'].toString();
    return key;
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expenseDate = picked);
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
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        final ext = result.files.single.extension?.toLowerCase() ?? '';
        _mimeType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
      });
    }
  }

  void _snack(String msg, {Color color = kDanger}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _submit() async {
    // Client-side validation of required fields.
    if (_propertyId == null) {
      _snack('Please select a property.');
      return;
    }
    final description = _descCtrl.text.trim();
    if (description.isEmpty) {
      _snack('Please enter a description.');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount.');
      return;
    }
    double? exchangeRate;
    if (_currency != 'TZS') {
      final raw = _rateCtrl.text.trim();
      if (raw.isNotEmpty) {
        exchangeRate = double.tryParse(raw);
        if (exchangeRate == null) {
          _snack('Please enter a valid exchange rate.');
          return;
        }
      }
    }
    final unitId = _unitCtrl.text.trim().isEmpty
        ? null
        : int.tryParse(_unitCtrl.text.trim());

    setState(() => _saving = true);
    try {
      await widget.service.addExpense(
        propertyId: _propertyId!,
        unitId: unitId,
        category: _category,
        description: description,
        amount: amount,
        currency: _currency,
        exchangeRate: exchangeRate,
        expenseDate: _fmtDate(_expenseDate),
        phase: _phase,
        vendor: _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim(),
        receiptNumber:
            _receiptNoCtrl.text.trim().isEmpty ? null : _receiptNoCtrl.text.trim(),
        receiptPath: _filePath,
        mimeType: _mimeType,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 18),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Add Expense',
                style: AppType.display(19, color: AppColors.textNavy(context))),
            const SizedBox(height: 4),
            Text('Record a property expense',
                style: AppType.body(13, color: kMuted)),
            const SizedBox(height: 20),

            // Property
            _fieldLabel('Property'),
            DropdownButtonFormField<int>(
              initialValue: _propertyId,
              isExpanded: true,
              decoration: _dec(context, 'Select property'),
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              dropdownColor: AppColors.surface(context),
              items: [
                for (final p in widget.properties)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _propertyId = v),
            ),
            const SizedBox(height: 14),

            // Unit ID (optional)
            _fieldLabel('Unit ID (optional)'),
            TextField(
              controller: _unitCtrl,
              keyboardType: TextInputType.number,
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              decoration: _dec(context, 'e.g. 12'),
            ),
            const SizedBox(height: 14),

            // Category
            _fieldLabel('Category'),
            DropdownButtonFormField<String>(
              initialValue: widget.categories.containsKey(_category)
                  ? _category
                  : null,
              isExpanded: true,
              decoration: _dec(context, 'Select category'),
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              dropdownColor: AppColors.surface(context),
              items: [
                for (final e in widget.categories.entries)
                  DropdownMenuItem(
                    value: e.key,
                    child: Text(_labelFor(e.value, e.key)),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),

            // Description
            _fieldLabel('Description'),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              decoration: _dec(context, 'What was this expense for?'),
            ),
            const SizedBox(height: 14),

            // Amount + Currency
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Amount'),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: AppType.body(14,
                            color: AppColors.textPrimary(context)),
                        decoration: _dec(context, '0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Currency'),
                      DropdownButtonFormField<String>(
                        initialValue: _currency,
                        isExpanded: true,
                        decoration: _dec(context, ''),
                        style: AppType.body(14,
                            color: AppColors.textPrimary(context)),
                        dropdownColor: AppColors.surface(context),
                        items: [
                          for (final c in _kCurrencies)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) =>
                            setState(() => _currency = v ?? _currency),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Exchange rate (only when currency != TZS)
            if (_currency != 'TZS') ...[
              const SizedBox(height: 14),
              _fieldLabel('Exchange rate (to TZS)'),
              TextField(
                controller: _rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: AppType.body(14, color: AppColors.textPrimary(context)),
                decoration: _dec(context, 'e.g. 2600'),
              ),
            ],
            const SizedBox(height: 14),

            // Expense date
            _fieldLabel('Expense date'),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: _dec(context, ''),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: kMuted),
                    const SizedBox(width: 10),
                    Text(_fmtDate(_expenseDate),
                        style: AppType.body(14,
                            color: AppColors.textPrimary(context))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Phase (optional)
            if (widget.phases.isNotEmpty) ...[
              _fieldLabel('Phase (optional)'),
              DropdownButtonFormField<String?>(
                initialValue: _phase,
                isExpanded: true,
                decoration: _dec(context, 'None'),
                style: AppType.body(14, color: AppColors.textPrimary(context)),
                dropdownColor: AppColors.surface(context),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('—')),
                  for (final e in widget.phases.entries)
                    DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(_labelFor(e.value, e.key)),
                    ),
                ],
                onChanged: (v) => setState(() => _phase = v),
              ),
              const SizedBox(height: 14),
            ],

            // Vendor + Receipt #
            _fieldLabel('Vendor (optional)'),
            TextField(
              controller: _vendorCtrl,
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              decoration: _dec(context, 'Supplier / contractor'),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Receipt # (optional)'),
            TextField(
              controller: _receiptNoCtrl,
              style: AppType.body(14, color: AppColors.textPrimary(context)),
              decoration: _dec(context, 'Receipt number'),
            ),
            const SizedBox(height: 14),

            // Receipt file
            _fieldLabel('Receipt file (optional)'),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _saving ? null : _pickFile,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileName == null
                          ? Icons.attach_file_rounded
                          : Icons.insert_drive_file_rounded,
                      size: 18,
                      color: _fileName == null ? kMuted : kPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Attach PDF / image',
                        style: AppType.body(13.5,
                            color: _fileName == null
                                ? kMuted
                                : AppColors.textPrimary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_fileName != null)
                      GestureDetector(
                        onTap: () => setState(() {
                          _filePath = null;
                          _fileName = null;
                          _mimeType = null;
                        }),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: kMuted),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kPrimary.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text('Save Expense',
                        style: AppType.body(15,
                            weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppType.body(12.5,
                weight: FontWeight.w700, color: kMuted)),
      );

  InputDecoration _dec(BuildContext context, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppType.body(13.5, color: kMuted),
        filled: true,
        fillColor: AppColors.surfaceVariant(context),
        isDense: true,
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
      );
}