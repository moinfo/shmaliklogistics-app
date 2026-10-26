import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Build info gate.
//
// Wraps the whole app and watches for ten quick, consecutive taps anywhere on
// any screen. When that happens it shows the build credits card. The text is
// kept only as scrambled bytes (decoded at runtime), so it does not appear as
// readable strings in the source or as plain text in the compiled app.
// ─────────────────────────────────────────────────────────────────────────────

const List<int> _a = [0xaa, 0xcc, 0xa9, 0x00, 0x5a, 0x77, 0x98, 0xb1, 0xd9, 0xe1, 0x0e, 0x4e, 0x67, 0xd2, 0xbe, 0xc1, 0xa3, 0x2e, 0x49, 0x75, 0xcf, 0xb9, 0xcc, 0xe8, 0x0f];
const List<int> _b = [0xb5, 0xc9, 0xeb, 0x04, 0x4f, 0x5a, 0xd2, 0xa5, 0xd8, 0xe6, 0x2d, 0x56, 0x5e, 0xcf, 0xe4, 0xc2, 0xee, 0x1e];
const List<int> _c = [0xc6, 0xe9, 0x02, 0x12, 0x7b, 0x9b, 0xac, 0xc5, 0xe4, 0x1e, 0x5c, 0x76, 0x82, 0xaf, 0xd6, 0xed, 0x31];
const List<int> _d = [0x45, 0x75, 0xd2, 0xa9, 0xcd, 0xf1, 0x3b, 0x4e, 0x7b, 0x9f, 0xea, 0xd1, 0xf5, 0x39];
const List<int> _e = [0xc0, 0xe0, 0x3b, 0x4d, 0x7b, 0x89, 0xa4, 0xcc, 0xef, 0x16];

String _decode(List<int> v) {
  final b = v.reversed.toList();
  return String.fromCharCodes(
    List<int>.generate(b.length, (i) => b[i] ^ ((i * 37 + 91) & 255)),
  );
}

const int _kTapsNeeded = 10;
const Duration _kTapGap = Duration(milliseconds: 650);
const double _kTapSlop = 24; // px a finger may move and still count as a tap

class DiagnosticsGate extends StatefulWidget {
  const DiagnosticsGate({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<DiagnosticsGate> createState() => _DiagnosticsGateState();
}

class _DiagnosticsGateState extends State<DiagnosticsGate> {
  int _count = 0;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Offset? _down;
  OverlayEntry? _entry;

  void _onUp(PointerUpEvent e) {
    final start = _down;
    _down = null;
    if (start == null || (e.position - start).distance > _kTapSlop) {
      _count = 0; // a drag / scroll breaks the streak
      return;
    }
    final now = DateTime.now();
    _count = now.difference(_last) <= _kTapGap ? _count + 1 : 1;
    _last = now;
    if (_count >= _kTapsNeeded) {
      _count = 0;
      _show();
    }
  }

  void _show() {
    if (_entry != null) return;
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    HapticFeedback.heavyImpact();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CreditsToast(
        onClosed: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _down = e.position,
      onPointerUp: _onUp,
      onPointerCancel: (_) => _count = 0,
      child: widget.child,
    );
  }
}

class _CreditsToast extends StatefulWidget {
  const _CreditsToast({required this.onClosed});
  final VoidCallback onClosed;

  @override
  State<_CreditsToast> createState() => _CreditsToastState();
}

class _CreditsToastState extends State<_CreditsToast> with TickerProviderStateMixin {
  // The card stays for 0.8 s, then fades out on its own.
  static const _life = Duration(milliseconds: 800);

  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  late final AnimationController _countdown =
      AnimationController(vsync: this, duration: _life)..forward();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _countdown.addStatusListener((s) {
      if (s == AnimationStatus.completed) _close();
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _in.reverse();
    if (mounted) widget.onClosed();
  }

  @override
  void dispose() {
    _in.dispose();
    _glow.dispose();
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _in, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    final fade = CurvedAnimation(parent: _in, curve: const Interval(0, 0.6, curve: Curves.easeOut));

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _close,
        child: FadeTransition(
          opacity: fade,
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1).animate(curved),
              child: _card(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) {
        final t = _glow.value;
        return Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: SweepGradient(
              transform: GradientRotation(t * 2 * math.pi),
              colors: const [
                Color(0xFFFFB347),
                kPrimary,
                Color(0xFFC2410C),
                Color(0xFF22D3EE),
                Color(0xFFFFB347),
              ],
            ),
            boxShadow: [
              BoxShadow(color: kPrimary.withValues(alpha: 0.45), blurRadius: 40, spreadRadius: 2),
              BoxShadow(
                color: const Color(0xFF7A2800).withValues(alpha: 0.55),
                blurRadius: 60,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A1300), Color(0xFF1F0A00), Color(0xFF2C0F00)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _badge(t),
                const SizedBox(height: 18),
                Text(
                  _decode(_a),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFFD58A), Colors.white, Color(0xFFFFB347)],
                  ).createShader(r),
                  child: Text(
                    _decode(_b),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alternate_email_rounded, size: 15, color: Color(0xFF22D3EE)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _decode(_c),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _decode(_d),
                        style: TextStyle(
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: _divider()),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(colors: [kPrimary, Color(0xFFFF8A3D)]),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _decode(_e),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.22)],
          ),
        ),
      );

  Widget _badge(double t) {
    final pulse = 1 + 0.06 * math.sin(t * 2 * math.pi);
    return Transform.scale(
      scale: pulse,
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8A3D), kPrimary, Color(0xFF7A2800)],
          ),
          boxShadow: [BoxShadow(color: Color(0x88EA580C), blurRadius: 24, spreadRadius: 1)],
        ),
        child: const Icon(Icons.code_rounded, size: 38, color: Colors.white),
      ),
    );
  }
}
