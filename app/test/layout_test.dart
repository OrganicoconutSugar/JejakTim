import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/features/auth/auth_screens.dart';
import 'package:jejaktim/features/projects/project_screens.dart';
import 'package:jejaktim/features/tasks/task_screens.dart';
import 'package:jejaktim/features/insights/insight_screens.dart';
import 'package:jejaktim/features/profile/profile_screens.dart';
import 'package:jejaktim/features/reports/report_screens.dart';
import 'fake_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    final loader = FontLoader('Outfit')
      ..addFont(rootBundle.load('assets/fonts/Outfit-400.ttf'));
    await loader.load();
  });
  testWidgets('onboarding shows the three supplied photos in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final c = AppController(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(theme: appTheme(), home: const OnboardingScreen()),
      ),
    );
    for (final photo in [
      'assets/onboarding/tim-bersama.png',
      'assets/onboarding/jejak-langkah.png',
      'assets/onboarding/tumbuh-bersama.png',
    ]) {
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == photo,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (photo != 'assets/onboarding/tumbuh-bersama.png') {
        await tester.tap(find.text('Lanjut'));
      }
    }
  });
  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
    const Size(800, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('screens fit ${size.width}x${size.height}, text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final screens = <Widget>[
          const AuthScreen(),
          const OnboardingScreen(),
          const HomeScreen(),
          const ProjectsScreen(),
          const ProjectDetailScreen('p1'),
          const TasksScreen(),
          const TaskDetailScreen('t1'),
          const TaskActionScreen('t1', 'evidence'),
          const TaskFormScreen('p1'),
          const InsightsScreen(),
          const ReportScreen('p1'),
          const ProfileScreen(),
        ];
        for (final screen in screens) {
          final c = AppController(await SharedPreferences.getInstance());
          await c.setSessionForTest(FakeTeamRepository(), 'nara');
          await tester.pumpWidget(
            ProviderScope(
              overrides: [controllerProvider.overrideWith((ref) => c)],
              child: MaterialApp(
                theme: appTheme(),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: screen,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} at $size / $scale',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
}
