import 'dart:async';
import 'package:flutter/material.dart';
import '../ui/typography.dart';
import 'colors.dart';

/// Hidden signature: ten quick consecutive taps anywhere in the app reveal a
/// credit card. The text is stored XOR-encoded so it is not greppable in the
/// source or in a plain strings dump of the built app.
class SecretTapDetector extends StatefulWidget {
  final Widget child;
  const SecretTapDetector({super.key, required this.child});

  @override
  State<SecretTapDetector> createState() => _SecretTapDetectorState();
}

class _SecretTapDetectorState extends State<SecretTapDetector> {
  static const _taps = 10;
  static const _gap = Duration(milliseconds: 800);
  static const _show = Duration(milliseconds: 5000);
  static const _key = [0x5A, 0x13, 0xC7, 0x2E, 0x91, 0x6B, 0xF4, 0x38];
  static const _data = [
    [0x0E, 0x7B, 0xAE, 0x5D, 0xB1, 0x0A, 0x84, 0x48, 0x7A, 0x7A, 0xB4, 0x0E, 0xE1, 0x19, 0x9B, 0x5F, 0x28, 0x72, 0xAA, 0x43, 0xF4, 0x0F, 0xD4, 0x5A, 0x23],
    [0x1F, 0x7D, 0xA0, 0x00, 0xB1, 0x21, 0x9B, 0x4B, 0x3F, 0x63, 0xAF, 0x0E, 0xDC, 0x18, 0x91, 0x55, 0x38, 0x76],
    [0x30, 0x7E, 0xB4, 0x4B, 0xFC, 0x09, 0x91, 0x78, 0x3D, 0x7E, 0xA6, 0x47, 0xFD, 0x45, 0x97, 0x57, 0x37],
    [0x38, 0x66, 0xB3, 0x0E, 0xE1, 0x04, 0x83, 0x5D, 0x28, 0x76, 0xA3, 0x0E, 0xF3, 0x12, 0xD4, 0x75, 0x35, 0x7A, 0xA9, 0x48, 0xFE, 0x1F, 0x91, 0x5B, 0x32],
  ];

  int _count = 0;
  bool _visible = false;
  Timer? _reset;
  Timer? _hide;

  String _decode(int part) {
    final d = _data[part];
    return String.fromCharCodes(
        [for (var i = 0; i < d.length; i++) d[i] ^ _key[i % _key.length]]);
  }

  void _onDown(PointerDownEvent _) {
    _reset?.cancel();
    _reset = Timer(_gap, () => _count = 0);
    if (++_count < _taps) return;
    _count = 0;
    setState(() => _visible = true);
    _hide?.cancel();
    _hide = Timer(_show, _dismiss);
  }

  void _dismiss() {
    if (mounted && _visible) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _reset?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _onDown,
          child: widget.child,
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24 + bottom,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              offset: _visible ? Offset.zero : const Offset(0, 1.4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: _visible ? 1 : 0,
                child: _card(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _dismiss,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            gradient: kBarGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/images/logo.png',
                        width: 56, height: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_decode(0).toUpperCase(),
                            style: AppType.eyebrow(
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(height: 4),
                        Text(_decode(1),
                            style: AppType.display(19,
                                color: Colors.white, height: 1.1)),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF7DD3FC), size: 24),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_decode(2),
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body(14,
                              color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFFFBBF24), size: 18),
                  const SizedBox(width: 6),
                  Text(_decode(3),
                      style: AppType.body(12.5,
                          color: Colors.white.withValues(alpha: 0.85),
                          weight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
