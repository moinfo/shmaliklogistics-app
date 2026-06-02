import 'package:flutter/material.dart';

import '../ui/typography.dart';
import '../ui/ui_kit.dart';
import '../utils/app_theme.dart';
import '../utils/colors.dart';

/// Generic destination for modules that exist on the web portal but do not yet
/// have a dedicated mobile screen. Keeps the full permitted menu navigable
/// without inventing one screen per module.
///
/// Styled with the "Operations Command" kit: a branded [AppGradientHeader] and
/// an [AppEmpty] body explaining where the module lives today.
class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? eyebrow;

  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          AppGradientHeader(
            eyebrow: eyebrow ?? 'Module',
            title: title,
            trailing: const SizedBox.shrink(),
          ),
          Expanded(
            child: RevealOnLoad(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  AppCard(
                    accentColor: kPrimary,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7A2800), Color(0xFFEA580C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: AppType.display(
                                          18, color: AppColors.textNavy(context))),
                                  const SizedBox(height: 4),
                                  StatusPill(
                                      label: 'COMING SOON', color: kWarning),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'This module is fully available on the Trans-Mas web '
                          'portal. A native mobile experience is on the way.',
                          style: AppType.body(14, color: kMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppEmpty(
                    icon: Icons.devices_rounded,
                    message:
                        'Open the web portal to manage $title.\nMobile support is coming soon.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
