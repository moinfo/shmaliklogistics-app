import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../expense_service.dart';
import '../models/expense.dart';
import 'expenses_screen.dart' show kExpenseAccent, expenseCategoryColor, formatExpenseAmount;

/// Read-only detail for a single recorded expense.
class ExpenseDetailScreen extends StatefulWidget {
  final int expenseId;
  final ExpenseService service;

  const ExpenseDetailScreen({
    super.key,
    required this.expenseId,
    required this.service,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late Future<Expense> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchExpense(widget.expenseId);
  }

  void _reload() => setState(() => _future = widget.service.fetchExpense(widget.expenseId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Expense>(
      future: _future,
      builder: (context, snapshot) {
        final expense = snapshot.data;
        return Scaffold(
          backgroundColor: AppColors.surfaceVariant(context),
          body: Column(
            children: [
              _buildHeader(expense),
              Expanded(child: _buildBody(snapshot)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Expense? expense) {
    return AppGradientHeader(
      eyebrow: 'Expense',
      title: expense?.categoryLabel ?? 'Expense',
      subtitle: expense == null
          ? null
          : formatExpenseAmount(expense.amount, expense.currency),
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

  Widget _buildBody(AsyncSnapshot<Expense> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return AppError(message: snapshot.error.toString(), onRetry: _reload);
    }

    final e = snapshot.data!;
    final color = expenseCategoryColor(e.category);

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnLoad(delayMs: 0, child: _buildOverviewCard(e, color)),
            const SizedBox(height: 14),
            RevealOnLoad(delayMs: 60, child: _buildDetailsCard(e)),
            if (e.tripDescription != null || e.vehiclePlate != null) ...[
              const SizedBox(height: 14),
              RevealOnLoad(delayMs: 120, child: _buildLinkedCard(e)),
            ],
            if (e.description != null && e.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 180,
                child: _SectionCard(
                  title: 'Description',
                  eyebrow: 'Detail',
                  icon: Icons.description_outlined,
                  children: [Text(e.description!, style: AppType.body(14, height: 1.5))],
                ),
              ),
            ],
            if (e.notes != null && e.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              RevealOnLoad(
                delayMs: 240,
                child: _SectionCard(
                  title: 'Notes',
                  eyebrow: 'Memo',
                  icon: Icons.notes_outlined,
                  children: [Text(e.notes!, style: AppType.body(14, height: 1.5))],
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
          AppSkeleton.box(context, height: 130, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 170, radius: 16),
          const SizedBox(height: 14),
          AppSkeleton.box(context, height: 110, radius: 16),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Expense e, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: e.categoryLabel,
            eyebrow: 'Category',
            icon: Icons.receipt_long_outlined,
            accent: kExpenseAccent,
            trailing: StatusPill(label: e.categoryLabel, color: color),
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Amount',
                  value: formatExpenseAmount(e.amount, e.currency),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Date',
                  value: formatDate(e.expenseDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Expense e) {
    return _SectionCard(
      title: 'Expense Details',
      eyebrow: 'Record',
      icon: Icons.fact_check_outlined,
      children: [
        _DetailRow(label: 'Category', value: e.categoryLabel),
        _DetailRow(label: 'Amount', value: formatExpenseAmount(e.amount, e.currency), isNumber: true),
        _DetailRow(label: 'Currency', value: e.currency),
        _DetailRow(label: 'Date', value: formatDate(e.expenseDate)),
        if (e.receiptNumber != null && e.receiptNumber!.isNotEmpty)
          _DetailRow(label: 'Receipt #', value: e.receiptNumber!),
      ],
    );
  }

  Widget _buildLinkedCard(Expense e) {
    return _SectionCard(
      title: 'Linked',
      eyebrow: 'Trip / Vehicle',
      icon: Icons.link_outlined,
      children: [
        if (e.tripNumber != null && e.tripNumber!.isNotEmpty)
          _DetailRow(label: 'Trip', value: e.tripNumber!),
        if (e.tripRoute != null && e.tripRoute!.isNotEmpty)
          _DetailRow(label: 'Route', value: e.tripRoute!),
        if (e.vehiclePlate != null && e.vehiclePlate!.isNotEmpty)
          _DetailRow(label: 'Vehicle', value: e.vehiclePlate!),
      ],
    );
  }
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

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
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: kExpenseAccent),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isNumber;
  const _DetailRow({required this.label, required this.value, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppType.body(13, color: kMuted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isNumber
                  ? AppType.number(13.5, color: AppColors.textPrimary(context))
                  : AppType.body(13.5, weight: FontWeight.w600, color: AppColors.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.body(10, color: kMuted, weight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: AppType.number(14, color: AppColors.textPrimary(context))),
      ],
    );
  }
}
