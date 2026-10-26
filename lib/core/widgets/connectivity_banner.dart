import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Wraps the whole app and shows a slim "No internet connection" bar whenever
/// the device has no network, so failed requests are easy to explain.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _backOnlineTimer;
  bool _offline = false;
  bool _backOnline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update).catchError((_) {});
    _sub = Connectivity().onConnectivityChanged.listen(_update, onError: (_) {});
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (!mounted || offline == _offline) return;
    setState(() {
      _offline = offline;
      _backOnline = !offline; // just reconnected → flash "Back online"
    });
    _backOnlineTimer?.cancel();
    if (!offline) {
      _backOnlineTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _backOnline = false);
      });
    }
  }

  @override
  void dispose() {
    _backOnlineTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        if (_offline || _backOnline)
          Material(
            color: _offline ? const Color(0xFFB3261E) : const Color(0xFF15803D),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_offline ? Icons.wifi_off_rounded : Icons.wifi_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _offline ? 'No internet connection' : 'Back online',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
