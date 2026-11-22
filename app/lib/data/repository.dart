import '../core/models.dart';

abstract class TeamRepository {
  bool get isDemo;
  Future<Json> load(String uid);
  Future<Json> command(String uid, String action, Json payload);
  Future<void> clearSession();
}
