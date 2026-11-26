import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'controller.dart';
import 'design.dart';
import 'geo_icons.dart';

class PageFrame extends ConsumerWidget {
  final String? title;
  final Widget child;
  final int? navIndex;
  final List<Widget>? actions;
  final Widget? bottom;
  const PageFrame({
    super.key,
    this.title,
    required this.child,
    this.navIndex,
    this.actions,
    this.bottom,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    return Scaffold(
      extendBody: navIndex != null && bottom == null,
      appBar:
          title == null
              ? null
              : AppBar(
                title: Text(title!),
                leading:
                    navIndex == null
                        ? Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Center(
                            child: IconButton(
                              tooltip: 'Kembali',
                              iconSize: 20,
                              icon: const Icon(
                                LucideIcons.chevronLeft,
                                size: 20,
                                color: C.ink,
                              ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(40, 40),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: C.line),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed:
                                  () =>
                                      context.canPop()
                                          ? context.pop()
                                          : context.go('/home'),
                            ),
                          ),
                        )
                        : null,
                automaticallyImplyLeading: false,
                actions: actions,
              ),
      body: SafeArea(
        top: title == null,
        bottom: navIndex == null || bottom != null,
        child: Column(
          children: [
            Expanded(
              child:
                  c.loading && c.data.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: S.lg),
                            Text('Memuat data tim…', style: T.small),
                          ],
                        ),
                      )
                      : c.error != null
                      ? EmptyState(
                        'Belum dapat memuat data',
                        c.error!,
                        icon: LucideIcons.wifiOff,
                        action: FilledButton(
                          onPressed: c.refresh,
                          child: const Text('Coba lagi'),
                        ),
                      )
                      : child,
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          bottom ??
          (navIndex == null
              ? null
              : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 66,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: const Color(0xFFE1E6F2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _nav(
                              context,
                              0,
                              GeoIconKind.home,
                              'Beranda',
                              '/home',
                            ),
                            _nav(
                              context,
                              1,
                              GeoIconKind.clipboard,
                              'Tugas',
                              '/tasks',
                            ),
                            Expanded(
                              child: _addNav(
                                context,
                                onTap: () => showAddSheet(context, c),
                              ),
                            ),
                            _nav(
                              context,
                              2,
                              GeoIconKind.star,
                              'Insight',
                              '/insights',
                            ),
                            _nav(
                              context,
                              3,
                              GeoIconKind.profile,
                              'Profil',
                              '/profile',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )),
    );
  }

  Widget _nav(
    BuildContext context,
    int i,
    GeoIconKind icon,
    String label,
    String path,
  ) {
    final selected = navIndex == i;
    final dur = Duration(milliseconds: reduceMotion(context) ? 0 : 180);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => context.go(path),
              child: Center(
                child: AnimatedContainer(
                  duration: dur,
                  width: 50,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? C.sky : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: dur,
                        opacity: selected ? 1 : .58,
                        child: ExcludeSemantics(
                          child: GeoIcon(icon, size: 26),
                        ),
                      ),
                      Positioned(
                        bottom: 3,
                        child: AnimatedContainer(
                          duration: dur,
                          width: selected ? 14 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: C.blue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addNav(BuildContext context, {required VoidCallback onTap}) =>
      Semantics(
        button: true,
        label: 'Tambah',
        child: Tooltip(
          message: 'Tambah',
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                child: Container(
                  width: 48,
                  height: 46,
                  decoration: BoxDecoration(
                    color: C.panel,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: GeoIcon(GeoIconKind.plus, size: 26),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

void showAddSheet(
  BuildContext context,
  AppController c, {
  String? projectId,
}) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder:
      (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.page, 0, S.page, S.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Langkah baru bersama tim', style: T.h1),
              const SizedBox(height: 4),
              const Text(
                'Pilih aksi cepat untuk memulai atau bergabung.',
                style: T.small,
              ),
              const SizedBox(height: S.lg),
              if (projectId != null && c.owner(projectId)) ...[
                _SheetAction(
                  icon: GeoIconKind.clipboard,
                  title: 'Buat tugas',
                  subtitle: 'Bagi tanggung jawab dengan jelas',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/projects/$projectId/tasks/new');
                  },
                ),
                const SizedBox(height: S.sm),
              ],
              _SheetAction(
                icon: GeoIconKind.folderPlus,
                title: 'Buat proyek',
                subtitle: 'Mulai ruang kolaborasi baru',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/projects/new');
                },
              ),
              const SizedBox(height: S.sm),
              _SheetAction(
                icon: GeoIconKind.scan,
                title: 'Gabung dengan kode',
                subtitle: 'Temukan proyek dari undangan tim',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/projects/join');
                },
              ),
            ],
          ),
        ),
      ),
);

class _SheetAction extends StatelessWidget {
  final GeoIconKind icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Surface(
    color: C.panel,
    padding: const EdgeInsets.all(14),
    radius: 16,
    onTap: onTap,
    child: Row(
      children: [
        GeoIcon(icon, size: 32),
        const SizedBox(width: S.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: T.bodyStrong),
              const SizedBox(height: 2),
              Text(subtitle, style: T.caption),
            ],
          ),
        ),
        const Icon(LucideIcons.chevronRight, size: 18, color: C.muted),
      ],
    ),
  );
}

class ContentList extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const ContentList({super.key, required this.children, this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final view = ListView(
      padding: EdgeInsets.fromLTRB(
        S.page,
        S.md,
        S.page,
        S.xxl + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
    return onRefresh == null
        ? view
        : RefreshIndicator(onRefresh: onRefresh!, child: view);
  }
}
