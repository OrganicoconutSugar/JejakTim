import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/controller.dart';
import '../../core/design.dart';
import '../../core/geo_icons.dart';
import '../../core/layout.dart';
import '../../core/models.dart';
import '../projects/project_screens.dart';
import 'team_insight_service.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  final String? projectId;
  final TeamInsightService? insightService;
  const InsightsScreen({super.key, this.projectId, this.insightService});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsState();
}

class _InsightsState extends ConsumerState<InsightsScreen> {
  String? selected, error;
  bool busy = false;
  bool _consentGranted = false;
  bool _showDetails = false;
  final Map<String, TeamInsightResult> _resultsByProject = {};

  TeamInsightService _service(AppController c) =>
      widget.insightService ??
      TeamInsightService(
        supabase: c.supabaseReady ? Supabase.instance.client : null,
      );

  Map<String, String> _memberNameMap(AppController c) => {
    for (final person in c.people)
      if (textOf(person, 'uid').isNotEmpty)
        textOf(person, 'uid'): textOf(person, 'name', 'Anggota'),
  };

  Future<void> generate(AppController c, Json project, List<Json> tasks) async {
    final id = textOf(project, 'id');
    if (!_consentGranted) {
      final ok = await confirm(
        context,
        'Tentang analisis Gemini AI',
        'Hanya agregat status tugas, tenggat relatif, dan kode anonim (tanpa nama, email, foto, atau isi dokumen bukti) yang dikirim ke Gemini AI untuk menyusun saran koordinasi. Saran tidak mengubah tugas secara otomatis.',
        label: 'Lanjutkan',
      );
      if (!ok || !mounted) return;
      _consentGranted = true;
    }

    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await _service(c).generateInsight(
        tasks: tasks,
        memberIds: stringsOf(project, 'memberIds'),
        memberNames: _memberNameMap(c),
        ownerId: project['ownerId']?.toString(),
      );
      if (mounted) {
        setState(() => _resultsByProject[id] = result);
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
    final projectIds = c.projects.map((p) => textOf(p, 'id')).toSet();
    final requestedId = widget.projectId ?? selected;
    final id =
        (requestedId != null && projectIds.contains(requestedId))
            ? requestedId
            : c.projects.firstOrNull?['id']?.toString();
    final project = id == null ? null : c.project(id);
    final tasks = id == null ? <Json>[] : c.projectTasks(id);
    final stats = aggregateTasks(tasks, DateTime.now());
    final memberNames = _memberNameMap(c);
    final workload =
        project == null
            ? null
            : analyzeTeamWorkload(
              tasks: tasks,
              memberIds: stringsOf(project, 'memberIds'),
              memberNames: memberNames,
              ownerId: project['ownerId']?.toString(),
            );
    final activeResult =
        project == null
            ? null
            : _resultsByProject[id] ??
                _service(c).analyzeLocal(
                  tasks: tasks,
                  memberIds: stringsOf(project, 'memberIds'),
                  memberNames: memberNames,
                  ownerId: project['ownerId']?.toString(),
                );
    final hasGenerated = id != null && _resultsByProject.containsKey(id);
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
    final total = stats['total'] as int;
    final done = stats['done'] as int;
    final review = stats['review'] as int;
    final overdue = stats['overdue'] as int;
    final activeCount = (total - done).clamp(0, total);
    final pct = total == 0 ? 0 : (done / total * 100).round();

    return PageFrame(
      title: widget.projectId == null ? null : 'Insight Tim',
      navIndex: widget.projectId == null ? 2 : null,
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          // Clean, direct header without text clutter
          if (widget.projectId == null) ...[
            Row(
              children: [
                const GeoIcon(GeoIconKind.star, size: 32),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Insight Tim', style: T.h1),
                      Text('Pantau beban & aksi prioritas', style: T.caption),
                    ],
                  ),
                ),
                if (project != null)
                  Pill(
                    '$pct% selesai',
                    color: C.lime,
                    foreground: C.teal,
                  ),
              ],
            ),
            const SizedBox(height: S.lg),
          ],

          if (project == null || workload == null || activeResult == null)
            const Surface(
              child: EmptyState(
                'Belum ada proyek',
                'Buat atau gabung ke proyek untuk melihat insight tim.',
              ),
            )
          else ...[
            // Project selector
            DropdownButtonFormField<String>(
              value: id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih proyek',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(13),
                  child: GeoIcon(GeoIconKind.folder, size: 20),
                ),
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
                        _showDetails = false;
                      })
                      : null,
            ),
            const SizedBox(height: S.md),

            // 3-Column visual pulse strip (numbers + flat geometric icons, zero prose)
            Row(
              children: [
                Expanded(
                  child: _PulseTile(
                    icon: GeoIconKind.checkCircle,
                    value: '$done/$total',
                    label: 'Selesai',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PulseTile(
                    icon: GeoIconKind.review,
                    value: '$review',
                    label: 'Review',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PulseTile(
                    icon: overdue > 0 ? GeoIconKind.clock : GeoIconKind.layers,
                    value: overdue > 0 ? '$overdue' : '$activeCount',
                    label: overdue > 0 ? 'Terlambat' : 'Aktif',
                    highlight: overdue > 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: S.xl),

            // Block 1: Scannable visual workload balance
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Keseimbangan beban kerja', style: T.h2),
                _WorkloadStatusPill(workload),
              ],
            ),
            const SizedBox(height: S.md),
            _WorkloadFairnessCard(analysis: workload, controller: c),
            const SizedBox(height: S.xl),

            // Block 2: Action-first AI coordination card
            _AiActionCard(
              result: activeResult,
              hasGenerated: hasGenerated,
              busy: busy,
              error: error,
              showDetails: _showDetails,
              onToggleDetails:
                  () => setState(() => _showDetails = !_showDetails),
              onGenerate: () => generate(c, project, tasks),
            ),

            // Block 3: Tasks needing attention right now (only when present)
            if (attention.isNotEmpty) ...[
              SectionTitle('Perlu tindakan (${attention.length})'),
              ...attention.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskTile(t, controller: c),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PulseTile extends StatelessWidget {
  final GeoIconKind icon;
  final String value, label;
  final bool highlight;
  const _PulseTile({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Surface(
    color: highlight ? C.blush : Colors.white,
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GeoIcon(icon, size: 28),
        const SizedBox(height: 10),
        Text(
          value,
          style: T.number.copyWith(color: highlight ? C.rose : C.ink),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: T.caption.copyWith(color: highlight ? C.rose : C.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _WorkloadStatusPill extends StatelessWidget {
  final TeamWorkloadAnalysis analysis;
  const _WorkloadStatusPill(this.analysis);

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (analysis.status) {
      'balanced' || 'completed' => (C.lime, C.teal),
      'needs_balance' => (C.amber, C.orange),
      _ => (C.sky, C.blue),
    };
    return Pill(analysis.statusLabel, color: bg, foreground: fg);
  }
}

class _WorkloadFairnessCard extends StatelessWidget {
  final TeamWorkloadAnalysis analysis;
  final AppController controller;
  const _WorkloadFairnessCard({
    required this.analysis,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final denominator = analysis.maxAssigned == 0 ? 1 : analysis.maxAssigned;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analysis.members.isEmpty)
            const Text('Belum ada anggota di proyek ini.', style: T.small)
          else
            ...analysis.members.asMap().entries.map((entry) {
              final index = entry.key;
              final m = entry.value;
              final totalMember = m.done + m.active;
              final doneRatio = (m.done / denominator).clamp(0.0, 1.0);
              final activeRatio = (m.active / denominator).clamp(
                0.0,
                1.0 - doneRatio,
              );
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == analysis.members.length - 1 ? 0 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Avatar(
                          m.name,
                          size: 30,
                          index: index,
                          avatarDataUrl: controller.avatarOf(m.uid),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: T.bodyStrong,
                                ),
                              ),
                              if (m.isOwner) ...[
                                const SizedBox(width: 6),
                                const GeoIcon(GeoIconKind.crown, size: 14),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${m.done}/$totalMember tugas',
                          style: T.caption.copyWith(color: C.ink2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 8,
                        width: double.infinity,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final doneW = maxW * doneRatio;
                            final activeW = maxW * activeRatio;
                            return ColoredBox(
                              color: C.panel,
                              child: Row(
                                children: [
                                  if (doneW > 0)
                                    Container(width: doneW, color: C.teal),
                                  if (activeW > 0)
                                    Container(
                                      width: activeW,
                                      color:
                                          m.overdue > 0 ? C.orange : C.blue,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 22),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendDot(C.teal, 'Selesai'),
              _LegendDot(C.blue, 'Aktif'),
              _LegendDot(C.orange, 'Lewat tenggat'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: T.caption),
    ],
  );
}

class _AiActionCard extends StatelessWidget {
  final TeamInsightResult result;
  final bool hasGenerated, busy, showDetails;
  final String? error;
  final VoidCallback onToggleDetails, onGenerate;

  const _AiActionCard({
    required this.result,
    required this.hasGenerated,
    required this.busy,
    required this.error,
    required this.showDetails,
    required this.onToggleDetails,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GeoIcon(GeoIconKind.lightbulb, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.headline, style: T.title),
                    const SizedBox(height: 2),
                    Text(
                      result.isAiGenerated
                          ? 'Saran dari Gemini AI'
                          : 'Ringkasan cepat lokal',
                      style: T.caption,
                    ),
                  ],
                ),
              ),
              Pill(
                result.isAiGenerated ? 'AI' : 'Lokal',
                color: result.isAiGenerated ? C.lavender : C.sky,
                foreground: result.isAiGenerated ? C.purple : C.blue,
              ),
            ],
          ),

          if (result.recommendations.isNotEmpty) ...[
            const SizedBox(height: S.md),
            ...result.recommendations.take(3).map((rec) {
              final tileColor = switch (rec.priority) {
                'high' => C.amber,
                'calm' => C.lime,
                _ => C.sky,
              };
              final hasTask = rec.taskId != null && rec.taskId!.isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Surface(
                  color: tileColor,
                  radius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap:
                      hasTask
                          ? () => context.push('/tasks/${rec.taskId}')
                          : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.title, style: T.bodyStrong),
                            const SizedBox(height: 2),
                            Text(
                              rec.detail,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: T.caption.copyWith(color: C.ink2),
                            ),
                          ],
                        ),
                      ),
                      if (hasTask) ...[
                        const SizedBox(width: 8),
                        const GeoIcon(GeoIconKind.chevronRight, size: 16),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],

          // Collapsible detail section so the page stays uncluttered by default
          if (result.highlights.isNotEmpty || result.summary.isNotEmpty) ...[
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onToggleDetails,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(
                      showDetails ? 'Sembunyikan detail' : 'Lihat detail',
                      style: T.caption.copyWith(
                        color: C.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      showDetails
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: C.blue,
                    ),
                  ],
                ),
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 6),
              Text(result.summary, style: T.small),
              const SizedBox(height: 8),
              ...result.highlights.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 5, color: C.blue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item, style: T.caption)),
                    ],
                  ),
                ),
              ),
            ],
          ],

          if (error != null) ...[
            const SizedBox(height: S.sm),
            ErrorBanner(error!),
          ],

          const SizedBox(height: S.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onGenerate,
              icon:
                  busy
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const GeoIcon(GeoIconKind.star, size: 20),
              label: Text(
                hasGenerated
                    ? 'Perbarui analisis Gemini AI'
                    : 'Analisis dengan Gemini AI',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(controllerProvider);
    final disabled =
        (c.profile['notificationPrefs'] as Map?)?['inApp'] == false;
    final showReview = c.notificationCategoryEnabled('review');
    final showRevision = c.notificationCategoryEnabled('revision');
    final showDeadline = c.notificationCategoryEnabled('deadline');
    final now = today();
    final cutoff = DateTime(now.year, now.month, now.day + 4);
    final tasks =
        c.tasks.where((t) {
          if (c.project(textOf(t, 'projectId'))?['status'] != 'active') {
            return false;
          }
          final status = t['status'];
          if (showReview && t['reviewerId'] == c.uid && status == 'submitted') {
            return true;
          }
          if (!stringsOf(t, 'assigneeIds').contains(c.uid)) return false;
          if (showRevision && status == 'revision_requested') return true;
          if (!showDeadline ||
              !['todo', 'in_progress', 'revision_requested'].contains(status)) {
            return false;
          }
          final deadline = dateOf(t, 'dueAt');
          return deadline != null &&
              !deadline.isBefore(now) &&
              deadline.isBefore(cutoff);
        }).toList();
    return PageFrame(
      title: 'Notifikasi',
      child: ContentList(
        onRefresh: c.refresh,
        children: [
          const PageHeader(
            'Yang perlu perhatianmu',
            subtitle: 'Pengingat tugas & review terbaru.',
            trailing: GeoIcon(GeoIconKind.bell, size: 40),
          ),
          if (disabled)
            const Surface(
              child: EmptyState(
                'Notifikasi dinonaktifkan',
                'Aktifkan kembali melalui preferensi profil.',
                icon: LucideIcons.bellOff,
              ),
            )
          else if (tasks.isEmpty)
            const Surface(
              child: EmptyState(
                'Sudah terbaca semua',
                'Belum ada pengingat yang sesuai dengan pengaturanmu.',
                icon: LucideIcons.bell,
              ),
            )
          else
            ...tasks.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskTile(t, controller: c),
              ),
            ),
          const SizedBox(height: S.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/profile/notifications'),
              icon: const GeoIcon(GeoIconKind.sliders, size: 20),
              label: const Text('Atur notifikasi'),
            ),
          ),
        ],
      ),
    );
  }
}
