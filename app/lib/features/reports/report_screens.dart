import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/geo_icons.dart';
import '../../core/layout.dart';

class PaperlessImpactMetrics {
  final int totalTasks;
  final int submissions;
  final int reviews;
  final int updates;
  final int totalDigitalRecords;
  final int estimatedSheetsSaved;
  final int estimatedCo2GramsSaved;

  const PaperlessImpactMetrics({
    required this.totalTasks,
    required this.submissions,
    required this.reviews,
    required this.updates,
    required this.totalDigitalRecords,
    required this.estimatedSheetsSaved,
    required this.estimatedCo2GramsSaved,
  });
}

PaperlessImpactMetrics computePaperlessImpact(List<Json> tasks) {
  var submissions = 0;
  var reviews = 0;
  var updates = 0;
  for (final task in tasks) {
    submissions += rowsOf(task, 'submissions').length;
    reviews += rowsOf(task, 'reviews').length;
    updates += rowsOf(task, 'updates').length;
  }
  final totalDigitalRecords = tasks.length + submissions + reviews + updates;
  final estimatedSheetsSaved =
      tasks.isEmpty
          ? 2
          : 2 + tasks.length + submissions + reviews + (updates + 1) ~/ 2;
  final estimatedCo2GramsSaved = estimatedSheetsSaved * 5;
  return PaperlessImpactMetrics(
    totalTasks: tasks.length,
    submissions: submissions,
    reviews: reviews,
    updates: updates,
    totalDigitalRecords: totalDigitalRecords,
    estimatedSheetsSaved: estimatedSheetsSaved,
    estimatedCo2GramsSaved: estimatedCo2GramsSaved,
  );
}

String computeReportIntegrityCode(Json report) {
  final tasks =
      rowsOf(report, 'tasks')..sort(
        (a, b) => textOf(a, 'id').compareTo(textOf(b, 'id')),
      );
  final canonical = jsonEncode({
    'id': textOf(report, 'id'),
    'projectId': textOf(report, 'projectId'),
    'projectName': textOf(report, 'projectName'),
    'periodStart': textOf(report, 'periodStart'),
    'periodEnd': textOf(report, 'periodEnd'),
    'createdAt': textOf(report, 'createdAt'),
    'tasks':
        tasks
            .map(
              (t) => {
                'id': textOf(t, 'id'),
                'title': textOf(t, 'title'),
                'status': textOf(t, 'status'),
                'assignees': stringsOf(t, 'assigneeIds')..sort(),
                'reviewer': textOf(t, 'reviewerId'),
                'submissions': rowsOf(t, 'submissions').length,
                'reviews': rowsOf(t, 'reviews').length,
                'updates': rowsOf(t, 'updates').length,
              },
            )
            .toList(),
  });
  final bytes = utf8.encode(canonical);

  int fnv32(int seed, List<int> data) {
    var hash = seed;
    for (final byte in data) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  final h1 = fnv32(0x811C9DC5, bytes);
  final h2 = fnv32(0x050C5D1F, bytes.reversed.toList());
  final hex =
      '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}'
          .toUpperCase();
  return 'JT-${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}';
}

String buildReportVerificationPayload(Json report, String integrityCode) {
  final tasks = rowsOf(report, 'tasks');
  final done = tasks.where((t) => t['status'] == 'done').length;
  final rawId = textOf(report, 'id');
  final shortId = rawId.length > 12 ? rawId.substring(0, 12) : rawId;
  return 'JEJAKTIM|VERIFIED|CODE:$integrityCode|SNAP:$shortId|TASKS:${tasks.length}|DONE:$done';
}

class MemberContribution {
  final String uid;
  final String name;
  final int assigned;
  final int done;
  final int submissions;
  final int reviews;
  final int updates;

  const MemberContribution({
    required this.uid,
    required this.name,
    required this.assigned,
    required this.done,
    required this.submissions,
    required this.reviews,
    required this.updates,
  });
}

List<MemberContribution> buildMemberContributions(
  List<Json> tasks, {
  List<String> memberIds = const [],
  Map<String, String> memberNames = const {},
}) {
  final ids = <String>{...memberIds};
  for (final task in tasks) {
    ids.addAll(stringsOf(task, 'assigneeIds'));
    final reviewer = textOf(task, 'reviewerId');
    if (reviewer.isNotEmpty) ids.add(reviewer);
    for (final s in rowsOf(task, 'submissions')) {
      final by = textOf(s, 'submittedBy');
      if (by.isNotEmpty) ids.add(by);
    }
    for (final r in rowsOf(task, 'reviews')) {
      final by = textOf(r, 'reviewerId');
      if (by.isNotEmpty) ids.add(by);
    }
    for (final u in rowsOf(task, 'updates')) {
      final by = textOf(u, 'authorId');
      if (by.isNotEmpty) ids.add(by);
    }
  }
  final result =
      ids.map((id) {
        var assigned = 0;
        var done = 0;
        var submissions = 0;
        var reviews = 0;
        var updates = 0;
        for (final task in tasks) {
          if (stringsOf(task, 'assigneeIds').contains(id)) {
            assigned++;
            if (task['status'] == 'done') done++;
          }
          submissions +=
              rowsOf(
                task,
                'submissions',
              ).where((s) => s['submittedBy'] == id).length;
          reviews +=
              rowsOf(task, 'reviews').where((r) => r['reviewerId'] == id).length;
          updates +=
              rowsOf(task, 'updates').where((u) => u['authorId'] == id).length;
        }
        return MemberContribution(
          uid: id,
          name: memberNames[id]?.trim().isNotEmpty == true
              ? memberNames[id]!.trim()
              : 'Anggota',
          assigned: assigned,
          done: done,
          submissions: submissions,
          reviews: reviews,
          updates: updates,
        );
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return result;
}

Future<Uint8List> buildReportPdf(
  Json report, {
  Map<String, String> memberNames = const {},
  List<String> memberIds = const [],
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Outfit-400.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Outfit-600.ttf'),
  );
  final doc = pw.Document();
  final tasks = rowsOf(report, 'tasks');
  final contributions = buildMemberContributions(
    tasks,
    memberIds: memberIds,
    memberNames: memberNames,
  );
  final impact = computePaperlessImpact(tasks);
  final integrityCode = computeReportIntegrityCode(report);
  final verificationPayload = buildReportVerificationPayload(
    report,
    integrityCode,
  );
  final doneCount = tasks.where((t) => t['status'] == 'done').length;
  final reviewCount = tasks.where((t) => t['status'] == 'submitted').length;
  final revisionCount =
      tasks.where((t) => t['status'] == 'revision_requested').length;

  String labelFor(String? uid) {
    if (uid == null || uid.isEmpty) return '-';
    final name = memberNames[uid]?.trim();
    return (name == null || name.isEmpty) ? 'Anggota' : name;
  }

  String assigneesLabel(Json task) {
    final ids = stringsOf(task, 'assigneeIds');
    return ids.isEmpty ? '-' : ids.map(labelFor).join(', ');
  }

  pw.Widget metricBox(String value, String label) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
        ],
      ),
    ),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      margin: const pw.EdgeInsets.all(36),
      header:
          (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'JejakTim',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.Text(
                  'LAPORAN PROSES & KONTRIBUSI TIM',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
      footer:
          (context) => pw.Text(
            'JejakTim | Bukan penilaian akademik | Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
      build:
          (_) => [
            pw.Text(
              textOf(report, 'projectName'),
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Periode: ${dateLabel(report['periodStart'])} - ${dateLabel(report['periodEnd'])}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Dibuat: ${dateLabel(report['createdAt'], time: true)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Laporan ini memuat snapshot tugas dan jejak kontribusi yang diperbarui dalam periode terpilih. Data menunjukkan proses kolaborasi, bukan nilai atau peringkat anggota.',
              style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              children: [
                metricBox('${tasks.length}', 'Total tugas'),
                pw.SizedBox(width: 8),
                metricBox('$doneCount', 'Selesai'),
                pw.SizedBox(width: 8),
                metricBox('$reviewCount', 'Menunggu review'),
                pw.SizedBox(width: 8),
                metricBox('$revisionCount', 'Perlu revisi'),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Daftar Tugas',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (tasks.isEmpty)
              pw.Text(
                'Tidak ada tugas yang diperbarui dalam periode ini.',
                style: const pw.TextStyle(fontSize: 10),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  'Tugas',
                  'Penanggung Jawab',
                  'Reviewer',
                  'Status',
                  'Tenggat',
                ],
                data:
                    tasks
                        .map(
                          (t) => [
                            textOf(t, 'title'),
                            assigneesLabel(t),
                            labelFor(t['reviewerId']?.toString()),
                            statusLabel(t),
                            dateLabel(t['dueAt']),
                          ],
                        )
                        .toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.all(7),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.6),
                  1: pw.FlexColumnWidth(1.8),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.3),
                  4: pw.FlexColumnWidth(1.3),
                },
              ),
            if (contributions.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Ringkasan Jejak Kontribusi Anggota',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Anggota',
                  'Ditugaskan',
                  'Selesai',
                  'Bukti Dikirim',
                  'Review',
                  'Catatan',
                ],
                data:
                    contributions
                        .map(
                          (m) => [
                            m.name,
                            '${m.assigned}',
                            '${m.done}',
                            '${m.submissions}',
                            '${m.reviews}',
                            '${m.updates}',
                          ],
                        )
                        .toList(),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue50,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.all(7),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.4),
                  1: pw.FlexColumnWidth(1.1),
                  2: pw.FlexColumnWidth(1.0),
                  3: pw.FlexColumnWidth(1.2),
                  4: pw.FlexColumnWidth(1.0),
                  5: pw.FlexColumnWidth(1.0),
                },
              ),
            ],
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'JEJAK PAPERLESS & KEBERLANJUTAN',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${impact.totalDigitalRecords} rekam jejak digital (${impact.submissions} bukti kerja, ${impact.reviews} peer review, ${impact.updates} catatan proses) terdokumentasi tanpa cetak fisik — estimasi menghemat ~${impact.estimatedSheetsSaved} lembar kertas (±${impact.estimatedCo2GramsSaved} g CO2e).',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    color: PdfColors.white,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: verificationPayload,
                      width: 62,
                      height: 62,
                      drawText: false,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VERIFIKASI INTEGRITAS SNAPSHOT',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Kode Integritas: $integrityCode',
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Snapshot otomatis dari sistem JejakTim untuk menjaga keaslian jejak kontribusi tanpa suntingan manual.',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'Privasi: tautan bukti, email, dan dokumen pribadi tidak disertakan. Bagikan laporan hanya kepada pihak yang kamu pilih.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
    ),
  );
  return doc.save();
}

class ReportScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ReportScreen(this.projectId, {super.key});
  @override
  ConsumerState<ReportScreen> createState() => _ReportState();
}

class _ReportState extends ConsumerState<ReportScreen> {
  DateTimeRange period = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  Json? snapshot;
  String? error;
  bool busy = false, sharing = false;
  Future<void> generate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await ref
          .read(controllerProvider)
          .act('generateProjectReport', {
            'projectId': widget.projectId,
            'periodStart':
                DateTime(
                  period.start.year,
                  period.start.month,
                  period.start.day,
                ).toUtc().toIso8601String(),
            'periodEnd':
                DateTime(
                  period.end.year,
                  period.end.month,
                  period.end.day,
                  23,
                  59,
                  59,
                ).toUtc().toIso8601String(),
          });
      if (mounted) setState(() => snapshot = result);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Map<String, String> _memberNameMap(AppController c) => {
    for (final person in c.people)
      if (textOf(person, 'uid').isNotEmpty)
        textOf(person, 'uid'): textOf(person, 'name', 'Anggota'),
  };

  Future<void> share(AppController c, Json project) async {
    setState(() => sharing = true);
    try {
      final bytes = await buildReportPdf(
        snapshot!,
        memberNames: _memberNameMap(c),
        memberIds: stringsOf(project, 'memberIds'),
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'JejakTim-Laporan-${widget.projectId}.pdf',
      );
    } catch (e) {
      if (mounted) {
        setState(() => error = 'PDF belum dapat dibagikan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final p = c.project(widget.projectId);
    if (p == null) {
      return const PageFrame(
        title: 'Laporan',
        child: EmptyState('Akses tidak tersedia', 'Proyek tidak ditemukan.'),
      );
    }
    final tasks = c.projectTasks(widget.projectId);
    final snapshotTasks =
        snapshot == null ? <Json>[] : rowsOf(snapshot!, 'tasks');
    final contributions =
        snapshot == null
            ? <MemberContribution>[]
            : buildMemberContributions(
              snapshotTasks,
              memberIds: stringsOf(p, 'memberIds'),
              memberNames: _memberNameMap(c),
            );
    final impact =
        snapshot == null ? null : computePaperlessImpact(snapshotTasks);
    final integrityCode =
        snapshot == null ? null : computeReportIntegrityCode(snapshot!);
    final verificationPayload =
        snapshot == null || integrityCode == null
            ? null
            : buildReportVerificationPayload(snapshot!, integrityCode);
    return PageFrame(
      title: snapshot == null ? 'Laporan proyek' : 'Pratinjau laporan',
      child: ContentList(
        children: [
          if (snapshot == null) ...[
            const PageHeader(
              'Ceritakan proses,\nbukan sekadar hasil.',
              subtitle:
                  'Satukan jejak kerja menjadi laporan yang mudah dibaca dan dibagikan.',
              trailing: GeoIcon(GeoIconKind.document, size: 46),
            ),
            Surface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KELENGKAPAN LAPORAN', style: T.overline),
                  const SizedBox(height: 6),
                  Text(textOf(p, 'name'), style: T.h2),
                  const SizedBox(height: S.lg),
                  _check(
                    'Tugas memiliki penanggung jawab',
                    tasks.isNotEmpty &&
                        tasks.every(
                          (t) => stringsOf(t, 'assigneeIds').isNotEmpty,
                        ),
                  ),
                  _check(
                    'Semua tugas selesai',
                    tasks.isNotEmpty &&
                        tasks.every((t) => t['status'] == 'done'),
                  ),
                  _check(
                    'Bukti kerja tercatat',
                    tasks.any((t) => rowsOf(t, 'submissions').isNotEmpty),
                  ),
                  const Divider(height: 20),
                  const Text(
                    'Laporan progres tetap dapat dibuat meski proyek belum selesai.',
                    style: T.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.md),
            Surface(
              padding: const EdgeInsets.all(14),
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: period,
                );
                if (range != null) setState(() => period = range);
              },
              child: Row(
                children: [
                  const GeoIcon(GeoIconKind.calendar, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Periode laporan', style: T.caption),
                        Text(
                          '${dateLabel(period.start.toIso8601String())} — ${dateLabel(period.end.toIso8601String())}',
                          style: T.bodyStrong,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: C.subtle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.xl),
            PrimaryButton(
              'Buat pratinjau laporan',
              icon: LucideIcons.fileText,
              onPressed: generate,
              busy: busy,
            ),
          ] else ...[
            Surface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      BrandLogo(size: 34),
                      SizedBox(width: 10),
                      Text('JejakTim', style: T.h2),
                    ],
                  ),
                  const SizedBox(height: S.lg),
                  Text(
                    'LAPORAN PROSES & KONTRIBUSI PROYEK',
                    style: T.overline.copyWith(color: C.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(textOf(snapshot!, 'projectName'), style: T.h1),
                  const SizedBox(height: 8),
                  Text(
                    '${dateLabel(snapshot!['periodStart'])} — ${dateLabel(snapshot!['periodEnd'])}',
                    style: T.caption,
                  ),
                  Text(
                    'Dibuat ${dateLabel(snapshot!['createdAt'], time: true)}',
                    style: T.caption,
                  ),
                  const Divider(height: 28),
                  ...snapshotTasks.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(textOf(t, 'title'), style: T.bodyStrong),
                          const SizedBox(height: 3),
                          Text(
                            '${statusLabel(t)} · ${dateLabel(t['dueAt'])}',
                            style: T.caption,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PJ: ${stringsOf(t, 'assigneeIds').map(c.name).join(', ')} · Reviewer: ${c.name(t['reviewerId'])}',
                            style: T.caption.copyWith(color: C.ink2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshotTasks.isEmpty)
                    const Text(
                      'Tidak ada tugas yang diperbarui dalam periode ini.',
                      style: T.small,
                    ),
                  if (contributions.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'JEJAK KONTRIBUSI ANGGOTA',
                      style: T.overline.copyWith(color: C.blue),
                    ),
                    const SizedBox(height: S.md),
                    ...contributions.map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Avatar(
                              m.name,
                              size: 32,
                              avatarDataUrl: c.avatarOf(m.uid),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name, style: T.bodyStrong),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${m.done}/${m.assigned} tugas selesai · ${m.submissions} bukti · ${m.reviews} review · ${m.updates} catatan',
                                    style: T.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (impact != null) ...[
                    const Divider(height: 24),
                    Surface(
                      color: C.lime,
                      padding: const EdgeInsets.all(14),
                      radius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Pill(
                            'JEJAK PAPERLESS',
                            color: Colors.white,
                            foreground: C.teal,
                            icon: LucideIcons.sprout,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Estimasi hemat ~${impact.estimatedSheetsSaved} lembar kertas (±${impact.estimatedCo2GramsSaved} g CO2e)',
                            style: T.bodyStrong,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${impact.totalDigitalRecords} rekam jejak digital (${impact.submissions} bukti · ${impact.reviews} review · ${impact.updates} catatan) menggantikan logbook cetak.',
                            style: T.caption.copyWith(color: C.ink2),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (integrityCode != null && verificationPayload != null) ...[
                    const SizedBox(height: S.md),
                    Surface(
                      color: C.panel,
                      padding: const EdgeInsets.all(14),
                      radius: 16,
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: 78,
                              height: 78,
                              child: QrImageView(
                                data: verificationPayload,
                                version: QrVersions.auto,
                                size: 78,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.circle,
                                  color: C.blue,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.circle,
                                  color: C.ink,
                                ),
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VERIFIKASI INTEGRITAS SNAPSHOT',
                                  style: T.overline.copyWith(color: C.blue),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  integrityCode,
                                  style: T.title.copyWith(letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Kode & QR ikut tercetak di PDF untuk membuktikan laporan berasal langsung dari sistem JejakTim.',
                                  style: T.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  const Text(
                    'Snapshot proses, bukan nilai akademik. Email dan tautan bukti pribadi tidak disertakan.',
                    style: T.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.xl),
            PrimaryButton(
              'Bagikan / simpan PDF',
              icon: LucideIcons.share2,
              onPressed: () => share(c, p),
              busy: sharing,
            ),
            Center(
              child: TextButton(
                onPressed: () => setState(() => snapshot = null),
                child: const Text('Ubah periode'),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: S.md),
            ErrorBanner(error!),
          ],
        ],
      ),
    );
  }

  Widget _check(String label, bool value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        value
            ? const GeoIcon(GeoIconKind.checkCircle, size: 20)
            : const Icon(LucideIcons.circle, size: 19, color: C.subtle),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: T.body)),
      ],
    ),
  );
}
