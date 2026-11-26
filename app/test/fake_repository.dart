import 'package:uuid/uuid.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/data/repository.dart';

/// Test-only in-memory repository so widget and unit tests run offline
/// without shipping any demo mode inside `lib/`.
class FakeTeamRepository implements TeamRepository {
  late Json db;

  FakeTeamRepository() {
    db = _seed();
  }

  static Json _seed() {
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
      'description': 'Susun hasil kerja yang jelas lalu minta masukan rekan tim.',
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
        'note': 'Alur utama siap ditinjau.',
        'evidenceLinks': [
          {'label': 'Bukti kerja', 'url': 'https://example.com/wireframe'},
        ],
        'status': 'pending_review',
        'submittedAt': day(-1),
      },
    ];
    pending['latestSubmissionId'] = 's1';
    return {
      'profiles': [
        {
          'uid': 'nara',
          'name': 'Nara Putri',
          'email': 'nara@example.test',
          'major': 'Sistem Informasi',
          'institution': 'Kampus Uji',
        },
        {
          'uid': 'raka',
          'name': 'Raka Aditya',
          'email': 'raka@example.test',
          'major': 'Teknik Informatika',
          'institution': 'Kampus Uji',
        },
        {
          'uid': 'salsa',
          'name': 'Salsa Amalia',
          'email': 'salsa@example.test',
          'major': 'Desain Komunikasi Visual',
          'institution': 'Kampus Uji',
        },
      ],
      'projects': [
        {
          'id': 'p1',
          'name': 'Riset & Desain Aplikasi',
          'description': 'Membangun pengalaman kolaborasi mahasiswa.',
          'courseLabel': 'Interaksi Manusia & Komputer',
          'targetDate': day(12),
          'ownerId': 'nara',
          'status': 'active',
          'memberIds': ['nara', 'raka', 'salsa'],
          'createdAt': day(-7),
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
          'summary': 'Mengirim bukti kerja',
          'createdAt': day(-1),
          'entityId': 't2',
        },
      ],
      'reports': <Json>[],
    };
  }

  List<Json> _list(String key) => rowsOf(db, key);

  @override
  Future<void> clearSession() async {}

  @override
  Future<Json> load(String uid) async {
    final projects =
        _list(
          'projects',
        ).where((p) => stringsOf(p, 'memberIds').contains(uid)).toList();
    final ids = projects.map((p) => p['id']).toSet();
    return {
      'profile': _list('profiles').firstWhere((p) => p['uid'] == uid),
      'profiles': _list('profiles'),
      'projects': projects,
      'tasks':
          _list('tasks').where((t) => ids.contains(t['projectId'])).toList(),
      'activity':
          _list('activity').where((a) => ids.contains(a['projectId'])).toList(),
      'reports':
          _list('reports').where((r) => ids.contains(r['projectId'])).toList(),
    };
  }

  @override
  Future<Json> command(String uid, String action, Json d) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = const Uuid().v4();
    if (action == 'saveProfile') {
      final profiles = _list('profiles');
      final i = profiles.indexWhere((p) => p['uid'] == uid);
      final p = Map<String, dynamic>.from(profiles[i]);
      for (final k in [
        'name',
        'institution',
        'major',
        'notificationPrefs',
        'avatarDataUrl',
      ]) {
        if (d.containsKey(k)) p[k] = d[k];
      }
      profiles[i] = p;
      db['profiles'] = profiles;
      return p;
    }
    if (action == 'generateProjectReport') {
      final pid = textOf(d, 'projectId');
      final p = _list('projects').firstWhere((x) => x['id'] == pid);
      final start = DateTime.parse(d['periodStart']);
      final end = DateTime.parse(d['periodEnd']);
      final tasks =
          _list('tasks')
              .where(
                (t) =>
                    t['projectId'] == pid &&
                    t['deletedAt'] == null &&
                    !DateTime.parse(t['updatedAt']).isBefore(start) &&
                    !DateTime.parse(t['updatedAt']).isAfter(end),
              )
              .toList();
      return {
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
    }
    throw const AppFailure('Tindakan tidak tersedia di fake repository.');
  }
}
