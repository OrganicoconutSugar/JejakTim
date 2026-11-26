import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'design.dart';

/// JejakTim's icon helper.
///
/// Primary navigation and key feature symbols use the playful 3D raster assets
/// when no explicit tint color is requested. Utility icons and tinted badges
/// render crisp Lucide vector glyphs so every symbol matches its exact meaning.
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  const AppIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final asset = color == null ? _assetFor(icon) : null;
    if (asset == null) {
      return Icon(icon, size: size, color: color ?? _fallbackTone(icon));
    }
    final dimension = size ?? 24;
    return Image.asset(
      asset,
      width: dimension,
      height: dimension,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}

String? _assetFor(IconData icon) {
  if (icon == LucideIcons.home) {
    return 'assets/icons3d/home.png';
  }
  if (icon == LucideIcons.folderOpen || icon == LucideIcons.folderPlus) {
    return 'assets/icons3d/projects.png';
  }
  if (icon == LucideIcons.checkSquare ||
      icon == LucideIcons.clipboardCheck ||
      icon == LucideIcons.clipboardList) {
    return 'assets/icons3d/tasks.png';
  }
  if (icon == LucideIcons.sparkles) {
    return 'assets/icons3d/insights.png';
  }
  if (icon == LucideIcons.userCircle) {
    return 'assets/icons3d/profile.png';
  }
  if (icon == LucideIcons.bell) {
    return 'assets/icons3d/notifications.png';
  }
  if (icon == LucideIcons.shieldCheck) {
    return 'assets/icons3d/privacy.png';
  }
  if (icon == LucideIcons.fileText) {
    return 'assets/icons3d/terms.png';
  }
  if (icon == LucideIcons.pencil) {
    return 'assets/icons3d/edit.png';
  }
  if (icon == LucideIcons.camera ||
      icon == LucideIcons.image ||
      icon == LucideIcons.imagePlus) {
    return 'assets/icons3d/photo.png';
  }
  if (icon == LucideIcons.search) {
    return 'assets/icons3d/search.png';
  }
  if (icon == LucideIcons.plus) {
    return 'assets/icons3d/add.png';
  }
  return null;
}

Color _fallbackTone(IconData icon) {
  if ([
    LucideIcons.chevronLeft,
    LucideIcons.chevronRight,
    LucideIcons.chevronDown,
    LucideIcons.arrowRight,
    LucideIcons.arrowUpRight,
    LucideIcons.x,
  ].contains(icon)) {
    return C.ink2;
  }
  return C.blue;
}
