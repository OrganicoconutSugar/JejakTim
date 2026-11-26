import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/features/reports/report_screens.dart';
import 'fake_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildMemberContributions tallies assigned, done, submissions, reviews, and updates', () {
    final tasks = <Json>[
      {
        'id': 't1',
        'title': 'Riset',
        'status': 'done',
        'assigneeIds': ['nara'],
        'reviewerId': 'raka',
        'submissions': [
          {'submittedBy': 'nara'},
        ],
        'reviews': [
          {'reviewerId': 'raka'},
        ],
        'updates': [
          {'authorId': 'nara'},
          {'authorId': 'nara'},
        ],
      },
      {
        'id': 't2',
        'title': 'Desain',
        'status': 'submitted',
        'assigneeIds': ['nara', 'salsa'],
        'reviewerId': 'raka',
        'submissions': [
          {'submittedBy': 'salsa'},
        ],
        'reviews': <Json>[],
        'updates': <Json>[],
      },
    ];

    final rows = buildMemberContributions(
      tasks,
      memberIds: const ['nara', 'raka', 'salsa'],
      memberNames: const {
        'nara': 'Nara Putri',
        'raka': 'Raka Aditya',
        'salsa': 'Salsa Amalia',
      },
    );

    final byUid = {for (final row in rows) row.uid: row};
    expect(byUid['nara']!.assigned, 2);
    expect(byUid['nara']!.done, 1);
    expect(byUid['nara']!.submissions, 1);
    expect(byUid['nara']!.reviews, 0);
    expect(byUid['nara']!.updates, 2);

    expect(byUid['raka']!.assigned, 0);
    expect(byUid['raka']!.reviews, 1);

    expect(byUid['salsa']!.assigned, 1);
    expect(byUid['salsa']!.done, 0);
    expect(byUid['salsa']!.submissions, 1);
  });

  test('report snapshot exports readable PDF bytes with member contributions', () async {
    await initializeDateFormatting('id');
    final repo = FakeTeamRepository();
    final report = await repo.command('nara', 'generateProjectReport', {
      'projectId': 'p1',
      'periodStart': '2020-01-01T00:00:00Z',
      'periodEnd': '2099-01-01T00:00:00Z',
    });

    final bytes = await buildReportPdf(
      report,
      memberIds: const ['nara', 'raka', 'salsa'],
      memberNames: const {
        'nara': 'Nara Putri',
        'raka': 'Raka Aditya',
        'salsa': 'Salsa Amalia',
      },
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(5000));
  });
}
