import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'illustrated_icon.dart';

abstract class C {
  static const blue = Color(0xFF0866FF),
      ink = Color(0xFF24262B),
      muted = Color(0xFF677080),
      line = Color(0xFFE8EBF1),
      panel = Color(0xFFEEF1F8),
      sky = Color(0xFFCEE8FF),
      purple = Color(0xFF8753ED),
      lavender = Color(0xFFEEE6FF),
      lime = Color(0xFFEEF8CE),
      amber = Color(0xFFFFF3D5);
}

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Outfit',
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: C.blue,
    primary: C.blue,
    surface: Colors.white,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      height: 1.12,
      letterSpacing: -1.1,
      color: C.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.18,
      letterSpacing: -.6,
      color: C.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      color: C.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: C.ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: C.ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: C.ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: C.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: C.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: C.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: C.blue, width: 1.5),
    ),
    labelStyle: const TextStyle(color: C.muted),
    errorMaxLines: 3,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: C.blue,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 54),
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      shape: const StadiumBorder(),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  dividerColor: C.line,
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
      minimumSize: const Size(48, 48),
      backgroundColor:
          filled ? (color ?? C.blue) : Colors.white.withValues(alpha: .12),
      foregroundColor: filled ? Colors.white : (color ?? C.ink),
      side: BorderSide(color: filled ? Colors.transparent : C.line),
    ),
    icon: AppIcon(icon, size: 28),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              AppIcon(icon, size: 20),
            const SizedBox(width: 10),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: BorderSide(
        color: color == Colors.white ? C.line : Colors.transparent,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const Pill(this.label, {super.key, this.color = C.panel, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: 14),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

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
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      children: [
        DimensionalIcon(icon, size: 72, color: C.blue),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: C.muted),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(LucideIcons.info, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final int index;
  const Avatar(this.name, {super.key, this.size = 36, this.index = 0});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: [C.sky, C.lavender, C.lime, C.amber][index % 4],
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(
      name.isEmpty
          ? '?'
          : name.split(' ').take(2).map((s) => s.isEmpty ? '' : s[0]).join(),
      style: TextStyle(
        fontSize: size * .32,
        fontWeight: FontWeight.w600,
        color: C.ink,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
