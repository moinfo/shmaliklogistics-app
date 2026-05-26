import 'package:flutter/material.dart';

import '../../../core/ui/typography.dart';
import '../models/driver.dart';

/// A driver's photo rendered as a rounded-square avatar, falling back to the
/// driver's initials on a status-tinted chip when there is no photo (or it
/// fails to load). Shared by the list card and the detail hero so both stay
/// visually consistent.
///
/// Set [ring] to wrap the avatar in a soft status-coloured halo (used on the
/// larger detail hero to give the photo more presence).
class DriverAvatar extends StatelessWidget {
  final Driver driver;
  final double size;
  final double radius;
  final bool ring;

  const DriverAvatar({
    super.key,
    required this.driver,
    this.size = 40,
    this.radius = 12,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = driver.statusColor;
    final avatar = SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _imageOrInitials(color),
      ),
    );

    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius + 4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: avatar,
    );
  }

  Widget _imageOrInitials(Color color) {
    final url = driver.photoFullUrl;
    if (url == null) return _initialsChip(color);
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _initialsChip(color),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _initialsChip(color),
    );
  }

  Widget _initialsChip(Color color) {
    return Container(
      width: size,
      height: size,
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        _initials(driver.name),
        style: AppType.number(size * 0.34, color: color),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2);
    final s = parts.map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }
}
