import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/features/auth/auth_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'register requires matching passwords and exposes Google sign-in',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final controller = AppController(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [controllerProvider.overrideWith((ref) => controller)],
          child: MaterialApp(
            theme: appTheme(),
            home: const AuthScreen(mode: 'register'),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(4));
      await tester.enterText(fields.at(0), 'Nara Putri');
      await tester.enterText(fields.at(1), 'nara@example.test');
      await tester.enterText(fields.at(2), 'securepass123');
      await tester.enterText(fields.at(3), 'differentpass');
      await tester.ensureVisible(find.text('Buat akun'));
      await tester.tap(find.text('Buat akun'));
      await tester.pump();
      expect(find.text('Kata sandi belum sama.'), findsOneWidget);
      await tester.enterText(fields.at(3), 'securepass123');
      await tester.ensureVisible(find.text('Buat akun'));
      await tester.tap(find.text('Buat akun'));
      await tester.pump();
      expect(find.text('Kata sandi belum sama.'), findsNothing);
      expect(
        find.textContaining('Layanan autentikasi belum siap'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Daftar dengan Google'));
      await tester.tap(find.text('Daftar dengan Google'));
      await tester.pump();
      expect(
        find.textContaining('Masuk dengan Google belum tersedia'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
