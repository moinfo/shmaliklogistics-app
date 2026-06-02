import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'typography.dart';
import '../utils/app_theme.dart';
import '../utils/colors.dart';

/// Shared "Trans-Mas mobile" design kit — the "Operations Command" language.
///
/// One source of visual truth: a blueprint-grid brand header, gradient-chip
/// stat tiles with tabular numerals, soft-shadow cards with status rails,
/// tinted pills, staggered load reveals, and consistent loading/empty/error
/// states. Compose these instead of hand-rolling chrome per screen.

/// Per-module accent gradients. Keeps Ops/Finance/HR/Customer visually distinct
/// but harmonious. Use [.colors] for gradients and [.base] for solid accents.
enum ModuleAccent {
  ops([Color(0xFFEA580C), Color(0xFFC2410C)]),
  finance([Color(0xFF0E9F6E), Color(0xFF22C55E)]),
  hr([Color(0xFF6D28D9), Color(0xFF8B5CF6)]),
  brand([Color(0xFF7A2800), Color(0xFFEA580C)]),
  danger([Color(0xFFDC2626), Color(0xFFF97316)]);

  const ModuleAccent(this.colors);
  final List<Color> colors;
  Color get base => colors.first;
}

// ── macOS-Tahoe "Liquid Glass" primitive ───────────────────────────────────

/// One place to dial in the Liquid-Glass feel app-wide. Raise [blurSigma] for
/// a heavier frost; raise tint alphas for more opacity (less background bleed).
/// The 1px top highlight is what sells the "polished glass edge" illusion.
class GlassTokens {
  GlassTokens._();
  // Cards use a lighter blur than full sheets so scroll perf stays clean
  // (one save-layer per visible card).
  static const double blurSigmaCard  = 18;
  static const double blurSigmaSheet = 28;
  static const double blurSigmaBar   = 24;

  // Glass body colors — pulled from the WEB palette so light/dark mode read as
  // the same brand on phone and browser.
  //   • Light: a cool sky-white (sits on white bodies as a near-neutral glass,
  //     picks up subtle blue when overlapping the navy AppGradientHeader).
  //   • Dark : the web's `dk.card` color `#0F1E32` — the same navy used by web
  //     card surfaces in dark mode (see resources/js/pages/system/Trips/Show.jsx).
  static const Color tintLight = Color(0xFFF1F5FB);
  static const Color tintDark  = Color(0xFF1E0800);

  // Tint gradient alphas (top→bottom). Tahoe runs a slightly brighter top edge.
  // Dark-mode alphas are higher than light-mode because a tinted dark color
  // needs more opacity to read at the same visual weight as a white tint.
  static const double tintLightTopAlpha = 0.78;
  static const double tintLightBotAlpha = 0.60;
  static const double tintDarkTopAlpha  = 0.55;
  static const double tintDarkBotAlpha  = 0.32;

  // 1px top specular highlight — STAYS near-white in both modes because polished
  // glass edges reflect ambient light regardless of substrate (Tahoe convention).
  static const double highlightLightAlpha = 0.60;
  static const double highlightDarkAlpha  = 0.32;

  // Outer hairline border.
  static const double borderLightAlpha = 0.35;
  static const double borderDarkAlpha  = 0.20;
}

/// macOS Tahoe-style frosted glass surface. Samples whatever is painted behind
/// it (in the same Stack/parent) and frosts it, then layers a top-bright tint
/// gradient with a 1px white specular highlight at the top edge so it reads as
/// a polished piece of glass rather than a translucent PNG.
///
/// Always wraps its child in a [ClipRRect] so the blur respects rounded corners.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius radius;
  final EdgeInsetsGeometry? padding;

  /// Override the blur intensity (defaults to [GlassTokens.blurSigmaCard]).
  /// Use [GlassTokens.blurSigmaSheet] for hero sheets, [GlassTokens.blurSigmaBar]
  /// for floating bars, or a custom value.
  final double? sigma;

  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = const BorderRadius.all(Radius.circular(18)),
    this.padding,
    this.sigma,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintColor = isDark ? GlassTokens.tintDark : GlassTokens.tintLight;
    final topA = isDark ? GlassTokens.tintDarkTopAlpha : GlassTokens.tintLightTopAlpha;
    final botA = isDark ? GlassTokens.tintDarkBotAlpha : GlassTokens.tintLightBotAlpha;
    // Highlight + border stay white — polished glass edges read as white
    // regardless of the body's tint.
    final highlight = Colors.white.withValues(
      alpha: isDark ? GlassTokens.highlightDarkAlpha : GlassTokens.highlightLightAlpha,
    );
    final border = Colors.white.withValues(
      alpha: isDark ? GlassTokens.borderDarkAlpha : GlassTokens.borderLightAlpha,
    );
    final s = sigma ?? GlassTokens.blurSigmaCard;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: s, sigmaY: s),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tintColor.withValues(alpha: topA),
                tintColor.withValues(alpha: botA),
              ],
            ),
            border: Border.all(color: border, width: 0.5),
          ),
          // Top specular highlight painted ABOVE the child so it catches the
          // glass edge the way Tahoe surfaces catch light.
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border(top: BorderSide(color: highlight, width: 1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Shell chrome inset ──────────────────────────────────────────────────────

/// Published by the app shell around its body so any [AppGradientHeader] drawn
/// inside a tab/module knows to leave room for the shell's transparent, floating
/// app bar — letting the header's gradient run continuously behind it.
///
/// Pushed routes (detail screens) live above the shell in the navigator tree, so
/// they don't see this and render with no extra inset.
class ShellChrome extends InheritedWidget {
  final double topInset;
  const ShellChrome({super.key, required this.topInset, required super.child});

  static double topInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellChrome>()?.topInset ?? 0;

  @override
  bool updateShouldNotify(ShellChrome oldWidget) => oldWidget.topInset != topInset;
}

// ── Brand header ──────────────────────────────────────────────────────────

/// Curved command header: layered navy→blue mesh, a faint blueprint grid and a
/// radar motif, with an optional uppercase eyebrow above the title.
class AppGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? trailing;
  final List<Widget> actions;
  final List<Color> gradient;
  final EdgeInsets padding;

  /// Optional widget shown to the left of the text column (e.g. an avatar).
  final Widget? leading;

  /// Optional widget shown below the title (e.g. a role chip / meta row).
  final Widget? footer;

  const AppGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
    this.actions = const [],
    this.gradient = const [Color(0xFF7A2800), Color(0xFFEA580C)],
    this.padding = const EdgeInsets.fromLTRB(20, 18, 14, 24),
    this.leading,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    // Extra top padding so header content clears the shell's floating app bar
    // (0 when there is no shell above, e.g. on pushed detail screens).
    final extraTop = ShellChrome.topInsetOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradient.first, gradient.last, const Color(0xFF7A2800)],
            stops: const [0.0, 0.6, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Blueprint grid + radar rings.
            Positioned.fill(
              child: CustomPaint(painter: _CommandTexturePainter(gradient.last)),
            ),
            // Soft light bloom, top-right.
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                // Under the shell, the app-bar inset replaces (not adds to) the
                // default top padding, so the content tucks just under the
                // floating bar instead of leaving a tall empty band.
                padding: padding.copyWith(
                    top: extraTop > 0 ? extraTop : padding.top),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 14)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 2,
                                    margin: const EdgeInsets.only(right: 8),
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  Text(eyebrow!.toUpperCase(),
                                      style: AppType.eyebrow(
                                          color: Colors.white.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                          if (subtitle != null)
                            Text(subtitle!,
                                style: AppType.body(13.5,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    weight: FontWeight.w500)),
                          Text(title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.display(25, color: Colors.white, height: 1.1)),
                          if (footer != null) ...[const SizedBox(height: 10), footer!],
                        ],
                      ),
                    ),
                    ...actions,
                    ?trailing,
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

/// Faint engineering grid + concentric radar rings — the "command" texture.
class _CommandTexturePainter extends CustomPainter {
  final Color tint;
  _CommandTexturePainter(this.tint);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // Radar rings, anchored bottom-left.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.07);
    final center = Offset(size.width * 0.06, size.height * 1.05);
    for (final r in [60.0, 110.0, 160.0]) {
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _CommandTexturePainter old) => old.tint != tint;
}

/// A header action rendered as a frosted circular icon button.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  const HeaderIconButton({super.key, required this.icon, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ── Stat tile ───────────────────────────────────────────────────────────────

/// Gradient icon chip + tabular value + label, on a soft-shadow surface.
/// Set [danger] to flag a value red (and red chip) when it is non-zero.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ModuleAccent accent;
  final bool danger;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = ModuleAccent.brand,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = danger && value.trim() != '0' && value.trim().isNotEmpty;
    final chip = highlight ? ModuleAccent.danger : accent;
    final radius = BorderRadius.circular(20);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LiquidGlass(
        radius: radius,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: chip.colors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: chip.base.withValues(alpha: 0.38),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 20, color: Colors.white),
                      ),
                      if (highlight) ...[
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: kDanger, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value,
                    style: AppType.number(27,
                        color: highlight ? kDanger : AppColors.textNavy(context)),
                  ),
                  const SizedBox(height: 3),
                  Text(label, style: AppType.body(12.5, color: kMuted, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section heading ───────────────────────────────────────────────────────

/// Gradient icon chip + title, with optional uppercase eyebrow + trailing.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ModuleAccent accent;
  final String? eyebrow;
  final Widget? trailing;
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.accent = ModuleAccent.brand,
    this.eyebrow,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: accent.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accent.base.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null)
                Text(eyebrow!.toUpperCase(),
                    style: AppType.eyebrow(size: 9.5, color: accent.base)),
              Text(title, style: AppType.display(16.5, color: AppColors.textNavy(context))),
            ],
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

// ── Content card with status rail ───────────────────────────────────────────

/// A soft-shadow content card with an optional colored left accent bar.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.accentColor,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LiquidGlass(
        radius: radius,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  if (accentColor != null)
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accentColor!, accentColor!.withValues(alpha: 0.55)],
                        ),
                      ),
                    ),
                  Expanded(child: Padding(padding: padding, child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded tinted status badge.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Text(label,
              style: AppType.body(11.5, color: color, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Motion: staggered load reveal ─────────────────────────────────────────

/// Fades + lifts its child into place once, after [delayMs]. Stagger a list by
/// passing increasing delays (e.g. `index * 70`).
class RevealOnLoad extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;
  const RevealOnLoad({super.key, required this.child, this.delayMs = 0, this.offsetY = 18});

  @override
  State<RevealOnLoad> createState() => _RevealOnLoadState();
}

class _RevealOnLoadState extends State<RevealOnLoad> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<double> _move =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _move.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ── Empty / error / skeleton ────────────────────────────────────────────────

/// Centered empty state (icon + message).
class AppEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  const AppEmpty({super.key, this.icon = Icons.inbox_rounded, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kMuted.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: kMuted.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: AppType.body(14, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

/// Centered error state with retry.
class AppError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AppError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 38, color: kDanger),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: AppType.body(14, color: kMuted)),
            const SizedBox(height: 18),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton helper — wrap skeleton boxes built with [AppSkeleton.box].
class AppSkeleton extends StatelessWidget {
  final Widget child;
  const AppSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      highlightColor: dark ? const Color(0xFF475569) : const Color(0xFFF8FAFC),
      child: child,
    );
  }

  static Widget box(BuildContext context, {double? height, double? width, double radius = 16}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
