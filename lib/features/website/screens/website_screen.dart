import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';

/// In-app browser for the live SH Malik Logistics website. [path] opens a
/// specific page of the web portal (e.g. `system/hr/bonus`); the web session
/// cookie persists, so the user signs in on the site once.
class WebsiteScreen extends StatefulWidget {
  final String path;
  const WebsiteScreen({super.key, this.path = ''});

  static const String url = 'https://shmaliklogistics.co.tz';

  @override
  State<WebsiteScreen> createState() => _WebsiteScreenState();
}

class _WebsiteScreenState extends State<WebsiteScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _error = null),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) {
              setState(() => _error = e.description);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('${WebsiteScreen.url}/${widget.path}'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // Go back within the site first; the shell then handles leaving the module.
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceVariant(context),
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
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 40,
                        color: kMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load the website.\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kMuted),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() => _error = null);
                          _controller.reload();
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
}
