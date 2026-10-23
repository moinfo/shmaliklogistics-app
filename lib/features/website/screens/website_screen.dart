import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/web_resilience.dart';

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
  bool _retrying = false;
  late final WebResilience _resilience;

  @override
  void initState() {
    super.initState();
    _resilience = WebResilience(
      reload: () {
        if (mounted) _controller.loadRequest(_target);
      },
      onConnectionBack: () {
        if (mounted) setState(() { _error = null; _retrying = true; });
      },
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) {
            _resilience.pageStarted();
            setState(() => _error = null);
          },
          onPageFinished: (_) {
            _resilience.pageFinished();
            if (_retrying && mounted) setState(() => _retrying = false);
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) _onLoadFailed(e.description);
          },
          onHttpError: (e) {
            final code = e.response?.statusCode ?? 0;
            final path = e.request?.uri.path ?? '';
            if (code >= 500 && !path.contains('.') &&
                e.request?.uri.host.endsWith('shmaliklogistics.co.tz') == true) {
              _onLoadFailed('Server error ($code)');
            }
          },
        ),
      )
      ..loadRequest(_target);
  }

  Uri get _target => Uri.parse('${WebsiteScreen.url}/${widget.path}');

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
            if (_retrying && _error == null)
              Positioned.fill(
                child: Container(
                  color: AppColors.surfaceVariant(context),
                  child: const Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
              ),
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
                          _resilience.reset();
                          setState(() => _error = null);
                          _controller.loadRequest(_target);
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
