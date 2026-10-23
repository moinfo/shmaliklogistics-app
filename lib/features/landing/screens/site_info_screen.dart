import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/colors.dart';

/// The public website pages reachable from the landing menu.
enum SitePage { services, about, contact }

/// Offline copy of the website's Services / About / Contact pages. The text is
/// taken verbatim from the live site (English). The landing screen always loads
/// the live page first and shows this only when the page cannot be reached.
class SiteInfoView extends StatelessWidget {
  final SitePage page;
  const SiteInfoView({super.key, required this.page});

  /// Maps a site URL path (`/about`, `/services/`) to a page, or null.
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

  @override
  Widget build(BuildContext context) {
    final children = switch (page) {
      SitePage.about => _about(context),
      SitePage.services => _services(context),
      SitePage.contact => _contact(context),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: children,
    );
  }

  // ── About ──────────────────────────────────────────────────────────────────

  List<Widget> _about(BuildContext c) => [
        _hero(c, 'Who We Are', 'About SH Malik Logistics',
            'SH MALIK LOGISTICS COMPANY LIMITED is a reliable and customer-focused logistics company based in Handeni, Tanzania. We provide efficient, secure, and cost-effective transportation solutions tailored to meet the needs of modern businesses.'),
        _chips(const [
          ('🚛', '550K+', 'Shipments'),
          ('🤝', '20+', 'Clients'),
          ('⭐', '1000+', 'Testimonials'),
          ('📞', '24/7', 'Support'),
        ]),
        _heading(c, 'About SH Malik Logistics Company Limited'),
        _para(c,
            'SH Malik Logistics Company Limited is a registered Tanzanian road-freight operator based in Handeni, Tanga Region. We move cross-border cargo on four active corridors — Tanzania to Zambia, DRC, Malawi and Mozambique — handling permits, customs and GPS-tracked transit in-house.'),
        _para(c,
            'Founded in 2020 by Mr. Abdulmalik Suleiman, the company was built around one principle: every shipment should be visible, every cost should be transparent, and every border should be cleared without third-party middlemen.'),
        _chips(const [
          ('📅', 'Founded', '2020'),
          ('👤', 'Founder', 'Abdulmalik Suleiman'),
          ('📍', 'Location', 'Handeni, Tanga Region'),
        ]),
        _heading(c, "Built for Africa's Trade Routes"),
        _para(c,
            'We operate routes connecting Tanzania to neighboring countries including Zambia and the Democratic Republic of Congo (DRC), with a fleet of well-maintained Scania trucks managed by experienced and trained drivers. We have worked with established companies such as Hornest Expeditors, African Queen Logistics, and Transfreight Logistics.'),
        _para(c,
            "With Hustles and Prayers We'll Reach Our Destination — we are committed to delivering excellence and building long-term partnerships through reliable and professional logistics services."),
        _heading(c, 'What Drives Us'),
        _card('🎯', 'Reliability', 'Every trip planned and tracked to ensure on-time delivery, every time.'),
        _card('🔍', 'Transparency', 'Full cost visibility on every trip — no hidden charges, ever.'),
        _card('🌍', 'Regional Expertise',
            'Deep knowledge of East and Central African trade routes and border requirements.'),
        _card('🤝', 'Partnership', 'We treat your cargo and your business as our own.'),
        _card('📱', 'Technology',
            'GPS tracking, digital documents, and automated alerts keep everything connected.'),
        _card('🛡️', 'Compliance',
            'COMESA/SADC compliant with all transit permits and customs requirements handled.'),
        _heading(c, 'Company Milestones'),
        _card('2020', 'Company Founded',
            'SH Malik Logistics Company Limited established in Handeni, Tanzania, with a focus on road freight to Zambia and DRC.'),
        _card('2021', 'Fleet Expanded',
            'Fleet grew to 20+ vehicles. Added Zambia and Malawi routes to regular operations.'),
        _card('2023', 'Technology Integrated',
            'GPS tracking, fuel sensors, and digital operations management rolled out across the fleet.'),
        _card('2025', 'Digital Platform',
            'Customer portal and route profitability system launched — giving clients full shipment visibility.'),
        _card('2026', 'Full ERP System',
            'Complete logistics management system — 29 modules covering all operations from trips to HR.'),
        _heading(c, 'The People Behind Every Delivery'),
        _card('👔', 'Abdulmalik Suleiman — CEO',
            "Leading SH Malik Logistics with vision and dedication, driving the company's mission to become a leading logistics provider in East Africa."),
        _card('📊', 'Salim Hilal — Head of Accounts',
            'Managing financial operations and ensuring full cost transparency for clients across all logistics operations.'),
        _card('💻', 'Towfiq Seif — Head of ICT',
            'Maintaining the GPS tracking systems, customer portal and digital infrastructure that keep every shipment visible and every operation connected.'),
        _card('🚛', 'Said — Operations',
            'Experienced team managing route planning, driver assignments, fleet coordination and day-to-day logistics operations.'),
        _card('📞', 'Support Team — Customer Service',
            'Available 24/7 to answer client queries, provide real-time cargo updates and ensure smooth operations for every shipment.'),
      ];

  // ── Services ───────────────────────────────────────────────────────────────

  List<Widget> _services(BuildContext c) => [
        _hero(c, 'What We Do', 'Our Core Services',
            'Reliable, efficient, and cost-effective logistics solutions for East and Central African trade routes.'),
        _card('🚛', 'Road Freight Transportation',
            'We provide reliable and efficient road freight services for the safe movement of goods across local and regional routes. We handle every shipment with professionalism and care, whether small or large consignments.',
            bullets: const ['Full Truck Load (FTL)', 'Part Load (LTL)', 'Local & regional routes', 'Safety-first operations']),
        _card('📦', 'Cargo Handling & Clearing',
            'We offer professional cargo handling services, ensuring goods are carefully managed during loading, unloading, and storage. Our clearing services include documentation assistance and customs coordination to reduce delays.',
            bullets: const ['Loading & unloading supervision', 'Secure storage', 'Customs documentation', 'Regulatory compliance']),
        _card('📍', 'Last-Mile Delivery Solutions',
            'Our last-mile delivery service ensures that goods reach their final destination quickly and efficiently. We focus on timely and accurate delivery to customers, businesses, and end users.',
            bullets: const ['Timely final delivery', 'Business & residential delivery', 'Customer satisfaction focus', 'Real-time status updates']),
        _card('📡', 'GPS Fleet Tracking',
            'Real-time location of every vehicle, accessible from any device. Know exactly where your cargo is at all times.',
            bullets: const ['Live map view', 'Trip history & replay', 'Fuel monitoring', 'Geofence alerts']),
        _card('🛂', 'Border & Customs',
            'End-to-end permit management for all border crossing points — with expiry alerts before documents lapse.',
            bullets: const ['Transit permits', 'COMESA/SADC compliance', 'Customs documentation', 'Expiry tracking']),
        _card('🤝', 'Customer Portal',
            'Clients track shipments and download invoices themselves — reducing support calls to zero.',
            bullets: const ['Self-service tracking', 'Invoice downloads', 'Trip history', 'SMS notifications']),
      ];

  // ── Contact ────────────────────────────────────────────────────────────────

  List<Widget> _contact(BuildContext c) => [
        _hero(c, 'Get In Touch', "Let's Move Your Cargo",
            'We are ready to support your logistics needs with reliable and efficient solutions. Get in touch with us today to discuss how we can help move your business forward.'),
        _card('📍', 'Address', 'Handeni, Tanzania\nMain operations base'),
        _card('📞', 'Phone / WhatsApp', '+255 652 373 434\nCall or WhatsApp anytime'),
        _card('📧', 'Email', 'info@shmaliklogistics.co.tz\nWe reply within 2 hours'),
        _heading(c, 'Frequently Asked Questions'),
        _card('❓', 'How long does Dar to Lubumbashi take?',
            'Typically 5–7 days depending on border conditions and cargo type. We provide real-time updates throughout.'),
        _card('❓', 'Do you handle customs documentation?',
            'Yes — we manage all transit permits, COMESA/SADC compliance documents and customs paperwork for every route.'),
        _card('❓', 'Can I track my cargo in real time?',
            'Yes. Every vehicle has GPS tracking. You can follow your cargo on our customer portal or receive SMS updates.'),
        _card('❓', 'What cargo types do you carry?',
            'General goods, industrial equipment, refrigerated cargo, oversized loads, and hazardous materials (with proper permits).'),
      ];

  // ── Building blocks ────────────────────────────────────────────────────────

  Widget _hero(BuildContext c, String eyebrow, String title, String desc) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow.toUpperCase(), style: AppType.eyebrow(size: 11, color: kPrimary)),
            const SizedBox(height: 6),
            Text(title, style: AppType.display(26)),
            const SizedBox(height: 10),
            Text(desc, style: AppType.body(14, color: kMuted, height: 1.6)),
          ],
        ),
      );

  Widget _heading(BuildContext c, String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(text, style: AppType.display(19)),
      );

  Widget _para(BuildContext c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppType.body(14, color: kMuted, height: 1.7)),
      );

  Widget _chips(List<(String, String, String)> items) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (icon, a, b) in items)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a, style: AppType.body(14, weight: FontWeight.w800)),
                        Text(b, style: AppType.body(11.5, color: kMuted)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _card(String icon, String title, String body, {List<String> bullets = const []}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          accentColor: kPrimary,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppType.body(15, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(body, style: AppType.body(13.5, color: kMuted, height: 1.5)),
                    for (final b in bullets)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('✓  $b', style: AppType.body(13, weight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
