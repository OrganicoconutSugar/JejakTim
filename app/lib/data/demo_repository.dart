import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/models.dart';
import 'repository.dart';

const demoPeople = [
  {
    'uid': 'nara',
    'name': 'Nara Putri',
    'email': 'nara@example.test',
    'major': 'Sistem Informasi',
    'institution': 'Kampus Demo',
  },
  {
    'uid': 'raka',
    'name': 'Raka Aditya',
    'email': 'raka@example.test',
    'major': 'Teknik Informatika',
    'institution': 'Kampus Demo',
  },
  {
    'uid': 'salsa',
    'name': 'Salsa Amalia',
    'email': 'salsa@example.test',
    'major': 'Desain Komunikasi Visual',
    'institution': 'Kampus Demo',
  },
];

class DemoRepository implements TeamRepository {
  static const storageKey = 'jejaktim.demo.v1';
  final SharedPreferences prefs;
  late Json db;
  DemoRepository(this.prefs) {
    final saved = prefs.getString(storageKey);
    if (saved == null) {
      db = seed();
      return;
    }
    try {
      db = _decodeStored(saved);
    } on FormatException {
      _recoverStorage();
    } on TypeError {
      _recoverStorage();
    }
  }

  static Json _decodeStored(String saved) {
    final decoded = jsonDecode(saved);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Demo storage must be a JSON object.');
    }
    for (final key in [
      'profiles',
      'projects',
      'tasks',
      'activity',
      'invites',
      'reports',
    ]) {
      final rows = decoded[key];
      if (rows is! List || rows.any((row) => row is! Map)) {
        throw FormatException('Demo storage has an invalid $key collection.');
      }
    }
    return decoded;
  }

  void _recoverStorage() {
    db = seed();
    unawaited(prefs.setString(storageKey, jsonEncode(db)));
  }

  @override
  bool get isDemo => true;
  @override
  Future<void> clearSession() async {}
  Future<void> reset() async {
    db = seed();
    await prefs.setString(storageKey, jsonEncode(db));
  }

  static Json seed() {
    final now = DateTime.now().toUtc();
    String day(int n) => now.add(Duration(days: n)).toIso8601String();
    Json task(
      String id,
      String title,
      String status,
      int days,
      List<String> assignees,
      String reviewer,
    ) => {
      'id': id,
      'projectId': 'p1',
      'title': title,
      'description':
          'Susun hasil kerja yang jelas, sertakan referensi, lalu minta masukan rekan tim.',
      'status': status,
      'assigneeIds': assignees,
      'reviewerId': reviewer,
      'dueAt': day(days),
      'createdAt': day(-5),
      'updatedAt': day(-1),
      'version': 1,
      'updates': <Json>[],
      'submissions': <Json>[],
      'reviews': <Json>[],
    };
    final pending = task('t2', 'Review wireframe aplikasi', 'submitted', 2, [
      'salsa',
    ], 'nara');
    pending['submissions'] = [
      {
        'id': 's1',
        'submittedBy': 'salsa',
        'note':
            'Alur utama siap ditinjau. Ini tautan contoh untuk demonstrasi.',
        'evidenceLinks': [
          {'label': 'Bukti contoh', 'url': 'https://example.com/wireframe'},
        ],
        'status': 'pending_review',
        'submittedAt': day(-1),
      },
    ];
    pending['latestSubmissionId'] = 's1';
    return {
      'profiles': demoPeople.map((p) => Map<String, dynamic>.from(p)).toList(),
      'projects': [
        {
          'id': 'p1',
          'name': 'Riset & Desain Aplikasi',
          'description':
              'Membangun pengalaman kolaborasi mahasiswa yang lebih baik.',
          'courseLabel': 'Interaksi Manusia & Komputer',
          'targetDate': day(12),
          'ownerId': 'nara',
          'status': 'active',
          'memberIds': ['nara', 'raka', 'salsa'],
          'createdAt': day(-7),
          'color': 0,
        },
        {
          'id': 'p2',
          'name': 'Kampus Berkelanjutan',
          'description': 'Eksplorasi kebiasaan ramah lingkungan di kampus.',
          'courseLabel': 'Proyek SDG 4',
          'targetDate': day(18),
          'ownerId': 'raka',
          'status': 'active',
          'memberIds': ['nara', 'raka'],
          'createdAt': day(-3),
          'color': 1,
        },
      ],
      'tasks': [
        task('t1', 'Susun hasil riset pengguna', 'in_progress', 1, [
          'nara',
        ], 'raka'),
        pending,
        task('t3', 'Rangkum referensi jurnal', 'done', -1, ['raka'], 'salsa'),
        task('t4', 'Siapkan materi presentasi', 'todo', 5, [
          'nara',
          'raka',
        ], 'salsa'),
      ],
      'activity': [
        {
          'id': 'a1',
          'projectId': 'p1',
          'actorId': 'salsa',
          'summary': 'Mengirim wireframe untuk ditinjau',
          'createdAt': day(-1),
          'entityId': 't2',
        },
      ],
      'invites': [
        {
          'code': 'JEJAK2026',
          'projectId': 'p1',
          'expiresAt': day(7),
          'status': 'active',
        },
      ],
      'reports': <Json>[],
    };
  }

  List<Json> list(String key) => rowsOf(db, key);
  Json project(String id, String uid, {bool owner = false}) {
    final p = list('projects').where((p) => p['id'] == id).firstOrNull;
    require(
      p != null && stringsOf(p, 'memberIds').contains(uid),
      'Akses proyek tidak tersedia.',
    );
    require(
      !owner || p!['ownerId'] == uid,
      'Hanya ketua proyek yang dapat melakukan tindakan ini.',
    );
    return p!;
  }

  @override
  Future<Json> load(String uid) async {
    final projects =
        list(
          'projects',
        ).where((p) => stringsOf(p, 'memberIds').contains(uid)).toList();
    final ids = projects.map((p) => p['id']).toSet();
    return {
      'profile': list('profiles').firstWhere((p) => p['uid'] == uid),
      'profiles': list('profiles'),
      'projects': projects,
      'tasks':
          list('tasks').where((t) => ids.contains(t['projectId'])).toList(),
      'activity':
          list('activity').where((a) => ids.contains(a['projectId'])).toList(),
      'reports':
          list('reports').where((r) => ids.contains(r['projectId'])).toList(),
    };
  }

  void put(String key, Json row, {String idKey = 'id'}) {
    final all = list(key);
    final index = all.indexWhere((r) => r[idKey] == row[idKey]);
    if (index < 0) {
      all.add(row);
    } else {
      all[index] = row;
    }
    db[key] = all;
  }

  void event(String uid, String pid, String message, [String? entityId]) {
    put('activity', {
      'id': const Uuid().v4(),
      'projectId': pid,
      'actorId': uid,
      'summary': message,
      'entityId': entityId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<Json> command(String uid, String action, Json payload) async {
    // Serialize local mutations; all validation precedes persisted state.
    final before = jsonEncode(db);
    try {
      final result = execute(uid, action, payload);
      await prefs.setString(storageKey, jsonEncode(db));
      return result;
    } catch (_) {
      db = jsonDecode(before) as Json;
      rethrow;
    }
  }

  Json execute(String uid, String action, Json d) {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = const Uuid().v4();
    if (action == 'saveProfile') {
      require(requiredText(d['name']) == null, 'Nama minimal 3 karakter.');
      final p = list('profiles').firstWhere((p) => p['uid'] == uid);
      for (final k in ['name', 'institution', 'major', 'notificationPrefs']) {
        if (d.containsKey(k)) p[k] = d[k];
      }
      put('profiles', p, idKey: 'uid');
      return p;
    }
    if (action == 'createProject') {
      require(requiredText(d['name']) == null, 'Nama proyek tidak valid.');
      final p = {
        ...d,
        'id': id,
        'ownerId': uid,
        'status': 'active',
        'memberIds': [uid],
        'createdAt': now,
      };
      put('projects', p);
      event(uid, id, 'Membuat proyek');
      return p;
    }
    if (action == 'previewInvite' || action == 'joinProject') {
      final invite =
          list('invites')
              .where(
                (i) =>
                    i['code'] == textOf(d, 'code').trim().toUpperCase() &&
                    i['status'] == 'active',
              )
              .firstOrNull;
      require(
        invite != null &&
            DateTime.parse(invite['expiresAt']).isAfter(DateTime.now()),
        'Kode tidak cocok atau kedaluwarsa. Minta kode baru kepada ketua.',
      );
      final p = list(
        'projects',
      ).firstWhere((p) => p['id'] == invite!['projectId']);
      require(p['status'] == 'active', 'Proyek sudah ditutup.');
      final members = stringsOf(p, 'memberIds');
      require(
        members.length < 30 || members.contains(uid),
        'Proyek penuh. Hubungi ketua.',
      );
      if (action == 'joinProject' && !members.contains(uid)) {
        p['memberIds'] = [...members, uid];
        put('projects', p);
        event(uid, p['id'], 'Bergabung ke proyek');
      }
      return {
        'id': p['id'],
        'name': p['name'],
        'description': p['description'],
        'ownerName':
            list(
              'profiles',
            ).firstWhere((u) => u['uid'] == p['ownerId'])['name'],
        'memberCount': stringsOf(p, 'memberIds').length,
      };
    }
    final pid = textOf(d, 'projectId');
    final p = project(
      pid,
      uid,
      owner: [
        'createInvite',
        'saveProject',
        'removeMember',
        'saveTask',
      ].contains(action),
    );
    if (action == 'createInvite') {
      require(p['status'] == 'active', 'Proyek sudah ditutup.');
      final invites = list('invites');
      for (final inv in invites) {
        if (inv['projectId'] == pid) inv['status'] = 'revoked';
      }
      db['invites'] = invites;
      final code = id.replaceAll('-', '').substring(0, 12).toUpperCase();
      put('invites', {
        'id': id,
        'code': code,
        'projectId': pid,
        'status': 'active',
        'expiresAt':
            DateTime.now()
                .toUtc()
                .add(const Duration(days: 7))
                .toIso8601String(),
      });
      event(uid, pid, 'Memperbarui kode undangan');
      return {'code': code};
    }
    if (action == 'saveProject') {
      require(requiredText(d['name']) == null, 'Nama proyek tidak valid.');
      for (final k in [
        'name',
        'description',
        'courseLabel',
        'targetDate',
        'status',
      ]) {
        if (d.containsKey(k)) p[k] = d[k];
      }
      put('projects', p);
      event(uid, pid, 'Memperbarui pengaturan proyek');
      return p;
    }
    if (action == 'removeMember') {
      final member = textOf(d, 'memberId');
      require(member != p['ownerId'], 'Ketua tidak dapat dikeluarkan.');
      require(
        !list('tasks').any(
          (t) =>
              t['projectId'] == pid &&
              !['done', 'cancelled'].contains(t['status']) &&
              (stringsOf(t, 'assigneeIds').contains(member) ||
                  t['reviewerId'] == member),
        ),
        'Alihkan tugas aktif anggota ini lebih dahulu.',
      );
      p['memberIds'] =
          stringsOf(p, 'memberIds').where((m) => m != member).toList();
      put('projects', p);
      event(uid, pid, 'Menghapus keanggotaan proyek');
      return p;
    }
    if (action == 'generateProjectReport') {
      final start = DateTime.parse(d['periodStart']);
      final end = DateTime.parse(d['periodEnd']);
      final tasks =
          list('tasks')
              .where(
                (t) =>
                    t['projectId'] == pid &&
                    !DateTime.parse(t['updatedAt']).isBefore(start) &&
                    !DateTime.parse(t['updatedAt']).isAfter(end),
              )
              .toList();
      final r = {
        'id': id,
        'projectId': pid,
        'projectName': p['name'],
        'generatedBy': uid,
        'createdAt': now,
        'periodStart': d['periodStart'],
        'periodEnd': d['periodEnd'],
        'tasks': tasks,
        'summary': aggregateTasks(tasks, DateTime.now()),
        'status': 'ready',
      };
      put('reports', r);
      event(uid, pid, 'Membuat snapshot laporan');
      return r;
    }
    if (action == 'generateTeamInsight') {
      require(
        list('tasks').where((t) => t['projectId'] == pid).length >= 3,
        'Data belum cukup. Catat minimal 3 tugas dan pembaruannya.',
      );
      throw const AppFailure(
        'AI belum terhubung. Ringkasan di bawah dihitung dari tugas; Anda tetap dapat berkoordinasi secara manual.',
      );
    }
    require(
      p['status'] == 'active',
      'Proyek diarsipkan. Buka kembali sebelum mengubah tugas.',
    );
    if (action == 'saveTask') {
      require(requiredText(d['title']) == null, 'Judul tugas tidak valid.');
      final assignees = stringsOf(d, 'assigneeIds');
      final members = stringsOf(p, 'memberIds');
      require(
        assignees.isNotEmpty && assignees.every(members.contains),
        'Pilih penanggung jawab dari anggota proyek.',
      );
      require(
        members.contains(d['reviewerId']) &&
            !assignees.contains(d['reviewerId']),
        'Pilih reviewer lain di dalam proyek.',
      );
      final existing =
          list('tasks')
              .where((t) => t['id'] == d['taskId'] && t['projectId'] == pid)
              .firstOrNull;
      if (existing != null) {
        require(
          existing['version'] == d['version'],
          'Tugas berubah. Muat ulang sebelum mengedit.',
        );
        require(
          [
            'todo',
            'in_progress',
            'revision_requested',
          ].contains(existing['status']),
          'Tugas dalam review atau selesai tidak dapat diedit.',
        );
      }
      final t = {
        ...?(existing),
        ...d,
        'id': existing?['id'] ?? id,
        'status': existing?['status'] ?? 'todo',
        'createdAt': existing?['createdAt'] ?? now,
        'updatedAt': now,
        'version': (existing?['version'] as int? ?? 0) + 1,
        'updates': existing?['updates'] ?? <Json>[],
        'submissions': existing?['submissions'] ?? <Json>[],
        'reviews': existing?['reviews'] ?? <Json>[],
      };
      put('tasks', t);
      event(
        uid,
        pid,
        existing == null
            ? 'Membuat tugas: ${t['title']}'
            : 'Memperbarui tugas: ${t['title']}',
        t['id'],
      );
      return t;
    }
    final t =
        list('tasks')
            .where((t) => t['id'] == d['taskId'] && t['projectId'] == pid)
            .firstOrNull;
    require(t != null, 'Tugas tidak ditemukan.');
    require(
      t!['version'] == d['version'],
      'Tugas berubah. Muat ulang lalu ulangi tindakan.',
    );
    switch (action) {
      case 'startTask':
        require(
          stringsOf(t, 'assigneeIds').contains(uid) && t['status'] == 'todo',
          'Tugas hanya dapat dimulai penanggung jawab.',
        );
        t['status'] = 'in_progress';
      case 'addUpdate':
        require(
          !['done', 'cancelled'].contains(t['status']),
          'Tugas yang selesai atau dibatalkan tidak dapat diperbarui.',
        );
        require(
          stringsOf(t, 'assigneeIds').contains(uid),
          'Hanya penanggung jawab dapat memperbarui progres.',
        );
        require(
          requiredText(d['message'], max: 2000) == null,
          'Catatan minimal 3 karakter.',
        );
        t['updates'] = [
          ...rowsOf(t, 'updates'),
          {
            'id': id,
            'authorId': uid,
            'message': d['message'],
            'kind': d['kind'],
            'createdAt': now,
          },
        ];
      case 'submitTask':
        canSubmit(t, uid);
        final evidenceUrl = textOf(d, 'url');
        final photoDataUrl = textOf(d, 'photoDataUrl');
        require(
          (evidenceUrl.isNotEmpty && validEvidence(evidenceUrl)) ||
              (photoDataUrl.startsWith('data:image/') &&
                  photoDataUrl.length <= 1000000),
          'Pilih foto atau isi tautan bukti kerja.',
        );
        final submissions = rowsOf(t, 'submissions');
        for (final s in submissions) {
          if (s['status'] == 'pending_review') s['status'] = 'superseded';
        }
        submissions.add({
          'id': id,
          'submittedBy': uid,
          'note': d['note'],
          'evidenceLinks':
              evidenceUrl.isEmpty
                  ? <Json>[]
                  : [
                    {'label': 'Bukti kerja', 'url': evidenceUrl},
                  ],
          'evidenceFiles':
              photoDataUrl.isEmpty
                  ? <Json>[]
                  : [
                    {'label': 'Foto hasil kerja', 'dataUrl': photoDataUrl},
                  ],
          'submittedAt': now,
          'status': 'pending_review',
        });
        t['submissions'] = submissions;
        t['latestSubmissionId'] = id;
        t['status'] = 'submitted';
      case 'reviewSubmission':
        final submissions = rowsOf(t, 'submissions');
        final s = submissions.firstWhere(
          (s) => s['id'] == t['latestSubmissionId'],
        );
        canReview(t, s, uid);
        require(
          ['approved', 'revision_requested'].contains(d['decision']),
          'Keputusan tidak valid.',
        );
        require(
          requiredText(d['comment'], max: 2000) == null,
          'Tambahkan komentar yang jelas, minimal 3 karakter.',
        );
        s['status'] = d['decision'];
        s['reviewedAt'] = now;
        s['reviewedBy'] = uid;
        t['submissions'] = submissions;
        t['reviews'] = [
          ...rowsOf(t, 'reviews'),
          {
            'id': id,
            'submissionId': s['id'],
            'reviewerId': uid,
            'decision': d['decision'],
            'comment': d['comment'],
            'createdAt': now,
          },
        ];
        t['status'] =
            d['decision'] == 'approved' ? 'done' : 'revision_requested';
        if (t['status'] == 'done') t['completedAt'] = now;
      default:
        throw const AppFailure('Tindakan tidak tersedia.');
    }
    t['version'] = (t['version'] as int) + 1;
    t['updatedAt'] = now;
    put('tasks', t);
    event(
      uid,
      pid,
      {
        'startTask': 'Memulai tugas',
        'addUpdate': 'Mencatat pembaruan',
        'submitTask': 'Mengirim bukti kerja',
        'reviewSubmission':
            d['decision'] == 'approved'
                ? 'Menyetujui hasil kerja'
                : 'Meminta revisi',
      }[action]!,
      t['id'],
    );
    return t;
  }
}
