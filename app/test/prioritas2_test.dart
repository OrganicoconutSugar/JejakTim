import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/features/projects/project_screens.dart';
import 'package:jejaktim/features/projects/project_templates.dart';
import 'package:jejaktim/features/reports/report_screens.dart';
import 'package:jejaktim/features/tasks/task_screens.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_repository.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id'));

  test('computeReportIntegrityCode is deterministic and sensitive to tampering', () async {
    final repo = FakeTeamRepository();
    final report = await repo.command('nara', 'generateProjectReport', {
      'projectId': 'p1',
      'periodStart': '2020-01-01T00:00:00Z',
      'periodEnd': '2099-01-01T00:00:00Z',
    });

    final code1 = computeReportIntegrityCode(report);
    final code2 = computeReportIntegrityCode(report);
    expect(code1, code2);
    expect(code1, matches(RegExp(r'^JT-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$')));

    final tampered = Map<String, dynamic>.from(report);
    final tasks = rowsOf(report, 'tasks');
    tasks.first['status'] = 'done';
    tampered['tasks'] = tasks;
    final tamperedCode = computeReportIntegrityCode(tampered);
    expect(tamperedCode, isNot(code1));
  });

  test('computePaperlessImpact tallies digital records and paper saved', () {
    final tasks = <Json>[
      {
        'id': 't1',
        'submissions': [{'id': 's1'}],
        'reviews': [{'id': 'r1'}],
        'updates': [{'id': 'u1'}, {'id': 'u2'}],
      },
      {
        'id': 't2',
        'submissions': <Json>[],
        'reviews': <Json>[],
        'updates': <Json>[],
      },
    ];
    final impact = computePaperlessImpact(tasks);
    expect(impact.totalTasks, 2);
    expect(impact.submissions, 1);
    expect(impact.reviews, 1);
    expect(impact.updates, 2);
    expect(impact.totalDigitalRecords, 6);
    expect(impact.estimatedSheetsSaved, 7);
    expect(impact.estimatedCo2GramsSaved, 35);
  });

  test('inferTemplateForProject detects Green Campus, KKN, and Organisasi', () {
    expect(
      inferTemplateForProject({
        'name': 'Bank Sampah Kampus',
        'courseLabel': 'Green Campus',
      }).id,
      'green_campus',
    );
    expect(
      inferTemplateForProject({
        'name': 'Digitalisasi UMKM Desa',
        'courseLabel': 'KKN Tematik',
      }).id,
      'kkn',
    );
    expect(
      inferTemplateForProject({
        'name': 'Seminar Nasional IT',
        'courseLabel': 'Kepanitiaan Himpunan',
      }).id,
      'organization',
    );
  });

  test('buildReportPdf includes verified QR and paperless summary cleanly', () async {
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
    expect(bytes.length, greaterThan(6000));
  });

  testWidgets('ProjectFormScreen shows Impact templates and prefills Green Campus', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final controller = AppController(await SharedPreferences.getInstance());
    await controller.setSessionForTest(FakeTeamRepository(), 'nara');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: appTheme(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: ProjectFormScreen(),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Green Campus'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Green Campus'));
    await tester.pump();
    await tester.tap(find.text('Green Campus'));
    await tester.pump();

    expect(find.textContaining('SDG 13'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReportScreen preview shows paperless impact and verification QR', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(await SharedPreferences.getInstance());
    await controller.setSessionForTest(FakeTeamRepository(), 'nara');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: appTheme(),
          home: const ReportScreen('p1'),
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Buat pratinjau laporan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Buat pratinjau laporan'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('JEJAK PAPERLESS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('JEJAK PAPERLESS'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('VERIFIKASI INTEGRITAS SNAPSHOT'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('VERIFIKASI INTEGRITAS SNAPSHOT'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TaskFormScreen prefills starter task title and description', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(await SharedPreferences.getInstance());
    await controller.setSessionForTest(FakeTeamRepository(), 'nara');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: appTheme(),
          home: const TaskFormScreen(
            'p1',
            initialTitle: 'Audit kebiasaan kampus hijau',
            initialDescription: 'Dokumentasikan titik sampah dan foto lapangan.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Audit kebiasaan kampus hijau'), findsOneWidget);
    expect(
      find.text('Dokumentasikan titik sampah dan foto lapangan.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
