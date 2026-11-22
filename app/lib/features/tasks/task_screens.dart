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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Satu langkah\nlebih dekat.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Image.asset(
                'assets/illustrations/task-checklist.png',
                width: 88,
                height: 88,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tugas yang jelas, kerja tim yang lebih tenang.',
            style: TextStyle(color: C.muted),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Cari tugas...',
              prefixIcon: AppIcon(LucideIcons.search, size: 20),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 18),
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
                            labelStyle: TextStyle(
                              color: filter == f ? Colors.white : C.ink,
                            ),
                            shape: const StadiumBorder(),
                            onSelected: (_) => setState(() => filter = f),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          SectionTitle('${list.length} tugas'),
          if (list.isEmpty)
            const EmptyState(
              'Belum ada tugas di sini',
              'Coba filter lain atau buat tugas dari halaman proyek.',
              icon: LucideIcons.clipboardCheck,
            ),
          ...list.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TaskTile(t, controller: c),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskFormScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? taskId;
  const TaskFormScreen(this.projectId, {super.key, this.taskId});
  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskFormScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(), description = TextEditingController();
  List<String> assignees = [];
  String? reviewer, error;
  DateTime? due;
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
      version = t['version'];
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
    return PageFrame(
      title: widget.taskId == null ? 'Tugas baru' : 'Edit tugas',
      child: ContentList(
        children: [
          Text(
            'Bagi peran.\nTentukan langkah.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                members
                    .map(
                      (id) => FilterChip(
                        avatar: Avatar(c.name(id), size: 24),
                        label: Text(c.name(id)),
                        selected: assignees.contains(id),
                        onSelected:
                            (v) => setState(() {
                              v ? assignees.add(id) : assignees.remove(id);
                              if (assignees.contains(reviewer)) reviewer = null;
                            }),
                      ),
                    )
                    .toList(),
          ),
          const SectionTitle('Rekan reviewer'),
          const Text(
            'Pilih anggota lain agar hasil kerja mendapat sudut pandang baru.',
            style: TextStyle(color: C.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: reviewer,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pilih reviewer'),
            items:
                members
                    .where((id) => !assignees.contains(id))
                    .map(
                      (id) =>
                          DropdownMenuItem(value: id, child: Text(c.name(id))),
                    )
                    .toList(),
            onChanged: (v) => setState(() => reviewer = v),
          ),
          if (members.length < 2)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: ErrorBanner(
                'Undang satu rekan ke proyek sebelum membuat tugas dengan peer review.',
              ),
            ),
          const SectionTitle('Tenggat'),
          Surface(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: due ?? DateTime.now().add(const Duration(days: 3)),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) {
                setState(() => due = DateTime(d.year, d.month, d.day, 23, 59));
              }
            },
            child: Row(
              children: [
                const AppIcon(LucideIcons.calendarDays, color: C.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    due == null
                        ? 'Pilih tanggal (opsional)'
                        : dateLabel(due!.toIso8601String()),
                  ),
                ),
                const AppIcon(LucideIcons.chevronRight, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 28),
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
    final assignee = stringsOf(t, 'assigneeIds').contains(c.uid);
    final active = c.project(t['projectId'])?['status'] == 'active';
    final submissions = rowsOf(t, 'submissions').reversed.toList(),
        reviews = rowsOf(t, 'reviews'),
        updates = rowsOf(t, 'updates');
    final stage = switch (t['status']) {
      'todo' => 0,
      'in_progress' || 'revision_requested' => 1,
      'submitted' => 2,
      'done' => 3,
      _ => 0,
    };
    return PageFrame(
      title: 'Detail tugas',
      actions: [
        if (c.owner(t['projectId']) &&
            ['todo', 'in_progress', 'revision_requested'].contains(t['status']))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAction(
              LucideIcons.pencil,
              label: 'Edit tugas',
              onTap: () => context.push('/tasks/${t['id']}/edit'),
            ),
          ),
      ],
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: C.sky,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pill(
                  statusLabel(t),
                  color: Colors.white,
                  icon: LucideIcons.circleDot,
                ),
                const SizedBox(height: 22),
                Text(
                  textOf(t, 'title'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                if (textOf(t, 'description').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    textOf(t, 'description'),
                    style: const TextStyle(fontSize: 15, color: C.ink),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'ALUR KERJA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: C.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _stage('01', 'Kerjakan', stage >= 1),
                    const SizedBox(width: 6),
                    _stage('02', 'Kirim bukti', stage >= 2),
                    const SizedBox(width: 6),
                    _stage('03', 'Review', stage >= 3),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _fact(
                  LucideIcons.calendarDays,
                  'Tenggat',
                  dateLabel(t['dueAt']),
                  C.panel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fact(
                  LucideIcons.users,
                  'Dikerjakan',
                  stringsOf(t, 'assigneeIds').map(c.name).join(', '),
                  C.lime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fact(
            LucideIcons.messageCircle,
            'Ditinjau oleh',
            c.name(t['reviewerId']),
            C.lavender,
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            ErrorBanner(error!),
          ],
          if (active) ...[
            const SizedBox(height: 24),
            if (assignee && t['status'] == 'todo')
              PrimaryButton(
                'Mulai kerjakan',
                busy: c.busy,
                icon: LucideIcons.play,
                onPressed: () => start(t),
              ),
            if (assignee &&
                [
                  'in_progress',
                  'revision_requested',
                ].contains(t['status'])) ...[
              PrimaryButton(
                t['status'] == 'revision_requested'
                    ? 'Kirim ulang bukti'
                    : 'Kirim bukti kerja',
                icon: LucideIcons.imagePlus,
                onPressed: () => context.push('/tasks/${t['id']}/evidence'),
              ),
              const SizedBox(height: 10),
            ],
            if (assignee && !['done', 'cancelled'].contains(t['status']))
              OutlinedButton.icon(
                onPressed: () => context.push('/tasks/${t['id']}/update'),
                icon: const AppIcon(LucideIcons.pencil, size: 18),
                label: const Text('Catat progres / kendala'),
              ),
            if (t['reviewerId'] == c.uid && t['status'] == 'submitted')
              PrimaryButton(
                'Tinjau hasil kerja',
                icon: LucideIcons.messageSquare,
                onPressed: () => context.push('/tasks/${t['id']}/review'),
              ),
          ],
          SectionTitle('Bukti kerja (${submissions.length})'),
          if (submissions.isEmpty)
            _emptyTrail(
              LucideIcons.image,
              'Belum ada bukti',
              'Tambahkan foto hasil kerja atau tautan saat siap ditinjau.',
            ),
          ...submissions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Surface(
                color: C.panel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppIcon(
                          LucideIcons.image,
                          color: C.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.name(s['submittedBy']),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(textOf(s, 'note')),
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
                        icon: const AppIcon(LucideIcons.externalLink, size: 16),
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
                      style: const TextStyle(fontSize: 11, color: C.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SectionTitle('Riwayat masukan'),
          if (reviews.isEmpty)
            _emptyTrail(
              LucideIcons.messageSquare,
              'Belum ada masukan',
              'Komentar reviewer akan tersimpan di sini.',
            ),
          ...reviews.reversed.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                color: r['decision'] == 'approved' ? C.lime : C.amber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.name(r['reviewerId'])} · ${r['decision'] == 'approved' ? 'Menyetujui' : 'Meminta revisi'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(textOf(r, 'comment')),
                    const SizedBox(height: 8),
                    Text(
                      dateLabel(r['createdAt'], time: true),
                      style: const TextStyle(color: C.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SectionTitle('Catatan perjalanan'),
          if (updates.isEmpty)
            _emptyTrail(
              LucideIcons.pencil,
              'Belum ada catatan',
              'Ceritakan langkah kecil atau kendala selama mengerjakan.',
            ),
          ...updates.reversed.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(
                      u['kind'] == 'blocker' ? 'Perlu bantuan' : 'Pembaruan',
                      color: u['kind'] == 'blocker' ? C.amber : C.sky,
                    ),
                    const SizedBox(height: 10),
                    Text(textOf(u, 'message')),
                    const SizedBox(height: 8),
                    Text(
                      '${c.name(u['authorId'])} · ${dateLabel(u['createdAt'], time: true)}',
                      style: const TextStyle(fontSize: 11, color: C.muted),
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

  Widget _stage(String number, String label, bool completed) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: completed ? C.blue : Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: completed ? Colors.white : C.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: completed ? Colors.white : C.ink,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _fact(IconData icon, String label, String value, Color color) =>
      Surface(
        color: color,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 19, color: C.blue),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: C.muted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _emptyTrail(IconData icon, String title, String description) =>
      Surface(
        color: C.panel,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 20, color: C.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: C.muted, fontSize: 13),
                  ),
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
          style: TextStyle(color: C.muted, fontSize: 13),
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
            borderRadius: BorderRadius.circular(18),
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
  String kind = 'progress', decision = 'approved';
  bool busy = false;
  String? error;
  Uint8List? photoBytes;
  EvidencePhotoType? photoType;
  String? photoName;
  @override
  void dispose() {
    note.dispose();
    url.dispose();
    super.dispose();
  }

  Future<void> choosePhoto() async {
    try {
      final chosen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
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
        error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Foto belum dapat dipilih. Coba lagi dari galeri.',
        );
      }
    }
  }

  Future<void> submit(Json t) async {
    if (!form.currentState!.validate()) return;
    final review = widget.action == 'review';
    final evidence = widget.action == 'evidence';
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
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final c = ref.read(controllerProvider);
      String? photoPath;
      String? photoDataUrl;
      if (evidence && photoBytes != null && photoType != null) {
        if (c.demo) {
          require(
            photoBytes!.length <= 700 * 1024,
            'Di mode demo, foto maksimal 700 KB. Gunakan akun Supabase untuk foto hingga 5 MB.',
          );
          photoDataUrl =
              'data:${photoType!.mimeType};base64,${base64Encode(photoBytes!)}';
        } else {
          photoPath = await c.uploadEvidencePhoto(
            projectId: textOf(t, 'projectId'),
            taskId: textOf(t, 'id'),
            bytes: photoBytes!,
            type: photoType!,
          );
        }
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
          'photoDataUrl': photoDataUrl,
          'note': note.text.trim(),
          'message': note.text.trim(),
          'kind': kind,
          'decision': decision,
          'comment': note.text.trim(),
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
                (submission?['submittedBy'] != c.uid)
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
          Text(
            textOf(t, 'title'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            review
                ? 'Beri masukan yang spesifik dan membantu.'
                : evidence
                ? 'Jejak kecil untuk hasil kerja yang berarti.'
                : 'Ceritakan perkembangan atau hal yang membutuhkan bantuan.',
            style: const TextStyle(color: C.muted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (error != null) ...[
            ErrorBanner(error!),
            const SizedBox(height: 16),
          ],
          if (review && submission != null) ...[
            Surface(
              color: C.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dikirim ${c.name(submission['submittedBy'])}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(textOf(submission, 'note')),
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
                      icon: const AppIcon(LucideIcons.externalLink, size: 18),
                      label: const Text('Buka bukti kerja'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            RadioListTile<String>(
              value: 'approved',
              groupValue: decision,
              onChanged: (v) => setState(() => decision = v!),
              title: const Text('Setujui, hasil sudah sesuai'),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              value: 'revision_requested',
              groupValue: decision,
              onChanged: (v) => setState(() => decision = v!),
              title: const Text('Minta revisi dengan masukan'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          if (!review && !evidence)
            Wrap(
              spacing: 10,
              children:
                  ['progress', 'blocker']
                      .map(
                        (v) => ChoiceChip(
                          label: Text(
                            v == 'progress' ? 'Progres' : 'Kendala / bantuan',
                          ),
                          selected: kind == v,
                          onSelected: (_) => setState(() => kind = v),
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 16),
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
                        const AppIcon(
                          LucideIcons.imagePlus,
                          size: 28,
                          color: C.blue,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Foto hasil kerja',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pilih dari galeri. Foto hanya dapat dilihat anggota proyek.',
                          style: TextStyle(color: C.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (photoBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              photoBytes!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              semanticLabel: 'Pratinjau foto bukti kerja',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            photoName ?? 'Foto terpilih',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          TextButton.icon(
                            onPressed:
                                () => setState(() {
                                  photoBytes = null;
                                  photoType = null;
                                  photoName = null;
                                }),
                            icon: const AppIcon(LucideIcons.x, size: 16),
                            label: const Text('Hapus pilihan'),
                          ),
                        ] else
                          OutlinedButton.icon(
                            onPressed: busy ? null : choosePhoto,
                            icon: const AppIcon(LucideIcons.upload, size: 18),
                            label: const Text('Pilih foto'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Tautan bukti (opsional)',
                      hintText: 'drive.google.com/...',
                      prefixIcon: AppIcon(LucideIcons.link),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Jika menambah tautan, atur akses dokumen di layanan asalnya. Kamu boleh mengirim foto tanpa tautan.',
                    style: TextStyle(fontSize: 12, color: C.muted),
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: note,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
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
                              : requiredText(v, max: 2000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            review
                ? 'Simpan review'
                : evidence
                ? 'Kirim untuk direview'
                : 'Simpan pembaruan',
            icon: review ? LucideIcons.check : LucideIcons.send,
            onPressed: () => submit(t),
            busy: busy,
          ),
        ],
      ),
    );
  }
}
