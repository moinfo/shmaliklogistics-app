import 'package:flutter/material.dart';
import 'command_nav_bar.dart';

/// Shared 4-tab bottom navigation bar used on the driver flow screens.
/// Wraps the branded [CommandNavBar] so drivers get the same look as staff.
///
/// [currentIndex] — 0 Dashboard · 1 Trips · 2 Check In · 3 Inspection
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  static const _routes = ['/dashboard', '/trips', '/check_in', '/inspection'];

  static const _items = [
    CommandNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Dashboard'),
    CommandNavItem(icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt_rounded, label: 'Trips'),
    CommandNavItem(icon: Icons.add_location_outlined, selectedIcon: Icons.add_location_alt_rounded, label: 'Check In'),
    CommandNavItem(icon: Icons.checklist_outlined, selectedIcon: Icons.checklist_rounded, label: 'Inspection'),
  ];

  @override
  Widget build(BuildContext context) {
    return CommandNavBar(
      currentIndex: currentIndex,
      items: _items,
      onSelect: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, _routes[0], (r) => false);
        } else {
          Navigator.pushNamed(context, _routes[index]);
        }
      },
    );
  }
}
