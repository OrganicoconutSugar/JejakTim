import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide OAuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository.dart';
import '../data/demo_repository.dart';
import '../data/firebase_repository.dart';
import '../data/supabase_repository.dart';
import 'evidence_photo.dart';
import 'models.dart';

final controllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw UnimplementedError(),
);

class AppController extends ChangeNotifier {
  final SharedPreferences prefs;
  final bool firebaseReady;
  final bool supabaseReady;
  RealtimeChannel? _workspaceChannel;
  late TeamRepository repository;
  String? uid;
  Json data = {};
  bool loading = false;
  bool busy = false;
  String? error;
  String? bootstrapError;
  AppController(
    this.prefs, {
    this.firebaseReady = false,
    this.supabaseReady = false,
    this.bootstrapError,
  }) {
    repository = DemoRepository(prefs);
  }
  bool get authenticated => uid != null;
  bool get demo => repository.isDemo;
  bool get onboarded => prefs.getBool('onboarded') ?? false;
  Json get profile => Map<String, dynamic>.from(data['profile'] as Map? ?? {});
  List<Json> get projects => rowsOf(data, 'projects');
  List<Json> get tasks => rowsOf(data, 'tasks');
  List<Json> get activity => rowsOf(data, 'activity')
    ..sort((a, b) => textOf(b, 'createdAt').compareTo(textOf(a, 'createdAt')));
  List<Json> get people => rowsOf(data, 'profiles');
  String name(String? id) => textOf(
    people.where((p) => p['uid'] == id).firstOrNull ?? {},
    'name',
    'Anggota',
  );
  Json? project(String id) => projects.where((p) => p['id'] == id).firstOrNull;
  Json? task(String id) => tasks.where((t) => t['id'] == id).firstOrNull;
  List<Json> projectTasks(String id) =>
      tasks.where((t) => t['projectId'] == id).toList();
  bool owner(String id) => project(id)?['ownerId'] == uid;
  Future<void> finishOnboarding() async {
    await prefs.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> restore() async {
    if (supabaseReady && Supabase.instance.client.auth.currentUser != null) {
      repository = SupabaseTeamRepository(Supabase.instance.client);
      uid = Supabase.instance.client.auth.currentUser!.id;
      await repository.command(uid!, 'syncProfile', {
        'name':
            Supabase.instance.client.auth.currentUser!.userMetadata?['name'] ??
            'Mahasiswa',
      });
      await refresh();
      _watchWorkspace();
      return;
    }
    if (firebaseReady && FirebaseAuth.instance.currentUser != null) {
      repository = FirebaseTeamRepository(FirebaseFunctions.instance);
      uid = FirebaseAuth.instance.currentUser!.uid;
      await refresh();
    }
  }

  Future<void> enterDemo([String person = 'nara']) async {
    await _stopWatching();
    repository = DemoRepository(prefs);
    uid = person;
    await refresh();
  }

  Future<void> refresh() async {
    if (uid == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await repository.load(uid!);
    } catch (e) {
      data = {};
      error = errorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password, {String? name}) async {
    if (supabaseReady) {
      final auth = Supabase.instance.client.auth;
      if (name != null) {
        final response = await auth.signUp(
          email: email.trim(),
          password: password,
          data: {'name': name.trim()},
        );
        require(
          response.session != null,
          'Akun dibuat. Periksa email verifikasi, lalu masuk kembali.',
        );
      } else {
        await auth.signInWithPassword(email: email.trim(), password: password);
      }
      final user = auth.currentUser;
      require(user != null, 'Akun belum dapat diverifikasi. Coba lagi.');
      final repo = SupabaseTeamRepository(Supabase.instance.client);
      await repo.command(user!.id, 'syncProfile', {
        'name': name?.trim() ?? user.userMetadata?['name'] ?? 'Mahasiswa',
      });
      repository = repo;
      uid = user.id;
      await refresh();
      _watchWorkspace();
      return;
    }
    require(
      firebaseReady,
      'Layanan autentikasi belum siap. Periksa konfigurasi dan coba lagi.',
    );
    final auth = FirebaseAuth.instance;
    UserCredential result;
    if (name != null) {
      result = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await result.user!.updateDisplayName(name.trim());
    } else {
      result = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    }
    await _completeFirebaseSignIn(result);
  }

  bool _googleInitialized = false;

  Future<void> signInWithGoogle() async {
    if (supabaseReady) {
      final started = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
      require(started, 'Google belum dapat dibuka. Coba lagi.');
      return;
    }
    require(
      firebaseReady,
      'Masuk dengan Google belum tersedia. Firebase perlu dikonfigurasi terlebih dahulu.',
    );
    final auth = FirebaseAuth.instance;
    UserCredential result;
    if (kIsWeb) {
      result = await auth.signInWithPopup(GoogleAuthProvider());
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      if (!_googleInitialized) {
        const serverClientId = String.fromEnvironment(
          'GOOGLE_SERVER_CLIENT_ID',
        );
        await GoogleSignIn.instance.initialize(
          serverClientId: serverClientId.isEmpty ? null : serverClientId,
        );
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      require(
        idToken != null && idToken.isNotEmpty,
        'Google belum dapat memverifikasi akun. Periksa konfigurasi lalu coba lagi.',
      );
      result = await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } else {
      throw const AppFailure(
        'Masuk dengan Google tersedia di Android dan browser web.',
      );
    }
    await _completeFirebaseSignIn(result);
  }

  Future<void> _completeFirebaseSignIn(UserCredential result) async {
    final user = result.user;
    require(user != null, 'Akun belum dapat diverifikasi. Coba lagi.');
    final firebaseRepository = FirebaseTeamRepository(
      FirebaseFunctions.instance,
    );
    final candidateName = (user!.displayName ?? '').trim();
    final profileName = candidateName.length >= 3 ? candidateName : 'Mahasiswa';
    try {
      await firebaseRepository.command(user.uid, 'syncProfile', {
        'name':
            profileName.length > 80
                ? profileName.substring(0, 80)
                : profileName,
      });
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      rethrow;
    }
    repository = firebaseRepository;
    uid = user.uid;
    await refresh();
  }

  Future<void> resetPassword(String email) async {
    if (supabaseReady) {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
      return;
    }
    require(
      firebaseReady,
      'Firebase lokal belum diaktifkan. Reset email tersedia setelah emulator Auth dijalankan.',
    );
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (!['user-not-found', 'invalid-email'].contains(e.code)) rethrow;
    }
  }

  Future<Json> act(String action, Json payload) async {
    require(uid != null, 'Masuk terlebih dahulu.');
    require(!busy, 'Tunggu proses sebelumnya selesai.');
    busy = true;
    notifyListeners();
    try {
      final result = await repository.command(uid!, action, {
        ...payload,
        'requestId': const Uuid().v4(),
      });
      await refresh();
      return result;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String> uploadEvidencePhoto({
    required String projectId,
    required String taskId,
    required Uint8List bytes,
    required EvidencePhotoType type,
  }) async {
    require(
      repository is SupabaseTeamRepository,
      'Unggah foto memerlukan akun Supabase.',
    );
    return (repository as SupabaseTeamRepository).uploadEvidencePhoto(
      projectId: projectId,
      taskId: taskId,
      bytes: bytes,
      type: type,
    );
  }

  Future<Uint8List> downloadEvidencePhoto(String path) async {
    require(repository is SupabaseTeamRepository, 'Foto tidak tersedia.');
    return (repository as SupabaseTeamRepository).downloadEvidencePhoto(path);
  }

  Future<void> logout() async {
    await _stopWatching();
    await repository.clearSession();
    if (firebaseReady && !demo && repository is FirebaseTeamRepository) {
      await FirebaseAuth.instance.signOut();
    }
    uid = null;
    data = {};
    error = null;
    notifyListeners();
  }

  void _watchWorkspace() {
    if (repository is! SupabaseTeamRepository || uid == null) return;
    _workspaceChannel = (repository as SupabaseTeamRepository).watch(uid!, () {
      if (!loading && !busy) refresh();
    });
  }

  Future<void> _stopWatching() async {
    final channel = _workspaceChannel;
    _workspaceChannel = null;
    if (channel != null && supabaseReady) {
      await Supabase.instance.client.removeChannel(channel);
    }
  }

  Future<void> resetDemo() async {
    if (repository is DemoRepository) {
      await (repository as DemoRepository).reset();
      await refresh();
    }
  }
}

String errorMessage(Object e) {
  if (e is AppFailure) return e.message;
  if (e is AuthException) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Email atau kata sandi belum cocok.';
    }
    if (message.contains('email not confirmed')) {
      return 'Periksa email verifikasi, lalu masuk kembali.';
    }
    if (message.contains('already registered')) {
      return 'Email sudah terdaftar. Coba masuk atau reset kata sandi.';
    }
    if (message.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Tunggu sebentar.';
    }
    return 'Autentikasi belum berhasil. Periksa isian dan coba lagi.';
  }
  if (e is PostgrestException) return e.message;
  if (e is GoogleSignInException) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode
          .interrupted => 'Login Google dibatalkan. Silakan coba lagi.',
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Masuk dengan Google belum dikonfigurasi. Hubungi pengelola aplikasi.',
      _ =>
        'Masuk dengan Google belum berhasil. Periksa koneksi lalu coba lagi.',
    };
  }
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'popup-closed-by-user' || 'cancelled-popup-request' =>
        'Login Google dibatalkan. Silakan coba lagi.',
      'popup-blocked' =>
        'Browser memblokir jendela Google. Izinkan pop-up lalu coba lagi.',
      'account-exists-with-different-credential' =>
        'Email sudah menggunakan metode masuk lain. Masuk dengan metode sebelumnya.',
      'operation-not-allowed' =>
        'Masuk Google belum diaktifkan. Hubungi pengelola aplikasi.',
      'network-request-failed' =>
        'Tidak terhubung. Periksa koneksi lalu coba lagi.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email atau kata sandi belum cocok.',
      'email-already-in-use' =>
        'Email tidak dapat dipakai. Coba masuk atau reset kata sandi.',
      'weak-password' => 'Gunakan kata sandi minimal 8 karakter.',
      'too-many-requests' => 'Terlalu banyak percobaan. Tunggu sebentar.',
      _ => 'Autentikasi gagal. Periksa isian dan coba lagi.',
    };
  }
  if (e is FirebaseFunctionsException) {
    return e.message ?? 'Layanan belum tersedia. Coba lagi.';
  }
  return 'Tidak dapat menyelesaikan tindakan. Periksa koneksi dan coba lagi.';
}
