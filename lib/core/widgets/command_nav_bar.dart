import 'package:flutter/material.dart';

import '../ui/typography.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: kBarGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: kPrimary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.2) : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppType.body(
                11.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.65),
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
