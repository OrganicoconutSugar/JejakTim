import '../../core/illustrated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/layout.dart';
import '../projects/project_screens.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  final String? projectId;
  const InsightsScreen({super.key, this.projectId});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsState();
}

class _InsightsState extends ConsumerState<InsightsScreen> {
  String? selected, error;
  bool busy = false;
  Future<void> generate(String id) async {
    if (!await confirm(
      context,
      'Tentang analisis AI',
      'Jika penyedia AI diaktifkan, hanya agregat status, tenggat, dan referensi ID tugas yang dikirim untuk membantu koordinasi. Email, profil, dan isi dokumen bukti tidak dikirim. Saran tidak mengubah tugas otomatis.',
      label: 'Lanjutkan',
    )) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(controllerProvider).act('generateTeamInsight', {
        'projectId': id,
      });
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final id = widget.projectId ?? selected ?? c.projects.firstOrNull?['id'];
    final tasks = id == null ? <Json>[] : c.projectTasks(id);
    final stats = aggregateTasks(tasks, DateTime.now());
    final attention =
        tasks
            .where(
              (t) =>
                  t['status'] == 'submitted' ||
                  t['status'] == 'revision_requested' ||
                  (dateOf(t, 'dueAt')?.isBefore(DateTime.now()) ?? false) &&
                      !['done', 'cancelled'].contains(t['status']),
            )
            .toList();
    return PageFrame(
      title: widget.projectId == null ? null : 'AI Team Insight',
      navIndex: widget.projectId == null ? 2 : null,
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          if (widget.projectId == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pahami ritme\nkerja timmu.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const DimensionalIcon(
                  LucideIcons.sparkles,
                  color: C.purple,
                  size: 52,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Data sebagai panduan. Tim sebagai penentu.',
              style: TextStyle(color: C.muted),
            ),
            const SizedBox(height: 24),
          ],
          Surface(
            color: C.lavender,
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill('AI TEAM INSIGHT', color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Lebih paham.\nLebih kompak.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tanpa skor. Tanpa ranking.',
                        style: TextStyle(fontSize: 12, color: C.muted),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/illustrations/ai-orbit.png',
                  width: 125,
                  height: 160,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (c.projects.isEmpty)
            const EmptyState(
              'Mulai dari sebuah proyek',
              'Insight membutuhkan jejak tugas kelompokmu.',
            )
          else ...[
            DropdownButtonFormField<String>(
              value: id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Proyek yang ingin dipahami',
              ),
              items:
                  c.projects
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: p['id'],
                          child: Text(
                            textOf(p, 'name'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged:
                  widget.projectId == null
                      ? (v) => setState(() {
                        selected = v;
                        error = null;
                      })
                      : null,
            ),
            const SectionTitle('Ringkasan dari data tugas'),
            const Text(
              'Dihitung langsung oleh aplikasi, bukan keluaran AI.',
              style: TextStyle(fontSize: 12, color: C.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Surface(
                    color: C.sky,
                    child: _number(
                      '${stats['done']}/${stats['total']}',
                      'Tugas selesai',
                      LucideIcons.checkCircle2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Surface(
                    color: C.amber,
                    child: _number(
                      '${stats['review']}',
                      'Menunggu review',
                      LucideIcons.messageCircle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (tasks.length < 3)
              const ErrorBanner(
                'Data belum cukup untuk analisis. Tambahkan minimal 3 tugas dan catat perkembangannya.',
              )
            else
              const ErrorBanner(
                'Penyedia AI belum dihubungkan. Proyek dan tugas tetap dapat digunakan; ringkasan di atas bukan hasil AI.',
              ),
            const SizedBox(height: 16),
            if (error != null) ...[
              ErrorBanner(error!),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              'Coba analisis AI',
              icon: LucideIcons.sparkles,
              onPressed: () => generate(id!),
              busy: busy,
            ),
            const SectionTitle('Bisa ditindaklanjuti'),
            if (attention.isEmpty)
              const EmptyState(
                'Belum ada perhatian khusus',
                'Terus catat progres agar tim tetap saling memahami.',
                icon: LucideIcons.heartHandshake,
              ),
            ...attention.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskTile(t, controller: c),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Saran koordinasi bukan penilaian akademik. Tenggat yang terlewat tidak menjelaskan niat atau kondisi seseorang.',
              style: TextStyle(fontSize: 12, color: C.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _number(String value, String label, IconData icon) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppIcon(icon, size: 22),
      const SizedBox(height: 18),
      Text(
        value,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
      ),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    final disabled =
        (c.profile['notificationPrefs'] as Map?)?['inApp'] == false;
    final tasks =
        c.tasks
            .where(
              (t) =>
                  t['reviewerId'] == c.uid && t['status'] == 'submitted' ||
                  stringsOf(t, 'assigneeIds').contains(c.uid) &&
                      t['status'] == 'revision_requested',
            )
            .toList();
    return PageFrame(
      title: 'Notifikasi',
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          const Text(
            'Yang perlu perhatianmu',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pengingat di aplikasi berdasarkan tugas saat ini.',
            style: TextStyle(color: C.muted),
          ),
          const SizedBox(height: 24),
          if (disabled)
            const EmptyState(
              'Notifikasi dinonaktifkan',
              'Aktifkan kembali melalui preferensi profil.',
              icon: LucideIcons.bellOff,
            )
          else if (tasks.isEmpty)
            const EmptyState(
              'Sudah terbaca semua',
              'Belum ada permintaan review atau revisi untukmu.',
              icon: LucideIcons.bell,
            )
          else
            ...tasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TaskTile(t, controller: c),
              ),
            ),
          TextButton(
            onPressed: () => context.push('/profile/notifications'),
            child: const Text('Atur notifikasi'),
          ),
        ],
      ),
    );
  }
}
