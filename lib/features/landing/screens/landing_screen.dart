import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/ui/typography.dart';
import '../../../core/utils/colors.dart';

/// First screen for a signed-out visitor: the live marketing site in a web
/// view, under the same brand bar as the rest of the app. Login lives in the
/// toggle (drawer) menu.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  static const String url = 'https://shmaliklogistics.co.tz';

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        // The site's own Login button opens its web login; use the app's form.
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          final isLogin = uri != null &&
              uri.host.endsWith('shmaliklogistics.co.tz') &&
              uri.path.replaceAll(RegExp(r'/+$'), '') == '/login';
          if (isLogin) {
            Navigator.of(context).pushNamed('/login');
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (_) => setState(() => _error = null),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _error = e.description);
        },
      ))
      ..loadRequest(Uri.parse(LandingScreen.url));
  }

  void _goHome() {
    Navigator.of(context).pop(); // close drawer
    _controller.loadRequest(Uri.parse(LandingScreen.url));
  }

  void _goLogin() {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // Back walks the site's own history; on the first page it leaves the app.
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 52,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBarGradient),
          ),
          titleSpacing: 16,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset('assets/images/logo.png', height: 26, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                child: Text('SH Malik Logistics',
                    overflow: TextOverflow.ellipsis,
                    style: AppType.display(16, color: Colors.white, letterSpacing: 0.2)),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              tooltip: 'Menu',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        endDrawer: _buildDrawer(),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_progress < 100 && _error == null)
              LinearProgressIndicator(value: _progress / 100, color: kPrimary),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 40, color: kMuted),
                      const SizedBox(height: 12),
                      const Text('Could not load the website.\nCheck your internet connection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kMuted)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() => _error = null);
                          _controller.loadRequest(Uri.parse(LandingScreen.url));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: kBarGradient),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/images/logo.png',
                      width: 52, height: 52, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SH MALIK',
                          style: AppType.display(18, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Logistics Portal',
                          style: AppType.body(12.5,
                              color: Colors.white.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: kPrimary),
            title: Text('Home', style: AppType.body(15, weight: FontWeight.w600)),
            onTap: _goHome,
          ),
          ListTile(
            leading: const Icon(Icons.login_rounded, color: kPrimary),
            title: Text('Login', style: AppType.body(15, weight: FontWeight.w600)),
            onTap: _goLogin,
          ),
        ],
      ),
    );
  }
}
