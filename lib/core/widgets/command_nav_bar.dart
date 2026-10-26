import 'package:flutter/material.dart';

import '../ui/typography.dart';

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
/// It uses exactly the same orange brand gradient as the top header
/// ([AppGradientHeader]) and never reads the theme, so it looks identical in
/// light and dark mode. The active destination sits in a translucent white
/// pill; the others are softer white glyphs.
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

  /// Same colours and stops as the header gradient in `ui_kit.dart`.
  static const List<Color> _gradient = [
    Color(0xFF7A2800),
    Color(0xFFEA580C),
    Color(0xFF7A2800),
  ];
  static const List<double> _stops = [0.0, 0.6, 1.0];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _gradient,
          stops: _stops,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
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
    final soft = Colors.white.withValues(alpha: 0.72);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.white.withValues(alpha: 0.16),
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
                color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? Colors.white.withValues(alpha: 0.38) : Colors.transparent,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: selected ? Colors.white : soft,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppType.body(
                11.5,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : soft,
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
