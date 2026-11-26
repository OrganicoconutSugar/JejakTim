import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/features/insights/insight_screens.dart';
import 'fake_repository.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('id'));
  test('activitySummary maps raw Supabase actions to Indonesian labels', () {
    expect(activitySummary({'summary': 'saveTask'}), 'Menyimpan perubahan tugas');
    expect(activitySummary({'summary': 'startTask'}), 'Memulai tugas');
    expect(
      activitySummary({'summary': 'Mengirim wireframe untuk ditinjau'}),
      'Mengirim wireframe untuk ditinjau',
    );
  });

  testWidgets('PrimaryButton renders white icon and white spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: const Scaffold(
          body: PrimaryButton('Masuk', icon: LucideIcons.arrowRight),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.arrowRight));
    expect(icon.color, Colors.white);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: const Scaffold(body: PrimaryButton('Masuk', busy: true)),
      ),
    );
    final spinner = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(spinner.color, Colors.white);
  });

  testWidgets('Avatar trims whitespace and supports profile photo dataUrl', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Avatar('  nara   putri  '))),
    );
    expect(find.text('NP'), findsOneWidget);

    // 1x1 transparent PNG
    const pngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Avatar(
            'Nara Putri',
            avatarDataUrl: 'data:image/png;base64,$pngBase64',
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('InsightsScreen handles unknown projectId without crashing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(await SharedPreferences.getInstance());
    await controller.setSessionForTest(FakeTeamRepository(), 'nara');
    await controller.act('saveProfile', {
      'name': 'Nara Putri',
      'avatarDataUrl':
          'data:image/png;base64,${base64Encode([137, 80, 78, 71])}',
    });
    expect(controller.avatarOf('nara'), startsWith('data:image/png'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => controller)],
        child: MaterialApp(
          theme: appTheme(),
          home: const InsightsScreen(projectId: 'non-existent-id'),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
