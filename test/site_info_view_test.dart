import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shmalik_driver/features/landing/screens/site_info_screen.dart';

Future<void> _pump(WidgetTester tester, SitePage page) async {
  tester.view.physicalSize = const Size(720, 8000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SiteInfoView(page: page)),
  ));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('pageForPath maps site paths and ignores trailing slashes', () {
    expect(SiteInfoView.pageForPath('/about'), SitePage.about);
    expect(SiteInfoView.pageForPath('/services/'), SitePage.services);
    expect(SiteInfoView.pageForPath('/contact'), SitePage.contact);
    expect(SiteInfoView.pageForPath('/'), isNull);
    expect(SiteInfoView.pageForPath(''), isNull);
    expect(SiteInfoView.pageForPath('/login'), isNull);
  });

  testWidgets('About shows the live site content', (tester) async {
    await _pump(tester, SitePage.about);
    expect(find.text('About SH Malik Logistics'), findsOneWidget);
    expect(find.text('Company Milestones'), findsOneWidget);
    expect(find.text('Full ERP System'), findsOneWidget);
    expect(find.textContaining('Abdulmalik Suleiman'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Services lists all six services', (tester) async {
    await _pump(tester, SitePage.services);
    for (final t in [
      'Road Freight Transportation',
      'Cargo Handling & Clearing',
      'Last-Mile Delivery Solutions',
      'GPS Fleet Tracking',
      'Border & Customs',
      'Customer Portal',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('✓  Full Truck Load (FTL)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Contact shows address, phone, email and FAQ', (tester) async {
    await _pump(tester, SitePage.contact);
    expect(find.textContaining('Handeni, Tanzania'), findsOneWidget);
    expect(find.textContaining('+255 652 373 434'), findsOneWidget);
    expect(find.textContaining('info@shmaliklogistics.co.tz'), findsOneWidget);
    expect(find.text('Can I track my cargo in real time?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
