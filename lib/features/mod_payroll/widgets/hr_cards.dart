import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/hr_profile.dart';
import '../models/salary_slip.dart';

/// Shared HR/payroll cards rendered on both the Employees and Drivers detail
/// screens. Returns the spaced, staggered cards for the [payroll] bundle —
/// allowances, the latest payslip breakdown and open advances/loans — skipping
/// any section that has no data (so permission-gated empties just disappear).
List<Widget> hrPayrollCards(
  BuildContext context,
  HrPayroll payroll, {
  String? currency,
  int startDelayMs = 200,
}) {
  final cards = <Widget>[];
  var delay = startDelayMs;

  void add(Widget card) {
    cards.add(const SizedBox(height: 14));
    cards.add(RevealOnLoad(delayMs: delay.clamp(0, 300), child: card));
    delay += 30;
  }

  if (payroll.allowances.isNotEmpty) {
    add(HrAllowancesCard(
      allowances: payroll.allowances,
      total: payroll.allowancesTotal,
      currency: currency,
    ));
  }
  final bonus = payroll.bonus;
  if (bonus != null && bonus.hasContent) {
    add(HrBonusCard(bonus: bonus, currency: currency));
  }
  final slip = payroll.latestSlip;
  if (slip != null) add(HrPayslipCard(slip: slip, currency: currency));
  if (payroll.hasLiabilities) {
    add(HrLiabilitiesCard(advances: payroll.advances, loans: payroll.loans));
  }

  return cards;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────────

class HrAllowancesCard extends StatelessWidget {
  final List<HrAllowance> allowances;
  final double total;
  final String? currency;
  const HrAllowancesCard(
      {super.key, required this.allowances, required this.total, this.currency});

  @override
  Widget build(BuildContext context) {
    return _HrSectionCard(
      title: 'Allowances',
      eyebrow: 'Package',
      icon: Icons.add_card_outlined,
      children: [
        for (final a in allowances)
          HrAmountRow(
            label: a.isTaxable ? '${a.name}  (taxable)' : a.name,
            value: hrFormatMoney(a.amount, currency),
          ),
        const Divider(height: 18),
        HrAmountRow(
          label: 'Total allowances',
          value: hrFormatMoney(total, currency),
          strong: true,
        ),
      ],
    );
  }
}

class HrBonusCard extends StatelessWidget {
  final HrBonus bonus;
  final String? currency;
  const HrBonusCard({super.key, required this.bonus, this.currency});

  @override
  Widget build(BuildContext context) {
    final hasPenalty = bonus.penaltiesTotal > 0;
    final netColor = bonus.netBonus > 0 ? kSuccess : kMuted;
    return _HrSectionCard(
      title: 'Performance Bonus',
      eyebrow: bonus.department ?? 'Bonus',
      icon: Icons.military_tech_outlined,
      children: [
        if (bonus.policyAmount != null)
          HrAmountRow(label: 'Dept. policy', value: hrFormatMoney(bonus.policyAmount!, currency)),
        if (bonus.standingBonus != null)
          HrAmountRow(label: 'Your bonus', value: hrFormatMoney(bonus.standingBonus!, currency)),
        HrAmountRow(label: 'Eligible bonus', value: hrFormatMoney(bonus.effectiveBonus, currency), strong: true),
        if (hasPenalty)
          HrAmountRow(
            label: 'Infraction penalties',
            value: '− ${hrFormatMoney(bonus.penaltiesTotal, currency)}',
            color: kDanger,
          ),
        const SizedBox(height: 10),
        HrHeroAmount(label: 'Net bonus', amount: hrFormatMoney(bonus.netBonus, currency), color: netColor),
        if (bonus.infractions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Infractions (${bonus.infractions.length})',
              style: AppType.body(12.5, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final inf in bonus.infractions) _InfractionRow(infraction: inf, currency: currency),
        ],
      ],
    );
  }
}

class _InfractionRow extends StatelessWidget {
  final HrInfraction infraction;
  final String? currency;
  const _InfractionRow({required this.infraction, this.currency});

  @override
  Widget build(BuildContext context) {
    final i = infraction;
    final struck = i.waived;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.ruleName ?? 'Infraction',
                    style: AppType.body(13,
                        weight: FontWeight.w700, color: AppColors.textPrimary(context))),
                Row(
                  children: [
                    Text(
                      '− ${hrFormatMoney(i.amount, currency)}',
                      style: AppType.number(12.5,
                          color: struck ? kMuted : kDanger).copyWith(
                          decoration: struck ? TextDecoration.lineThrough : null),
                    ),
                    if (i.occurredOn != null) ...[
                      const SizedBox(width: 8),
                      Text(formatDate(i.occurredOn), style: AppType.body(11, color: kMuted)),
                    ],
                  ],
                ),
                if (i.notes != null && i.notes!.isNotEmpty)
                  Text(i.notes!, style: AppType.body(11, color: kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: i.statusLabel, color: i.statusColor),
        ],
      ),
    );
  }
}

class HrPayslipCard extends StatelessWidget {
  final SalarySlip slip;
  final String? currency;
  const HrPayslipCard({super.key, required this.slip, this.currency});

  @override
  Widget build(BuildContext context) {
    String m(double v) => hrFormatMoney(v, currency);
    return _HrSectionCard(
      title: 'Latest Payslip',
      eyebrow: slip.periodLabel ?? 'Payroll',
      icon: Icons.receipt_long_outlined,
      children: [
        _subheading('Earnings'),
        HrAmountRow(label: 'Basic salary', value: m(slip.basicSalary)),
        if (slip.allowances > 0) HrAmountRow(label: 'Allowances', value: m(slip.allowances)),
        if (slip.overtime > 0) HrAmountRow(label: 'Overtime', value: m(slip.overtime)),
        if (slip.netBonus > 0) HrAmountRow(label: 'Bonus', value: m(slip.netBonus)),
        if (slip.adjustment != 0) HrAmountRow(label: 'Adjustment', value: m(slip.adjustment)),
        const Divider(height: 18),
        HrAmountRow(label: 'Gross pay', value: m(slip.grossSalary), strong: true),
        const SizedBox(height: 12),
        _subheading('Deductions'),
        if (slip.paye > 0) HrAmountRow(label: 'PAYE', value: m(slip.paye)),
        if (slip.nssfEmployee > 0) HrAmountRow(label: 'NSSF', value: m(slip.nssfEmployee)),
        if (slip.nhifEmployee > 0) HrAmountRow(label: 'NHIF', value: m(slip.nhifEmployee)),
        if (slip.heslb > 0) HrAmountRow(label: 'HESLB', value: m(slip.heslb)),
        if (slip.advanceDeduction > 0)
          HrAmountRow(label: 'Advance recovery', value: m(slip.advanceDeduction)),
        if (slip.loanDeduction > 0)
          HrAmountRow(label: 'Loan repayment', value: m(slip.loanDeduction)),
        if (slip.otherDeductions > 0) HrAmountRow(label: 'Other', value: m(slip.otherDeductions)),
        const Divider(height: 18),
        HrAmountRow(
          label: 'Total deductions',
          value: '− ${m(slip.totalDeductions)}',
          strong: true,
          color: kDanger,
        ),
        const SizedBox(height: 12),
        HrHeroAmount(label: 'Net pay', amount: m(slip.netSalary), color: kSuccess),
      ],
    );
  }

  Widget _subheading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: AppType.body(12.5, color: kMuted, weight: FontWeight.w700)),
      );
}

class HrLiabilitiesCard extends StatelessWidget {
  final List<HrAdvance> advances;
  final List<HrLoan> loans;
  const HrLiabilitiesCard({super.key, required this.advances, required this.loans});

  @override
  Widget build(BuildContext context) {
    return _HrSectionCard(
      title: 'Advances & Loans',
      eyebrow: 'Liabilities',
      icon: Icons.account_balance_outlined,
      children: [
        if (advances.isNotEmpty) ...[
          Text('Advances', style: AppType.body(12.5, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final a in advances) _AdvanceRow(advance: a),
        ],
        if (advances.isNotEmpty && loans.isNotEmpty) const Divider(height: 22),
        if (loans.isNotEmpty) ...[
          Text('Loans', style: AppType.body(12.5, color: kMuted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final l in loans) _LoanRow(loan: l),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rows
// ─────────────────────────────────────────────────────────────────────────────

class _AdvanceRow extends StatelessWidget {
  final HrAdvance advance;
  const _AdvanceRow({required this.advance});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hrFormatMoney(advance.amount),
                    style: AppType.number(14.5, color: AppColors.textNavy(context))),
                if (advance.purpose != null && advance.purpose!.isNotEmpty)
                  Text(advance.purpose!, style: AppType.body(11.5, color: kMuted)),
                Text(formatDate(advance.requestedDate),
                    style: AppType.body(11, color: kMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(label: advance.statusLabel, color: advance.statusColor),
        ],
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  final HrLoan loan;
  const _LoanRow({required this.loan});

  @override
  Widget build(BuildContext context) {
    final paid = loan.monthsPaid;
    final total = loan.totalMonths;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(loan.loanNumber ?? 'Loan #${loan.id}',
                    style: AppType.body(13,
                        weight: FontWeight.w700, color: AppColors.textPrimary(context))),
              ),
              StatusPill(label: loan.statusLabel, color: loan.statusColor),
            ],
          ),
          const SizedBox(height: 6),
          HrAmountRow(label: 'Balance', value: hrFormatMoney(loan.balanceRemaining), strong: true),
          HrAmountRow(label: 'of principal', value: hrFormatMoney(loan.principal)),
          if (loan.monthlyInstallment > 0)
            HrAmountRow(label: 'Monthly', value: hrFormatMoney(loan.monthlyInstallment)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: loan.progress,
              minHeight: 6,
              backgroundColor: kMuted.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(loan.statusColor),
            ),
          ),
          if (paid != null && total != null) ...[
            const SizedBox(height: 4),
            Text('$paid of $total months paid', style: AppType.body(11, color: kMuted)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared building blocks (exported for the detail screens' own HR cards)
// ─────────────────────────────────────────────────────────────────────────────

/// A label + right-aligned money value row used across the HR cards.
class HrAmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;
  const HrAmountRow(
      {super.key, required this.label, required this.value, this.strong = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppType.body(13,
                    color: strong ? AppColors.textPrimary(context) : kMuted,
                    weight: strong ? FontWeight.w700 : FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: AppType.number(strong ? 14.5 : 13.5,
                  color: color ?? AppColors.textNavy(context))),
        ],
      ),
    );
  }
}

/// A prominent money figure (salary, net pay) on a tinted strip.
class HrHeroAmount extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  const HrHeroAmount({super.key, required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: AppType.eyebrow(size: 10.5, color: color))),
          const SizedBox(width: 8),
          Text(amount, style: AppType.number(18, color: color)),
        ],
      ),
    );
  }
}

class _HrSectionCard extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final IconData icon;
  final List<Widget> children;
  const _HrSectionCard(
      {required this.title, this.eyebrow, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.brand),
          ...children,
        ],
      ),
    );
  }
}
