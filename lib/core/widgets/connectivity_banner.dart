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
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_update).catchError((_) {});
    _sub = Connectivity().onConnectivityChanged.listen(_update, onError: (_) {});
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        if (_offline)
          Material(
            color: const Color(0xFFB3261E),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
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
