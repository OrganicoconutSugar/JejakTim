import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final controller = AppController(
    prefs,
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
