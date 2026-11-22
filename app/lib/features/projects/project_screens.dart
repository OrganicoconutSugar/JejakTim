import '../../core/illustrated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/layout.dart';

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
    return PageFrame(
      navIndex: 0,
      child: Builder(
        builder:
            (bodyContext) => RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(
                padding: EdgeInsets.only(
                  top: 24,
                  bottom: 24 + MediaQuery.paddingOf(bodyContext).bottom,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const BrandLogo(size: 42),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'JejakTim',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ),
                            CircleAction(
                              LucideIcons.bell,
                              label: 'Notifikasi',
                              onTap: () => context.push('/notifications'),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => context.go('/profile'),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Avatar(
                                  textOf(c.profile, 'name'),
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Halo, ${textOf(c.profile, 'name', 'Teman').split(' ').first}. Siap melangkah?',
                          style: const TextStyle(color: C.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kerja bareng.\nKontribusi terlihat.',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final create = FilledButton.icon(
                              onPressed: () => context.push('/projects/new'),
                              icon: const AppIcon(
                                LucideIcons.folderPlus,
                                size: 18,
                              ),
                              label: const Text('Buat proyek baru'),
                            );
                            final join = OutlinedButton.icon(
                              onPressed:
                                  () => context.push(
                                    '/projects/join?code=${Uri.encodeComponent(code.text)}',
                                  ),
                              icon: const AppIcon(
                                LucideIcons.scanLine,
                                size: 18,
                              ),
                              label: const Text('Gabung dengan kode'),
                            );
                            return Column(
                              children: [
                                if (constraints.maxWidth < 420) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: create,
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(width: double.infinity, child: join),
                                ] else
                                  Row(
                                    children: [
                                      Expanded(child: create),
                                      const SizedBox(width: 10),
                                      Expanded(child: join),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: code,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    labelText: 'Kode undangan (opsional)',
                                    hintText: 'Contoh: JEJAK2026',
                                    prefixIcon: AppIcon(LucideIcons.keyRound),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                  ),
                                  onSubmitted:
                                      (value) => context.push(
                                        '/projects/join?code=${Uri.encodeComponent(value)}',
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                        SectionTitle(
                          'Proyekmu',
                          action: 'Lihat semua',
                          onTap: () => context.push('/projects'),
                        ),
                      ],
                    ),
                  ),
                  if (active.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: EmptyState(
                        'Mulai dari satu proyek',
                        'Ajak teman dan bagi langkah pertama bersama.',
                        action: FilledButton(
                          onPressed: () => context.push('/projects/new'),
                          child: const Text('Buat proyek'),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height:
                          268 *
                          (MediaQuery.textScalerOf(context).scale(14) / 14)
                              .clamp(1.0, 2.0),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: active.length,
                        separatorBuilder: (_, i) => const SizedBox(width: 16),
                        itemBuilder:
                            (context, i) =>
                                ProjectCard(active[i], index: i, controller: c),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Surface(
                          color: C.panel,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              _stat(
                                '${active.length}',
                                'Proyek aktif',
                                LucideIcons.layers,
                              ),
                              _stat(
                                '${stats['done']}',
                                'Tugas selesai',
                                LucideIcons.checkCircle2,
                              ),
                              _stat(
                                '${stats['review']}',
                                'Perlu review',
                                LucideIcons.messagesSquare,
                              ),
                            ],
                          ),
                        ),
                        SectionTitle(
                          'Langkah terdekat',
                          action: 'Semua tugas',
                          onTap: () => context.go('/tasks'),
                        ),
                        if (mine.isEmpty)
                          const EmptyState(
                            'Semua terkendali',
                            'Belum ada tugas aktif untukmu.',
                            icon: LucideIcons.checkCircle2,
                          )
                        else
                          ...mine
                              .take(3)
                              .map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskTile(t, controller: c),
                                ),
                              ),
                        const SizedBox(height: 8),
                        Surface(
                          color: C.lavender,
                          onTap: () => context.go('/insights'),
                          child: Row(
                            children: [
                              const DimensionalIcon(
                                LucideIcons.sparkles,
                                color: C.purple,
                                size: 48,
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pahami ritme kerja tim',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Lihat progres & hal yang perlu perhatian',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: C.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const AppIcon(LucideIcons.arrowUpRight, size: 20),
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

  Widget _stat(String value, String label, IconData icon) => Expanded(
    child: Column(
      children: [
        DimensionalIcon(
          icon,
          size: 34,
          color:
              icon == LucideIcons.layers
                  ? C.blue
                  : icon == LucideIcons.checkCircle2
                  ? const Color(0xFF198E79)
                  : C.purple,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: C.muted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class ProjectCard extends StatelessWidget {
  final Json project;
  final int index;
  final AppController controller;
  const ProjectCard(
    this.project, {
    super.key,
    required this.index,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) {
    final tasks = controller.projectTasks(project['id']);
    final done = tasks.where((t) => t['status'] == 'done').length;
    final pct = tasks.isEmpty ? 0.0 : done / tasks.length;
    final color = index.isEven ? C.blue : C.purple;
    return SizedBox(
      width: 272,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/projects/${project['id']}'),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -74,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .15),
                      width: 22,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DimensionalIcon(
                          index.isEven
                              ? LucideIcons.layers
                              : LucideIcons.sprout,
                          size: 46,
                          color:
                              index.isEven
                                  ? const Color(0xFF59A8FF)
                                  : const Color(0xFFB390F7),
                        ),
                        const Spacer(),
                        AppIcon(
                          LucideIcons.arrowUpRight,
                          color: Colors.white.withValues(alpha: .9),
                          size: 23,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      textOf(project, 'name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        height: 1.12,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      textOf(project, 'courseLabel', 'Proyek kelompok'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        AppIcon(
                          controller.owner(project['id'])
                              ? LucideIcons.crown
                              : LucideIcons.users,
                          size: 17,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.owner(project['id']) ? 'Ketua' : 'Anggota',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
                                widthFactor: .78,
                                child: Avatar(
                                  controller.name(e.value),
                                  size: 29,
                                  index: e.key,
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: pct,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$done dari ${tasks.length} tugas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${(pct * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
  }
}

class TaskTile extends StatelessWidget {
  final Json task;
  final AppController controller;
  const TaskTile(this.task, {super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final status = textOf(task, 'status');
    final color = switch (status) {
      'done' => C.lime,
      'submitted' => C.lavender,
      'revision_requested' => C.amber,
      _ => C.sky,
    };
    return Surface(
      onTap: () => context.push('/tasks/${task['id']}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DimensionalIcon(
            status == 'done'
                ? LucideIcons.check
                : status == 'submitted'
                ? LucideIcons.messageCircle
                : status == 'revision_requested'
                ? LucideIcons.rotateCcw
                : LucideIcons.clipboardList,
            size: 44,
            color:
                status == 'done'
                    ? const Color(0xFF198E79)
                    : status == 'submitted'
                    ? C.purple
                    : status == 'revision_requested'
                    ? const Color(0xFFC77C16)
                    : C.blue,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textOf(task, 'title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateLabel(task['dueAt']),
                  style: const TextStyle(fontSize: 12, color: C.muted),
                ),
                const SizedBox(height: 9),
                Pill(statusLabel(task), color: color),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const AppIcon(LucideIcons.chevronRight, size: 18, color: C.muted),
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
              labelText: 'Cari proyek',
              prefixIcon: AppIcon(LucideIcons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 20),
          if (all.isEmpty)
            const EmptyState(
              'Proyek belum ditemukan',
              'Coba kata lain atau buat proyek pertama.',
            ),
          ...all.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                onTap: () => context.push('/projects/${p['id']}'),
                child: Row(
                  children: [
                    const BrandLogo(size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            textOf(p, 'name'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${stringsOf(p, 'memberIds').length} anggota · ${p['status'] == 'active' ? 'Aktif' : 'Diarsipkan'}',
                            style: const TextStyle(
                              color: C.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppIcon(LucideIcons.chevronRight, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Buat proyek',
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
  String? error;
  bool busy = false, review = false;
  @override
  void initState() {
    super.initState();
    final p = ref.read(controllerProvider).project(widget.projectId ?? '');
    if (p != null) {
      name.text = textOf(p, 'name');
      desc.text = textOf(p, 'description');
      course.text = textOf(p, 'courseLabel');
      target = dateOf(p, 'targetDate');
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
          if (!review) ...[
            const FloatingArt('project-folder', height: 150),
            Text(
              'Mulai sesuatu\nyang berarti.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Buat ruang untuk ide, langkah, dan hasil bersama.',
              style: TextStyle(color: C.muted),
            ),
            const SizedBox(height: 28),
          ],
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: 16),
          ],
          if (review)
            Surface(
              color: C.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Pill('TINJAU SEBELUM MEMBUAT', color: C.sky),
                  const SizedBox(height: 20),
                  Text(
                    name.text,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(desc.text),
                  const SizedBox(height: 20),
                  Text(course.text),
                  const SizedBox(height: 8),
                  Text(dateLabel(target?.toIso8601String())),
                ],
              ),
            )
          else
            Form(
              key: form,
              child: Column(
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nama proyek'),
                    validator: (v) => requiredText(v, max: 120),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: desc,
                    decoration: const InputDecoration(
                      labelText: 'Tentang proyek',
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: (v) => requiredText(v, max: 2000),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: course,
                    decoration: const InputDecoration(
                      labelText: 'Mata kuliah (opsional)',
                    ),
                    maxLength: 120,
                  ),
                  const SizedBox(height: 12),
                  Surface(
                    onTap: () async {
                      final day = await showDatePicker(
                        context: context,
                        initialDate:
                            target ??
                            DateTime.now().add(const Duration(days: 14)),
                        firstDate: DateTime(2020),
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
                        const AppIcon(LucideIcons.calendarDays, color: C.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            target == null
                                ? 'Pilih target selesai (opsional)'
                                : dateLabel(target!.toIso8601String()),
                          ),
                        ),
                        const AppIcon(LucideIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            review
                ? 'Konfirmasi & buat proyek'
                : widget.projectId == null
                ? 'Tinjau detail'
                : 'Simpan perubahan',
            busy: busy,
            onPressed: () {
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
            TextButton(
              onPressed: busy ? null : () => setState(() => review = false),
              child: const Text('Ubah detail'),
            ),
          if (widget.projectId != null) ...[
            const SizedBox(height: 20),
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
              icon: const AppIcon(LucideIcons.archive),
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

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Gabung proyek',
    child: ContentList(
      children: [
        const SizedBox(height: 20),
        const BrandLogo(size: 72),
        const SizedBox(height: 28),
        Text(
          'Temukan\nruang timmu.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        const Text(
          'Masukkan kode dari ketua. Kamu bisa melihat ringkasan sebelum bergabung.',
          style: TextStyle(color: C.muted, fontSize: 16),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: code,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Kode undangan',
            prefixIcon: AppIcon(LucideIcons.scanLine),
          ),
          onChanged: (_) => setState(() => preview = null),
        ),
        const SizedBox(height: 20),
        if (error != null) ...[ErrorBanner(error!), const SizedBox(height: 16)],
        if (preview != null) ...[
          Surface(
            color: C.panel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Pill('PRATINJAU PROYEK', color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  textOf(preview!, 'name'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(textOf(preview!, 'description')),
                const SizedBox(height: 20),
                Text('Ketua: ${preview!['ownerName']}'),
                Text(
                  '${preview!['memberCount']} anggota',
                  style: const TextStyle(color: C.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Ajak timmu bergabung'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Salin kode ini sekarang. Berikan hanya kepada calon anggota.',
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    result['code'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: C.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: result['code']),
                      );
                      if (ctx.mounted) toast(ctx, 'Kode disalin.');
                    },
                    icon: const AppIcon(LucideIcons.copy, size: 18),
                    label: const Text('Salin kode'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Selesai'),
                ),
              ],
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
    return PageFrame(
      title: 'Proyek',
      actions: [
        if (c.owner(widget.id))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAction(
              LucideIcons.settings2,
              label: 'Pengaturan proyek',
              onTap: () => context.push('/projects/${widget.id}/settings'),
            ),
          ),
      ],
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          Reveal(
            child: Surface(
              color: C.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLogo(size: 60, inverse: true),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              textOf(p, 'name'),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              textOf(p, 'courseLabel'),
                              style: const TextStyle(
                                color: C.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            AppIcon(
                              c.owner(widget.id)
                                  ? LucideIcons.crown
                                  : LucideIcons.userCheck,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(c.owner(widget.id) ? 'Ketua' : 'Anggota'),
                          ],
                        ),
                      ),
                      Container(height: 44, width: 1, color: Colors.white),
                      Expanded(
                        child: Column(
                          children: [
                            const AppIcon(LucideIcons.users, size: 24),
                            const SizedBox(height: 8),
                            Text('${members.length} anggota'),
                          ],
                        ),
                      ),
                      if (c.owner(widget.id)) ...[
                        Container(height: 44, width: 1, color: Colors.white),
                        Expanded(
                          child: Column(
                            children: [
                              IconButton(
                                tooltip: 'Buat kode undangan',
                                onPressed: inviteBusy ? null : () => invite(c),
                                icon: const AppIcon(
                                  LucideIcons.userPlus,
                                  size: 24,
                                ),
                              ),
                              const Text(
                                'Undang',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (p['status'] == 'archived')
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Pill('Proyek diarsipkan', color: C.amber),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Ringkasan', 'Tugas', 'Anggota', 'Aktivitas']
                      .map(
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
                              color: tab == t ? Colors.white : C.muted,
                            ),
                            shape: const StadiumBorder(
                              side: BorderSide(color: C.line),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: 16),
          ],
          ...switch (tab) {
            'Tugas' => [
              if (c.owner(widget.id) && p['status'] == 'active') ...[
                PrimaryButton(
                  'Buat tugas',
                  icon: LucideIcons.plus,
                  onPressed:
                      () => context.push('/projects/${widget.id}/tasks/new'),
                ),
                const SizedBox(height: 20),
              ],
              if (tasks.isEmpty)
                const EmptyState(
                  'Belum ada tugas',
                  'Mulai dengan satu langkah yang jelas.',
                ),
              ...tasks.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskTile(t, controller: c),
                ),
              ),
            ],
            'Anggota' => [
              ...members.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Surface(
                    child: Row(
                      children: [
                        Avatar(c.name(e.value), size: 44, index: e.key),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name(e.value),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                e.value == p['ownerId']
                                    ? 'Ketua proyek'
                                    : 'Anggota',
                                style: const TextStyle(
                                  color: C.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (c.owner(widget.id) && e.value != c.uid)
                          IconButton(
                            tooltip: 'Keluarkan anggota',
                            icon: const AppIcon(
                              LucideIcons.userMinus,
                              size: 20,
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
                const EmptyState(
                  'Belum ada aktivitas',
                  'Langkah tim akan tercatat di sini.',
                ),
              ...c.activity
                  .where((a) => a['projectId'] == widget.id)
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Surface(
                        color: C.panel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Avatar(c.name(a['actorId']), size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    c.name(a['actorId']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: C.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(textOf(a, 'summary')),
                            const SizedBox(height: 8),
                            Text(
                              dateLabel(a['createdAt'], time: true),
                              style: const TextStyle(
                                color: C.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
            _ => [
              Text(
                textOf(p, 'description'),
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SectionTitle('Setiap langkah tercatat'),
              Surface(
                color: C.sky,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Progres proyek',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          '${tasks.isEmpty ? 0 : (stats['done'] / tasks.length * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: tasks.isEmpty ? 0 : stats['done'] / tasks.length,
                      color: C.blue,
                      backgroundColor: Colors.white,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${stats['done']} dari ${tasks.length} tugas selesai · ${stats['review']} menunggu review',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Surface(
                color: C.lime,
                child: Row(
                  children: [
                    const AppIcon(LucideIcons.calendarDays, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target bersama',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            dateLabel(p['targetDate']),
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/insights/${widget.id}'),
                      icon: const AppIcon(LucideIcons.sparkles, size: 18),
                      label: const Text('Insight'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/reports/${widget.id}'),
                      icon: const AppIcon(LucideIcons.fileText, size: 18),
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
                      padding: const EdgeInsets.only(bottom: 12),
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
