import 'package:cloud_functions/cloud_functions.dart';
import '../core/models.dart';
import 'repository.dart';

class FirebaseTeamRepository implements TeamRepository {
  final FirebaseFunctions functions;
  FirebaseTeamRepository(this.functions);
  Json normalize(dynamic value) => Map<String, dynamic>.from(
    value as Map,
  ).map((k, v) => MapEntry(k, convert(v)));
  dynamic convert(dynamic v) =>
      v is Map
          ? v.map((k, val) => MapEntry(k.toString(), convert(val)))
          : v is List
          ? v.map(convert).toList()
          : v;
  @override
  Future<Json> load(String uid) async =>
      normalize((await functions.httpsCallable('getWorkspace').call()).data);
  @override
  Future<Json> command(String uid, String action, Json payload) async =>
      normalize((await functions.httpsCallable(action).call(payload)).data);
  @override
  Future<void> clearSession() async {}
}
