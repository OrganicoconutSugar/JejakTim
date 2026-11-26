import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'geo_icons.dart';
import 'illustrated_icon.dart';

/// Color tokens.
///
/// A calm canvas with white cards, one confident brand blue and a small set of
/// supporting accents (indigo, violet, teal, orange, rose). Every accent has a
/// soft tint used for backgrounds so screens feel colorful without being loud.
abstract class C {
  // Brand & accents.
  static const blue = Color(0xFF0866FF),
      blueDeep = Color(0xFF0B47D9),
      indigo = Color(0xFF4F46E5),
      purple = Color(0xFF7C4DFF),
      teal = Color(0xFF0E9F84),
      orange = Color(0xFFF08A24),
      rose = Color(0xFFE5486B);

  // Neutrals.
  static const ink = Color(0xFF161B2E),
      ink2 = Color(0xFF3B4357),
      muted = Color(0xFF6B7387),
      subtle = Color(0xFF9AA1B2),
      line = Color(0xFFE7EAF2),
      canvas = Color(0xFFF5F7FC),
      panel = Color(0xFFF0F3F9);

  // Soft tints (backgrounds for chips, badges and accent cards).
  static const sky = Color(0xFFE4EFFF),
      lavender = Color(0xFFEFE9FF),
      lime = Color(0xFFDFF6EC),
      amber = Color(0xFFFFF0DB),
      blush = Color(0xFFFFE7EC);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E74FF), Color(0xFF4F46E5)],
  );
  static const violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF4F46E5)],
  );
  static const tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12B191), Color(0xFF0B8AA8)],
  );

  static const softShadow = [
    BoxShadow(
      color: Color(0x0F1B2559),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

/// Type scale. Use these instead of ad-hoc font sizes so every screen shares
/// the same rhythm: 28 / 22 / 18 / 16 / 14 / 13 / 12 / 11.
abstract class T {
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -.6,
    color: C.ink,
  );
  static const h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -.3,
    color: C.ink,
  );
  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -.2,
    color: C.ink,
  );
  static const title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: C.ink,
  );
  static const body = TextStyle(fontSize: 14, height: 1.5, color: C.ink2);
  static const bodyStrong = TextStyle(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: C.ink,
  );
  static const small = TextStyle(fontSize: 13, height: 1.45, color: C.muted);
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: C.muted,
  );
  static const overline = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: C.muted,
  );
  static const number = TextStyle(
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -.4,
    color: C.ink,
  );
}

/// Spacing scale (4pt grid).
abstract class S {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24;
  static const double page = 20;
}

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Outfit',
  scaffoldBackgroundColor: C.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: C.blue,
    primary: C.blue,
    secondary: C.indigo,
    surface: Colors.white,
    onSurface: C.ink,
  ),
  textTheme: const TextTheme(
    headlineLarge: T.display,
    headlineMedium: T.h1,
    headlineSmall: T.h2,
    titleLarge: T.h2,
    titleMedium: T.title,
    titleSmall: T.bodyStrong,
    bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: C.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: C.ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: C.muted),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: C.canvas,
    surfaceTintColor: Colors.transparent,
    foregroundColor: C.ink,
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: C.ink,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: C.blue, width: 1.5),
    ),
    labelStyle: const TextStyle(color: C.muted, fontSize: 14),
    hintStyle: const TextStyle(color: C.subtle, fontSize: 14),
    floatingLabelStyle: const TextStyle(
      color: C.blue,
      fontWeight: FontWeight.w500,
    ),
    errorMaxLines: 3,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: C.blue,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: C.ink,
      backgroundColor: Colors.white,
      minimumSize: const Size(48, 50),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      side: const BorderSide(color: C.line),
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: C.blue,
      minimumSize: const Size(48, 44),
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    selectedColor: C.blue,
    side: const BorderSide(color: C.line),
    labelStyle: const TextStyle(
      fontFamily: 'Outfit',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: C.ink2,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  listTileTheme: const ListTileThemeData(
    titleTextStyle: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: C.ink,
    ),
    subtitleTextStyle: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 13,
      color: C.muted,
    ),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    titleTextStyle: T.h2,
    contentTextStyle: T.body,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: C.ink,
    contentTextStyle: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14,
      color: Colors.white,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: C.blue,
    linearTrackColor: C.sky,
  ),
  dividerColor: C.line,
  dividerTheme: const DividerThemeData(color: C.line, space: 1, thickness: 1),
);
bool reduceMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations ||
    MediaQuery.of(context).accessibleNavigation;

/// Illustrated icon without a colored tile behind it.
class DimensionalIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const DimensionalIcon(
    this.icon, {
    super.key,
    this.color = C.blue,
    this.size = 44,
  });
  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: AppIcon(icon, size: size));
}

/// Illustrated icon sitting on a soft tinted rounded tile.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final double size;
  final Color? iconColor;
  const IconBadge(
    this.icon, {
    super.key,
    this.tint = C.sky,
    this.size = 44,
    this.iconColor,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: ExcludeSemantics(
      child: AppIcon(icon, size: size * .58, color: iconColor),
    ),
  );
}

class BrandLogo extends StatelessWidget {
  final double size;
  final bool inverse;
  const BrandLogo({super.key, this.size = 48, this.inverse = false});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo JejakTim Titik Bertemu',
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inverse ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: EdgeInsets.all(inverse ? size * .08 : 0),
          child: SvgPicture.asset(
            'assets/branding/titik-bertemu.svg',
            excludeFromSemantics: true,
          ),
        ),
      ),
    ),
  );
}

class CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final Color? color;
  final bool filled;
  const CircleAction(
    this.icon, {
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.filled = false,
  });
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onTap,
    style: IconButton.styleFrom(
      minimumSize: const Size(44, 44),
      backgroundColor: filled ? (color ?? C.blue) : Colors.white,
      foregroundColor: filled ? Colors.white : (color ?? C.ink),
      side: filled ? BorderSide.none : const BorderSide(color: C.line),
    ),
    icon: AppIcon(icon, size: 22),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.busy = false,
    this.icon = LucideIcons.arrowRight,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else if (icon != null)
              AppIcon(icon!, size: 18, color: Colors.white),
            if (busy || icon != null) const SizedBox(width: 10),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    ),
  );
}

/// Base card. White cards float on the canvas with a soft shadow; tinted
/// cards stay flat so they read as accents rather than containers.
class Surface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double radius;
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
    this.radius = 20,
  });
  @override
  Widget build(BuildContext context) {
    final white = color == Colors.white && gradient == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: white ? C.softShadow : null,
      ),
      child: Material(
        color: gradient == null ? color : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: white ? const Color(0xFFEDF0F6) : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration:
              gradient == null ? null : BoxDecoration(gradient: gradient),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color? foreground;
  final IconData? icon;
  const Pill(
    this.label, {
    super.key,
    this.color = C.panel,
    this.icon,
    this.foreground,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: 14, color: foreground),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground ?? C.ink2,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Visual language for task status: (label tint, foreground accent, icon).
(Color, Color, IconData) statusVisual(String status) => switch (status) {
  'done' => (C.lime, C.teal, LucideIcons.checkCircle2),
  'submitted' => (C.lavender, C.purple, LucideIcons.messageCircle),
  'revision_requested' => (C.amber, C.orange, LucideIcons.rotateCcw),
  'in_progress' => (C.sky, C.blue, LucideIcons.clipboardList),
  'cancelled' => (C.panel, C.muted, LucideIcons.x),
  _ => (C.panel, C.ink2, LucideIcons.clipboardList),
};

class Reveal extends StatelessWidget {
  final Widget child;
  final String identity;
  const Reveal({super.key, required this.child, this.identity = ''});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(identity),
    tween: Tween(begin: reduceMotion(context) ? 1 : 0, end: 1),
    duration: Duration(milliseconds: reduceMotion(context) ? 0 : 420),
    curve: Curves.easeOutCubic,
    builder:
        (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: child,
          ),
        ),
    child: child,
  );
}

class FloatingArt extends StatefulWidget {
  final String asset;
  final double height;
  const FloatingArt(this.asset, {super.key, this.height = 280});
  @override
  State<FloatingArt> createState() => _FloatingArtState();
}

class _FloatingArtState extends State<FloatingArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder:
        (context, _) => Transform.translate(
          offset: Offset(
            0,
            reduceMotion(context)
                ? 0
                : math.sin(animation.value * math.pi * 2) * 5,
          ),
          child: Image.asset(
            'assets/illustrations/${widget.asset}.png',
            height: widget.height,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
  );
}

/// Compact page header for top-level and form screens.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final String? overline;
  const PageHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.overline,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.xl),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overline != null) ...[
                Text(overline!.toUpperCase(), style: T.overline),
                const SizedBox(height: 6),
              ],
              Text(title, style: T.display),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: T.small),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: S.md), trailing!],
      ],
    ),
  );
}

/// Small metric tile: tinted icon badge, big number, caption.
class StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color tint;
  const StatTile(
    this.value,
    this.label,
    this.icon, {
    super.key,
    this.tint = C.sky,
  });
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon, tint: tint, size: 36),
        const SizedBox(height: 12),
        Text(value, style: T.number),
        const SizedBox(height: 2),
        Text(
          label,
          style: T.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Widget? action;
  const EmptyState(
    this.title,
    this.description, {
    super.key,
    this.icon = LucideIcons.folderOpen,
    this.action,
  });

  Widget _graphic() {
    final kind = switch (icon) {
      LucideIcons.folderOpen => GeoIconKind.folder,
      LucideIcons.checkCircle2 => GeoIconKind.checkCircle,
      LucideIcons.clipboardCheck => GeoIconKind.clipboard,
      LucideIcons.bell => GeoIconKind.bell,
      LucideIcons.heartHandshake => GeoIconKind.star,
      _ => null,
    };
    if (kind != null) return GeoIcon(kind, size: 52);
    return IconBadge(icon, tint: C.sky, iconColor: C.blue, size: 56);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    child: Column(
      children: [
        _graphic(),
        const SizedBox(height: 14),
        Text(title, style: T.title, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(description, style: T.small, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Surface(
      color: C.amber,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(LucideIcons.info, size: 18, color: C.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: T.body.copyWith(color: C.ink)),
          ),
        ],
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final int index;
  final String? avatarDataUrl;
  const Avatar(
    this.name, {
    super.key,
    this.size = 36,
    this.index = 0,
    this.avatarDataUrl,
  });

  static const _tints = [
    (C.sky, C.blueDeep),
    (C.lavender, C.purple),
    (C.lime, C.teal),
    (C.amber, Color(0xFFB45F06)),
  ];

  String _initials() {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2);
    return parts.isEmpty ? '?' : parts.map((s) => s[0].toUpperCase()).join();
  }

  Widget _fallback() => Text(
    _initials(),
    style: TextStyle(
      fontSize: size * .34,
      fontWeight: FontWeight.w700,
      color: _tints[index % 4].$2,
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget content = _fallback();
    final data = avatarDataUrl?.trim() ?? '';
    if (data.startsWith('data:image/') && data.contains(',')) {
      try {
        final bytes = base64Decode(data.split(',').last);
        content = ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => Center(child: _fallback()),
          ),
        );
      } catch (_) {
        content = _fallback();
      }
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _tints[index % 4].$1,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: content,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: T.h2)),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!),
                const SizedBox(width: 2),
                const GeoIcon(GeoIconKind.chevronRight, size: 16),
              ],
            ),
          ),
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String label = 'Konfirmasi',
}) async =>
    await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
                onPressed: () => Navigator.pop(context, true),
                child: Text(label),
              ),
            ],
          ),
    ) ??
    false;
void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
