import '../../core/illustrated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/controller.dart';
import '../../core/models.dart';
import '../../core/design.dart';
import '../../core/layout.dart';

Future<Uint8List> buildReportPdf(Json report) async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Outfit-400.ttf'),
  );
  final doc = pw.Document();
  final tasks = rowsOf(report, 'tasks');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: font),
      margin: const pw.EdgeInsets.all(40),
      header:
          (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'JejakTim',
                  style: pw.TextStyle(fontSize: 24, color: PdfColors.blue700),
                ),
                pw.Text(
                  'LAPORAN PROSES',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
      footer:
          (context) => pw.Text(
            'JejakTim | Bukan penilaian akademik | Halaman ${context.pageNumber}',
            style: const pw.TextStyle(fontSize: 9),
          ),
      build:
          (_) => [
            pw.Text(
              textOf(report, 'projectName'),
              style: const pw.TextStyle(fontSize: 25),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Periode: ${dateLabel(report['periodStart'])} - ${dateLabel(report['periodEnd'])}',
            ),
            pw.Text('Dibuat: ${dateLabel(report['createdAt'], time: true)}'),
            pw.SizedBox(height: 18),
            pw.Text(
              'Laporan ini memuat snapshot tugas yang diperbarui dalam periode terpilih. Data menunjukkan proses, bukan nilai atau peringkat anggota.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Tugas', 'Status', 'Tenggat'],
              data:
                  tasks
                      .map(
                        (t) => [
                          textOf(t, 'title'),
                          statusLabel(t),
                          dateLabel(t['dueAt']),
                        ],
                      )
                      .toList(),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              headerStyle: const pw.TextStyle(fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.all(9),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              '${tasks.where((t) => t['status'] == 'done').length} dari ${tasks.length} tugas selesai.',
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Privasi: tautan bukti, email, dan dokumen pribadi tidak disertakan. Bagikan laporan hanya kepada pihak yang kamu pilih.',
              style: const pw.TextStyle(fontSize: 10),
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

  Future<void> share() async {
    setState(() => sharing = true);
    try {
      final bytes = await buildReportPdf(snapshot!);
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
    return PageFrame(
      title: snapshot == null ? 'Laporan proyek' : 'Pratinjau laporan',
      child: ContentList(
        children: [
          if (snapshot == null) ...[
            const FloatingArt('report-analytics', height: 170),
            Text(
              'Ceritakan proses,\nbukan sekadar hasil.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Satukan jejak kerja menjadi laporan yang mudah dibaca dan dibagikan.',
              style: TextStyle(color: C.muted, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Surface(
              color: C.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textOf(p, 'name'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 8),
                  const Text(
                    'Laporan progres tetap dapat dibuat meski proyek belum selesai.',
                    style: TextStyle(fontSize: 12, color: C.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Surface(
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
                  const AppIcon(LucideIcons.calendarDays, color: C.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${dateLabel(period.start.toIso8601String())} — ${dateLabel(period.end.toIso8601String())}',
                    ),
                  ),
                  const AppIcon(LucideIcons.chevronDown, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              'Buat pratinjau laporan',
              icon: LucideIcons.fileText,
              onPressed: generate,
              busy: busy,
            ),
          ] else ...[
            Surface(
              color: C.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      BrandLogo(size: 36),
                      SizedBox(width: 10),
                      Text(
                        'JejakTim',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'LAPORAN PROSES PROYEK',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      color: C.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    textOf(snapshot!, 'projectName'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${dateLabel(snapshot!['periodStart'])} — ${dateLabel(snapshot!['periodEnd'])}',
                    style: const TextStyle(fontSize: 12, color: C.muted),
                  ),
                  Text(
                    'Dibuat ${dateLabel(snapshot!['createdAt'], time: true)}',
                    style: const TextStyle(fontSize: 12, color: C.muted),
                  ),
                  const Divider(height: 36),
                  ...rowsOf(snapshot!, 'tasks').map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            textOf(t, 'title'),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${statusLabel(t)} · ${dateLabel(t['dueAt'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: C.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (rowsOf(snapshot!, 'tasks').isEmpty)
                    const Text(
                      'Tidak ada tugas yang diperbarui dalam periode ini.',
                    ),
                  const Divider(height: 28),
                  const Text(
                    'Snapshot proses, bukan nilai akademik. Email dan tautan bukti pribadi tidak disertakan.',
                    style: TextStyle(fontSize: 12, color: C.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              'Bagikan / simpan PDF',
              icon: LucideIcons.share2,
              onPressed: share,
              busy: sharing,
            ),
            TextButton(
              onPressed: () => setState(() => snapshot = null),
              child: const Text('Ubah periode'),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            ErrorBanner(error!),
          ],
        ],
      ),
    );
  }

  Widget _check(String label, bool value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        AppIcon(
          value ? LucideIcons.checkCircle2 : LucideIcons.circle,
          size: 20,
          color: value ? const Color(0xFF297047) : C.muted,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}
