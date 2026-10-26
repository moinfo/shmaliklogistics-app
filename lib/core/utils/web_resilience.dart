import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Keeps a web view that shows the live site resilient: retries a failed main
/// frame load a couple of times (resets/timeouts are often momentary) and
/// reloads by itself once the device regains a network connection.
///
/// Wire it to the web view's navigation delegate: [pageStarted], [failed],
/// [pageFinished]. [failed] returns true while it is still retrying; only when
/// it returns false should the screen show its error state.
class WebResilience {
  final void Function() reload;
  final void Function() onConnectionBack;
  static const int _maxAutoRetries = 2;

  int _attempts = 0;
  bool _errored = false;
  bool _gaveUp = false;
  Timer? _timer;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  WebResilience({required this.reload, required this.onConnectionBack}) {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && _gaveUp) {
        _gaveUp = false;
        _attempts = 0;
        onConnectionBack();
        reload();
      }
    });
  }

  void pageStarted() => _errored = false;

  /// Records a main-frame failure. Returns true if an automatic retry is
  /// scheduled (keep showing the loading state), false if retries are used up.
  bool failed() {
    _errored = true;
    if (_attempts < _maxAutoRetries) {
      _attempts++;
      _timer?.cancel();
      _timer = Timer(Duration(seconds: 2 * _attempts), reload);
      return true;
    }
    _gaveUp = true;
    return false;
  }

  void pageFinished() {
    if (_errored) return;
    _attempts = 0;
    _gaveUp = false;
  }

  /// Manual Retry button: start the retry budget over.
  void reset() {
    _attempts = 0;
    _gaveUp = false;
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
  }
}
