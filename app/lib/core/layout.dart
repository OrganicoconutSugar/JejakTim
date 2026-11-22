import 'illustrated_icon.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'controller.dart';
import 'design.dart';

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
                title: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading:
                    navIndex == null
                        ? IconButton(
                          tooltip: 'Kembali',
                          iconSize: 20,
                          icon: const AppIcon(
                            LucideIcons.chevronLeft,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            foregroundColor: C.ink,
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed:
                              () =>
                                  context.canPop()
                                      ? context.pop()
                                      : context.go('/home'),
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
                            SizedBox(height: 16),
                            Text(
                              'Memuat data tim…',
                              style: TextStyle(color: C.muted),
                            ),
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
                minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: C.ink.withValues(alpha: .10),
                        blurRadius: 22,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 66,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .82),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: const Color(0xFFCFD9E8),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            _nav(
                              context,
                              0,
                              LucideIcons.home,
                              'Beranda',
                              '/home',
                            ),
                            _nav(
                              context,
                              1,
                              LucideIcons.checkSquare,
                              'Tugas',
                              '/tasks',
                            ),
                            Expanded(
                              child: Center(
                                child: CircleAction(
                                  LucideIcons.plus,
                                  label: 'Tambah',
                                  onTap: () => showAddSheet(context, c),
                                ),
                              ),
                            ),
                            _nav(
                              context,
                              2,
                              LucideIcons.sparkles,
                              'Insight',
                              '/insights',
                            ),
                            _nav(
                              context,
                              3,
                              LucideIcons.userCircle,
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
    IconData icon,
    String label,
    String path,
  ) {
    final selected = navIndex == i;
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
              borderRadius: BorderRadius.circular(40),
              onTap: () => context.go(path),
              child: Center(
                child: AnimatedContainer(
                  duration: Duration(
                    milliseconds: reduceMotion(context) ? 0 : 220,
                  ),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        selected
                            ? C.blue.withValues(alpha: .08)
                            : Colors.transparent,
                    border:
                        selected
                            ? Border.all(color: C.blue.withValues(alpha: .30))
                            : null,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: DimensionalIcon(icon, size: 32),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
  ),
  builder:
      (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Langkah baru bersama tim',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (projectId != null && c.owner(projectId))
                ListTile(
                  leading: const AppIcon(
                    LucideIcons.checkSquare,
                    color: C.blue,
                  ),
                  title: const Text('Buat tugas'),
                  subtitle: const Text('Bagi tanggung jawab dengan jelas'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/projects/$projectId/tasks/new');
                  },
                ),
              ListTile(
                leading: const AppIcon(LucideIcons.folderPlus, color: C.blue),
                title: const Text('Buat proyek'),
                subtitle: const Text('Mulai ruang kolaborasi baru'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/projects/new');
                },
              ),
              ListTile(
                leading: const AppIcon(LucideIcons.scanLine, color: C.purple),
                title: const Text('Gabung dengan kode'),
                subtitle: const Text('Temukan proyek dari undangan tim'),
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

class ContentList extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const ContentList({super.key, required this.children, this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final view = ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        28 + MediaQuery.paddingOf(context).bottom,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
    return onRefresh == null
        ? view
        : RefreshIndicator(onRefresh: onRefresh!, child: view);
  }
}
