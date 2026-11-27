import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import 'evidence_photo.dart';
import 'models.dart';

final controllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw UnimplementedError(),
);

class AppController extends ChangeNotifier {
  final SharedPreferences prefs;
  final bool supabaseReady;
  RealtimeChannel? _workspaceChannel;
  StreamSubscription<AuthState>? _authSub;
  Future<void>? _attachingSupabase;
  TeamRepository? repository;
  String? uid;
  Json data = {};
  bool loading = false;
  bool busy = false;
  String? error;
  String? bootstrapError;
  AppController(
    this.prefs, {
    this.supabaseReady = false,
    this.bootstrapError,
    this.repository,
  }) {
    if (supabaseReady) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
        event,
      ) {
        final sessionUser = event.session?.user;
        if (event.event == AuthChangeEvent.signedOut) {
          if (uid != null) {
            unawaited(_clearLocalState());
          }
          return;
        }
        if (sessionUser != null && uid != sessionUser.id) {
          unawaited(_attachSupabaseUser(sessionUser));
        }
      });
    }
  }
  bool get authenticated => uid != null;
  bool get onboarded => prefs.getBool('onboarded') ?? false;
  Json get profile => Map<String, dynamic>.from(data['profile'] as Map? ?? {});
  List<Json> get projects => rowsOf(data, 'projects');
  List<Json> get tasks =>
      rowsOf(data, 'tasks').where((task) => task['deletedAt'] == null).toList();
  List<Json> get activity => rowsOf(data, 'activity')
    ..sort((a, b) => textOf(b, 'createdAt').compareTo(textOf(a, 'createdAt')));
  List<Json> get people => rowsOf(data, 'profiles');
  String name(String? id) => textOf(
    people.where((p) => p['uid'] == id).firstOrNull ?? {},
    'name',
    'Anggota',
  );
  String avatarOf(String? id) {
    if (id == null) return '';
    if (id == uid) {
      final own = textOf(profile, 'avatarDataUrl');
      if (own.isNotEmpty) return own;
    }
    return textOf(
      people.where((p) => p['uid'] == id).firstOrNull ?? {},
      'avatarDataUrl',
    );
  }
  Json? project(String id) => projects.where((p) => p['id'] == id).firstOrNull;
  Json? task(String id) => tasks.where((t) => t['id'] == id).firstOrNull;
  List<Json> projectTasks(String id) =>
      tasks.where((t) => t['projectId'] == id).toList();
  bool owner(String id) => project(id)?['ownerId'] == uid;
  bool notificationCategoryEnabled(String category) =>
      prefs.getBool('notifications.$uid.$category') ?? true;

  bool get notificationsDisabled =>
      (profile['notificationPrefs'] as Map?)?['inApp'] == false;

  List<Json> get notificationTasks {
    if (notificationsDisabled || uid == null) return const [];
    final showReview = notificationCategoryEnabled('review');
    final showRevision = notificationCategoryEnabled('revision');
    final showDeadline = notificationCategoryEnabled('deadline');
    final now = today();
    final cutoff = DateTime(now.year, now.month, now.day + 4);
    return tasks.where((t) {
      if (project(textOf(t, 'projectId'))?['status'] != 'active') {
        return false;
      }
      final status = t['status'];
      if (showReview && t['reviewerId'] == uid && status == 'submitted') {
        return true;
      }
      if (!stringsOf(t, 'assigneeIds').contains(uid)) return false;
      if (showRevision && status == 'revision_requested') return true;
      if (!showDeadline ||
          !['todo', 'in_progress', 'revision_requested'].contains(status)) {
        return false;
      }
      final deadline = dateOf(t, 'dueAt');
      return deadline != null &&
          !deadline.isBefore(now) &&
          deadline.isBefore(cutoff);
    }).toList();
  }

  int get notificationCount => notificationTasks.length;

  Future<void> setNotificationCategory(String category, bool enabled) async {
    await prefs.setBool('notifications.$uid.$category', enabled);
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    await prefs.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> _attachSupabaseUser(
    User user, {
    String? explicitName,
  }) async {
    if (_attachingSupabase != null) return _attachingSupabase;
    final task = () async {
      final repo = SupabaseTeamRepository(Supabase.instance.client);
      final candidate =
          explicitName?.trim() ??
          user.userMetadata?['name']?.toString().trim() ??
          user.userMetadata?['full_name']?.toString().trim() ??
          '';
      await repo.command(user.id, 'syncProfile', {
        'name': candidate.length >= 3 ? candidate : 'Mahasiswa',
      });
      repository = repo;
      uid = user.id;
      await _stopWatching();
      await refresh();
      _watchWorkspace();
    }();
    _attachingSupabase = task;
    try {
      await task;
    } finally {
      if (identical(_attachingSupabase, task)) {
        _attachingSupabase = null;
      }
    }
  }

  Future<void> restore() async {
    if (supabaseReady && Supabase.instance.client.auth.currentUser != null) {
      await _attachSupabaseUser(Supabase.instance.client.auth.currentUser!);
    }
  }

  @visibleForTesting
  Future<void> setSessionForTest(TeamRepository repo, String testUid) async {
    await _stopWatching();
    repository = repo;
    uid = testUid;
    await refresh();
  }

  Future<void> refresh() async {
    final repo = repository;
    if (uid == null || repo == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await repo.load(uid!);
    } catch (e) {
      data = {};
      error = errorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password, {String? name}) async {
    require(
      supabaseReady,
      'Layanan autentikasi belum siap. Periksa konfigurasi dan coba lagi.',
    );
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
    await _attachSupabaseUser(user!, explicitName: name);
  }

  Future<void> signInWithGoogle() async {
    require(
      supabaseReady,
      'Masuk dengan Google belum tersedia. Supabase perlu dikonfigurasi terlebih dahulu.',
    );
    final started = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : 'jejaktim://login-callback',
    );
    require(started, 'Google belum dapat dibuka. Coba lagi.');
  }

  Future<void> resetPassword(String email) async {
    require(
      supabaseReady,
      'Layanan reset kata sandi belum siap. Periksa konfigurasi Supabase.',
    );
    await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<Json> act(String action, Json payload) async {
    final repo = repository;
    require(uid != null && repo != null, 'Masuk terlebih dahulu.');
    require(!busy, 'Tunggu proses sebelumnya selesai.');
    busy = true;
    notifyListeners();
    try {
      final result = await repo!.command(uid!, action, {
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
    final repo = repository;
    require(
      repo is SupabaseTeamRepository,
      'Unggah foto memerlukan akun Supabase.',
    );
    return (repo as SupabaseTeamRepository).uploadEvidencePhoto(
      projectId: projectId,
      taskId: taskId,
      bytes: bytes,
      type: type,
    );
  }

  Future<Uint8List> downloadEvidencePhoto(String path) async {
    final repo = repository;
    require(repo is SupabaseTeamRepository, 'Foto tidak tersedia.');
    return (repo as SupabaseTeamRepository).downloadEvidencePhoto(path);
  }

  Future<void> _clearLocalState() async {
    await _stopWatching();
    repository = null;
    uid = null;
    data = {};
    error = null;
    notifyListeners();
  }

  Future<void> logout() async {
    final repo = repository;
    await _stopWatching();
    if (repo != null) {
      await repo.clearSession();
    }
    repository = null;
    uid = null;
    data = {};
    error = null;
    notifyListeners();
  }

  void _watchWorkspace() {
    final repo = repository;
    if (repo is! SupabaseTeamRepository || uid == null) return;
    _workspaceChannel = repo.watch(uid!, () {
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

  @override
  void dispose() {
    unawaited(_authSub?.cancel());
    unawaited(_stopWatching());
    super.dispose();
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
  return 'Tidak dapat menyelesaikan tindakan. Periksa koneksi dan coba lagi.';
}
