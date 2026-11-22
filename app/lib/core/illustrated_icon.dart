import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// JejakTim's playful 3D icon set.
///
/// Primary navigation and feature symbols use transparent raster assets inspired
/// by the soft toy-like reference. Small utility controls keep Lucide glyphs so
/// arrows, close buttons, and form affordances stay crisp at compact sizes.
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  const AppIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final asset = _assetFor(icon);
    if (asset == null || color == Colors.white) {
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
  if ([
    LucideIcons.folderOpen,
    LucideIcons.folderPlus,
    LucideIcons.layers,
    LucideIcons.sprout,
    LucideIcons.archive,
  ].contains(icon)) {
    return 'assets/icons3d/projects.png';
  }
  if ([
    LucideIcons.checkSquare,
    LucideIcons.clipboardCheck,
    LucideIcons.clipboardList,
    LucideIcons.check,
    LucideIcons.checkCheck,
    LucideIcons.checkCircle2,
    LucideIcons.calendarDays,
    LucideIcons.circleDot,
  ].contains(icon)) {
    return 'assets/icons3d/tasks.png';
  }
  if ([
    LucideIcons.sparkles,
    LucideIcons.heartHandshake,
    LucideIcons.messageCircle,
    LucideIcons.messageSquare,
    LucideIcons.messagesSquare,
  ].contains(icon)) {
    return 'assets/icons3d/insights.png';
  }
  if ([
    LucideIcons.user,
    LucideIcons.userCircle,
    LucideIcons.userCheck,
    LucideIcons.userPlus,
    LucideIcons.userMinus,
    LucideIcons.users,
    LucideIcons.crown,
  ].contains(icon)) {
    return 'assets/icons3d/profile.png';
  }
  if ([LucideIcons.bell, LucideIcons.bellOff].contains(icon)) {
    return 'assets/icons3d/notifications.png';
  }
  if ([LucideIcons.shieldCheck, LucideIcons.shieldAlert].contains(icon)) {
    return 'assets/icons3d/privacy.png';
  }
  if (icon == LucideIcons.fileText) {
    return 'assets/icons3d/terms.png';
  }
  if (icon == LucideIcons.pencil) {
    return 'assets/icons3d/edit.png';
  }
  if ([
    LucideIcons.camera,
    LucideIcons.image,
    LucideIcons.imagePlus,
    LucideIcons.upload,
  ].contains(icon)) {
    return 'assets/icons3d/photo.png';
  }
  if ([LucideIcons.search, LucideIcons.scanLine].contains(icon)) {
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
    return const Color(0xFF292F3C);
  }
  return const Color(0xFF286DA0);
}
