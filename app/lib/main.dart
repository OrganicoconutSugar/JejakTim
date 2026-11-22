import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/controller.dart';
import 'core/design.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  final prefs = await SharedPreferences.getInstance();
  bool ready = false;
  String? bootError;
  bool supabaseReady = false;
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      supabaseReady = true;
    } catch (_) {
      bootError = 'Supabase belum siap. Periksa konfigurasi koneksi.';
    }
  }
  if (const bool.fromEnvironment('USE_FIREBASE')) {
    try {
      const emulator = bool.fromEnvironment(
        'USE_EMULATORS',
        defaultValue: true,
      );
      const projectId = String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'demo-jejaktim',
      );
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment(
            'FIREBASE_API_KEY',
            defaultValue: 'demo-emulator-only',
          ),
          appId: String.fromEnvironment(
            'FIREBASE_APP_ID',
            defaultValue: '1:123456789:android:demojejaktim',
          ),
          messagingSenderId: String.fromEnvironment(
            'FIREBASE_SENDER_ID',
            defaultValue: '123456789',
          ),
          projectId: projectId,
          authDomain: String.fromEnvironment(
            'FIREBASE_AUTH_DOMAIN',
            defaultValue: 'demo-jejaktim.firebaseapp.com',
          ),
        ),
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (emulator) {
        const host = String.fromEnvironment(
          'EMULATOR_HOST',
          defaultValue: '10.0.2.2',
        );
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      }
      ready = true;
    } catch (_) {
      bootError = 'Firebase belum siap. Periksa konfigurasi koneksi.';
    }
  }
  final controller = AppController(
    prefs,
    firebaseReady: ready,
    supabaseReady: supabaseReady,
    bootstrapError: bootError,
  );
  runApp(
    ProviderScope(
      overrides: [controllerProvider.overrideWith((ref) => controller)],
      child: const JejakTimApp(),
    ),
  );
}

class JejakTimApp extends ConsumerStatefulWidget {
  const JejakTimApp({super.key});
  @override
  ConsumerState<JejakTimApp> createState() => _AppState();
}

class _AppState extends ConsumerState<JejakTimApp> {
  late final router = makeRouter(ref.read(controllerProvider));
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'JejakTim AI',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    routerConfig: router,
    builder:
        (context, child) => ColoredBox(
          color: const Color(0xFFF2F5FA),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: child!,
            ),
          ),
        ),
  );
}
