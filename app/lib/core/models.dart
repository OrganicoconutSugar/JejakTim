import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;
String textOf(Json row, String key, [String fallback = '']) =>
    row[key]?.toString() ?? fallback;
List<Json> rowsOf(Json row, String key) =>
    (row[key] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
List<String> stringsOf(Json row, String key) =>
    (row[key] as List? ?? []).map((e) => e.toString()).toList();
DateTime? dateOf(Json row, String key) =>
    DateTime.tryParse(textOf(row, key))?.toLocal();
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime today() => dateOnly(DateTime.now());
bool isPastDate(DateTime? value) =>
    value != null && dateOnly(value).isBefore(today());
String dateLabel(dynamic value, {bool time = false}) {
  final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  return d == null
      ? 'Tanpa tenggat'
      : DateFormat(time ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy', 'id').format(d);
}

const statusLabels = {
  'todo': 'Belum mulai',
  'in_progress': 'Dikerjakan',
  'submitted': 'Perlu review',
  'revision_requested': 'Perlu revisi',
  'done': 'Selesai',
  'cancelled': 'Dibatalkan',
};
String statusLabel(Json task) => statusLabels[task['status']] ?? 'Belum mulai';

const activityActionLabels = {
  'createProject': 'Membuat proyek',
  'saveProject': 'Memperbarui pengaturan proyek',
  'createInvite': 'Memperbarui kode undangan',
  'joinProject': 'Bergabung ke proyek',
  'removeMember': 'Menghapus keanggotaan proyek',
  'saveTask': 'Menyimpan perubahan tugas',
  'startTask': 'Memulai tugas',
  'addUpdate': 'Mencatat pembaruan tugas',
  'submitTask': 'Mengirim bukti kerja',
  'reviewSubmission': 'Meninjau hasil kerja',
  'removeTask': 'Menghapus tugas',
  'leaveProject': 'Keluar dari proyek',
  'transferOwnership': 'Mengalihkan peran ketua proyek',
  'generateProjectReport': 'Membuat snapshot laporan',
};

String activitySummary(Json event) {
  final raw = textOf(event, 'summary').trim();
  return activityActionLabels[raw] ?? raw;
}

class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
  @override
  String toString() => message;
}

String? requiredText(String? value, {int min = 3, int max = 200}) {
  final v = value?.trim() ?? '';
  if (v.length < min) return 'Isi minimal $min karakter.';
  if (v.length > max) return 'Maksimal $max karakter.';
  return null;
}

String? emailError(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
        ? null
        : 'Masukkan alamat email yang valid.';
bool validEvidence(String value) {
  final uri = Uri.tryParse(value);
  return value.length <= 2048 &&
      uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.contains('.') &&
      uri.userInfo.isEmpty;
}

String normalizeEvidenceLink(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.contains('://') ? trimmed : 'https://$trimmed';
}

void require(bool condition, String message) {
  if (!condition) throw AppFailure(message);
}

void canSubmit(Json task, String uid) {
  require(
    stringsOf(task, 'assigneeIds').contains(uid),
    'Hanya penanggung jawab yang dapat mengirim bukti.',
  );
  require(
    ['in_progress', 'revision_requested'].contains(task['status']),
    'Mulai tugas atau lakukan revisi sebelum mengirim bukti.',
  );
}

void canReview(Json task, Json submission, String uid) {
  require(
    task['reviewerId'] == uid && submission['submittedBy'] != uid,
    'Review harus dilakukan rekan yang ditunjuk, bukan pengirim.',
  );
  require(
    task['status'] == 'submitted' && submission['status'] == 'pending_review',
    'Submission ini sudah berubah. Muat ulang tugas.',
  );
}

Json aggregateTasks(List<Json> tasks, DateTime now) => {
  'total': tasks.length,
  'done': tasks.where((t) => t['status'] == 'done').length,
  'review': tasks.where((t) => t['status'] == 'submitted').length,
  'overdue':
      tasks
          .where(
            (t) =>
                !['done', 'cancelled'].contains(t['status']) &&
                dateOf(t, 'dueAt') != null &&
                dateOf(t, 'dueAt')!.isBefore(now),
          )
          .length,
};
