import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/colors.dart';

/// The public pages reachable from the landing menu.
enum SitePage { services, about, contact }

/// Native (offline-safe) version of the website's Services / About / Contact
/// pages. The landing menu opens these instead of the remote site so a menu
/// link never lands on a "web page not available" error.
class SiteInfoScreen extends StatelessWidget {
  final SitePage page;
  const SiteInfoScreen({super.key, required this.page});

  static const String website = 'shmaliklogistics.co.tz';

  /// Maps a site URL path (`/about`, `/services/`) to a native page, or null.
  static SitePage? pageForPath(String path) {
    switch (path.replaceAll(RegExp(r'/+$'), '')) {
      case '/services':
        return SitePage.services;
      case '/about':
        return SitePage.about;
      case '/contact':
        return SitePage.contact;
    }
    return null;
  }

  String get _title => switch (page) {
        SitePage.services => 'Our Services',
        SitePage.about => 'About Us',
        SitePage.contact => 'Contact Us',
      };

  IconData get _icon => switch (page) {
        SitePage.services => Icons.local_shipping_rounded,
        SitePage.about => Icons.info_outline_rounded,
        SitePage.contact => Icons.mail_outline_rounded,
      };

  List<(IconData, String, String)> get _items => switch (page) {
        SitePage.services => const [
            (Icons.route_rounded, 'Freight & Trip Management',
                'Road freight with every trip planned, dispatched and tracked from loading to delivery.'),
            (Icons.inventory_2_rounded, 'Cargo Handling',
                'Cargo is recorded, tracked and updated so customers always know where their goods are.'),
            (Icons.directions_car_rounded, 'Fleet Operations',
                'Vehicles, drivers, permits, inspections, fuel and maintenance managed in one place.'),
            (Icons.request_quote_rounded, 'Quotes & Billing',
                'Request a quote, receive proformas and invoices, and follow payments online.'),
            (Icons.home_work_rounded, 'Real Estate',
                'Property, tenant, lease and rent management alongside our logistics business.'),
          ],
        SitePage.about => const [
            (Icons.business_rounded, 'SH Malik Logistics Company Limited',
                'A Tanzanian logistics company moving cargo safely and reliably, with a modern digital platform for customers, drivers and staff.'),
            (Icons.verified_user_rounded, 'Our Commitment',
                'Safe transport, transparent tracking and clear billing on every trip.'),
            (Icons.phone_android_rounded, 'This App',
                'Customers follow trips, cargo and invoices; drivers check in and inspect vehicles; staff run operations, finance and HR.'),
          ],
        SitePage.contact => const [
            (Icons.language_rounded, 'Website', website),
            (Icons.request_quote_rounded, 'Need a quote?',
                'Sign in as a customer and use Quote Requests to tell us about your shipment.'),
            (Icons.login_rounded, 'Already a customer, driver or staff member?',
                'Use Login from the menu to access your account.'),
          ],
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 52,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kBarGradient)),
        title: Text(_title,
            style: AppType.display(16, color: Colors.white, letterSpacing: 0.2)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              Icon(_icon, color: kPrimary, size: 28),
              const SizedBox(width: 10),
              Text(_title, style: AppType.display(22)),
            ],
          ),
          const SizedBox(height: 16),
          for (final (icon, heading, body) in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                accentColor: kPrimary,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: kPrimary, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(heading,
                              style: AppType.body(15, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(body, style: AppType.body(13.5, color: kMuted, height: 1.5)),
                        ],
                      ),
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
