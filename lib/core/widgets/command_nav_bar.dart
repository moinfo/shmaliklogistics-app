import 'dart:ui';

import 'package:flutter/material.dart';

import '../ui/typography.dart';
import '../ui/ui_kit.dart';
import '../utils/app_theme.dart';
import '../utils/colors.dart';

/// One destination in the [CommandNavBar].
class CommandNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const CommandNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// The app's custom bottom navigation — the "Operations Command" bar.
///
/// The active destination sits in a navy→blue gradient pill (the same brand
/// gradient as [AppGradientHeader]) with a white glyph and a soft glow; the
/// others are muted outline glyphs. Selection animates the pill and the label
/// weight/colour rather than swapping widgets, so switching tabs feels fluid.
class CommandNavBar extends StatelessWidget {
  final int currentIndex;
  final List<CommandNavItem> items;
  final ValueChanged<int> onSelect;

  const CommandNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onSelect,
  });

  /// Brand gradient, shared with the command header.
  static const List<Color> _gradient = [Color(0xFF7A2800), Color(0xFFEA580C)];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Tahoe-style frosted bar — content slides under it and gets blurred.
    // Manually composed (rather than wrapped in LiquidGlass) so the highlight
    // line lives on the TOP edge only and the soft drop shadow points UPWARD.
    final tintColor = isDark ? GlassTokens.tintDark : GlassTokens.tintLight;
    final highlight = Colors.white.withValues(
      alpha: isDark ? GlassTokens.highlightDarkAlpha : GlassTokens.highlightLightAlpha,
    );
    final topA = isDark ? GlassTokens.tintDarkTopAlpha : GlassTokens.tintLightTopAlpha;
    final botA = isDark ? GlassTokens.tintDarkBotAlpha : GlassTokens.tintLightBotAlpha;

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.blurSigmaBar,
            sigmaY: GlassTokens.blurSigmaBar,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tintColor.withValues(alpha: topA),
                  tintColor.withValues(alpha: botA),
                ],
              ),
              border: Border(top: BorderSide(color: highlight, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItem(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final CommandNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selectedLabel = AppColors.textNavy(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: kPrimary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: CommandNavBar._gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.34),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: selected ? Colors.white : kMuted,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppType.body(
                11.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedLabel : kMuted,
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
