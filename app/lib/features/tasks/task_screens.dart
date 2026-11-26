import 'dart:convert';
import 'dart:typed_data';

import '../../core/illustrated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/controller.dart';
import '../../core/evidence_photo.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/geo_icons.dart';
import '../../core/layout.dart';
import '../projects/project_screens.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksState();
}

class _TasksState extends ConsumerState<TasksScreen> {
  String filter = 'Semua', query = '';
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final activeCount =
        c.tasks
            .where(
              (t) => [
                'todo',
                'in_progress',
                'revision_requested',
              ].contains(t['status']),
            )
            .length;
    final reviewCount =
        c.tasks.where((t) => t['status'] == 'submitted').length;
    final doneCount = c.tasks.where((t) => t['status'] == 'done').length;

    final list =
        c.tasks
            .where(
              (t) =>
                  textOf(
                    t,
                    'title',
                  ).toLowerCase().contains(query.toLowerCase()) &&
                  (filter == 'Semua' ||
                      filter == 'Tugasku' &&
                          stringsOf(t, 'assigneeIds').contains(c.uid) ||
                      filter == 'Review' &&
                          t['status'] == 'submitted' &&
                          t['reviewerId'] == c.uid ||
                      filter == 'Selesai' && t['status'] == 'done'),
            )
            .toList()
          ..sort(
            (a, b) => textOf(
              a,
              'dueAt',
              '9999',
            ).compareTo(textOf(b, 'dueAt', '9999')),
          );
    return PageFrame(
      navIndex: 1,
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          const PageHeader(
            'Satu langkah\nlebih dekat.',
            subtitle: 'Tugas yang jelas, kerja tim yang lebih tenang.',
            trailing: GeoIcon(GeoIconKind.clipboard, size: 46),
          ),

          // Quick status overview strip
          Row(
            children: [
              Expanded(
                child: _TaskMiniStat(
                  '$activeCount',
                  'Aktif',
                  C.sky,
                  C.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskMiniStat(
                  '$reviewCount',
                  'Review',
                  C.lavender,
                  C.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TaskMiniStat(
                  '$doneCount',
                  'Selesai',
                  C.lime,
                  C.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: S.lg),

          TextField(
            decoration: const InputDecoration(
              hintText: 'Cari tugas...',
              prefixIcon: Padding(
                padding: EdgeInsets.all(13),
                child: GeoIcon(GeoIconKind.search, size: 20),
              ),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: S.md),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['Semua', 'Tugasku', 'Review', 'Selesai']
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: filter == f,
                            showCheckmark: false,
                            selectedColor: C.blue,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: filter == f ? Colors.white : C.ink2,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: filter == f ? C.blue : C.line,
                              ),
                            ),
                            onSelected: (_) => setState(() => filter = f),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          SectionTitle('${list.length} tugas'),
          if (list.isEmpty)
            const Surface(
              child: EmptyState(
                'Belum ada tugas di sini',
                'Coba filter lain atau buat tugas dari halaman proyek.',
                icon: LucideIcons.clipboardCheck,
              ),
            ),
          ...list.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskTile(t, controller: c),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskMiniStat extends StatelessWidget {
  final String value, label;
  final Color tint, accent;
  const _TaskMiniStat(this.value, this.label, this.tint, this.accent);

  @override
  Widget build(BuildContext context) => Surface(
    color: tint,
    radius: 16,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: T.number.copyWith(color: accent, fontSize: 22)),
        const SizedBox(height: 2),
        Text(
          label,
          style: T.caption.copyWith(color: C.ink2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class TaskFormScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? taskId;
  final String? initialTitle;
  final String? initialDescription;
  const TaskFormScreen(
    this.projectId, {
    super.key,
    this.taskId,
    this.initialTitle,
    this.initialDescription,
  });
  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskFormScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(), description = TextEditingController();
  List<String> assignees = [];
  String? reviewer, error;
  DateTime? due;
  DateTime? _initialDue;
  bool busy = false;
  int? version;
  @override
  void initState() {
    super.initState();
    final t = ref.read(controllerProvider).task(widget.taskId ?? '');
    if (t != null) {
      title.text = textOf(t, 'title');
      description.text = textOf(t, 'description');
      assignees = stringsOf(t, 'assigneeIds');
      reviewer = t['reviewerId'];
      due = dateOf(t, 'dueAt');
      _initialDue = due;
      version = t['version'];
    } else {
      if (widget.initialTitle != null &&
          widget.initialTitle!.trim().isNotEmpty) {
        title.text = widget.initialTitle!.trim();
      }
      if (widget.initialDescription != null &&
          widget.initialDescription!.trim().isNotEmpty) {
        description.text = widget.initialDescription!.trim();
      }
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (due != _initialDue && isPastDate(due)) {
      setState(
        () =>
            error = 'Tenggat tidak boleh menggunakan tanggal yang sudah lewat.',
      );
      return;
    }
    if (assignees.isEmpty || reviewer == null) {
      setState(
        () =>
            error =
                'Pilih minimal satu penanggung jawab dan satu reviewer lain.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref.read(controllerProvider).act('saveTask', {
        'projectId': widget.projectId,
        'taskId': widget.taskId,
        'version': version,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'assigneeIds': assignees,
        'reviewerId': reviewer,
        'dueAt': due?.toUtc().toIso8601String(),
      });
      if (mounted) {
        context.replace('/tasks/${result['id']}');
        toast(context, 'Tugas tersimpan.');
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
    final p = c.project(widget.projectId);
    if (p == null || !c.owner(widget.projectId)) {
      return const PageFrame(
        title: 'Tugas',
        child: EmptyState(
          'Akses terbatas',
          'Pembuatan dan pengaturan tugas dilakukan ketua.',
        ),
      );
    }
    final members = stringsOf(p, 'memberIds');
    final reviewerOptions =
        members.where((id) => !assignees.contains(id)).toList();
    final safeReviewer =
        reviewer != null && reviewerOptions.contains(reviewer)
            ? reviewer
            : null;
    return PageFrame(
      title: widget.taskId == null ? 'Tugas baru' : 'Edit tugas',
      child: ContentList(
        children: [
          const PageHeader(
            'Bagi peran.\nTentukan langkah.',
            subtitle: 'Pastikan setiap tugas punya penanggung jawab & reviewer.',
          ),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: S.lg),
          ],
          Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Judul tugas'),
                  validator: (v) => requiredText(v, max: 160),
                ),
                const SizedBox(height: S.md),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi & definisi selesai',
                  ),
                  minLines: 3,
                  maxLines: 6,
                  validator: (v) => requiredText(v, max: 2000),
                ),
              ],
            ),
          ),
          const SectionTitle('Penanggung jawab'),
          Surface(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  members
                      .map(
                        (id) => FilterChip(
                          avatar: Avatar(
                            c.name(id),
                            size: 24,
                            avatarDataUrl: c.avatarOf(id),
                          ),
                          label: Text(c.name(id)),
                          selected: assignees.contains(id),
                          selectedColor: C.sky,
                          checkmarkColor: C.blue,
                          labelStyle: TextStyle(
                            color: assignees.contains(id) ? C.blue : C.ink,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          onSelected:
                              (v) => setState(() {
                                v ? assignees.add(id) : assignees.remove(id);
                                if (assignees.contains(reviewer)) {
                                  reviewer = null;
                                }
                              }),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SectionTitle('Rekan reviewer'),
          const Text(
            'Pilih anggota lain agar hasil kerja mendapat sudut pandang baru.',
            style: T.small,
          ),
          const SizedBox(height: S.md),
          DropdownButtonFormField<String>(
            value: safeReviewer,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pilih reviewer'),
            items:
                reviewerOptions
                    .map(
                      (id) =>
                          DropdownMenuItem(value: id, child: Text(c.name(id))),
                    )
                    .toList(),
            onChanged: (v) => setState(() => reviewer = v),
          ),
          if (members.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: S.md),
              child: ErrorBanner(
                'Undang satu rekan ke proyek sebelum membuat tugas dengan peer review.',
              ),
            ),
          const SectionTitle('Tenggat'),
          Surface(
            padding: const EdgeInsets.all(14),
            onTap: () async {
              final minimumDate = today();
              final suggestedDate = DateTime.now().add(const Duration(days: 3));
              final d = await showDatePicker(
                context: context,
                initialDate:
                    due != null && !isPastDate(due) ? due! : suggestedDate,
                firstDate: minimumDate,
                lastDate: DateTime(2100),
              );
              if (d != null) {
                setState(() => due = DateTime(d.year, d.month, d.day, 23, 59));
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
                      const Text('Batas waktu', style: T.caption),
                      Text(
                        due == null
                            ? 'Pilih tanggal (opsional)'
                            : dateLabel(due!.toIso8601String()),
                        style: T.bodyStrong,
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: C.subtle),
              ],
            ),
          ),
          const SizedBox(height: S.xxl),
          PrimaryButton('Simpan tugas', busy: busy, onPressed: save),
        ],
      ),
    );
  }
}

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const TaskDetailScreen(this.id, {super.key});
  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailState();
}

class _TaskDetailState extends ConsumerState<TaskDetailScreen> {
  String? error;
  Future<void> start(Json t) async {
    try {
      await ref.read(controllerProvider).act('startTask', {
        'projectId': t['projectId'],
        'taskId': t['id'],
        'version': t['version'],
      });
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final t = c.task(widget.id);
    if (t == null) {
      return const PageFrame(
        title: 'Tugas',
        child: EmptyState(
          'Tugas tidak tersedia',
          'Periksa kembali akses proyekmu.',
        ),
      );
    }
    final status = textOf(t, 'status');
    final (tint, accent, statusIcon) = statusVisual(status);
    final assignee = stringsOf(t, 'assigneeIds').contains(c.uid);
    final active = c.project(t['projectId'])?['status'] == 'active';
    final submissions = rowsOf(t, 'submissions').reversed.toList(),
        reviews = rowsOf(t, 'reviews'),
        updates = rowsOf(t, 'updates');
    final stage = switch (status) {
      'todo' => 0,
      'in_progress' || 'revision_requested' => 1,
      'submitted' => 2,
      'done' => 3,
      _ => 0,
    };
    return PageFrame(
      title: 'Detail tugas',
      actions: [
        if (active &&
            c.owner(t['projectId']) &&
            ['todo', 'in_progress', 'revision_requested'].contains(status))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Edit tugas',
              onPressed: () => context.push('/tasks/${t['id']}/edit'),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                backgroundColor: Colors.white,
                side: const BorderSide(color: C.line),
              ),
              icon: const GeoIcon(GeoIconKind.pencil, size: 20),
            ),
          ),
      ],
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          // Hero Status Card
          Surface(
            color: tint == C.panel ? C.sky : tint,
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  statusLabel(t),
                  color: Colors.white,
                  foreground: accent,
                  icon: statusIcon,
                ),
                const SizedBox(height: S.md),
                Text(
                  textOf(t, 'title'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: T.h1,
                ),
                if (textOf(t, 'description').isNotEmpty) ...[
                  const SizedBox(height: S.sm),
                  Text(
                    textOf(t, 'description'),
                    style: T.body.copyWith(color: C.ink2),
                  ),
                ],
                const SizedBox(height: S.lg),
                const Text('ALUR KERJA', style: T.overline),
                const SizedBox(height: S.sm),
                Row(
                  children: [
                    _stage('01', 'Kerjakan', stage >= 1, accent),
                    const SizedBox(width: 6),
                    _stage('02', 'Kirim bukti', stage >= 2, accent),
                    const SizedBox(width: 6),
                    _stage('03', 'Review', stage >= 3, accent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: S.md),

          // Task Metadata Card
          Surface(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RINGKASAN TUGAS', style: T.overline),
                const SizedBox(height: 6),
                _fact(
                  GeoIconKind.calendar,
                  'Tenggat',
                  dateLabel(t['dueAt']),
                ),
                const Divider(),
                _fact(
                  GeoIconKind.users,
                  'Dikerjakan',
                  stringsOf(t, 'assigneeIds').map(c.name).join(', '),
                ),
                const Divider(),
                _fact(
                  GeoIconKind.review,
                  'Ditinjau oleh',
                  c.name(t['reviewerId']),
                ),
              ],
            ),
          ),

          if (error != null) ...[
            const SizedBox(height: S.md),
            ErrorBanner(error!),
          ],
          if (active) ...[
            const SizedBox(height: S.lg),
            if (assignee && status == 'todo')
              PrimaryButton(
                'Mulai kerjakan',
                busy: c.busy,
                icon: LucideIcons.play,
                onPressed: () => start(t),
              ),
            if (assignee &&
                ['in_progress', 'revision_requested'].contains(status)) ...[
              PrimaryButton(
                status == 'revision_requested'
                    ? 'Kirim ulang bukti'
                    : 'Kirim bukti kerja',
                icon: LucideIcons.imagePlus,
                onPressed: () => context.push('/tasks/${t['id']}/evidence'),
              ),
              const SizedBox(height: 10),
            ],
            if (assignee && !['done', 'cancelled'].contains(status))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/tasks/${t['id']}/update'),
                  icon: const Icon(LucideIcons.pencil, size: 17),
                  label: const Text('Catat progres / kendala'),
                ),
              ),
            if (t['reviewerId'] == c.uid && status == 'submitted') ...[
              if (assignee) const SizedBox(height: 10),
              PrimaryButton(
                'Tinjau hasil kerja',
                icon: LucideIcons.checkCircle2,
                onPressed: () => context.push('/tasks/${t['id']}/review'),
              ),
            ],
          ],

          SectionTitle('Bukti kerja (${submissions.length})'),
          if (submissions.isEmpty)
            _emptyTrail(
              GeoIconKind.camera,
              'Belum ada bukti',
              'Tambahkan foto hasil kerja atau tautan saat siap ditinjau.',
            ),
          ...submissions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBadge(
                          LucideIcons.image,
                          tint: C.sky,
                          iconColor: C.blue,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.name(s['submittedBy']),
                            style: T.bodyStrong,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(textOf(s, 'note'), style: T.body),
                    const SizedBox(height: 8),
                    ...rowsOf(s, 'evidenceFiles').map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EvidencePhotoTile(file),
                      ),
                    ),
                    ...rowsOf(s, 'evidenceLinks').map(
                      (link) => TextButton.icon(
                        onPressed: () async {
                          final uri = Uri.tryParse(textOf(link, 'url'));
                          if (uri != null && validEvidence(uri.toString())) {
                            final ok = await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!ok && context.mounted) {
                              toast(
                                context,
                                'Tautan tidak dapat dibuka. Periksa aplikasi browser.',
                              );
                            }
                          }
                        },
                        icon: const Icon(LucideIcons.externalLink, size: 16),
                        label: Text(
                          textOf(link, 'label', 'Buka bukti'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      '${s['status'] == 'approved'
                          ? 'Disetujui'
                          : s['status'] == 'revision_requested'
                          ? 'Perlu revisi'
                          : s['status'] == 'superseded'
                          ? 'Versi sebelumnya'
                          : 'Menunggu review'} · ${dateLabel(s['submittedAt'], time: true)}',
                      style: T.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SectionTitle('Riwayat masukan'),
          if (reviews.isEmpty)
            _emptyTrail(
              GeoIconKind.review,
              'Belum ada masukan',
              'Komentar reviewer akan tersimpan di sini.',
            ),
          ...reviews.reversed.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                color: r['decision'] == 'approved' ? C.lime : C.amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.name(r['reviewerId'])} · ${r['decision'] == 'approved' ? 'Menyetujui' : 'Meminta revisi'}',
                      style: T.bodyStrong,
                    ),
                    const SizedBox(height: 8),
                    Text(textOf(r, 'comment'), style: T.body),
                    const SizedBox(height: 6),
                    Text(
                      dateLabel(r['createdAt'], time: true),
                      style: T.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SectionTitle('Catatan perjalanan'),
          if (updates.isEmpty)
            _emptyTrail(
              GeoIconKind.pencil,
              'Belum ada catatan',
              'Ceritakan langkah kecil atau kendala selama mengerjakan.',
            ),
          ...updates.reversed.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(
                      u['kind'] == 'blocker' ? 'Perlu bantuan' : 'Pembaruan',
                      color: u['kind'] == 'blocker' ? C.amber : C.sky,
                      foreground: u['kind'] == 'blocker' ? C.orange : C.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(textOf(u, 'message'), style: T.body),
                    const SizedBox(height: 6),
                    Text(
                      '${c.name(u['authorId'])} · ${dateLabel(u['createdAt'], time: true)}',
                      style: T.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage(String number, String label, bool completed, Color accent) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: completed ? accent : Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: T.overline.copyWith(
                  letterSpacing: 0.6,
                  color: completed ? Colors.white.withValues(alpha: .85) : C.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: completed ? Colors.white : C.ink,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _fact(
    GeoIconKind icon,
    String label,
    String value,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        GeoIcon(icon, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: T.caption),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: T.bodyStrong,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _emptyTrail(
    GeoIconKind icon,
    String title,
    String description,
  ) => Surface(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GeoIcon(icon, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: T.bodyStrong),
              const SizedBox(height: 2),
              Text(description, style: T.caption),
            ],
          ),
        ),
      ],
    ),
  );
}

class EvidencePhotoTile extends ConsumerStatefulWidget {
  final Json file;
  const EvidencePhotoTile(this.file, {super.key});

  @override
  ConsumerState<EvidencePhotoTile> createState() => _EvidencePhotoTileState();
}

class _EvidencePhotoTileState extends ConsumerState<EvidencePhotoTile> {
  late Future<Uint8List> image;

  @override
  void initState() {
    super.initState();
    image = _load();
  }

  @override
  void didUpdateWidget(covariant EvidencePhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file['path'] != widget.file['path'] ||
        oldWidget.file['dataUrl'] != widget.file['dataUrl']) {
      image = _load();
    }
  }

  Future<Uint8List> _load() async {
    final dataUrl = textOf(widget.file, 'dataUrl');
    if (dataUrl.isNotEmpty) return base64Decode(dataUrl.split(',').last);
    return ref
        .read(controllerProvider)
        .downloadEvidencePhoto(textOf(widget.file, 'path'));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: image,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Text(
          'Foto belum dapat dimuat. Tarik layar untuk mencoba lagi.',
          style: T.small,
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final bytes = snapshot.data!;
      return Semantics(
        button: true,
        label: 'Lihat foto bukti kerja',
        child: InkWell(
          onTap:
              () => showDialog<void>(
                context: context,
                builder:
                    (dialogContext) => Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Tutup foto',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const AppIcon(LucideIcons.x, size: 20),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(dialogContext).height * .72,
                            ),
                            child: InteractiveViewer(
                              child: Image.memory(bytes, fit: BoxFit.contain),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              bytes,
              width: double.infinity,
              height: 164,
              fit: BoxFit.cover,
              semanticLabel: 'Foto bukti kerja',
            ),
          ),
        ),
      );
    },
  );
}

class TaskActionScreen extends ConsumerStatefulWidget {
  final String id, action;
  const TaskActionScreen(this.id, this.action, {super.key});
  @override
  ConsumerState<TaskActionScreen> createState() => _TaskActionState();
}

class _TaskActionState extends ConsumerState<TaskActionScreen> {
  final form = GlobalKey<FormState>();
  final note = TextEditingController(), url = TextEditingController();
  String kind = 'progress';
  String? decision;
  final revision = TextEditingController();
  static const criteria = [
    'Bukti hasil kerja dapat dibuka',
    'Hasil mencakup semua bagian tugas',
    'Hasil sesuai definisi selesai',
  ];
  final checked = <String>{};
  bool busy = false;
  String? error;
  Uint8List? photoBytes;
  EvidencePhotoType? photoType;
  String? photoName;
  ImageSource? photoSource;
  DateTime? photoCapturedAt;
  @override
  void dispose() {
    note.dispose();
    url.dispose();
    revision.dispose();
    super.dispose();
  }

  Future<void> choosePhoto(ImageSource source) async {
    try {
      final chosen = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (chosen == null) return;
      final bytes = await chosen.readAsBytes();
      final type = detectEvidencePhoto(bytes);
      if (bytes.length > maxEvidencePhotoBytes || type == null) {
        setState(
          () =>
              error =
                  'Pilih foto JPG, PNG, atau WebP dengan ukuran maksimal 5 MB.',
        );
        return;
      }
      setState(() {
        photoBytes = bytes;
        photoType = type;
        photoName = chosen.name;
        photoSource = source;
        photoCapturedAt = DateTime.now();
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error =
                  source == ImageSource.camera
                      ? 'Kamera belum dapat dibuka. Periksa izin kamera atau pilih dari galeri.'
                      : 'Foto belum dapat dipilih. Coba lagi dari galeri.',
        );
      }
    }
  }

  Future<void> submit(Json t) async {
    if (!form.currentState!.validate()) return;
    final review = widget.action == 'review';
    final evidence = widget.action == 'evidence';
    if (review &&
        (decision == null ||
            (decision == 'approved' && checked.length != criteria.length))) {
      setState(
        () =>
            error =
                decision == null
                    ? 'Pilih keputusan review.'
                    : 'Centang semua kriteria sebelum menyetujui hasil.',
      );
      return;
    }
    final reviewComment = [
      note.text.trim(),
      'Checklist:\n${criteria.map((item) => '${checked.contains(item) ? '✓' : '○'} $item').join('\n')}',
      if (decision == 'revision_requested')
        'Perbaikan yang diminta:\n${revision.text.trim()}',
    ].join('\n\n');
    final link = normalizeEvidenceLink(url.text);
    if (evidence && photoBytes == null && link.isEmpty) {
      setState(() => error = 'Pilih foto atau isi tautan bukti kerja.');
      return;
    }
    if (review &&
        !await confirm(
          context,
          decision == 'approved' ? 'Setujui hasil kerja?' : 'Minta revisi?',
          'Masukan ini akan disimpan dalam riwayat dan tidak dapat dihapus.',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final c = ref.read(controllerProvider);
      String? photoPath;
      if (evidence && photoBytes != null && photoType != null) {
        photoPath = await c.uploadEvidencePhoto(
          projectId: textOf(t, 'projectId'),
          taskId: textOf(t, 'id'),
          bytes: photoBytes!,
          type: photoType!,
        );
      }
      await c.act(
        review
            ? 'reviewSubmission'
            : widget.action == 'evidence'
            ? 'submitTask'
            : 'addUpdate',
        {
          'projectId': t['projectId'],
          'taskId': t['id'],
          'version': t['version'],
          'url': link,
          'photoPath': photoPath,
          'note': note.text.trim(),
          'message': note.text.trim(),
          'kind': kind,
          if (review) 'decision': decision,
          'comment': review ? reviewComment : note.text.trim(),
        },
      );
      if (mounted) {
        context.pop();
        toast(
          context,
          review
              ? 'Review tersimpan.'
              : evidence
              ? 'Bukti terkirim untuk ditinjau.'
              : 'Pembaruan tersimpan.',
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
    final t = c.task(widget.id);
    final review = widget.action == 'review',
        evidence = widget.action == 'evidence';
    if (t == null) {
      return const PageFrame(
        title: 'Tugas',
        child: EmptyState('Tugas tidak tersedia', 'Kembali ke daftar tugas.'),
      );
    }
    final submission =
        rowsOf(
          t,
          'submissions',
        ).where((s) => s['id'] == t['latestSubmissionId']).firstOrNull;
    final allowed =
        review
            ? t['reviewerId'] == c.uid &&
                t['status'] == 'submitted' &&
                submission != null &&
                submission['submittedBy'] != c.uid
            : stringsOf(t, 'assigneeIds').contains(c.uid);
    if (!allowed) {
      return const PageFrame(
        title: 'Tugas',
        child: EmptyState(
          'Akses terbatas',
          'Tindakan ini tidak tersedia untuk peranmu saat ini.',
        ),
      );
    }
    return PageFrame(
      title:
          review
              ? 'Peer review'
              : evidence
              ? 'Bukti kerja'
              : 'Catat pembaruan',
      child: ContentList(
        children: [
          PageHeader(
            textOf(t, 'title'),
            subtitle:
                review
                    ? 'Beri masukan yang spesifik dan membantu.'
                    : evidence
                    ? 'Jejak kecil untuk hasil kerja yang berarti.'
                    : 'Ceritakan perkembangan atau hal yang membutuhkan bantuan.',
          ),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: S.lg),
          ],
          if (review && submission != null) ...[
            if (textOf(t, 'description').isNotEmpty) ...[
              const SectionTitle('Definisi selesai'),
              Surface(child: Text(textOf(t, 'description'), style: T.body)),
              const SizedBox(height: S.md),
            ],
            if (rowsOf(t, 'reviews').isNotEmpty) ...[
              const SectionTitle('Masukan terakhir'),
              Surface(
                color: C.amber,
                child: Text(
                  textOf(rowsOf(t, 'reviews').last, 'comment'),
                  style: T.body,
                ),
              ),
              const SizedBox(height: S.md),
            ],
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dikirim ${c.name(submission['submittedBy'])} · ${dateLabel(submission['submittedAt'], time: true)}',
                    style: T.bodyStrong,
                  ),
                  const SizedBox(height: 8),
                  Text(textOf(submission, 'note'), style: T.body),
                  ...rowsOf(submission, 'evidenceFiles').map(
                    (file) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: EvidencePhotoTile(file),
                    ),
                  ),
                  ...rowsOf(submission, 'evidenceLinks').map(
                    (l) => TextButton.icon(
                      onPressed: () async {
                        if (validEvidence(textOf(l, 'url'))) {
                          await launchUrl(
                            Uri.parse(l['url']),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Buka bukti kerja'),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Checklist hasil kerja'),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  for (final item in criteria)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item, style: T.body),
                      value: checked.contains(item),
                      onChanged:
                          busy
                              ? null
                              : (selected) => setState(() {
                                if (selected == true) {
                                  checked.add(item);
                                } else {
                                  checked.remove(item);
                                }
                              }),
                    ),
                ],
              ),
            ),
            const SectionTitle('Keputusan'),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'approved',
                    groupValue: decision,
                    onChanged:
                        busy ? null : (v) => setState(() => decision = v),
                    title: const Text(
                      'Setujui, hasil sudah sesuai',
                      style: T.bodyStrong,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  RadioListTile<String>(
                    value: 'revision_requested',
                    groupValue: decision,
                    onChanged:
                        busy ? null : (v) => setState(() => decision = v),
                    title: const Text(
                      'Minta revisi dengan masukan',
                      style: T.bodyStrong,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
          if (!review && !evidence)
            Wrap(
              spacing: 8,
              children:
                  ['progress', 'blocker']
                      .map(
                        (v) => ChoiceChip(
                          label: Text(
                            v == 'progress' ? 'Progres' : 'Kendala / bantuan',
                          ),
                          selected: kind == v,
                          showCheckmark: false,
                          selectedColor: C.blue,
                          labelStyle: TextStyle(
                            color: kind == v ? Colors.white : C.ink2,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          onSelected: (_) => setState(() => kind = v),
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: S.md),
          Form(
            key: form,
            child: Column(
              children: [
                if (evidence) ...[
                  Surface(
                    color: C.sky,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const IconBadge(
                              LucideIcons.imagePlus,
                              tint: Colors.white,
                              iconColor: C.blue,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Foto hasil kerja', style: T.title),
                                  SizedBox(height: 2),
                                  Text(
                                    'Hanya dapat dilihat anggota proyek.',
                                    style: T.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: S.md),
                        if (photoBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              photoBytes!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              semanticLabel: 'Pratinjau foto bukti kerja',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Pill(
                            photoSource == ImageSource.camera
                                ? 'Foto kamera · ${dateLabel(photoCapturedAt?.toIso8601String(), time: true)}'
                                : 'Galeri · ${photoName ?? 'Foto terpilih'}',
                            color: Colors.white,
                          ),
                          TextButton.icon(
                            onPressed:
                                () => setState(() {
                                  photoBytes = null;
                                  photoType = null;
                                  photoName = null;
                                  photoSource = null;
                                  photoCapturedAt = null;
                                }),
                            icon: const Icon(LucideIcons.x, size: 16),
                            label: const Text('Hapus pilihan'),
                          ),
                        ] else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed:
                                    busy
                                        ? null
                                        : () => choosePhoto(ImageSource.camera),
                                icon: const Icon(
                                  LucideIcons.camera,
                                  size: 17,
                                  color: Colors.white,
                                ),
                                label: const Text('Ambil foto'),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    busy
                                        ? null
                                        : () =>
                                            choosePhoto(ImageSource.gallery),
                                icon: const Icon(LucideIcons.upload, size: 17),
                                label: const Text('Dari galeri'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: S.lg),
                  TextFormField(
                    controller: url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Tautan bukti (opsional)',
                      hintText: 'drive.google.com/...',
                      prefixIcon: Icon(
                        LucideIcons.link,
                        size: 18,
                        color: C.blue,
                      ),
                    ),
                    validator:
                        (v) =>
                            (v?.trim().isEmpty ?? true) ||
                                    validEvidence(
                                      normalizeEvidenceLink(v ?? ''),
                                    )
                                ? null
                                : 'Masukkan tautan web yang valid.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Jika menambah tautan, atur akses dokumen di layanan asalnya. Kamu boleh mengirim foto tanpa tautan.',
                    style: T.caption,
                  ),
                  const SizedBox(height: S.lg),
                ],
                TextFormField(
                  controller: note,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: review ? 800 : 2000,
                  decoration: InputDecoration(
                    labelText:
                        review
                            ? 'Masukan untuk rekan'
                            : evidence
                            ? 'Catatan hasil kerja'
                            : 'Apa yang ingin kamu catat?',
                  ),
                  validator:
                      (v) =>
                          evidence
                              ? (v?.length ?? 0) > 2000
                                  ? 'Maksimal 2000 karakter.'
                                  : null
                              : requiredText(v, max: review ? 800 : 2000),
                ),
                if (review && decision == 'revision_requested') ...[
                  const SizedBox(height: S.md),
                  TextFormField(
                    controller: revision,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 800,
                    decoration: const InputDecoration(
                      labelText: 'Perbaikan yang harus dikerjakan',
                    ),
                    validator: (v) => requiredText(v, max: 800),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: S.xl),
          PrimaryButton(
            review
                ? 'Simpan review'
                : evidence
                ? 'Kirim untuk direview'
                : 'Simpan pembaruan',
            icon: review ? null : LucideIcons.send,
            onPressed: () => submit(t),
            busy: busy,
          ),
        ],
      ),
    );
  }
}
