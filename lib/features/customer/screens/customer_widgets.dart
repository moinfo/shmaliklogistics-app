import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';

/// Gradient navy detail header used by the customer detail screens.
///
/// Mirrors the shared [AppGradientHeader] chrome (curved navy→blue gradient,
/// white w800 title, frosted [HeaderIconButton] actions) while adding a leading
/// back button and an optional status [subtitle] — neither of which the kit
/// header exposes a slot for.
class CustomerDetailHeader extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final VoidCallback? onRefresh;

  const CustomerDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: ModuleAccent.brand.colors,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: ModuleAccent.brand.colors.last.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 12, 22),
          child: Row(
            children: [
              HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 2,
                            margin: const EdgeInsets.only(right: 8),
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          Text('Customer Portal',
                              style: AppType.eyebrow(
                                  color: Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Text(
                      title,
                      style: AppType.display(23, color: Colors.white),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 8),
                HeaderIconButton(icon: Icons.refresh_rounded, onTap: onRefresh!, tooltip: 'Refresh'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card section with a coloured title + icon, built on the shared [AppCard]
/// and [SectionHeader] so detail sections match the kit.
class CustomerSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? eyebrow;

  const CustomerSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: title, eyebrow: eyebrow, icon: icon, accent: ModuleAccent.brand),
          ...children,
        ],
      ),
    );
  }
}

/// Label/value row used inside section cards.
class CustomerInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isHighlight;
  final Color? valueColor;

  const CustomerInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.isHighlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppType.body(
              13,
              color: isBold ? AppColors.textPrimary(context) : kMuted,
              weight: isBold ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppType.body(
                13,
                weight: isBold || isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? (isHighlight ? kPrimary : AppColors.textPrimary(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill status badge — delegates to the shared [StatusPill]. The [small] flag
/// is retained for source compatibility; the kit pill already sizes compactly.
class CustomerStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const CustomerStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: label, color: color);
  }
}

/// Standard centered error block with a retry action — delegates to [AppError].
class CustomerErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CustomerErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppError(message: message, onRetry: onRetry);
  }
}

/// Empty-state placeholder — delegates to [AppEmpty]. The [title]/[subtitle]
/// pair is composed into the kit's single message line.
class CustomerEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CustomerEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmpty(icon: icon, message: '$title\n$subtitle');
  }
}
