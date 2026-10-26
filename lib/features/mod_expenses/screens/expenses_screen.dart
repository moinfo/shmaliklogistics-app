import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../expense_service.dart';
import '../models/expense.dart';
import 'expense_detail_screen.dart';

/// Accent used across the expenses feature (finance).
const ModuleAccent kExpenseAccent = ModuleAccent.finance;

/// Maps an expense category to a display colour.
Color expenseCategoryColor(String category) {
  switch (category) {
    case 'fuel':          return const Color(0xFFF59E0B);
    case 'tyre':          return const Color(0xFFEA580C);
    case 'repair':        return const Color(0xFFEF4444);
    case 'driver_salary': return const Color(0xFF10B981);
    case 'accommodation': return const Color(0xFFC2410C);
    case 'toll':          return const Color(0xFF0EA5E9);
    case 'port':          return const Color(0xFF14B8A6);
    case 'permit_fee':    return const Color(0xFFEC4899);
    case 'communication': return const Color(0xFF3B82F6);
    case 'office':        return const Color(0xFF64748B);
    default:              return kMuted;
  }
}

/// Formats an expense amount with its currency code (TZS/USD/…).
String formatExpenseAmount(double amount, String currency) {
  final whole = amount.round();
  final s = whole.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$currency ${whole < 0 ? '-' : ''}$buf';
}

/// Module #4 — Expenses. A searchable list of recorded expenses with a running
/// total header and tap-through to a read-only detail screen.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final ExpenseService _service;
  late Future<List<Expense>> _future;

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service = ExpenseService(widget.apiClient);
    _future = _service.fetchExpenses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.fetchExpenses());

  List<Expense> _filter(List<Expense> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((e) {
      return e.categoryLabel.toLowerCase().contains(q) ||
          (e.description ?? '').toLowerCase().contains(q) ||
          (e.vehiclePlate ?? '').toLowerCase().contains(q) ||
          (e.receiptNumber ?? '').toLowerCase().contains(q) ||
          (e.tripDescription ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: 'Spending',
            title: 'Expenses',
            subtitle: 'Recorded operating costs',
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
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search category, plate, receipt, trip…',
          hintStyle: AppType.body(13, color: kMuted),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kExpenseAccent.base, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Expense>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return AppError(message: snapshot.error.toString(), onRetry: _reload);
        }
        final expenses = _filter(snapshot.data ?? []);
        return RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => _reload(),
          child: expenses.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: AppEmpty(
                        icon: Icons.receipt_long_outlined,
                        message: _query.isEmpty
                            ? 'No expenses\nRecorded expenses will appear here.'
                            : 'No matches\nTry a different search term.',
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: expenses.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return RevealOnLoad(
                        delayMs: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TotalHeader(expenses: expenses),
                        ),
                      );
                    }
                    final expense = expenses[i - 1];
                    return RevealOnLoad(
                      delayMs: (i * 60).clamp(0, 300),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ExpenseCard(
                          expense: expense,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExpenseDetailScreen(
                                  expenseId: expense.id,
                                  service: _service,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppSkeleton.box(context, height: 72, radius: 16),
          const SizedBox(height: 12),
          for (var i = 0; i < 6; i++) ...[
            AppSkeleton.box(context, height: 116, radius: 16),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Running total of the visible expenses, grouped by currency.
class _TotalHeader extends StatelessWidget {
  final List<Expense> expenses;
  const _TotalHeader({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final byCurrency = <String, double>{};
    for (final e in expenses) {
      byCurrency[e.currency] = (byCurrency[e.currency] ?? 0) + e.amount;
    }
    final entries = byCurrency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      accentColor: kExpenseAccent.base,
      child: Row(
        children: [
          Icon(Icons.summarize_outlined, size: 18, color: kExpenseAccent.base),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'}',
                  style: AppType.body(11, color: kMuted, weight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  entries.isEmpty
                      ? '—'
                      : entries
                          .map((e) => formatExpenseAmount(e.value, e.key))
                          .join('  •  '),
                  style: AppType.number(15, color: AppColors.textNavy(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = expenseCategoryColor(expense.category);
    final title = (expense.description != null && expense.description!.isNotEmpty)
        ? expense.description!
        : expense.categoryLabel;
    return AppCard(
      accentColor: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppType.display(15, color: AppColors.textNavy(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: expense.categoryLabel, color: color),
            ],
          ),
          if (expense.tripDescription != null || expense.vehiclePlate != null) ...[
            const SizedBox(height: 4),
            Text(
              expense.tripDescription ?? expense.vehiclePlate!,
              style: AppType.body(12, color: kMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: kMuted),
              const SizedBox(width: 4),
              Text(
                formatExpenseAmount(expense.amount, expense.currency),
                style: AppType.number(14, color: AppColors.textPrimary(context)),
              ),
              const Spacer(),
              const Icon(Icons.event_outlined, size: 12, color: kMuted),
              const SizedBox(width: 4),
              Text(formatDate(expense.expenseDate), style: AppType.body(11, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
