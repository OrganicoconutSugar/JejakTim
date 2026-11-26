import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/geo_icons.dart';
import '../../core/layout.dart';
import '../../core/evidence_photo.dart';
import '../../data/supabase_repository.dart';
import 'invite_qr.dart';
import 'project_chat_screen.dart';
import 'project_templates.dart';

const _projectIcons = {
  'folder': ('Folder', Icons.folder_rounded, Color(0xFF1765CB)),
  'sprout': ('Tunas', Icons.eco_rounded, Color(0xFF217451)),
  'sparkles': ('Bintang', Icons.stars_rounded, Color(0xFF8B5400)),
  'rocket': ('Roket', Icons.rocket_launch_rounded, Color(0xFF7943AF)),
  'design': ('Desain', Icons.palette_rounded, Color(0xFFAD3D70)),
  'code': ('Kode', Icons.code_rounded, Color(0xFF006A77)),
  'research': ('Riset', Icons.science_rounded, Color(0xFF5144B3)),
  'book': ('Buku', Icons.menu_book_rounded, Color(0xFF854D26)),
  'target': ('Target', Icons.track_changes_rounded, Color(0xFFC24636)),
  'idea': ('Ide', Icons.lightbulb_rounded, Color(0xFF8B6500)),
  'team': ('Tim', Icons.groups_rounded, Color(0xFF385BB2)),
  'event': ('Acara', Icons.event_rounded, Color(0xFF00766E)),
};

GeoIconKind _geoKindForProject(String value) => switch (value) {
  'sprout' => GeoIconKind.sprout,
  'sparkles' => GeoIconKind.star,
  'rocket' => GeoIconKind.rocket,
  'design' => GeoIconKind.layers,
  'code' => GeoIconKind.code,
  'research' => GeoIconKind.lightbulb,
  'book' => GeoIconKind.book,
  'target' => GeoIconKind.target,
  'idea' => GeoIconKind.lightbulb,
  'team' => GeoIconKind.users,
  'event' => GeoIconKind.calendar,
  _ => GeoIconKind.folder,
};

class _ProjectAvatar extends StatelessWidget {
  const _ProjectAvatar(
    this.value, {
    this.size = 44,
    this.onDark = false,
  });
  final String value;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (value.startsWith('data:image/') && value.length <= 180000) {
      try {
        final bytes = UriData.parse(value).contentAsBytes();
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * .28),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder:
                (_, __, ___) => GeoIcon(GeoIconKind.folder, size: size),
          ),
        );
      } on FormatException {
        // Older or invalid data falls back to the folder icon.
      }
    }
    final kind = _geoKindForProject(value);
    if (!onDark) {
      return GeoIcon(kind, size: size * .86);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: GeoIcon(kind, size: size * .66),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final active = c.projects.where((p) => p['status'] == 'active').toList();
    final mine =
        c.tasks
            .where(
              (t) =>
                  stringsOf(t, 'assigneeIds').contains(c.uid) &&
                  !['done', 'cancelled'].contains(t['status']),
            )
            .toList()
          ..sort(
            (a, b) => textOf(
              a,
              'dueAt',
              '9999',
            ).compareTo(textOf(b, 'dueAt', '9999')),
          );
    final stats = aggregateTasks(c.tasks, DateTime.now());
    final firstName = textOf(c.profile, 'name', 'Teman').split(' ').first;
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      2.0,
    );

    return PageFrame(
      navIndex: 0,
      child: Builder(
        builder:
            (bodyContext) => RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(
                padding: EdgeInsets.only(
                  top: S.lg,
                  bottom: S.xxl + MediaQuery.paddingOf(bodyContext).bottom,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: S.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          children: [
                            const BrandLogo(size: 38),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'JejakTim',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: T.h1,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Notifikasi',
                              onPressed: () => context.push('/notifications'),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(44, 44),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: C.line),
                              ),
                              icon: const GeoIcon(GeoIconKind.bell, size: 22),
                            ),
                            const SizedBox(width: S.sm),
                            InkWell(
                              onTap: () => context.go('/profile'),
                              customBorder: const CircleBorder(),
                              child: Avatar(
                                textOf(c.profile, 'name'),
                                size: 42,
                                avatarDataUrl: c.avatarOf(c.uid),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: S.lg),

                        // Hero banner card
                        Surface(
                          gradient: C.brandGradient,
                          padding: EdgeInsets.zero,
                          radius: 24,
                          child: Stack(
                            children: [
                              Positioned(
                                right: -28,
                                top: -36,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: .09),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 32,
                                bottom: -56,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: .14),
                                      width: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(S.xl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: .18,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Halo, $firstName · Siap melangkah?',
                                        style: T.caption.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: S.md),
                                    Text(
                                      'Kerja bareng.\nKontribusi terlihat.',
                                      style: T.h1.copyWith(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 1.18,
                                      ),
                                    ),
                                    const SizedBox(height: S.lg),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final create = FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: C.blue,
                                            minimumSize: const Size(48, 46),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed:
                                              () =>
                                                  context.push('/projects/new'),
                                          icon: const GeoIcon(
                                            GeoIconKind.folderPlus,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'Buat proyek baru',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                        final join = OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white
                                                .withValues(alpha: .14),
                                            foregroundColor: Colors.white,
                                            side: BorderSide(
                                              color: Colors.white.withValues(
                                                alpha: .42,
                                              ),
                                            ),
                                            minimumSize: const Size(48, 46),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                          onPressed:
                                              () => context.push(
                                                '/projects/join?code=${Uri.encodeComponent(code.text)}',
                                              ),
                                          icon: const GeoIcon(
                                            GeoIconKind.scan,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'Gabung dengan kode',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                        final stacked =
                                            constraints.maxWidth < 340 ||
                                            textScale > 1.3;
                                        if (stacked) {
                                          return Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: create,
                                              ),
                                              const SizedBox(height: S.sm),
                                              SizedBox(
                                                width: double.infinity,
                                                child: join,
                                              ),
                                            ],
                                          );
                                        }
                                        return Row(
                                          children: [
                                            Expanded(child: create),
                                            const SizedBox(width: 10),
                                            Expanded(child: join),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: S.md),

                        // Quick invite code bar
                        TextField(
                          controller: code,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Kode undangan (mis. JEJAK2026)',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(13),
                              child: GeoIcon(GeoIconKind.key, size: 20),
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Gabung dengan kode',
                              icon: const GeoIcon(
                                GeoIconKind.arrowRight,
                                size: 20,
                              ),
                              onPressed:
                                  () => context.push(
                                    '/projects/join?code=${Uri.encodeComponent(code.text)}',
                                  ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted:
                              (value) => context.push(
                                '/projects/join?code=${Uri.encodeComponent(value)}',
                              ),
                        ),
                        const SizedBox(height: S.lg),

                        // Compact 3-column stat strip
                        Row(
                          children: [
                            Expanded(
                              child: _HomeStat(
                                value: '${active.length}',
                                label: 'Proyek aktif',
                                icon: GeoIconKind.layers,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HomeStat(
                                value: '${stats['done']}',
                                label: 'Tugas selesai',
                                icon: GeoIconKind.checkCircle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HomeStat(
                                value: '${stats['review']}',
                                label: 'Perlu review',
                                icon: GeoIconKind.review,
                              ),
                            ),
                          ],
                        ),

                        SectionTitle(
                          'Proyekmu',
                          action: 'Lihat semua',
                          onTap: () => context.push('/projects'),
                        ),
                      ],
                    ),
                  ),

                  // Projects carousel or full-width card when single project
                  if (active.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: S.page),
                      child: Surface(
                        child: EmptyState(
                          'Mulai dari satu proyek',
                          'Ajak teman dan bagi langkah pertama bersama.',
                          action: FilledButton(
                            onPressed: () => context.push('/projects/new'),
                            child: const Text('Buat proyek'),
                          ),
                        ),
                      ),
                    )
                  else if (active.length == 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: S.page),
                      child: ProjectCard(
                        active.first,
                        index: 0,
                        controller: c,
                        fullWidth: true,
                      ),
                    )
                  else
                    SizedBox(
                      height: 222 * textScale,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: S.page),
                        scrollDirection: Axis.horizontal,
                        itemCount: active.length,
                        separatorBuilder: (_, i) => const SizedBox(width: S.md),
                        itemBuilder:
                            (context, i) => ProjectCard(
                              active[i],
                              index: i,
                              controller: c,
                            ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: S.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          'Langkah terdekat',
                          action: 'Semua tugas',
                          onTap: () => context.go('/tasks'),
                        ),
                        if (mine.isEmpty)
                          const Surface(
                            child: EmptyState(
                              'Semua terkendali',
                              'Belum ada tugas aktif untukmu.',
                              icon: LucideIcons.checkCircle2,
                            ),
                          )
                        else
                          ...mine
                              .take(3)
                              .map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TaskTile(t, controller: c),
                                ),
                              ),
                        const SizedBox(height: S.sm),

                        // AI Insight CTA banner
                        Surface(
                          gradient: C.violetGradient,
                          radius: 22,
                          padding: const EdgeInsets.all(S.lg),
                          onTap: () => context.go('/insights'),
                          child: Row(
                            children: [
                              const GeoIcon(GeoIconKind.star, size: 36),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pahami ritme kerja tim',
                                      style: T.title.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Lihat progres & hal yang perlu perhatian',
                                      style: T.caption.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: .88,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: S.sm),
                              const GeoIcon(GeoIconKind.arrowUpRight, size: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _HomeStat extends StatelessWidget {
  final String value, label;
  final GeoIconKind icon;
  const _HomeStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    radius: 18,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GeoIcon(icon, size: 30),
        const SizedBox(height: 10),
        Text(value, style: T.number),
        const SizedBox(height: 2),
        Text(
          label,
          style: T.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class ProjectCard extends StatelessWidget {
  final Json project;
  final int index;
  final AppController controller;
  final bool fullWidth;
  const ProjectCard(
    this.project, {
    super.key,
    required this.index,
    required this.controller,
    this.fullWidth = false,
  });
  @override
  Widget build(BuildContext context) {
    final tasks = controller.projectTasks(project['id']);
    final done = tasks.where((t) => t['status'] == 'done').length;
    final pct = tasks.isEmpty ? 0.0 : done / tasks.length;
    final gradient = switch (index % 3) {
      0 => C.brandGradient,
      1 => C.violetGradient,
      _ => C.tealGradient,
    };

    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: gradient),
        child: InkWell(
          onTap: () => context.push('/projects/${project['id']}'),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -54,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .14),
                      width: 18,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize:
                      fullWidth ? MainAxisSize.min : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProjectAvatar(
                          textOf(project, 'avatar'),
                          size: 42,
                          onDark: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textOf(project, 'name'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: T.h2.copyWith(
                                  color: Colors.white,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                textOf(
                                  project,
                                  'courseLabel',
                                  'Proyek kelompok',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: T.caption.copyWith(
                                  color: Colors.white.withValues(alpha: .84),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const GeoIcon(GeoIconKind.arrowUpRight, size: 22),
                      ],
                    ),
                    if (fullWidth)
                      const SizedBox(height: S.lg)
                    else
                      const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GeoIcon(
                                controller.owner(project['id'])
                                    ? GeoIconKind.crown
                                    : GeoIconKind.users,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                controller.owner(project['id'])
                                    ? 'Ketua'
                                    : 'Anggota',
                                style: T.caption.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ...stringsOf(project, 'memberIds')
                            .take(3)
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (e) => Align(
                                widthFactor: .76,
                                child: Avatar(
                                  controller.name(e.value),
                                  size: 28,
                                  index: e.key,
                                  avatarDataUrl: controller.avatarOf(e.value),
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        color: Colors.white,
                        backgroundColor: Colors.white24,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$done dari ${tasks.length} tugas selesai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.caption.copyWith(
                              color: Colors.white.withValues(alpha: .9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).round()}%',
                          style: T.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return fullWidth ? card : SizedBox(width: 286, child: card);
  }
}

class TaskTile extends StatelessWidget {
  final Json task;
  final AppController controller;
  const TaskTile(this.task, {super.key, required this.controller});

  Future<void> _remove(BuildContext context) async {
    if (!await confirm(
          context,
          'Hapus tugas?',
          '“${textOf(task, 'title')}” akan hilang dari daftar. Riwayatnya tetap tersimpan.',
        ) ||
        !context.mounted) {
      return;
    }
    try {
      await controller.act('removeTask', {
        'projectId': task['projectId'],
        'taskId': task['id'],
        'version': task['version'],
      });
      if (context.mounted) toast(context, 'Tugas dihapus.');
    } catch (e) {
      if (context.mounted) toast(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = textOf(task, 'status');
    final (tint, accent, _) = statusVisual(status);
    final geoKind = switch (status) {
      'done' => GeoIconKind.checkCircle,
      'submitted' => GeoIconKind.review,
      'revision_requested' => GeoIconKind.sync,
      'in_progress' => GeoIconKind.clipboard,
      _ => GeoIconKind.clipboardTodo,
    };
    return Surface(
      onTap: () => context.push('/tasks/${task['id']}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GeoIcon(geoKind, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textOf(task, 'title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: T.bodyStrong.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Pill(statusLabel(task), color: tint, foreground: accent),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GeoIcon(GeoIconKind.calendar, size: 14),
                        const SizedBox(width: 4),
                        Text(dateLabel(task['dueAt']), style: T.caption),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (controller.repository is SupabaseTeamRepository &&
              controller.owner(textOf(task, 'projectId')) &&
              controller.project(textOf(task, 'projectId'))?['status'] ==
                  'active')
            IconButton(
              tooltip: 'Hapus tugas',
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide.none,
              ),
              onPressed: controller.busy ? null : () => _remove(context),
              icon: Icon(
                LucideIcons.trash2,
                size: 18,
                color: Theme.of(context).colorScheme.error,
              ),
            )
          else
            const GeoIcon(GeoIconKind.chevronRight, size: 18),
        ],
      ),
    );
  }
}

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsState();
}

class _ProjectsState extends ConsumerState<ProjectsScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final all =
        c.projects
            .where(
              (p) =>
                  textOf(p, 'name').toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    return PageFrame(
      title: 'Semua proyek',
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Cari nama proyek...',
              prefixIcon: Icon(LucideIcons.search, size: 18, color: C.muted),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: S.lg),
          if (all.isEmpty)
            const Surface(
              child: EmptyState(
                'Proyek belum ditemukan',
                'Coba kata lain atau buat proyek pertama.',
              ),
            ),
          ...all.map((p) {
            final pTasks = c.projectTasks(p['id']);
            final done = pTasks.where((t) => t['status'] == 'done').length;
            final pct = pTasks.isEmpty ? 0.0 : done / pTasks.length;
            final isActive = p['status'] == 'active';
            return Padding(
              padding: const EdgeInsets.only(bottom: S.md),
              child: Surface(
                onTap: () => context.push('/projects/${p['id']}'),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProjectAvatar(textOf(p, 'avatar'), size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(textOf(p, 'name'), style: T.title),
                              const SizedBox(height: 3),
                              Text(
                                '${stringsOf(p, 'memberIds').length} anggota · ${textOf(p, 'courseLabel', 'Proyek tim')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: T.caption,
                              ),
                            ],
                          ),
                        ),
                        Pill(
                          isActive ? 'Aktif' : 'Arsip',
                          color: isActive ? C.lime : C.panel,
                          foreground: isActive ? C.teal : C.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        color: C.blue,
                        backgroundColor: C.sky,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$done dari ${pTasks.length} tugas selesai',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.caption,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(pct * 100).round()}%',
                          style: T.caption.copyWith(
                            color: C.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: S.sm),
          PrimaryButton(
            'Buat proyek',
            icon: LucideIcons.folderPlus,
            onPressed: () => context.push('/projects/new'),
          ),
        ],
      ),
    );
  }
}

class ProjectFormScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const ProjectFormScreen({super.key, this.projectId});
  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<ProjectFormScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      desc = TextEditingController(),
      course = TextEditingController();
  DateTime? target;
  DateTime? _initialTarget;
  String avatar = 'folder';
  String? selectedTemplateId;
  bool pickingAvatar = false;
  String? error;
  bool busy = false, review = false;

  void _applyTemplate(ProjectTemplate tpl) {
    setState(() {
      selectedTemplateId = tpl.id;
      avatar = tpl.avatarKey;
      course.text = tpl.courseLabel;
      desc.text = tpl.descriptionTemplate;
    });
  }

  @override
  void initState() {
    super.initState();
    final p = ref.read(controllerProvider).project(widget.projectId ?? '');
    if (p != null) {
      name.text = textOf(p, 'name');
      desc.text = textOf(p, 'description');
      course.text = textOf(p, 'courseLabel');
      target = dateOf(p, 'targetDate');
      _initialTarget = target;
      final savedAvatar = textOf(p, 'avatar');
      if (savedAvatar.isNotEmpty) avatar = savedAvatar;
    }
  }

  @override
  void dispose() {
    name.dispose();
    desc.dispose();
    course.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (target != _initialTarget && isPastDate(target)) {
      setState(
        () =>
            error =
                'Target selesai tidak boleh menggunakan tanggal yang sudah lewat.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final c = ref.read(controllerProvider);
      final p = await c
          .act(widget.projectId == null ? 'createProject' : 'saveProject', {
            'projectId': widget.projectId,
            'name': name.text.trim(),
            'description': desc.text.trim(),
            'courseLabel': course.text.trim(),
            'targetDate': target?.toUtc().toIso8601String(),
            if (c.repository is SupabaseTeamRepository) 'avatar': avatar,
          });
      if (mounted) {
        context.go('/projects/${p['id']}');
        toast(
          context,
          widget.projectId == null
              ? 'Proyek berhasil dibuat. Undang teman dari halaman proyek.'
              : 'Pengaturan proyek tersimpan.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _pickAvatar() async {
    setState(() => pickingAvatar = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 384,
        maxHeight: 384,
        imageQuality: 76,
        requestFullMetadata: false,
      );
      if (picked == null) return;
      final Uint8List bytes = await picked.readAsBytes();
      final type = detectEvidencePhoto(bytes);
      if (!mounted) return;
      if (type == null || bytes.length > 134000) {
        toast(context, 'Pilih JPG, PNG, atau WebP yang lebih kecil.');
        return;
      }
      setState(
        () => avatar = 'data:${type.mimeType};base64,${base64Encode(bytes)}',
      );
    } catch (_) {
      if (mounted) toast(context, 'Foto proyek belum dapat dipilih.');
    } finally {
      if (mounted) setState(() => pickingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    if (widget.projectId != null && !c.owner(widget.projectId!)) {
      return const PageFrame(
        title: 'Pengaturan',
        child: EmptyState(
          'Akses terbatas',
          'Pengaturan hanya dapat diubah ketua proyek.',
        ),
      );
    }
    return PageFrame(
      title:
          review
              ? 'Tinjau proyek'
              : widget.projectId == null
              ? 'Proyek baru'
              : 'Pengaturan proyek',
      child: ContentList(
        children: [
          if (!review)
            PageHeader(
              'Mulai sesuatu\nyang berarti.',
              subtitle: 'Buat ruang untuk ide, langkah, dan hasil bersama.',
              trailing: const FloatingArt('project-folder', height: 84),
            ),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: S.lg),
          ],
          if (review)
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (c.repository is SupabaseTeamRepository)
                        _ProjectAvatar(avatar)
                      else
                        const Pill(
                          'TINJAU SEBELUM MEMBUAT',
                          color: C.sky,
                          foreground: C.blue,
                        ),
                    ],
                  ),
                  const SizedBox(height: S.lg),
                  Text(name.text, style: T.h1),
                  const SizedBox(height: S.sm),
                  Text(desc.text, style: T.body),
                  const Divider(height: 28),
                  if (course.text.isNotEmpty) ...[
                    Text(course.text, style: T.bodyStrong),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'Target selesai: ${dateLabel(target?.toIso8601String())}',
                    style: T.small,
                  ),
                ],
              ),
            )
          else
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.projectId == null) ...[
                    Surface(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Template proyek berdampak (opsional)',
                            style: T.bodyStrong,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pilih fokus proyek agar konteks, ikon, dan saran langkah awal terisi otomatis.',
                            style: T.caption,
                          ),
                          const SizedBox(height: S.md),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tpl in kProjectTemplates)
                                ChoiceChip(
                                  avatar: Icon(
                                    (_projectIcons[tpl.avatarKey] ??
                                            _projectIcons['folder']!)
                                        .$2,
                                    size: 16,
                                    color:
                                        selectedTemplateId == tpl.id
                                            ? Colors.white
                                            : (_projectIcons[tpl.avatarKey] ??
                                                    _projectIcons['folder']!)
                                                .$3,
                                  ),
                                  showCheckmark: false,
                                  selectedColor: C.blue,
                                  labelStyle: TextStyle(
                                    color:
                                        selectedTemplateId == tpl.id
                                            ? Colors.white
                                            : C.ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  label: Text(tpl.label),
                                  selected: selectedTemplateId == tpl.id,
                                  onSelected: (_) => _applyTemplate(tpl),
                                ),
                            ],
                          ),
                          if (selectedTemplateId != null) ...[
                            const SizedBox(height: S.md),
                            Builder(
                              builder: (_) {
                                final tpl = kProjectTemplates.firstWhere(
                                  (t) => t.id == selectedTemplateId,
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Pill(
                                      tpl.sdgTag,
                                      color: C.lime,
                                      foreground: C.teal,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${tpl.subtitle} Termasuk ${tpl.starterTasks.length} saran langkah awal setelah proyek dibuat.',
                                      style: T.caption.copyWith(color: C.ink2),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: S.lg),
                  ],
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nama proyek'),
                    validator: (v) => requiredText(v, max: 120),
                  ),
                  if (c.repository is SupabaseTeamRepository) ...[
                    const SectionTitle('Ikon atau foto proyek'),
                    Surface(
                      child: Column(
                        children: [
                          _ProjectAvatar(avatar, size: 56),
                          const SizedBox(height: S.md),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final entry in _projectIcons.entries)
                                ChoiceChip(
                                  avatar: Icon(
                                    entry.value.$2,
                                    color:
                                        avatar == entry.key
                                            ? Colors.white
                                            : entry.value.$3,
                                    size: 18,
                                  ),
                                  showCheckmark: false,
                                  selectedColor: C.blue,
                                  labelStyle: TextStyle(
                                    color:
                                        avatar == entry.key
                                            ? Colors.white
                                            : C.ink2,
                                  ),
                                  label: Text(entry.value.$1),
                                  selected: avatar == entry.key,
                                  onSelected:
                                      pickingAvatar
                                          ? null
                                          : (_) => setState(
                                            () => avatar = entry.key,
                                          ),
                                ),
                            ],
                          ),
                          const SizedBox(height: S.sm),
                          TextButton.icon(
                            onPressed: pickingAvatar ? null : _pickAvatar,
                            icon: const Icon(LucideIcons.imagePlus, size: 16),
                            label: const Text('Pilih foto proyek'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: S.md),
                  TextFormField(
                    controller: desc,
                    decoration: const InputDecoration(
                      labelText: 'Tentang proyek',
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: (v) => requiredText(v, max: 2000),
                  ),
                  const SizedBox(height: S.md),
                  TextFormField(
                    controller: course,
                    decoration: const InputDecoration(
                      labelText: 'Konteks / Mata kuliah / Program (opsional)',
                    ),
                    maxLength: 120,
                  ),
                  const SizedBox(height: S.sm),
                  Surface(
                    padding: const EdgeInsets.all(14),
                    onTap: () async {
                      final minimumDate = today();
                      final suggestedDate = DateTime.now().add(
                        const Duration(days: 14),
                      );
                      final day = await showDatePicker(
                        context: context,
                        initialDate:
                            target != null && !isPastDate(target)
                                ? target!
                                : suggestedDate,
                        firstDate: minimumDate,
                        lastDate: DateTime(2100),
                      );
                      if (day != null) {
                        setState(
                          () =>
                              target = DateTime(
                                day.year,
                                day.month,
                                day.day,
                                23,
                                59,
                              ),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        const IconBadge(
                          LucideIcons.calendarDays,
                          tint: C.sky,
                          iconColor: C.blue,
                          size: 38,
                        ),
                        const SizedBox(width: S.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Target selesai', style: T.caption),
                              Text(
                                target == null
                                    ? 'Pilih tanggal (opsional)'
                                    : dateLabel(target!.toIso8601String()),
                                style: T.bodyStrong,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: C.subtle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: S.xl),
          PrimaryButton(
            review
                ? 'Konfirmasi & buat proyek'
                : widget.projectId == null
                ? 'Tinjau detail'
                : 'Simpan perubahan',
            busy: busy,
            onPressed:
                pickingAvatar
                    ? null
                    : () {
                      if (review) {
                        save();
                      } else if (form.currentState!.validate()) {
                        if (widget.projectId != null) {
                          save();
                        } else {
                          setState(() => review = true);
                        }
                      }
                    },
          ),
          if (review)
            Center(
              child: TextButton(
                onPressed: busy ? null : () => setState(() => review = false),
                child: const Text('Ubah detail'),
              ),
            ),
          if (widget.projectId != null) ...[
            const SizedBox(height: S.lg),
            OutlinedButton.icon(
              onPressed: () async {
                final p = c.project(widget.projectId!)!;
                final archived = p['status'] == 'archived';
                if (await confirm(
                  context,
                  archived ? 'Buka kembali proyek?' : 'Arsipkan proyek?',
                  archived
                      ? 'Anggota dapat memperbarui tugas kembali.'
                      : 'Riwayat tetap tersimpan. Tugas tidak dapat diperbarui selama diarsipkan.',
                )) {
                  try {
                    await c.act('saveProject', {
                      'projectId': p['id'],
                      'name': p['name'],
                      'status': archived ? 'active' : 'archived',
                    });
                    if (context.mounted) context.pop();
                  } catch (e) {
                    if (mounted) setState(() => error = errorMessage(e));
                  }
                }
              },
              icon: const Icon(LucideIcons.archive, size: 18),
              label: Text(
                c.project(widget.projectId!)?['status'] == 'archived'
                    ? 'Buka kembali proyek'
                    : 'Arsipkan proyek',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class JoinScreen extends ConsumerStatefulWidget {
  final String initialCode;
  const JoinScreen({super.key, this.initialCode = ''});
  @override
  ConsumerState<JoinScreen> createState() => _JoinState();
}

class _JoinState extends ConsumerState<JoinScreen> {
  late final TextEditingController code = TextEditingController(
    text: widget.initialCode,
  );
  Json? preview;
  String? error;
  bool busy = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> run(bool join) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref.read(controllerProvider).act(
        join ? 'joinProject' : 'previewInvite',
        {'code': code.text.trim()},
      );
      if (mounted) {
        if (join) {
          context.go('/projects/${result['id']}');
          toast(context, 'Kamu sudah bergabung. Selamat berkolaborasi!');
        } else {
          setState(() => preview = result);
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const InviteQrScannerScreen()),
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;
    setState(() {
      code.text = scanned;
      preview = null;
      error = null;
    });
    await run(false);
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Gabung proyek',
    child: ContentList(
      children: [
        const PageHeader(
          'Temukan\nruang timmu.',
          subtitle:
              'Masukkan kode atau pindai QR dari ketua. Kamu bisa melihat ringkasan sebelum bergabung.',
          trailing: BrandLogo(size: 56),
        ),
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Kode undangan',
            hintText: 'Contoh: JEJAK2026',
            prefixIcon: Icon(LucideIcons.scanLine, size: 18, color: C.blue),
          ),
          onChanged: (_) => setState(() => preview = null),
        ),
        const SizedBox(height: S.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : _scanQr,
            icon: const Icon(LucideIcons.qrCode, size: 18),
            label: const Text('Pindai QR undangan'),
          ),
        ),
        const SizedBox(height: S.lg),
        if (error != null) ...[
          ErrorBanner(error!),
          const SizedBox(height: S.lg),
        ],
        if (preview != null) ...[
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pill('PRATINJAU PROYEK', color: C.sky, foreground: C.blue),
                const SizedBox(height: S.md),
                Text(textOf(preview!, 'name'), style: T.h2),
                const SizedBox(height: 6),
                Text(textOf(preview!, 'description'), style: T.body),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(LucideIcons.crown, size: 15, color: C.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Ketua: ${preview!['ownerName']}',
                        style: T.bodyStrong,
                      ),
                    ),
                    Text(
                      '${preview!['memberCount']} anggota',
                      style: T.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: S.lg),
        ],
        PrimaryButton(
          preview == null ? 'Lihat proyek' : 'Konfirmasi bergabung',
          onPressed: () => run(preview != null),
          busy: busy,
        ),
      ],
    ),
  );
}

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final String tab;
  const ProjectDetailScreen(this.id, {super.key, this.tab = 'Ringkasan'});
  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailState();
}

class _ProjectDetailState extends ConsumerState<ProjectDetailScreen> {
  late String tab = widget.tab;
  String? error;
  bool inviteBusy = false;
  Future<void> invite(AppController c) async {
    setState(() => inviteBusy = true);
    try {
      if (!await confirm(
        context,
        'Buat kode undangan baru?',
        'Kode sebelumnya akan dicabut. Kode baru berlaku 7 hari dan ditampilkan sekali.',
      )) {
        return;
      }
      final result = await c.act('createInvite', {'projectId': widget.id});
      if (!mounted) return;
      final projectName = textOf(c.project(widget.id) ?? {}, 'name');
      await showDialog<void>(
        context: context,
        builder:
            (_) => InviteQrDialog(
              projectName: projectName,
              code: textOf(result, 'code'),
            ),
      );
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => inviteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final p = c.project(widget.id);
    if (p == null) {
      return const PageFrame(
        title: 'Proyek',
        child: EmptyState(
          'Akses tidak tersedia',
          'Proyek tidak ditemukan atau keanggotaanmu sudah berubah.',
          icon: LucideIcons.shieldAlert,
        ),
      );
    }
    final tasks = c.projectTasks(widget.id);
    final stats = aggregateTasks(tasks, DateTime.now());
    final members = stringsOf(p, 'memberIds');
    final isOwner = c.owner(widget.id);
    final pct = tasks.isEmpty ? 0.0 : stats['done'] / tasks.length;

    return PageFrame(
      title: 'Proyek',
      actions: [
        if (isOwner)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Pengaturan proyek',
              onPressed: () => context.push('/projects/${widget.id}/settings'),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                backgroundColor: Colors.white,
                side: const BorderSide(color: C.line),
              ),
              icon: const GeoIcon(GeoIconKind.settings, size: 20),
            ),
          ),
      ],
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          // Gradient Project Header Card
          Reveal(
            child: Surface(
              gradient: C.brandGradient,
              padding: const EdgeInsets.all(18),
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProjectAvatar(
                        textOf(p, 'avatar'),
                        size: 52,
                        onDark: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              textOf(p, 'name'),
                              style: T.h1.copyWith(color: Colors.white),
                            ),
                            if (textOf(p, 'courseLabel').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                textOf(p, 'courseLabel'),
                                style: T.small.copyWith(
                                  color: Colors.white.withValues(alpha: .86),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (p['status'] == 'archived') ...[
                    const SizedBox(height: S.md),
                    const Pill(
                      'Proyek diarsipkan',
                      color: C.amber,
                      foreground: C.orange,
                    ),
                  ],
                  const SizedBox(height: S.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _ProjectMetaCell(
                              icon:
                                  isOwner
                                      ? GeoIconKind.crown
                                      : GeoIconKind.profile,
                              label: isOwner ? 'Ketua' : 'Anggota',
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: Colors.white.withValues(alpha: .22),
                          ),
                          Expanded(
                            child: _ProjectMetaCell(
                              icon: GeoIconKind.users,
                              label: '${members.length} anggota',
                            ),
                          ),
                          if (isOwner) ...[
                            VerticalDivider(
                              width: 1,
                              color: Colors.white.withValues(alpha: .22),
                            ),
                            Expanded(
                              child: Semantics(
                                button: true,
                                label: 'Buat kode undangan',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: inviteBusy ? null : () => invite(c),
                                  child: const _ProjectMetaCell(
                                    icon: GeoIconKind.userPlus,
                                    label: 'Undang',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: S.lg),

          // Tab strip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...['Ringkasan', 'Tugas', 'Anggota', 'Aktivitas'].map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: tab == t,
                      onSelected: (_) => setState(() => tab = t),
                      showCheckmark: false,
                      selectedColor: C.blue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: tab == t ? Colors.white : C.ink2,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: tab == t ? C.blue : C.line,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                if (c.repository is SupabaseTeamRepository &&
                    members.contains(c.uid))
                  ActionChip(
                    avatar: const Icon(
                      LucideIcons.messageCircle,
                      size: 16,
                      color: C.blue,
                    ),
                    label: const Text('Chat proyek'),
                    backgroundColor: C.sky,
                    labelStyle: const TextStyle(
                      color: C.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: const StadiumBorder(
                      side: BorderSide(color: Colors.transparent),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProjectChatScreen(widget.id),
                          ),
                        ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: S.lg),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: S.lg),
          ],
          ...switch (tab) {
            'Tugas' => [
              if (isOwner && p['status'] == 'active') ...[
                PrimaryButton(
                  'Buat tugas',
                  icon: LucideIcons.plus,
                  onPressed:
                      () => context.push('/projects/${widget.id}/tasks/new'),
                ),
                const SizedBox(height: S.lg),
                if (tasks.length < 3)
                  Builder(
                    builder: (_) {
                      final tpl = inferTemplateForProject(p);
                      final existingTitles =
                          tasks
                              .map((t) => textOf(t, 'title').toLowerCase())
                              .toSet();
                      final suggestions =
                          tpl.starterTasks
                              .where(
                                (idea) =>
                                    !existingTitles.contains(
                                      idea.title.toLowerCase(),
                                    ),
                              )
                              .toList();
                      if (suggestions.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: S.lg),
                        child: Surface(
                          color: C.panel,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Saran langkah awal',
                                    style: T.bodyStrong,
                                  ),
                                  Pill(
                                    tpl.label,
                                    color: C.lime,
                                    foreground: C.teal,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              for (final idea in suggestions)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Surface(
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    radius: 14,
                                    onTap: () {
                                      final q = Uri(
                                        queryParameters: {
                                          'title': idea.title,
                                          'desc': idea.description,
                                        },
                                      ).query;
                                      context.push(
                                        '/projects/${widget.id}/tasks/new?$q',
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                idea.title,
                                                style: T.bodyStrong.copyWith(
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                idea.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: T.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pakai',
                                          style: T.caption.copyWith(
                                            color: C.blue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
              if (tasks.isEmpty)
                const Surface(
                  child: EmptyState(
                    'Belum ada tugas',
                    'Mulai dengan satu langkah yang jelas.',
                  ),
                ),
              ...tasks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskTile(t, controller: c),
                ),
              ),
            ],
            'Anggota' => [
              ...members.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Surface(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Avatar(
                          c.name(e.value),
                          size: 42,
                          index: e.key,
                          avatarDataUrl: c.avatarOf(e.value),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name(e.value), style: T.title),
                              const SizedBox(height: 2),
                              Pill(
                                e.value == p['ownerId']
                                    ? 'Ketua proyek'
                                    : 'Anggota',
                                color:
                                    e.value == p['ownerId'] ? C.sky : C.panel,
                                foreground:
                                    e.value == p['ownerId'] ? C.blue : C.muted,
                              ),
                            ],
                          ),
                        ),
                        if (isOwner && e.value != c.uid)
                          IconButton(
                            tooltip: 'Keluarkan anggota',
                            icon: const Icon(
                              LucideIcons.userMinus,
                              size: 18,
                              color: C.muted,
                            ),
                            onPressed: () async {
                              if (await confirm(
                                context,
                                'Keluarkan anggota?',
                                'Akses proyek akan dicabut. Tugas aktif harus dialihkan terlebih dahulu.',
                              )) {
                                try {
                                  await c.act('removeMember', {
                                    'projectId': widget.id,
                                    'memberId': e.value,
                                  });
                                } catch (ex) {
                                  if (mounted) {
                                    setState(() => error = errorMessage(ex));
                                  }
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            'Aktivitas' => [
              if (c.activity.where((a) => a['projectId'] == widget.id).isEmpty)
                const Surface(
                  child: EmptyState(
                    'Belum ada aktivitas',
                    'Langkah tim akan tercatat di sini.',
                  ),
                ),
              ...c.activity
                  .where((a) => a['projectId'] == widget.id)
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Surface(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Avatar(
                              c.name(a['actorId']),
                              size: 34,
                              avatarDataUrl: c.avatarOf(a['actorId']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name(a['actorId']),
                                    style: T.bodyStrong.copyWith(color: C.blue),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(activitySummary(a), style: T.body),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateLabel(a['createdAt'], time: true),
                                    style: T.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
            _ => [
              // Overview card
              Surface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(
                      inferTemplateForProject(p).sdgTag,
                      color: C.lime,
                      foreground: C.teal,
                      icon: LucideIcons.sprout,
                    ),
                    if (textOf(p, 'description').isNotEmpty) ...[
                      const SizedBox(height: S.md),
                      Text(textOf(p, 'description'), style: T.body),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: S.md),

              // Progress + Target Bento Row
              Surface(
                color: C.sky,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Progres proyek', style: T.bodyStrong),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: T.number.copyWith(color: C.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pct,
                        color: C.blue,
                        backgroundColor: Colors.white,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${stats['done']} dari ${tasks.length} tugas selesai · ${stats['review']} menunggu review',
                      style: T.caption.copyWith(color: C.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.md),
              Surface(
                color: C.lime,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const GeoIcon(GeoIconKind.calendar, size: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target bersama',
                            style: T.caption.copyWith(color: C.teal),
                          ),
                          const SizedBox(height: 2),
                          Text(dateLabel(p['targetDate']), style: T.h2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.purple,
                        backgroundColor: C.lavender,
                        side: BorderSide.none,
                      ),
                      onPressed: () => context.push('/insights/${widget.id}'),
                      icon: const GeoIcon(GeoIconKind.star, size: 18),
                      label: const Text('Insight'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.blue,
                        backgroundColor: C.sky,
                        side: BorderSide.none,
                      ),
                      onPressed: () => context.push('/reports/${widget.id}'),
                      icon: const GeoIcon(GeoIconKind.document, size: 18),
                      label: const Text('Laporan'),
                    ),
                  ),
                ],
              ),
              const SectionTitle('Dekat dengan tenggat'),
              ...([...tasks]..sort(
                    (a, b) => textOf(
                      a,
                      'dueAt',
                      '9999',
                    ).compareTo(textOf(b, 'dueAt', '9999')),
                  ))
                  .where((t) => !['done', 'cancelled'].contains(t['status']))
                  .take(3)
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskTile(t, controller: c),
                    ),
                  ),
            ],
          },
        ],
      ),
    );
  }
}

class _ProjectMetaCell extends StatelessWidget {
  final GeoIconKind icon;
  final String label;
  const _ProjectMetaCell({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GeoIcon(icon, size: 22),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: T.caption.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}
