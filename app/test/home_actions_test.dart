import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/features/projects/project_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fake_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  for (final size in [const Size(360, 800), const Size(800, 390)]) {
    testWidgets('home shows primary project actions at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final controller = AppController(await SharedPreferences.getInstance());
      await controller.setSessionForTest(FakeTeamRepository(), 'nara');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => controller)],
          child: MaterialApp(theme: appTheme(), home: const HomeScreen()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('demo', findRichText: true), findsNothing);
      expect(find.text('Buat proyek baru'), findsOneWidget);
      expect(find.text('Gabung dengan kode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
