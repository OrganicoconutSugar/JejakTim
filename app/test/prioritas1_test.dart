import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/features/insights/insight_screens.dart';
import 'package:jejaktim/features/insights/team_insight_service.dart';
import 'package:jejaktim/features/projects/invite_qr.dart';
import 'package:jejaktim/features/projects/project_screens.dart';
import 'package:jejaktim/features/tasks/task_screens.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_repository.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id'));

  test('anonymized payload excludes names, emails, and evidence URLs', () {
    final repo = FakeTeamRepository();
    final tasks = rowsOf(repo.db, 'tasks');
    final bundle = buildAnonymizedInsightBundle(
      tasks: tasks,
      memberIds: const ['nara', 'raka', 'salsa'],
      memberNames: const {
        'nara': 'Nara Putri',
        'raka': 'Raka Aditya',
        'salsa': 'Salsa Amalia',
      },
    );

    final serialized = jsonEncode(bundle.payload);
    expect(serialized, isNot(contains('Nara')));
    expect(serialized, isNot(contains('nara@example.test')));
    expect(serialized, isNot(contains('https://example.com/wireframe')));
    expect(serialized, contains('Anggota 1'));
    expect(serialized, contains('T1'));
  });

  test('TeamInsightService calls Gemini and de-anonymizes names and task refs', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.host, 'generativelanguage.googleapis.com');
      expect(request.headers['x-goog-api-key'], 'test-gemini-key');
      return http.Response(
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'headline': 'Ritme kolaborasi mulai solid',
                      'summary':
                          'Anggota 1 dan Anggota 2 menjaga progres, namun T2 menunggu review.',
                      'highlights': ['T3 sudah tuntas tepat waktu.'],
                      'recommendations': [
                        {
                          'title': 'Tinjau bukti yang menunggu',
                          'detail':
                              'Anggota 1 bisa meninjau T2 agar Anggota 3 bisa lanjut.',
                          'taskRef': 'T2',
                          'priority': 'high',
                        },
                      ],
                    }),
                  },
                ],
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = TeamInsightService(
      client: mockClient,
      apiKey: 'test-gemini-key',
      model: 'gemini-flash-lite-latest',
    );
    final repo = FakeTeamRepository();
    final result = await service.generateInsight(
      tasks: rowsOf(repo.db, 'tasks'),
      memberIds: const ['nara', 'raka', 'salsa'],
      memberNames: const {
        'nara': 'Nara Putri',
        'raka': 'Raka Aditya',
        'salsa': 'Salsa Amalia',
      },
      ownerId: 'nara',
    );

    expect(result.source, InsightSource.geminiDirect);
    expect(result.modelLabel, 'Gemini Flash Lite');
    expect(result.summary, contains('Nara'));
    expect(result.summary, contains('Raka'));
    expect(result.summary, contains('"Review wireframe aplikasi"'));
    expect(result.recommendations.first.taskId, 't2');
  });

  test('TeamInsightService falls back cleanly to local analyzer on HTTP error', () async {
    final failingClient = MockClient(
      (_) async => http.Response('Service unavailable', 503),
    );
    final service = TeamInsightService(
      client: failingClient,
      apiKey: 'test-gemini-key',
    );
    final repo = FakeTeamRepository();
    final result = await service.generateInsight(
      tasks: rowsOf(repo.db, 'tasks'),
      memberIds: const ['nara', 'raka', 'salsa'],
      memberNames: const {
        'nara': 'Nara Putri',
        'raka': 'Raka Aditya',
        'salsa': 'Salsa Amalia',
      },
      ownerId: 'nara',
    );

    expect(result.source, InsightSource.localSmart);
    expect(result.recommendations, isNotEmpty);
    expect(result.fallbackNote, isNotNull);
  });

  test('analyzeTeamWorkload detects uneven active task distribution', () {
    final tasks = <Json>[
      {'id': '1', 'status': 'in_progress', 'assigneeIds': ['nara']},
      {'id': '2', 'status': 'todo', 'assigneeIds': ['nara']},
      {'id': '3', 'status': 'todo', 'assigneeIds': ['nara']},
      {'id': '4', 'status': 'done', 'assigneeIds': ['raka']},
    ];
    final workload = analyzeTeamWorkload(
      tasks: tasks,
      memberIds: const ['nara', 'raka'],
      memberNames: const {'nara': 'Nara Putri', 'raka': 'Raka Aditya'},
      ownerId: 'nara',
    );

    expect(workload.status, 'needs_balance');
    expect(workload.statusLabel, 'Perlu pemerataan');
  });

  test('extractInviteCode parses QR deep links, web URLs, and raw codes', () {
    expect(extractInviteCode('jejaktim://join/jejak-2026'), 'JEJAK-2026');
    expect(
      extractInviteCode('https://jejaktim.app/projects/invite/ABCD1234/preview'),
      'ABCD1234',
    );
    expect(
      extractInviteCode('https://jejaktim.app/projects/join?code=tim99'),
      'TIM99',
    );
    expect(extractInviteCode('  KODE88  '), 'KODE88');
    expect(extractInviteCode('https://example.com/unrelated'), isNull);
    expect(extractInviteCode('halo dunia!'), isNull);
  });

  testWidgets('InsightsScreen renders workload chart and Gemini CTA without unconfigured error banner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(await SharedPreferences.getInstance());
    await controller.setSessionForTest(FakeTeamRepository(), 'nara');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: appTheme(), home: const InsightsScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Penyedia AI belum dihubungkan'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Keseimbangan beban kerja'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Keseimbangan beban kerja'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Analisis dengan Gemini AI'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Analisis dengan Gemini AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Evidence screen offers both camera capture and gallery upload', (
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
          home: const TaskActionScreen('t1', 'evidence'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Ambil foto'), findsOneWidget);
    expect(find.text('Dari galeri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('InviteQrDialog displays QR widget and JoinScreen offers QR scanner button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: const Scaffold(
          body: InviteQrDialog(
            projectName: 'Proyek Green Campus',
            code: 'JEJAK2026',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('JEJAK2026'), findsOneWidget);
    expect(find.text('Salin kode'), findsOneWidget);
    expect(find.text('Bagikan'), findsOneWidget);

    SharedPreferences.setMockInitialValues({});
    final controller = AppController(await SharedPreferences.getInstance());
    await controller.setSessionForTest(FakeTeamRepository(), 'nara');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(theme: appTheme(), home: const JoinScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Pindai QR undangan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
