import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/core/design.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/features/auth/auth_screens.dart';

void main() {
  test('auth validators reject malformed inputs', () {
    expect(emailError('test'), isNotNull);
    expect(emailError('nara@example.test'), isNull);
    expect(requiredText(' '), isNotNull);
  });
  testWidgets('login validates required fields and remains usable at 360px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final c = AppController(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [controllerProvider.overrideWith((ref) => c)],
        child: MaterialApp(theme: appTheme(), home: const AuthScreen()),
      ),
    );
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
