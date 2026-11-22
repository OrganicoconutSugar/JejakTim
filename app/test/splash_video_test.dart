import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejaktim/core/controller.dart';
import 'package:jejaktim/features/auth/auth_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final onboarded in [false, true]) {
    testWidgets(
      'opening waits four seconds then routes correctly (onboarded=$onboarded)',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarded': onboarded});
        final controller = AppController(await SharedPreferences.getInstance());
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
            GoRoute(
              path: '/onboarding',
              builder:
                  (_, __) =>
                      const Scaffold(body: Text('ONBOARDING DESTINATION')),
            ),
            GoRoute(
              path: '/auth/login',
              builder:
                  (_, __) => const Scaffold(body: Text('LOGIN DESTINATION')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [controllerProvider.overrideWith((ref) => controller)],
            child: MaterialApp.router(
              routerConfig: router,
              builder:
                  (context, child) => MediaQuery(
                    data: const MediaQueryData(disableAnimations: true),
                    child: child!,
                  ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('JejakTim'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await tester.pump(const Duration(milliseconds: 3900));
        expect(find.text('JejakTim'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(
          find.text(onboarded ? 'LOGIN DESTINATION' : 'ONBOARDING DESTINATION'),
          findsOneWidget,
        );
      },
    );
  }
}
