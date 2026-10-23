import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/web_resilience.dart';
import 'site_info_screen.dart';

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
  String _lang = 'en';
  String _path = '';
  bool _retrying = false;
  late final WebResilience _resilience;

  @override
  void initState() {
    super.initState();
    _resilience = WebResilience(
      reload: () {
        if (mounted) _controller.loadRequest(_uriFor(_path));
      },
      onConnectionBack: () {
        if (mounted) setState(() { _error = null; _retrying = true; });
      },
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        // The site's own Login button opens its web login; use the app's form.
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          final onSite = uri != null && uri.host.endsWith('shmaliklogistics.co.tz');
          final path = onSite ? uri.path.replaceAll(RegExp(r'/+$'), '') : '';
          if (path == '/login') {
            Navigator.of(context).pushNamed('/login');
            return NavigationDecision.prevent;
          }
          if (onSite && request.isMainFrame) _path = path;
          return NavigationDecision.navigate;
        },
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (_) {
          _resilience.pageStarted();
          setState(() => _error = null);
          _hideSiteChrome();
        },
        onPageFinished: (_) {
          _resilience.pageFinished();
          if (_retrying && mounted) setState(() => _retrying = false);
          _hideSiteChrome();
          _syncLanguage();
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) _onLoadFailed(e.description);
        },
        // Server-side failures (5xx) on the page itself get the same retry.
        onHttpError: (e) {
          final code = e.response?.statusCode ?? 0;
          if (code >= 500 && e.request?.uri.host.endsWith('shmaliklogistics.co.tz') == true &&
              e.request?.uri.path.contains('.') == false) {
            _onLoadFailed('Server error ($code)');
          }
        },
      ))
      ..loadRequest(Uri.parse(LandingScreen.url));
  }

  Uri _uriFor(String path) => Uri.parse('${LandingScreen.url}${path.isEmpty ? '' : path}');

  void _onLoadFailed(String description) {
    if (_resilience.failed()) {
      setState(() => _retrying = true); // hide the browser's own error page
    } else {
      setState(() { _retrying = false; _error = description; });
    }
  }

  @override
  void dispose() {
    _resilience.dispose();
    super.dispose();
  }

  /// The app's top menu replaces the site's header (language, theme, menu), so
  /// hide it. It stays in the page (invisible, not removed) so the top-bar
  /// language and theme buttons can still drive the site's own controls.
  void _hideSiteChrome() {
    _controller.runJavaScript(
      "(function(){var id='app-chrome-style';if(document.getElementById(id))return;"
      "var s=document.createElement('style');s.id=id;"
      "s.textContent='header.mantine-AppShell-header{visibility:hidden!important;pointer-events:none!important}"
      "nav.mantine-AppShell-navbar{display:none!important}"
      ".mantine-AppShell-main{padding-top:0!important}';"
      "(document.head||document.documentElement).appendChild(s);})();",
    );
  }

  /// The site remembers its language, so read it back to keep the EN/SW pill
  /// in step (the active button in the site's own toggle has a filled background).
  Future<void> _syncLanguage() async {
    try {
      final r = await _controller.runJavaScriptReturningResult(
        "(function(){var b=[].slice.call(document.querySelectorAll('header button'))"
        ".filter(function(x){var t=x.textContent.trim().toLowerCase();return t==='en'||t==='sw'});"
        "for(var i=0;i<b.length;i++){var c=getComputedStyle(b[i]).backgroundColor;"
        "if(c&&c!=='rgba(0, 0, 0, 0)'&&c!=='transparent')return b[i].textContent.trim().toLowerCase();}return '';})()",
      );
      final code = r.toString().replaceAll('"', '');
      if (mounted && (code == 'en' || code == 'sw') && code != _lang) {
        setState(() => _lang = code);
      }
    } catch (_) {}
  }

  /// Loads a page of the live website (as on the web). If it cannot be reached
  /// the error overlay shows an offline copy of the same page.
  void _openPage(String path) {
    Navigator.of(context).pop(); // close drawer
    _load(path);
  }

  void _load(String path) {
    _resilience.reset();
    setState(() {
      _error = null;
      _path = path;
    });
    _controller.loadRequest(_uriFor(path));
  }

  void _setLanguage(String code) {
    setState(() => _lang = code);
    _controller.runJavaScript(
      "(function(l){var b=[].slice.call(document.querySelectorAll('header button'))"
      ".filter(function(x){return x.getClientRects().length>0&&x.textContent.trim().toLowerCase()===l});"
      "if(b[0])b[0].click();})('$code');",
    );
  }

  void _toggleTheme() {
    _controller.runJavaScript(
      "(function(){var a=[].slice.call(document.querySelectorAll('header .mantine-ActionIcon-root'))"
      ".filter(function(x){return x.getClientRects().length>0});if(a[0])a[0].click();})();",
    );
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
            _langPill(),
            IconButton(
              icon: const Icon(Icons.brightness_6_rounded, color: Colors.white),
              tooltip: 'Light / Dark',
              onPressed: _toggleTheme,
            ),
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
            if (_retrying && _error == null)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: const Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
              ),
            if (_error != null) _buildOffline(),
          ],
        ),
      ),
    );
  }

  /// Shown when the live page cannot be loaded: the same page's content from
  /// the site (About / Services / Contact), or a plain retry for other pages.
  Widget _buildOffline() {
    final page = SiteInfoView.pageForPath(_path);
    final retry = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 36, color: kMuted),
        const SizedBox(height: 10),
        const Text('Could not reach the live website.\nCheck your internet connection.',
            textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => _load(_path.isEmpty ? '/' : _path),
          child: const Text('Retry'),
        ),
      ],
    );
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: page == null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: retry))
            : Column(
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 4), child: retry),
                  Expanded(child: SiteInfoView(page: page)),
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    final top = MediaQuery.of(context).padding.top + 52;
    // Transparent drawer shell: only the card below is drawn, sized to its
    // menu items and aligned under the app bar, so it doesn't run to the bottom.
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 280,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: top, right: 8, left: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            // Backdrop is only the card's background; the menu items define
            // its height, so the card ends right after Login.
            child: Stack(
              children: [
                const Positioned.fill(child: CommandBackdrop(child: SizedBox())),
                Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navTile(Icons.home_rounded, 'Home', () => _openPage('/')),
                    _navTile(Icons.local_shipping_rounded, 'Services', () => _openPage('/services')),
                    _navTile(Icons.info_outline_rounded, 'About', () => _openPage('/about')),
                    _navTile(Icons.mail_outline_rounded, 'Contact', () => _openPage('/contact')),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _goLogin,
                          icon: const Icon(Icons.login_rounded),
                          label: Text('Login',
                              style: AppType.body(16, color: Colors.white, weight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFC73A3A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// EN / SW switch in the app bar, styled like the site's own toggle.
  Widget _langPill() {
    Widget seg(String code) {
      final on = _lang == code;
      return GestureDetector(
        onTap: () => _setLanguage(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFC73A3A) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(code.toUpperCase(),
              style: AppType.body(12,
                  color: on ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  weight: FontWeight.w800)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('en'), seg('sw')]),
    );
  }

  Widget _navTile(IconData icon, String label, VoidCallback onTap) => ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
        title: Text(label,
            style: AppType.body(15.5, color: Colors.white, weight: FontWeight.w600)),
        onTap: onTap,
      );
}
